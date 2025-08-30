

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."meeting_status" AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."meeting_status" OWNER TO "postgres";


CREATE TYPE "public"."notification_delivery_status" AS ENUM (
    'pending',
    'sent',
    'delivered',
    'failed',
    'cancelled'
);


ALTER TYPE "public"."notification_delivery_status" OWNER TO "postgres";


CREATE TYPE "public"."notification_type" AS ENUM (
    'task_assigned',
    'task_due',
    'task_completed',
    'meeting_reminder',
    'meeting_cancelled',
    'meeting_updated',
    'comment_added',
    'role_changed',
    'branch_announcement',
    'general'
);


ALTER TYPE "public"."notification_type" OWNER TO "postgres";


CREATE TYPE "public"."task_priority" AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


ALTER TYPE "public"."task_priority" OWNER TO "postgres";


CREATE TYPE "public"."task_status" AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."task_status" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'pastor',
    'worker',
    'member'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cancel_meeting_notifications"("meeting_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."cancel_meeting_notifications"("meeting_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."cancel_meeting_notifications"("meeting_id" "uuid") IS 'Cancels pending notifications for a meeting';



CREATE OR REPLACE FUNCTION "public"."create_task_notification"("task_id" "uuid", "notification_type" "public"."notification_type", "recipient_user_id" "uuid", "custom_title" "text" DEFAULT NULL::"text", "custom_message" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."create_task_notification"("task_id" "uuid", "notification_type" "public"."notification_type", "recipient_user_id" "uuid", "custom_title" "text", "custom_message" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_task_notification"("task_id" "uuid", "notification_type" "public"."notification_type", "recipient_user_id" "uuid", "custom_title" "text", "custom_message" "text") IS 'Creates notifications for task-related events';



CREATE OR REPLACE FUNCTION "public"."get_current_user_branch_id"() RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    branch_uuid UUID;
BEGIN
    SELECT branch_id INTO branch_uuid 
    FROM public.users 
    WHERE id = auth.uid() AND is_active = true;
    
    RETURN branch_uuid;
EXCEPTION 
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."get_current_user_branch_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_role"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    user_role_value TEXT;
BEGIN
    SELECT role::TEXT INTO user_role_value 
    FROM public.users 
    WHERE id = auth.uid() AND is_active = true;
    
    RETURN COALESCE(user_role_value, 'member');
EXCEPTION 
    WHEN OTHERS THEN
        RETURN 'member';
END;
$$;


ALTER FUNCTION "public"."get_current_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_pending_notifications"("batch_size" integer DEFAULT 50) RETURNS TABLE("id" "uuid", "user_id" "uuid", "type" "public"."notification_type", "title" "text", "message" "text", "data" "jsonb", "scheduled_for" timestamp with time zone, "retry_count" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."get_pending_notifications"("batch_size" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_pending_notifications"("batch_size" integer) IS 'Retrieves notifications ready for processing by background services';



CREATE OR REPLACE FUNCTION "public"."handle_email_verification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Check if email_confirmed_at was just set (changed from NULL to a timestamp)
  IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
    -- Update the corresponding record in public.users
    UPDATE public.users 
    SET 
      email_verified = true,
      updated_at = NOW()
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_email_verification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.users (
        id, 
        display_name, 
        email, 
        phone_number, 
        location, 
        role, 
        branch_id, 
        photo_url,
        notification_settings,
        preferences,
        is_active,
        email_verified
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', ''),
        NEW.email,
        NEW.raw_user_meta_data->>'phone_number',
        CASE 
            WHEN NEW.raw_user_meta_data->>'location' IS NOT NULL 
            THEN (NEW.raw_user_meta_data->>'location')::jsonb
            ELSE NULL 
        END,
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'member'::public.user_role),
        CASE 
            WHEN NEW.raw_user_meta_data->>'branch_id' IS NOT NULL 
            AND NEW.raw_user_meta_data->>'branch_id' != ''
            THEN (NEW.raw_user_meta_data->>'branch_id')::uuid 
            ELSE NULL 
        END,
        NEW.raw_user_meta_data->>'photo_url',
        COALESCE(
            (NEW.raw_user_meta_data->>'notification_settings')::jsonb,
            '{"push_enabled": true, "email_enabled": true, "task_notifications": true, "general_notifications": true, "meeting_notifications": true}'::jsonb
        ),
        COALESCE(
            (NEW.raw_user_meta_data->>'preferences')::jsonb,
            '{}'::jsonb
        ),
        true,
        NEW.email_confirmed_at IS NOT NULL
    );
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error for debugging
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        -- Re-raise the exception to prevent the auth user creation if profile creation fails
        RAISE;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user_signup"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- If user is immediately confirmed, create profile
  IF NEW.email_confirmed_at IS NOT NULL THEN
    -- Check if profile already exists
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
      INSERT INTO public.users (
        id,
        email,
        display_name,
        phone_number,
        photo_url,
        role,
        is_active,
        email_verified,
        profile_completed,
        created_at,
        updated_at
      ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        NEW.raw_user_meta_data->>'phone_number',
        NEW.raw_user_meta_data->>'photo_url',
        'member',
        true,
        true,
        false,
        NOW(),
        NOW()
      );
    END IF;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the auth process
    RAISE WARNING 'Failed to create user profile for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user_signup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_meeting_notifications"("meeting_id" "uuid", "meeting_title" "text", "meeting_datetime" timestamp with time zone, "branch_id" "uuid" DEFAULT NULL::"uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."schedule_meeting_notifications"("meeting_id" "uuid", "meeting_title" "text", "meeting_datetime" timestamp with time zone, "branch_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."schedule_meeting_notifications"("meeting_id" "uuid", "meeting_title" "text", "meeting_datetime" timestamp with time zone, "branch_id" "uuid") IS 'Creates scheduled reminder notifications for meetings';



CREATE OR REPLACE FUNCTION "public"."update_notification_delivery"("notification_id" "uuid", "new_status" "public"."notification_delivery_status", "onesignal_id" "text" DEFAULT NULL::"text", "error_message" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."update_notification_delivery"("notification_id" "uuid", "new_status" "public"."notification_delivery_status", "onesignal_id" "text", "error_message" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_notification_delivery"("notification_id" "uuid", "new_status" "public"."notification_delivery_status", "onesignal_id" "text", "error_message" "text") IS 'Updates notification delivery status and OneSignal integration data';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."user_has_permission"("required_roles" "text"[]) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN get_current_user_role() = ANY(required_roles);
END;
$$;


ALTER FUNCTION "public"."user_has_permission"("required_roles" "text"[]) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "record_id" "uuid",
    "old_values" "jsonb",
    "new_values" "jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "audit_logs_action_not_empty" CHECK (("length"(TRIM(BOTH FROM "action")) > 0))
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."church_branches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "address" "text",
    "location" "jsonb",
    "pastor_id" "uuid",
    "created_by" "uuid",
    "is_active" boolean DEFAULT true,
    "settings" "jsonb" DEFAULT '{}'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "branches_pastor_check" CHECK ((("pastor_id" IS NULL) OR ("pastor_id" <> "created_by")))
);


ALTER TABLE "public"."church_branches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."meetings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "organizer_id" "uuid" NOT NULL,
    "branch_id" "uuid",
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "location" "text",
    "is_virtual" boolean DEFAULT false,
    "meeting_link" "text",
    "status" "public"."meeting_status" DEFAULT 'scheduled'::"public"."meeting_status",
    "max_attendees" integer,
    "is_recurring" boolean DEFAULT false,
    "recurrence_pattern" "jsonb",
    "invited_users" "uuid"[] DEFAULT '{}'::"uuid"[],
    "attendees" "uuid"[] DEFAULT '{}'::"uuid"[],
    "agenda" "jsonb" DEFAULT '[]'::"jsonb",
    "notes" "text",
    "attachments" "jsonb" DEFAULT '[]'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "meetings_future_check" CHECK (("start_time" > "created_at")),
    CONSTRAINT "meetings_time_valid" CHECK (("end_time" > "start_time"))
);


ALTER TABLE "public"."meetings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."notification_type" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb",
    "action_url" "text",
    "is_read" boolean DEFAULT false,
    "read_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "onesignal_notification_id" "text",
    "scheduled_for" timestamp with time zone,
    "is_push_sent" boolean DEFAULT false,
    "delivery_status" "public"."notification_delivery_status" DEFAULT 'pending'::"public"."notification_delivery_status",
    "retry_count" integer DEFAULT 0,
    "last_retry_at" timestamp with time zone,
    "failure_reason" "text",
    "related_entity_id" "uuid",
    "related_entity_type" "text",
    "scheduling_config" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "notifications_read_consistency" CHECK (((("is_read" = true) AND ("read_at" IS NOT NULL)) OR (("is_read" = false) AND ("read_at" IS NULL))))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."notification_analytics" WITH ("security_invoker"='true') AS
 SELECT "date_trunc"('day'::"text", "notifications"."created_at") AS "date",
    "notifications"."type",
    "notifications"."delivery_status",
    "count"(*) AS "count",
    "avg"(EXTRACT(epoch FROM (COALESCE("notifications"."updated_at", "notifications"."created_at") - "notifications"."created_at"))) AS "avg_processing_time_seconds"
   FROM "public"."notifications"
  WHERE ("notifications"."created_at" >= ("now"() - '30 days'::interval))
  GROUP BY ("date_trunc"('day'::"text", "notifications"."created_at")), "notifications"."type", "notifications"."delivery_status"
  ORDER BY ("date_trunc"('day'::"text", "notifications"."created_at")) DESC, "notifications"."type", "notifications"."delivery_status";


ALTER TABLE "public"."notification_analytics" OWNER TO "postgres";


COMMENT ON VIEW "public"."notification_analytics" IS 'Provides analytics data for notification delivery and performance (with security invoker)';



CREATE TABLE IF NOT EXISTS "public"."task_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "parent_comment_id" "uuid",
    "content" "text" NOT NULL,
    "attachments" "jsonb" DEFAULT '[]'::"jsonb",
    "is_edited" boolean DEFAULT false,
    "edited_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "task_comments_content_not_empty" CHECK (("length"(TRIM(BOTH FROM "content")) > 0))
);


ALTER TABLE "public"."task_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "assigned_to" "uuid",
    "created_by" "uuid" NOT NULL,
    "branch_id" "uuid",
    "status" "public"."task_status" DEFAULT 'pending'::"public"."task_status",
    "priority" "public"."task_priority" DEFAULT 'medium'::"public"."task_priority",
    "due_date" timestamp with time zone,
    "reminder_date" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "estimated_hours" integer,
    "actual_hours" integer,
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "attachments" "jsonb" DEFAULT '[]'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "tasks_actual_hours_positive" CHECK ((("actual_hours" IS NULL) OR ("actual_hours" > 0))),
    CONSTRAINT "tasks_hours_positive" CHECK ((("estimated_hours" IS NULL) OR ("estimated_hours" > 0))),
    CONSTRAINT "tasks_title_not_empty" CHECK (("length"(TRIM(BOTH FROM "title")) > 0))
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "device_id" "text" NOT NULL,
    "platform" "text" NOT NULL,
    "push_token" "text",
    "onesignal_user_id" "text",
    "app_version" "text",
    "os_version" "text",
    "is_active" boolean DEFAULT true,
    "last_seen" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_devices_platform_check" CHECK (("platform" = ANY (ARRAY['ios'::"text", 'android'::"text", 'web'::"text"])))
);


ALTER TABLE "public"."user_devices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "display_name" "text",
    "phone_number" "text",
    "photo_url" "text",
    "role" "public"."user_role" DEFAULT 'member'::"public"."user_role",
    "branch_id" "uuid",
    "departments" "text"[] DEFAULT '{}'::"text"[],
    "location" "jsonb",
    "is_active" boolean DEFAULT true,
    "email_verified" boolean DEFAULT false,
    "profile_completed" boolean DEFAULT false,
    "preferences" "jsonb" DEFAULT '{}'::"jsonb",
    "notification_settings" "jsonb" DEFAULT '{"push_enabled": true, "email_enabled": true, "task_notifications": true, "general_notifications": true, "meeting_notifications": true}'::"jsonb",
    "last_login" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "users_email_format" CHECK (("email" ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::"text"))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."church_branches"
    ADD CONSTRAINT "branches_name_unique" UNIQUE ("name");



ALTER TABLE ONLY "public"."church_branches"
    ADD CONSTRAINT "branches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."meetings"
    ADD CONSTRAINT "meetings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_unique_device" UNIQUE ("user_id", "device_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_audit_logs_created_at" ON "public"."audit_logs" USING "btree" ("created_at");



CREATE INDEX "idx_audit_logs_table_name" ON "public"."audit_logs" USING "btree" ("table_name");



CREATE INDEX "idx_audit_logs_user_id" ON "public"."audit_logs" USING "btree" ("user_id");



CREATE INDEX "idx_meetings_branch_id" ON "public"."meetings" USING "btree" ("branch_id");



CREATE INDEX "idx_meetings_organizer_id" ON "public"."meetings" USING "btree" ("organizer_id");



CREATE INDEX "idx_meetings_start_time" ON "public"."meetings" USING "btree" ("start_time");



CREATE INDEX "idx_meetings_status" ON "public"."meetings" USING "btree" ("status");



CREATE INDEX "idx_notifications_created_at" ON "public"."notifications" USING "btree" ("created_at");



CREATE INDEX "idx_notifications_delivery_status" ON "public"."notifications" USING "btree" ("delivery_status");



CREATE INDEX "idx_notifications_onesignal_id" ON "public"."notifications" USING "btree" ("onesignal_notification_id") WHERE ("onesignal_notification_id" IS NOT NULL);



CREATE INDEX "idx_notifications_read" ON "public"."notifications" USING "btree" ("is_read");



CREATE INDEX "idx_notifications_related_entity" ON "public"."notifications" USING "btree" ("related_entity_type", "related_entity_id");



CREATE INDEX "idx_notifications_scheduled_for" ON "public"."notifications" USING "btree" ("scheduled_for") WHERE ("scheduled_for" IS NOT NULL);



CREATE INDEX "idx_notifications_type" ON "public"."notifications" USING "btree" ("type");



CREATE INDEX "idx_notifications_user_id" ON "public"."notifications" USING "btree" ("user_id");



CREATE INDEX "idx_task_comments_parent" ON "public"."task_comments" USING "btree" ("parent_comment_id");



CREATE INDEX "idx_task_comments_task_id" ON "public"."task_comments" USING "btree" ("task_id");



CREATE INDEX "idx_task_comments_user_id" ON "public"."task_comments" USING "btree" ("user_id");



CREATE INDEX "idx_tasks_assigned_to" ON "public"."tasks" USING "btree" ("assigned_to");



CREATE INDEX "idx_tasks_branch_id" ON "public"."tasks" USING "btree" ("branch_id");



CREATE INDEX "idx_tasks_created_by" ON "public"."tasks" USING "btree" ("created_by");



CREATE INDEX "idx_tasks_due_date" ON "public"."tasks" USING "btree" ("due_date");



CREATE INDEX "idx_tasks_priority" ON "public"."tasks" USING "btree" ("priority");



CREATE INDEX "idx_tasks_status" ON "public"."tasks" USING "btree" ("status");



CREATE INDEX "idx_user_devices_active" ON "public"."user_devices" USING "btree" ("is_active");



CREATE INDEX "idx_user_devices_user_id" ON "public"."user_devices" USING "btree" ("user_id");



CREATE INDEX "idx_users_active" ON "public"."users" USING "btree" ("is_active");



CREATE INDEX "idx_users_branch_id" ON "public"."users" USING "btree" ("branch_id");



CREATE INDEX "idx_users_email" ON "public"."users" USING "btree" ("email");



CREATE INDEX "idx_users_role" ON "public"."users" USING "btree" ("role");



CREATE OR REPLACE TRIGGER "update_branches_updated_at" BEFORE UPDATE ON "public"."church_branches" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_meetings_updated_at" BEFORE UPDATE ON "public"."meetings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_notifications_updated_at" BEFORE UPDATE ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_tasks_updated_at" BEFORE UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_devices_updated_at" BEFORE UPDATE ON "public"."user_devices" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."church_branches"
    ADD CONSTRAINT "branches_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."meetings"
    ADD CONSTRAINT "meetings_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."church_branches"("id");



ALTER TABLE ONLY "public"."meetings"
    ADD CONSTRAINT "meetings_organizer_id_fkey" FOREIGN KEY ("organizer_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_parent_comment_id_fkey" FOREIGN KEY ("parent_comment_id") REFERENCES "public"."task_comments"("id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."church_branches"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."church_branches"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_logs_select_admin" ON "public"."audit_logs" FOR SELECT USING ("public"."user_has_permission"(ARRAY['admin'::"text"]));



CREATE POLICY "audit_logs_select_own" ON "public"."audit_logs" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "branches_admin_all" ON "public"."church_branches" USING ("public"."user_has_permission"(ARRAY['admin'::"text"]));



CREATE POLICY "branches_pastor_own_branch" ON "public"."church_branches" FOR SELECT USING (("pastor_id" = "auth"."uid"()));



CREATE POLICY "branches_select_all" ON "public"."church_branches" FOR SELECT USING (true);



ALTER TABLE "public"."church_branches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."meetings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "meetings_insert_leaders" ON "public"."meetings" FOR INSERT WITH CHECK (("public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text", 'worker'::"text"]) AND ("organizer_id" = "auth"."uid"())));



CREATE POLICY "meetings_select_invited" ON "public"."meetings" FOR SELECT USING ((("auth"."uid"() = ANY ("invited_users")) OR ("organizer_id" = "auth"."uid"()) OR "public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text"])));



CREATE POLICY "meetings_update_admin" ON "public"."meetings" FOR UPDATE USING ("public"."user_has_permission"(ARRAY['admin'::"text"]));



CREATE POLICY "meetings_update_organizer" ON "public"."meetings" FOR UPDATE USING (("organizer_id" = "auth"."uid"()));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_insert_system" ON "public"."notifications" FOR INSERT WITH CHECK (true);



CREATE POLICY "notifications_select_own" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "notifications_update_own" ON "public"."notifications" FOR UPDATE USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."task_comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "task_comments_insert_task_access" ON "public"."task_comments" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."tasks"
  WHERE (("tasks"."id" = "task_comments"."task_id") AND (("tasks"."assigned_to" = "auth"."uid"()) OR ("tasks"."created_by" = "auth"."uid"()) OR (("tasks"."branch_id" = "public"."get_current_user_branch_id"()) AND "public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text", 'worker'::"text"]))))))));



