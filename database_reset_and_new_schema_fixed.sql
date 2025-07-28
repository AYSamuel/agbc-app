-- =====================================================
-- AGBC App - Database Reset and New Schema (FIXED)
-- Clean Architecture Implementation
-- =====================================================

-- First, drop all existing tables and their dependencies
DROP POLICY IF EXISTS "Admins can do everything" ON "public"."branches";
DROP POLICY IF EXISTS "Admins can do everything" ON "public"."tasks";
DROP POLICY IF EXISTS "Admins can manage all device records" ON "public"."user_devices";
DROP POLICY IF EXISTS "Admins can read all user records" ON "public"."users";
DROP POLICY IF EXISTS "Allow public read access" ON "public"."branches";
DROP POLICY IF EXISTS "Enable insert for registration" ON "public"."users";
DROP POLICY IF EXISTS "Members can update assigned tasks" ON "public"."tasks";
DROP POLICY IF EXISTS "Members can view assigned tasks" ON "public"."tasks";
DROP POLICY IF EXISTS "Task creators can view their tasks" ON "public"."tasks";
DROP POLICY IF EXISTS "Users can manage their own device records" ON "public"."user_devices";
DROP POLICY IF EXISTS "Users can read their own record" ON "public"."users";
DROP POLICY IF EXISTS "Users can update their own notifications" ON "public"."notifications";
DROP POLICY IF EXISTS "Users can view their own notifications" ON "public"."notifications";
DROP POLICY IF EXISTS "Workers and pastors can create and update tasks" ON "public"."tasks";
DROP POLICY IF EXISTS "Workers and pastors can update tasks" ON "public"."tasks";

-- Drop all triggers
DROP TRIGGER IF EXISTS "update_branch_members_trigger" ON "public"."users";
DROP TRIGGER IF EXISTS "update_branches_updated_at" ON "public"."branches";
DROP TRIGGER IF EXISTS "update_users_updated_at" ON "public"."users";
DROP TRIGGER IF EXISTS "update_notifications_updated_at" ON "public"."notifications";

-- Drop all tables (in correct order to handle foreign key dependencies)
DROP TABLE IF EXISTS "public"."task_comments" CASCADE;
DROP TABLE IF EXISTS "public"."notifications" CASCADE;
DROP TABLE IF EXISTS "public"."user_devices" CASCADE;
DROP TABLE IF EXISTS "public"."tasks" CASCADE;
DROP TABLE IF EXISTS "public"."meetings" CASCADE;
DROP TABLE IF EXISTS "public"."users" CASCADE;
DROP TABLE IF EXISTS "public"."branches" CASCADE;
DROP TABLE IF EXISTS "public"."audit_logs" CASCADE;

-- Drop all functions
DROP FUNCTION IF EXISTS "public"."get_current_user_role"() CASCADE;
DROP FUNCTION IF EXISTS "public"."initialize_branch_members"() CASCADE;
DROP FUNCTION IF EXISTS "public"."update_branch_members"() CASCADE;
DROP FUNCTION IF EXISTS "public"."update_updated_at_column"() CASCADE;
DROP FUNCTION IF EXISTS "public"."user_has_permission"(text[]) CASCADE;
DROP FUNCTION IF EXISTS "public"."get_current_user_branch_id"() CASCADE;

-- Drop existing types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS task_status CASCADE;
DROP TYPE IF EXISTS task_priority CASCADE;
DROP TYPE IF EXISTS meeting_status CASCADE;
DROP TYPE IF EXISTS notification_type CASCADE;
DROP TYPE IF EXISTS notification_delivery_status CASCADE;

-- =====================================================
-- ENUMS AND TYPES
-- =====================================================

-- User roles enum
CREATE TYPE user_role AS ENUM ('admin', 'pastor', 'worker', 'member');

-- Task status enum
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');

-- Task priority enum
CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high', 'urgent');

-- Meeting status enum
CREATE TYPE meeting_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');

-- Notification type enum (includes all types from the Dart model)
CREATE TYPE notification_type AS ENUM (
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

-- Notification delivery status enum
CREATE TYPE notification_delivery_status AS ENUM (
    'pending',
    'sent',
    'delivered',
    'failed',
    'cancelled'
);

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Branches table (improved structure)
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    address TEXT,
    location JSONB, -- Store lat/lng and formatted address
    pastor_id UUID,
    created_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}', -- Branch-specific settings
    metadata JSONB DEFAULT '{}', -- Additional metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT branches_name_unique UNIQUE(name),
    CONSTRAINT branches_pastor_check CHECK (pastor_id IS NULL OR pastor_id != created_by)
);

