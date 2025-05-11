-- Supabase RLS Policies for the public.users table
-- Generated: {{2025-05-11}}

-- =================================================================
-- Helper Function: Get Current User's Role from public.users
-- =================================================================
-- This function is crucial as it allows RLS policies to reference the
-- role stored in the public.users table, making it the source of truth.
-- SECURITY DEFINER allows it to read from public.users even if the
-- calling user doesn't have direct table-wide read access.

CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Assumes 'id' in public.users matches auth.uid() and 'role' column exists.
  SELECT role INTO user_role FROM public.users WHERE id = auth.uid();
  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permission to any authenticated user.
GRANT EXECUTE ON FUNCTION get_current_user_role() TO authenticated;


-- =================================================================
-- Admin Policies
-- =================================================================
-- These policies grant administrators full control over the users table,
-- based on their 'admin' role in the public.users table.

-- Policy: Allow admins to read all user records.
CREATE POLICY "Allow admins to read all user records"
ON public.users
FOR SELECT
TO authenticated
USING (get_current_user_role() = 'admin');

-- Policy: Allow admins to update all user records.
-- The WITH CHECK clause ensures an admin cannot make an update
-- that would violate the USING condition for subsequent operations.
CREATE POLICY "Allow admins to update all user records"
ON public.users
FOR UPDATE
TO authenticated
USING (get_current_user_role() = 'admin')
WITH CHECK (get_current_user_role() = 'admin');

-- Policy: Allow admins to delete user records.
CREATE POLICY "Allow admins to delete user records"
ON public.users
FOR DELETE
TO authenticated
USING (get_current_user_role() = 'admin');


-- =================================================================
-- Pastor Policies
-- =================================================================
-- This policy grants pastors read access to all user records,
-- based on their 'pastor' role in the public.users table.

-- Policy: Allow pastors to read all user records.
CREATE POLICY "Allow pastors to read all user records"
ON public.users
FOR SELECT
TO authenticated
USING (get_current_user_role() = 'pastor');


-- =================================================================
-- User-Specific Policies (Own Data)
-- =================================================================
-- These policies allow authenticated users to manage their own records
-- in the public.users table.

-- Policy: Allow users to read their own user record.
CREATE POLICY "Allow users to read their own user record"
ON public.users
FOR SELECT
TO authenticated
USING (id = auth.uid()); -- auth.uid() is the ID of the currently authenticated user.

-- Policy: Allow users to update their own user record.
-- The WITH CHECK clause ensures a user can only modify their own record
-- and cannot change their ID to someone else's.
CREATE POLICY "Allow users to update their own user record"
ON public.users
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());


-- =================================================================
-- INSERT Policy (for New User Registration)
-- =================================================================
-- This policy controls who can insert new records into the public.users table.
-- It's designed to allow new users to add their corresponding record after
-- successfully authenticating via Supabase Auth (e.g., during app registration).

-- Policy: Allow new authenticated users to insert their own record into public.users.
CREATE POLICY "Allow new authenticated users to insert their own record into public.users"
ON public.users
FOR INSERT
TO authenticated -- The user should be authenticated by Supabase Auth at this point.
WITH CHECK (
    id = auth.uid() AND -- The ID being inserted must match the authenticated user's ID.
    NOT EXISTS (SELECT 1 FROM public.users p_u WHERE p_u.id = auth.uid()) -- Prevents inserting if a record for this user already exists in public.users.
);

-- =================================================================
-- End of RLS Policies for public.users
-- =================================================================
-- Note: If you had default "Enable read access for all users" policies
-- (often created by Supabase by default), these more specific policies
-- effectively replace them. Ensure those defaults are removed or disabled if they
-- grant overly broad permissions. Test thoroughly after applying.
