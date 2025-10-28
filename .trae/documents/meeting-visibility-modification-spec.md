# Meeting Visibility Logic Modification - Technical Specification

## 1. Overview

This document outlines the technical changes required to modify the meeting visibility logic in the AGBC app to support global meeting visibility while maintaining branch-specific meeting restrictions.

## 2. Current Implementation Analysis

### 2.1 Current Database Schema

The `meetings` table includes a `branch_id` field:
- `branch_id` UUID (nullable) - References `church_branches.id`
- When `branch_id` is NULL, the meeting is considered "global"
- When `branch_id` has a value, the meeting is branch-specific

### 2.2 Current RLS Policy

**Policy Name:** `meetings_select_invited`

**Current Logic:**
```sql
CREATE POLICY "meetings_select_invited" ON "public"."meetings" FOR SELECT 
USING ((
  ("auth"."uid"() = ANY ("invited_users")) OR 
  ("organizer_id" = "auth"."uid"()) OR 
  "public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text"])
));
```

**Current Behavior:**
- Users can see meetings if they are:
  1. In the `invited_users` array, OR
  2. The meeting organizer, OR
  3. Have admin or pastor permissions

**Problem:** The current policy doesn't consider branch affiliation or global meeting visibility.

## 3. Required Changes

### 3.1 New Visibility Requirements

1. **Global Meetings** (`branch_id` IS NULL):
   - Visible to ALL authenticated users on the platform
   - No branch restrictions apply

2. **Branch-Specific Meetings** (`branch_id` IS NOT NULL):
   - Visible only to:
     - Users within the same branch (`user.branch_id = meeting.branch_id`)
     - Administrators (who can see all meetings)
     - Users explicitly invited (`user_id` in `invited_users` array)
     - The meeting organizer

### 3.2 Updated RLS Policy

**New Policy Name:** `meetings_select_visibility`

**New Logic:**
```sql
CREATE POLICY "meetings_select_visibility" ON "public"."meetings" FOR SELECT 
USING ((
  -- Global meetings (branch_id IS NULL) are visible to all authenticated users
  ("branch_id" IS NULL) OR
  
  -- Branch-specific meetings are visible to:
  (
    -- Users in the same branch
    ("branch_id" = "public"."get_current_user_branch_id"()) OR
    
    -- Administrators can see all meetings
    "public"."user_has_permission"(ARRAY['admin'::"text"]) OR
    
    -- Users explicitly invited
    ("auth"."uid"() = ANY ("invited_users")) OR
    
    -- Meeting organizer
    ("organizer_id" = "auth"."uid"())
  )
));
```

## 4. Implementation Steps

### 4.1 Database Migration

1. **Drop the existing policy:**
   ```sql
   DROP POLICY IF EXISTS "meetings_select_invited" ON "public"."meetings";
   ```

2. **Create the new policy:**
   ```sql
   CREATE POLICY "meetings_select_visibility" ON "public"."meetings" FOR SELECT 
   USING ((
     ("branch_id" IS NULL) OR
     (
       ("branch_id" = "public"."get_current_user_branch_id"()) OR
       "public"."user_has_permission"(ARRAY['admin'::"text"]) OR
       ("auth"."uid"() = ANY ("invited_users")) OR
       ("organizer_id" = "auth"."uid"())
     )
   ));
   ```

### 4.2 Application Layer Changes

**No changes required** in the Flutter application code since:
- The `getAllMeetings()` method in `SupabaseProvider` will automatically respect the new RLS policy
- All existing screens (`MeetingsScreen`, `UpcomingEventsScreen`, `MeetingManagementScreen`, etc.) will automatically show the correct meetings based on the updated policy

### 4.3 Testing Scenarios

1. **Global Meeting Visibility:**
   - Create a meeting with `branch_id = NULL`
   - Verify all users can see it regardless of their branch

2. **Branch-Specific Meeting Visibility:**
   - Create a meeting with a specific `branch_id`
   - Verify only users in that branch + admins + invited users + organizer can see it

3. **Admin Access:**
   - Verify admins can see all meetings (global and branch-specific)

4. **Invited User Access:**
   - Add a user from a different branch to `invited_users`
   - Verify they can see the branch-specific meeting

## 5. Migration Script

```sql
-- Meeting Visibility Logic Update
-- Date: [Current Date]
-- Description: Update RLS policy to support global meeting visibility

BEGIN;

-- Drop existing policy
DROP POLICY IF EXISTS "meetings_select_invited" ON "public"."meetings";

-- Create new policy with global meeting support
CREATE POLICY "meetings_select_visibility" ON "public"."meetings" FOR SELECT 
USING ((
  -- Global meetings (branch_id IS NULL) are visible to all authenticated users
  ("branch_id" IS NULL) OR
  
  -- Branch-specific meetings are visible to:
  (
    -- Users in the same branch
    ("branch_id" = "public"."get_current_user_branch_id"()) OR
    
    -- Administrators can see all meetings
    "public"."user_has_permission"(ARRAY['admin'::"text"]) OR
    
    -- Users explicitly invited
    ("auth"."uid"() = ANY ("invited_users")) OR
    
    -- Meeting organizer
    ("organizer_id" = "auth"."uid"())
  )
));

COMMIT;
```

## 6. Impact Analysis

### 6.1 Positive Impacts
- Global meetings will be visible to all users, improving church-wide communication
- Branch-specific meetings remain properly restricted
- Maintains existing security for sensitive branch meetings
- No application code changes required

### 6.2 Potential Considerations
- Increased meeting visibility for global meetings may result in more notifications
- Users may see more meetings in their lists (global meetings they previously couldn't see)
- Meeting organizers should be aware of global vs. branch-specific visibility when creating meetings

## 7. Rollback Plan

If issues arise, the original policy can be restored:

```sql
-- Rollback to original policy
DROP POLICY IF EXISTS "meetings_select_visibility" ON "public"."meetings";

CREATE POLICY "meetings_select_invited" ON "public"."meetings" FOR SELECT 
USING ((
  ("auth"."uid"() = ANY ("invited_users")) OR 
  ("organizer_id" = "auth"."uid"()) OR 
  "public"."user_has_permission"(ARRAY['admin'::"text", 'pastor'::"text"])
));
```

## 8. Conclusion

This modification will provide the required meeting visibility logic while maintaining security and proper access controls. The implementation is straightforward and requires only a database policy update with no application code changes.