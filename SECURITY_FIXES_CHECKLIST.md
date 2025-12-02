# Security Fixes Checklist

This document tracks critical security vulnerabilities found in the AGBC app and their remediation status.

**Date Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Severity Levels**: 🔴 Critical | 🟠 High | 🟡 Medium | 🔵 Low

---

## 🔴 CRITICAL PRIORITY (Fix Immediately)

### ❌ 1. Exposed Secrets in Version Control
**Status**: ⚠️ NOT STARTED
**Risk**: Complete system compromise
**Location**: `.env` file (lines 9-15)

**Issue**:
- Live Supabase credentials (URL, anon key, service role key) committed to repository
- OneSignal API keys exposed
- Anyone with repo access can access entire database

**Steps to Fix**:
- [ ] Rotate Supabase anon key in Supabase dashboard
- [ ] Rotate Supabase service role key in Supabase dashboard
- [ ] Rotate OneSignal API keys in OneSignal dashboard
- [ ] Remove `.env` from git history:
  ```bash
  git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch .env" \
    --prune-empty --tag-name-filter cat -- --all
  ```
- [ ] Force push to remote: `git push origin --force --all`
- [ ] Update `.env` with new credentials (locally only)
- [ ] Verify `.env` is in `.gitignore` (already present at line 81)
- [ ] Notify team members to pull latest changes

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 2. Service Role Key in Client App
**Status**: ⚠️ NOT STARTED
**Risk**: Complete bypass of all security rules
**Location**: `.env` line 11

**Issue**:
- `SUPABASE_SERVICE_ROLE_KEY` should NEVER be in client applications
- This key bypasses ALL Row Level Security (RLS) policies
- Grants unrestricted database access

**Steps to Fix**:
- [ ] Remove `SUPABASE_SERVICE_ROLE_KEY` from `.env` file
- [ ] Remove any references to service role key in code
- [ ] Verify only `SUPABASE_ANON_KEY` is used in client app
- [ ] Move service role operations to Supabase Edge Functions (server-side only)

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 3. Plaintext Password Storage
**Status**: ⚠️ NOT STARTED
**Risk**: Credential theft from device
**Location**: `lib/services/auth_service.dart:136-138`

**Issue**:
- User passwords stored in plaintext in SharedPreferences
- Accessible via device backup, physical access, or malware
- "Remember Me" feature creates major security risk

**Steps to Fix**:
- [ ] Add `flutter_secure_storage` dependency to `pubspec.yaml`
- [ ] Replace SharedPreferences password storage with FlutterSecureStorage
- [ ] Update `auth_service.dart` sign-in method (lines 134-143)
- [ ] Update `login_form.dart` credential loading (lines 67-79)
- [ ] Consider using biometric authentication instead
- [ ] Test on both iOS and Android devices

**Code Changes Needed**:
```dart
// Replace in auth_service.dart
final storage = FlutterSecureStorage();
if (rememberMe) {
  await storage.write(key: 'saved_email', value: email);
  await storage.write(key: 'saved_password', value: password);
} else {
  await storage.delete(key: 'saved_email');
  await storage.delete(key: 'saved_password');
}
```

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

## 🟠 HIGH PRIORITY (Fix This Week)

### ❌ 4. Missing Row Level Security (RLS) Policies
**Status**: ⚠️ NOT STARTED
**Risk**: Unauthorized data access and modification
**Location**: All Supabase tables, `lib/providers/supabase_provider.dart`

**Issue**:
- App relies only on client-side role checks
- No server-side authorization enforcement
- Attackers can bypass role checks by modifying client code

**Steps to Fix**:
- [ ] Enable RLS on all Supabase tables
- [ ] Create RLS policy for `users` table (profile updates)
- [ ] Create RLS policy for `users` table (role changes - admin only)
- [ ] Create RLS policy for `tasks` table (CRUD operations)
- [ ] Create RLS policy for `meetings` table (CRUD operations)
- [ ] Create RLS policy for `church_branches` table (CRUD operations)
- [ ] Create RLS policy for `notifications` table (user access only)
- [ ] Create RLS policy for `meeting_responses` table
- [ ] Test all user roles (admin, pastor, worker, member)
- [ ] Document all RLS policies

**Example Policies**:
```sql
-- Users can only update their own profile
CREATE POLICY "users_update_own_profile"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Only admins can change user roles
CREATE POLICY "admins_update_roles"
  ON users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can only view their assigned tasks
CREATE POLICY "users_view_assigned_tasks"
  ON tasks FOR SELECT
  USING (
    assigned_to = auth.uid() OR
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role IN ('admin', 'pastor')
    )
  );
```

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 5. Open URL Redirect Vulnerability
**Status**: ⚠️ NOT STARTED
**Risk**: Phishing attacks via malicious meeting links
**Location**: `lib/widgets/meeting_card.dart:286-293`

**Issue**:
- Meeting links launched without validation
- Attackers can create meetings with phishing URLs
- Users redirected to malicious sites

**Steps to Fix**:
- [ ] Create whitelist of trusted meeting platforms
- [ ] Update `_launchMeetingLink` method with validation
- [ ] Add user warning for non-whitelisted domains
- [ ] Consider adding URL preview before opening
- [ ] Update meeting creation to validate URLs
- [ ] Test with various URL formats