-- Users table (improved structure with better role management)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    phone_number TEXT,
    photo_url TEXT,
    role user_role DEFAULT 'member',
    branch_id UUID REFERENCES branches(id),
    departments TEXT[] DEFAULT '{}',
    location JSONB, -- Store user's location data
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    profile_completed BOOLEAN DEFAULT false,
    preferences JSONB DEFAULT '{}', -- User preferences
    notification_settings JSONB DEFAULT '{
        "push_enabled": true,
        "email_enabled": true,
        "task_notifications": true,
        "meeting_notifications": true,
        "general_notifications": true
    }',
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Now create functions that depend on the users table
-- Function to get current user role with better error handling
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has permission for action (using TEXT instead of ENUM)
CREATE OR REPLACE FUNCTION user_has_permission(required_roles TEXT[])
RETURNS BOOLEAN AS $$
BEGIN
    RETURN get_current_user_role() = ANY(required_roles);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's branch ID
CREATE OR REPLACE FUNCTION get_current_user_branch_id()
RETURNS UUID AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Tasks table (improved with better status tracking)
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES users(id),
    created_by UUID REFERENCES auth.users(id) NOT NULL,
    branch_id UUID REFERENCES branches(id),
    status task_status DEFAULT 'pending',
    priority task_priority DEFAULT 'medium',
    due_date TIMESTAMPTZ,
    reminder_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    estimated_hours INTEGER,
    actual_hours INTEGER,
    tags TEXT[] DEFAULT '{}',
    attachments JSONB DEFAULT '[]', -- Store file references
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT tasks_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT tasks_hours_positive CHECK (estimated_hours IS NULL OR estimated_hours > 0),
    CONSTRAINT tasks_actual_hours_positive CHECK (actual_hours IS NULL OR actual_hours > 0)
);

-- Meetings table (improved with better attendee management)
CREATE TABLE meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    organizer_id UUID REFERENCES users(id) NOT NULL,
    branch_id UUID REFERENCES branches(id),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    is_virtual BOOLEAN DEFAULT false,
    meeting_link TEXT, -- For virtual meetings
    status meeting_status DEFAULT 'scheduled',
    max_attendees INTEGER,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern JSONB, -- Store recurrence rules
    invited_users UUID[] DEFAULT '{}',
    attendees UUID[] DEFAULT '{}',
    agenda JSONB DEFAULT '[]',
    notes TEXT,
    attachments JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT meetings_time_valid CHECK (end_time > start_time),
    CONSTRAINT meetings_future_check CHECK (start_time > created_at)
);

-- Task comments (improved with better threading)
CREATE TABLE task_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) NOT NULL,
    parent_comment_id UUID REFERENCES task_comments(id), -- For threaded comments
    content TEXT NOT NULL,
    attachments JSONB DEFAULT '[]',
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT task_comments_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Notifications table (compatible with Dart model)
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL, -- Changed from 'body' to 'message' to match Dart model
    data JSONB DEFAULT '{}',
    action_url TEXT, -- Deep link or action URL
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(), -- Added updated_at field
    
    -- OneSignal integration fields
    onesignal_notification_id TEXT, -- Track OneSignal notification ID
    scheduled_for TIMESTAMPTZ, -- When to send the notification
    is_push_sent BOOLEAN DEFAULT false, -- Whether push notification was sent
    delivery_status notification_delivery_status DEFAULT 'pending', -- Delivery tracking
    retry_count INTEGER DEFAULT 0, -- Number of retry attempts
    last_retry_at TIMESTAMPTZ, -- Last retry timestamp
    failure_reason TEXT, -- Reason for delivery failure
    
    -- Entity relationship fields
    related_entity_id UUID, -- ID of related task/meeting/etc
    related_entity_type TEXT, -- Type: 'task', 'meeting', 'user', etc
    scheduling_config JSONB DEFAULT '{}', -- Custom scheduling configuration
    
    CONSTRAINT notifications_read_consistency CHECK (
        (is_read = true AND read_at IS NOT NULL) OR 
        (is_read = false AND read_at IS NULL)
    )
);

-- User devices (improved for better push notification handling)
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    device_id TEXT NOT NULL, -- Unique device identifier
    platform TEXT NOT NULL, -- 'ios', 'android', 'web'
    push_token TEXT,
    onesignal_user_id TEXT,
    app_version TEXT,
    os_version TEXT,
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT user_devices_unique_device UNIQUE(user_id, device_id),
    CONSTRAINT user_devices_platform_check CHECK (platform IN ('ios', 'android', 'web'))
);

