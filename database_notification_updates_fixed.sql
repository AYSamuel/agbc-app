-- Database Notification Updates - Fixed Version
-- This script adds notification management functions for OneSignal integration
-- Note: The main schema file already includes all necessary columns and indexes

-- Function to get pending notifications ready for processing
CREATE OR REPLACE FUNCTION get_pending_notifications(
    batch_size INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    type notification_type,
    title TEXT,
    message TEXT,
    data JSONB,
    scheduled_for TIMESTAMPTZ,
    retry_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.user_id,
        n.type,
        n.title,
        n.message,
        n.data,
        n.scheduled_for,
        n.retry_count
    FROM notifications n
    WHERE n.delivery_status = 'pending'
      AND (n.scheduled_for IS NULL OR n.scheduled_for <= NOW())
      AND n.retry_count < 3
    ORDER BY 
        COALESCE(n.scheduled_for, n.created_at) ASC
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update notification delivery status
CREATE OR REPLACE FUNCTION update_notification_delivery(
    notification_id UUID,
    new_status notification_delivery_status,
    onesignal_id TEXT DEFAULT NULL,
    error_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE notifications 
    SET 
        delivery_status = new_status,
        onesignal_notification_id = COALESCE(onesignal_id, onesignal_notification_id),
        is_push_sent = CASE 
            WHEN new_status IN ('sent', 'delivered') THEN TRUE 
            ELSE is_push_sent 
        END,
        failure_reason = CASE 
            WHEN new_status = 'failed' THEN error_message 
            ELSE failure_reason 
        END,
        retry_count = CASE 
            WHEN new_status = 'failed' THEN retry_count + 1 
            ELSE retry_count 
        END,
        last_retry_at = CASE 
            WHEN new_status = 'failed' THEN NOW() 
            ELSE last_retry_at 
        END,
        updated_at = NOW()
    WHERE id = notification_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to schedule meeting notifications
CREATE OR REPLACE FUNCTION schedule_meeting_notifications(
    meeting_id UUID,
    meeting_title TEXT,
    meeting_datetime TIMESTAMPTZ,
    branch_id UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    user_record RECORD;
    notification_count INTEGER := 0;
    reminder_times INTEGER[] := ARRAY[1440, 60, 15]; -- 24 hours, 1 hour, 15 minutes before
    reminder_time INTEGER;
    scheduled_time TIMESTAMPTZ;
BEGIN
    -- Get users to notify (branch members or all users if no branch specified)
    FOR user_record IN 
        SELECT u.id, u.display_name
        FROM users u
        WHERE u.is_active = TRUE
          AND u.notification_settings->>'meeting_notifications' != 'false'
          AND (branch_id IS NULL OR u.branch_id = schedule_meeting_notifications.branch_id)
    LOOP
        -- Create notifications for each reminder time
        FOREACH reminder_time IN ARRAY reminder_times
        LOOP
            scheduled_time := meeting_datetime - (reminder_time || ' minutes')::INTERVAL;
            
            -- Only schedule if the reminder time is in the future
            IF scheduled_time > NOW() THEN
                INSERT INTO notifications (
                    user_id,
                    type,
                    title,
                    message,
                    data,
                    scheduled_for,
                    related_entity_id,
                    related_entity_type,
                    scheduling_config
                ) VALUES (
                    user_record.id,
                    'meeting_reminder',
                    CASE 
                        WHEN reminder_time >= 1440 THEN 'Meeting Tomorrow'
                        WHEN reminder_time >= 60 THEN 'Meeting in 1 Hour'
                        ELSE 'Meeting Starting Soon'
                    END,
                    CASE 
                        WHEN reminder_time >= 1440 THEN meeting_title || ' is scheduled for tomorrow'
                        WHEN reminder_time >= 60 THEN meeting_title || ' starts in 1 hour'
                        ELSE meeting_title || ' starts in 15 minutes'
                    END,
                    jsonb_build_object(
                        'meeting_id', meeting_id,
                        'meeting_title', meeting_title,
                        'meeting_datetime', meeting_datetime,
                        'reminder_minutes', reminder_time
                    ),
                    scheduled_time,
                    meeting_id,
                    'meeting',
                    jsonb_build_object(
                        'reminder_type', 'meeting',
                        'minutes_before', reminder_time
                    )
                );
                
                notification_count := notification_count + 1;
            END IF;
        END LOOP;
    END LOOP;
    
    RETURN notification_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cancel meeting notifications
CREATE OR REPLACE FUNCTION cancel_meeting_notifications(
    meeting_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    cancelled_count INTEGER;
BEGIN
    UPDATE notifications 
    SET 
        delivery_status = 'cancelled',
        updated_at = NOW()
    WHERE related_entity_id = meeting_id
      AND related_entity_type = 'meeting'
      AND delivery_status = 'pending'
      AND scheduled_for > NOW();
    
    GET DIAGNOSTICS cancelled_count = ROW_COUNT;
    RETURN cancelled_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create task notifications
CREATE OR REPLACE FUNCTION create_task_notification(
    task_id UUID,
    notification_type notification_type,
    recipient_user_id UUID,
    custom_title TEXT DEFAULT NULL,
    custom_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    task_record RECORD;
    notification_id UUID;
    final_title TEXT;
    final_message TEXT;
BEGIN
    -- Get task details
    SELECT t.title, t.description, t.due_date, u.display_name as assigned_to_name
    INTO task_record
    FROM tasks t
    LEFT JOIN users u ON t.assigned_to = u.id
    WHERE t.id = task_id;
    
    -- Generate title and message based on type
    final_title := COALESCE(custom_title, 
        CASE notification_type
            WHEN 'task_assigned' THEN 'New Task Assigned'
            WHEN 'task_due' THEN 'Task Due Soon'
            WHEN 'task_completed' THEN 'Task Completed'
            ELSE 'Task Update'
        END
    );
    
    final_message := COALESCE(custom_message,
        CASE notification_type
            WHEN 'task_assigned' THEN 'You have been assigned: ' || task_record.title
            WHEN 'task_due' THEN task_record.title || ' is due soon'
            WHEN 'task_completed' THEN task_record.title || ' has been completed'
            ELSE 'Task ' || task_record.title || ' has been updated'
        END
    );
    
    -- Create notification
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        data,
        related_entity_id,
        related_entity_type
    ) VALUES (
        recipient_user_id,
        notification_type,
        final_title,
        final_message,
        jsonb_build_object(
            'task_id', task_id,
            'task_title', task_record.title,
            'task_description', task_record.description,
            'due_date', task_record.due_date,
            'assigned_to_name', task_record.assigned_to_name
        ),
        task_id,
        'task'
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create notification analytics view
CREATE OR REPLACE VIEW notification_analytics AS
SELECT 
    DATE_TRUNC('day', created_at) as date,
    type,
    delivery_status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (COALESCE(updated_at, created_at) - created_at))) as avg_processing_time_seconds
FROM notifications 
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at), type, delivery_status
ORDER BY date DESC, type, delivery_status;

-- Grant permissions
GRANT SELECT ON notification_analytics TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_notifications(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION update_notification_delivery(UUID, notification_delivery_status, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION schedule_meeting_notifications(UUID, TEXT, TIMESTAMPTZ, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_meeting_notifications(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_task_notification(UUID, notification_type, UUID, TEXT, TEXT) TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION get_pending_notifications IS 'Retrieves notifications ready for processing by background services';
COMMENT ON FUNCTION update_notification_delivery IS 'Updates notification delivery status and OneSignal integration data';
COMMENT ON FUNCTION schedule_meeting_notifications IS 'Creates scheduled reminder notifications for meetings';
COMMENT ON FUNCTION cancel_meeting_notifications IS 'Cancels pending notifications for a meeting';
COMMENT ON FUNCTION create_task_notification IS 'Creates notifications for task-related events';
COMMENT ON VIEW notification_analytics IS 'Provides analytics data for notification delivery and performance';