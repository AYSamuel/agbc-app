-- Add reminder column to tasks table
ALTER TABLE tasks
ADD COLUMN reminder TIMESTAMP WITH TIME ZONE;

-- Enable Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can do everything" ON tasks;
DROP POLICY IF EXISTS "Workers and pastors can create and update tasks" ON tasks;
DROP POLICY IF EXISTS "Workers and pastors can update tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators can view their tasks" ON tasks;
DROP POLICY IF EXISTS "Members can view assigned tasks" ON tasks;
DROP POLICY IF EXISTS "Members can update assigned tasks" ON tasks;

-- Create policies for different roles and operations

-- 1. Admin Policy
-- Admins have full access to all tasks (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Admins can do everything"
ON tasks
FOR ALL
TO authenticated
USING (
  get_current_user_role() = 'admin'
)
WITH CHECK (
  get_current_user_role() = 'admin'
);

-- 2. Worker and Pastor Policies
-- Workers and pastors can create and update tasks
CREATE POLICY "Workers and pastors can create and update tasks"
ON tasks
FOR INSERT
TO authenticated
WITH CHECK (
  get_current_user_role() IN ('worker', 'pastor')
);

CREATE POLICY "Workers and pastors can update tasks"
ON tasks
FOR UPDATE
TO authenticated
USING (
  get_current_user_role() IN ('worker', 'pastor')
);

-- 3. Task Creator Policy
-- Anyone who created a task can view it
CREATE POLICY "Task creators can view their tasks"
ON tasks
FOR SELECT
TO authenticated
USING (
  created_by = auth.uid()
);

-- 4. Member Policies
-- Members can view tasks assigned to them
CREATE POLICY "Members can view assigned tasks"
ON tasks
FOR SELECT
TO authenticated
USING (
  assigned_to = auth.uid()
);

-- Members can update status and reminder fields
CREATE POLICY "Members can update assigned tasks"
ON tasks
FOR UPDATE
TO authenticated
USING (
  assigned_to = auth.uid()
)
WITH CHECK (
  assigned_to = auth.uid()
  AND
  (
    -- Only allow status and reminder to be changed
    (status IS NOT NULL OR reminder IS NOT NULL)
  )
);

-- Add comments to the table and columns for better documentation
COMMENT ON TABLE tasks IS 'Tasks table with Row Level Security policies for different user roles';
COMMENT ON COLUMN tasks.created_by IS 'ID of the user who created the task';
COMMENT ON COLUMN tasks.assigned_to IS 'ID of the user the task is assigned to';
COMMENT ON COLUMN tasks.status IS 'Current status of the task (pending, in_progress, completed)';
COMMENT ON COLUMN tasks.reminder IS 'Optional reminder timestamp for the assigned user'; 