CREATE POLICY "task_comments_select_task_access" ON "public"."task_comments" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."tasks"
  WHERE (("tasks"."id" = "task_comments"."task_id") AND (("tasks"."assigned_to" = "auth"."uid"()) OR ("tasks"."created_by" = "auth"."uid"()) OR (("tasks"."branch_id" = "public"."get_current_user_branch_id"()) AND "public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text", 'worker'::"text"])))))));



CREATE POLICY "task_comments_update_own" ON "public"."task_comments" FOR UPDATE USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tasks_delete_admin" ON "public"."tasks" FOR DELETE USING ("public"."user_has_permission"(ARRAY['admin'::"text"]));



CREATE POLICY "tasks_insert_leaders" ON "public"."tasks" FOR INSERT WITH CHECK (("public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text", 'worker'::"text"]) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "tasks_select_assigned" ON "public"."tasks" FOR SELECT USING (("assigned_to" = "auth"."uid"()));



CREATE POLICY "tasks_select_branch_leaders" ON "public"."tasks" FOR SELECT USING ((("branch_id" = "public"."get_current_user_branch_id"()) AND "public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text", 'worker'::"text"])));



CREATE POLICY "tasks_select_created" ON "public"."tasks" FOR SELECT USING (("created_by" = "auth"."uid"()));