-- Audit log table (new - for tracking important changes)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT audit_logs_action_not_empty CHECK (LENGTH(TRIM(action)) > 0)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_branch_id ON users(branch_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- Tasks indexes
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_branch_id ON tasks(branch_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_priority ON tasks(priority);

-- Meetings indexes
CREATE INDEX idx_meetings_organizer_id ON meetings(organizer_id);
CREATE INDEX idx_meetings_branch_id ON meetings(branch_id);
CREATE INDEX idx_meetings_start_time ON meetings(start_time);
CREATE INDEX idx_meetings_status ON meetings(status);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_scheduled_for ON notifications(scheduled_for) WHERE scheduled_for IS NOT NULL;
CREATE INDEX idx_notifications_delivery_status ON notifications(delivery_status);
CREATE INDEX idx_notifications_onesignal_id ON notifications(onesignal_notification_id) WHERE onesignal_notification_id IS NOT NULL;
CREATE INDEX idx_notifications_related_entity ON notifications(related_entity_type, related_entity_id);

-- Task comments indexes
CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_user_id ON task_comments(user_id);
CREATE INDEX idx_task_comments_parent ON task_comments(parent_comment_id);

-- User devices indexes
CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_active ON user_devices(is_active);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update timestamps
CREATE TRIGGER update_branches_updated_at
    BEFORE UPDATE ON branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meetings_updated_at
    BEFORE UPDATE ON meetings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_devices_updated_at
    BEFORE UPDATE ON user_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Branches policies
CREATE POLICY "branches_select_all" ON branches FOR SELECT USING (true);
CREATE POLICY "branches_admin_all" ON branches FOR ALL USING (user_has_permission(ARRAY['admin']));
CREATE POLICY "branches_pastor_own_branch" ON branches FOR SELECT USING (pastor_id = auth.uid());

-- Users policies
CREATE POLICY "users_select_own" ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "users_select_admin" ON users FOR SELECT USING (user_has_permission(ARRAY['admin']));
CREATE POLICY "users_select_same_branch" ON users FOR SELECT USING (
    branch_id = get_current_user_branch_id() AND 
    user_has_permission(ARRAY['pastor', 'worker'])
);
CREATE POLICY "users_insert_registration" ON users FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (id = auth.uid());
CREATE POLICY "users_update_admin" ON users FOR UPDATE USING (user_has_permission(ARRAY['admin']));

-- Tasks policies
CREATE POLICY "tasks_select_assigned" ON tasks FOR SELECT USING (assigned_to = auth.uid());
CREATE POLICY "tasks_select_created" ON tasks FOR SELECT USING (created_by = auth.uid());
CREATE POLICY "tasks_select_branch_leaders" ON tasks FOR SELECT USING (
    branch_id = get_current_user_branch_id() AND 
    user_has_permission(ARRAY['admin', 'pastor', 'worker'])
);
CREATE POLICY "tasks_insert_leaders" ON tasks FOR INSERT WITH CHECK (
    user_has_permission(ARRAY['admin', 'pastor', 'worker']) AND
    created_by = auth.uid()
);
CREATE POLICY "tasks_update_assigned" ON tasks FOR UPDATE USING (assigned_to = auth.uid());
CREATE POLICY "tasks_update_leaders" ON tasks FOR UPDATE USING (
    user_has_permission(ARRAY['admin', 'pastor', 'worker'])
);
CREATE POLICY "tasks_delete_admin" ON tasks FOR DELETE USING (user_has_permission(ARRAY['admin']));

-- Meetings policies
CREATE POLICY "meetings_select_invited" ON meetings FOR SELECT USING (
    auth.uid() = ANY(invited_users) OR 
    organizer_id = auth.uid() OR
    user_has_permission(ARRAY['admin', 'pastor'])
);
CREATE POLICY "meetings_insert_leaders" ON meetings FOR INSERT WITH CHECK (
    user_has_permission(ARRAY['admin', 'pastor', 'worker']) AND
    organizer_id = auth.uid()
);
CREATE POLICY "meetings_update_organizer" ON meetings FOR UPDATE USING (organizer_id = auth.uid());
CREATE POLICY "meetings_update_admin" ON meetings FOR UPDATE USING (user_has_permission(ARRAY['admin']));

-- Task comments policies
CREATE POLICY "task_comments_select_task_access" ON task_comments FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM tasks 
        WHERE tasks.id = task_comments.task_id AND (
            tasks.assigned_to = auth.uid() OR 
            tasks.created_by = auth.uid() OR
            (tasks.branch_id = get_current_user_branch_id() AND user_has_permission(ARRAY['admin', 'pastor', 'worker']))
        )
    )
);
CREATE POLICY "task_comments_insert_task_access" ON task_comments FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM tasks 
        WHERE tasks.id = task_comments.task_id AND (
            tasks.assigned_to = auth.uid() OR 
            tasks.created_by = auth.uid() OR
            (tasks.branch_id = get_current_user_branch_id() AND user_has_permission(ARRAY['admin', 'pastor', 'worker']))
        )
    )
);
CREATE POLICY "task_comments_update_own" ON task_comments FOR UPDATE USING (user_id = auth.uid());

-- Notifications policies
CREATE POLICY "notifications_select_own" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications_update_own" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notifications_insert_system" ON notifications FOR INSERT WITH CHECK (true); -- Allow system to insert

-- User devices policies
CREATE POLICY "user_devices_select_own" ON user_devices FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "user_devices_insert_own" ON user_devices FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "user_devices_update_own" ON user_devices FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "user_devices_delete_own" ON user_devices FOR DELETE USING (user_id = auth.uid());

-- Audit logs policies (read-only for users, admin can see all)
CREATE POLICY "audit_logs_select_own" ON audit_logs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "audit_logs_select_admin" ON audit_logs FOR SELECT USING (user_has_permission(ARRAY['admin']));

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;