**Code Changes Needed**:
```dart
Future<void> _launchMeetingLink(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url);

    // Whitelist trusted meeting platforms
    final allowedHosts = [
      'zoom.us',
      'meet.google.com',
      'teams.microsoft.com',
      'webex.com',
      // Add more as needed
    ];

    final isTrusted = allowedHosts.any((host) =>
      uri.host == host || uri.host.endsWith('.$host')
    );

    if (!isTrusted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Untrusted Link'),
          content: Text('This meeting link (${uri.host}) is not from a verified platform. Do you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Continue Anyway'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch meeting link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error opening meeting link: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 6. Insufficient Input Validation
**Status**: ⚠️ NOT STARTED
**Risk**: XSS, data injection
**Location**: Multiple files (meeting creation, task creation, user registration)

**Issue**:
- User inputs not sanitized before database insertion
- Potential for XSS payloads in meeting descriptions
- Email/phone validation only on client side

**Steps to Fix**:
- [ ] Add server-side validation in Supabase (database constraints)
- [ ] Sanitize HTML/script tags from text inputs
- [ ] Add email format validation (regex)
- [ ] Add phone number format validation
- [ ] Limit text field lengths (title: 100 chars, description: 500 chars)
- [ ] Prevent SQL injection (already handled by Supabase parameterized queries)
- [ ] Add validation for meeting dates (must be in future)
- [ ] Validate task priority values (enum)

**Locations to Update**:
- `lib/screens/meeting_creation_screen.dart`
- `lib/screens/add_task_screen.dart`
- `lib/widgets/register_form.dart`

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

## 🟡 MEDIUM PRIORITY (Fix Next Week)

### ❌ 7. No Rate Limiting
**Status**: ⚠️ NOT STARTED
**Risk**: Brute force attacks, API abuse
**Location**: Authentication endpoints, all API calls

**Issue**:
- No protection against password brute forcing
- No account enumeration prevention
- No API abuse prevention

**Steps to Fix**:
- [ ] Enable Supabase Auth rate limiting in dashboard
- [ ] Add client-side request throttling
- [ ] Implement exponential backoff for failed logins
- [ ] Add CAPTCHA after 3 failed login attempts
- [ ] Monitor for suspicious activity
- [ ] Add account lockout after 5 failed attempts

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 8. Missing Email Verification Enforcement
**Status**: ⚠️ NOT STARTED
**Risk**: Spam accounts, fake users
**Location**: `lib/services/auth_service.dart`

**Issue**:
- Users can sign up without verifying email
- Inconsistent enforcement of email verification

**Steps to Fix**:
- [ ] Enable "Confirm email" in Supabase Auth settings
- [ ] Block unverified users from accessing app features
- [ ] Add verification reminder on login for unverified accounts
- [ ] Send verification email on registration
- [ ] Add "Resend verification" functionality
- [ ] Test email delivery

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 9. Weak Password Requirements
**Status**: ⚠️ NOT STARTED
**Risk**: Account compromise via weak passwords
**Location**: `lib/widgets/mixins/form_validation_mixin.dart`

**Issue**:
- No password complexity requirements
- Allows simple passwords like "password123"

**Steps to Fix**:
- [ ] Enforce minimum 8 characters
- [ ] Require at least one uppercase letter
- [ ] Require at least one number
- [ ] Require at least one special character
- [ ] Add password strength indicator
- [ ] Update validation mixin
- [ ] Update Supabase Auth password policy

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

## 🔵 LOW PRIORITY (Future Improvements)

### ❌ 10. Session Management Issues
**Status**: ⚠️ NOT STARTED
**Risk**: Unauthorized session persistence
**Location**: Authentication flow

**Issue**:
- No session timeout
- No device tracking
- No "logout all devices" functionality

**Steps to Fix**:
- [ ] Implement session timeout (30 minutes of inactivity)
- [ ] Add device fingerprinting
- [ ] Create "Active Sessions" screen
- [ ] Add "Logout all devices" feature
- [ ] Store session metadata (device, location, IP)
- [ ] Notify users of new device logins

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

### ❌ 11. No Security Logging/Monitoring
**Status**: ⚠️ NOT STARTED
**Risk**: Undetected security breaches
**Location**: N/A

**Issue**:
- No audit trail for sensitive operations
- No security event logging
- No anomaly detection

**Steps to Fix**:
- [ ] Log all authentication attempts
- [ ] Log role changes
- [ ] Log data access/modifications
- [ ] Set up Supabase logging
- [ ] Create security dashboard
- [ ] Set up alerts for suspicious activity

**Assigned To**: _____________
**Due Date**: _____________
**Completed Date**: _____________

---

## Progress Summary

- **Total Issues**: 11
- **Critical**: 3 ⚠️
- **High**: 3 ⚠️
- **Medium**: 3 ⚠️
- **Low**: 2 ⚠️
- **Completed**: 0 ✅

**Overall Progress**: 0% (0/11)

---

## Notes

- Update this checklist as you complete each item
- Mark items as ✅ when completed and add completion date
- Add any new security issues discovered during remediation
- Review this document weekly during team meetings
- Consider security audit after all critical/high items are completed

---

## Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/going-into-prod)