CREATE POLICY "tasks_update_assigned" ON "public"."tasks" FOR UPDATE USING (("assigned_to" = "auth"."uid"()));



CREATE POLICY "tasks_update_leaders" ON "public"."tasks" FOR UPDATE USING ("public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text", 'worker'::"text"]));



ALTER TABLE "public"."user_devices" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_devices_delete_own" ON "public"."user_devices" FOR DELETE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_devices_insert_own" ON "public"."user_devices" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "user_devices_select_own" ON "public"."user_devices" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "user_devices_update_own" ON "public"."user_devices" FOR UPDATE USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_insert_registration" ON "public"."users" FOR INSERT WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "users_select_admin" ON "public"."users" FOR SELECT USING ("public"."user_has_permission"(ARRAY['admin'::"text"]));



CREATE POLICY "users_select_own" ON "public"."users" FOR SELECT USING (("id" = "auth"."uid"()));



CREATE POLICY "users_select_same_branch" ON "public"."users" FOR SELECT USING ((("branch_id" = "public"."get_current_user_branch_id"()) AND "public"."user_has_permission"(ARRAY['pastor'::"text", 'worker'::"text"])));



CREATE POLICY "users_update_admin" ON "public"."users" FOR UPDATE USING ("public"."user_has_permission"(ARRAY['admin'::"text"]));



