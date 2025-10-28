-- Revert meetings RLS policies to original invited-only visibility
-- This migration restores the policy where users can view meetings if:
-- 1) They are invited (their `auth.uid()` is in `invited_users`), OR
-- 2) They are the organizer, OR
-- 3) They have 'admin' or 'pastor' permissions.

BEGIN;

-- Ensure RLS is enabled on meetings
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;

-- Drop any broad/select-all policies that may have been introduced
DROP POLICY IF EXISTS meetings_select_comprehensive ON public.meetings;
DROP POLICY IF EXISTS meetings_select_visibility ON public.meetings;
DROP POLICY IF EXISTS meetings_select_all ON public.meetings;

-- Recreate the original invited policy exactly
DROP POLICY IF EXISTS meetings_select_invited ON public.meetings;
CREATE POLICY meetings_select_invited ON public.meetings FOR SELECT
USING (
    (auth.uid() = ANY (invited_users))
    OR (organizer_id = auth.uid())
    OR public.user_has_permission(ARRAY['admin','pastor'])
);

COMMIT;