CREATE POLICY "users_update_own" ON "public"."users" FOR UPDATE USING (("id" = "auth"."uid"()));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































GRANT ALL ON FUNCTION "public"."cancel_meeting_notifications"("meeting_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."cancel_meeting_notifications"("meeting_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cancel_meeting_notifications"("meeting_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_task_notification"("task_id" "uuid", "notification_type" "public"."notification_type", "recipient_user_id" "uuid", "custom_title" "text", "custom_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_task_notification"("task_id" "uuid", "notification_type" "public"."notification_type", "recipient_user_id" "uuid", "custom_title" "text", "custom_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_task_notification"("task_id" "uuid", "notification_type" "public"."notification_type", "recipient_user_id" "uuid", "custom_title" "text", "custom_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_branch_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_user_branch_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_user_branch_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_pending_notifications"("batch_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_pending_notifications"("batch_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_pending_notifications"("batch_size" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_email_verification"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_email_verification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_email_verification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user_signup"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user_signup"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user_signup"() TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_meeting_notifications"("meeting_id" "uuid", "meeting_title" "text", "meeting_datetime" timestamp with time zone, "branch_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_meeting_notifications"("meeting_id" "uuid", "meeting_title" "text", "meeting_datetime" timestamp with time zone, "branch_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_meeting_notifications"("meeting_id" "uuid", "meeting_title" "text", "meeting_datetime" timestamp with time zone, "branch_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_notification_delivery"("notification_id" "uuid", "new_status" "public"."notification_delivery_status", "onesignal_id" "text", "error_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_notification_delivery"("notification_id" "uuid", "new_status" "public"."notification_delivery_status", "onesignal_id" "text", "error_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_notification_delivery"("notification_id" "uuid", "new_status" "public"."notification_delivery_status", "onesignal_id" "text", "error_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."user_has_permission"("required_roles" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."user_has_permission"("required_roles" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_has_permission"("required_roles" "text"[]) TO "service_role";


















GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."church_branches" TO "anon";
GRANT ALL ON TABLE "public"."church_branches" TO "authenticated";
GRANT ALL ON TABLE "public"."church_branches" TO "service_role";



GRANT ALL ON TABLE "public"."meetings" TO "anon";
GRANT ALL ON TABLE "public"."meetings" TO "authenticated";
GRANT ALL ON TABLE "public"."meetings" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."notification_analytics" TO "anon";
GRANT ALL ON TABLE "public"."notification_analytics" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_analytics" TO "service_role";



GRANT ALL ON TABLE "public"."task_comments" TO "anon";
GRANT ALL ON TABLE "public"."task_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."task_comments" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."user_devices" TO "anon";
GRANT ALL ON TABLE "public"."user_devices" TO "authenticated";
GRANT ALL ON TABLE "public"."user_devices" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
