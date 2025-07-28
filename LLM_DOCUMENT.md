# AGBC App - Comprehensive Project Overview

## 1. Introduction

**App Name:** AGBC App

**Overview:**
AGBC App is a comprehensive church management tool designed to streamline administrative tasks and enhance member engagement. Developed using Flutter, it provides a centralized platform for managing church activities, member communication, and organizational workflows. The application serves both church administrators by offering robust management tools and church members by fostering a connected and engaged community.

**Purpose:**
To empower church leaders with efficient management tools for tasks, meetings, members, and branches, while providing church members with timely information, resources, and avenues for community engagement.

**Target Audience:**

- **Church Administrators & Leaders (Pastors, Workers):** Individuals responsible for organizing church activities, managing resources, assigning tasks, and overseeing church operations across potentially multiple branches.
- **Church Members:** General congregation members who need to stay informed about church events, access resources, receive communications, and participate in church life.

## 2. Core Features

The AGBC App offers a suite of features tailored to the needs of a church community:

**2.1. User Authentication & Role-Based Access Control:**

- **Secure Registration & Login:** Users can register with email/password, name, phone, location, and optionally select a branch. Login is via email and password, with a "remember me" option.
- **Email Verification:** New users receive a verification email. The app uses deep linking (`agbcapp://` or `agbc://` scheme with `/verify-email` path) to handle verification links and confirm user emails via Supabase Auth.
- **User Roles:**
  - **Super Admin (`admin`):** Full access to all app features and data management.
  - **Pastor (`pastor`):** High-level administrative access, particularly for managing meetings, tasks, and viewing user data.
  - **Worker (`worker`):** Can create and manage tasks, typically involved in specific church departments or activities.
  - **Member (`member`):** Basic access to view information, receive notifications, manage their own profile, and interact with features like prayer requests (when implemented).
- **Session Management:** Handled by Supabase, with `AuthService` managing the user session state within the app.

**2.2. Comprehensive Task Management:**

- **Creation & Assignment:** Admins, Pastors, and Workers can create tasks with a title, description, assignee (user), due date, priority, and associated branch.
- **Tracking & Status Updates:** Tasks can have statuses like 'pending', 'in_progress', or 'completed'. Users assigned to tasks can update their status.
- **Prioritization:** Tasks can be set with 'high', 'medium', or 'low' priority.
- **Viewing:** Users can view tasks assigned to them. Admins/Pastors/Workers can view a broader range of tasks. The `TasksScreen` provides filtering (by status) and sorting (by due date, priority, status, title, created date).
- **Details:** A dedicated screen shows full task details, including creator and assignee information.
- **Notifications:** Planned for new task assignments and upcoming deadlines (via OneSignal and `send-notification` Edge Function).

**2.3. Advanced Meeting Scheduling & Management:**

- **Scheduling:** (Partially Implemented) Admins/Pastors can schedule one-time or recurring meetings/events. The `MeetingModel` supports title, description, date/time, end time, type (global/local), branch, category, organizer, location (physical/virtual), meeting link, and expected attendance.
- **Viewing:** A `MeetingsScreen` exists but currently shows a "Coming Soon" placeholder. An admin-focused `MeetingManagementScreen` lists all meetings.
- **Attendance & RSVPs:** The `MeetingModel` includes an `attendees` list, but UI for RSVP and detailed attendance tracking is not yet fully implemented.
- **Notifications:** Planned for meeting reminders.

**2.4. Multi-Branch Management:**

- **Branch Data:** Churches with multiple locations can manage each branch's information (name, location, address, description, pastor, members, departments).
- **Admin Interface:** `BranchManagementScreen` allows admins to view, add (`AddBranchScreen`), and delete branches. Deleting a branch includes a warning and reassigns users if members are present.
- **User Affiliation:** Users can be associated with a specific branch, stored in their profile. This can be used to filter content and communication.
- **Branch Display:** User profiles show the name of their assigned branch.

**2.5. Prayer Requests Module:**

- **(Planned / Placeholder)** The `PrayScreen` shows a "Prayer Wall Coming Soon" placeholder.
- **Planned Functionality (from README):** Members submit prayer requests (public/private), view public requests, and admins moderate submissions.

**2.6. Daily Bible Verse Display:**

- **Display:** A `DailyVerseCard` on the `HomeScreen` shows a Bible verse and reference.
- **Current Implementation:** The verse is currently hardcoded (Jeremiah 29:11). Dynamic fetching is not yet implemented.

**2.7. User Profile Management:**

- **View & Update:** Users can view their profile information (name, email, phone, location, photo, role, branch).
- **Logout:** Users can log out of their account.
- **Planned Updates (via `AuthService` methods):** Functionality to update profile (name, photo), email, and password exists in `AuthService` but corresponding UI screens for these actions are not yet fully built out in the `ProfileScreen`.
- **Account Deletion:** `AuthService` has a `deleteAccount` method (marks user as inactive).

**2.8. Push Notification System:**

- **Service:** OneSignal is used for delivering push notifications.
- **Mechanism:** `NotificationService` registers devices with OneSignal, linking OneSignal Player ID to the app's User ID. A Supabase Edge Function (`send-notification`) is triggered by the app to send messages via OneSignal's API.
- **Triggers:** Notifications are planned for task assignments, meeting reminders, new prayer requests, and general announcements. Admins have a test broadcast notification button in `BranchManagementScreen`.

## 3. Technology Stack

- **Programming Language:** Dart
- **Framework:** Flutter (for cross-platform mobile, web, desktop development)
- **Backend-as-a-Service (BaaS):** Supabase
  - **Database:** PostgreSQL
  - **Authentication:** Supabase Auth (email/password, email verification)
  - **Real-time Subscriptions:** For live data updates
  - **Storage:** (Implied for profile pictures, etc., though not explicitly detailed in services yet)
  - **Edge Functions:** Serverless functions (TypeScript) for custom backend logic (e.g., sending notifications).
- **State Management:** Provider package
- **Navigation:**
  - Flutter's built-in `MaterialApp` routes for initial/auth screens.
  - `go_router` package for declarative routing, deep linking, and more complex navigation within the authenticated part of the app.
- **Push Notifications:** OneSignal (via `onesignal_flutter` SDK and a Supabase Edge Function)
- **Local Storage:** `shared_preferences` (for "remember me" functionality)
- **Location Services:**
  - `geolocator` (for fetching GPS coordinates)
  - `geocoding` (for converting coordinates to addresses and vice-versa)
  - `google_maps_flutter` (for displaying maps, e.g., branch locations)
- **UI Libraries & Utilities:**
  - `google_fonts` (specifically 'Inter' font)
  - `remixicon` (for a rich set of icons)
  - `intl` (for internationalization and localization, e.g., date formatting - usage implied)
  - `uuid` (for generating unique identifiers)
- **Environment Management:** `flutter_dotenv` (for managing API keys and environment variables)
- **Deep Linking:** `app_links` (for handling URI schemes, e.g., email verification)
- **Permissions:** `permission_handler` (for requesting OS-level device permissions)
- **Logging:** `logging` package.

## 4. Application Architecture

**4.1. Project Structure (主なディレクトリ):**

- `lib/`: Main Dart code.
  - `main.dart`: App entry point, initialization, root providers, initial routing.
  - `config/`: App-level configurations (e.g., `theme.dart`, `app_config.dart`).
  - `models/`: Data model classes (e.g., `UserModel`, `TaskModel`, `MeetingModel`, `ChurchBranch`).
  - `providers/`: State management classes using Provider (e.g., `AuthService`, `SupabaseProvider`, `BranchesProvider`, `NavigationProvider`).
  - `screens/`: UI views/pages for different app sections.
  - `services/`: Business logic, API/service communication (e.g., `AuthService`, `SupabaseService`, `NotificationService`, `LocationService`).
  - `widgets/`: Reusable UI components shared across screens.
  - `utils/`: Utility functions, helper classes (e.g., `theme.dart`, `role_utils.dart`).
- `assets/`: Static assets (images, fonts if locally stored). `.env` file.
- `supabase/`: Supabase-specific files.
  - `functions/`: Contains directories for Supabase Edge Functions (e.g., `check_user_exists`, `send-notification`). Actual code managed on Supabase dashboard.
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Platform-specific project files.
- `test/`: Unit, widget, and integration tests.
- `*.sql`: SQL scripts for database schema and RLS policies (e.g., `rls_policies_users_table.sql`).

**4.2. State Management:**

- Utilizes the `Provider` package.
- `ChangeNotifierProvider` is used for mutable state (e.g., `AuthService`, `SupabaseProvider`, `BranchesProvider`, `NavigationProvider`).
- `Provider.value` is used for providing existing service instances (e.g., `SupabaseService`).
- Providers manage application state, interact with services for business logic, and notify widgets of changes.

**4.3. Navigation:**

- Initial routes (`/`, `/login`, `/register`, `/verification`, `/home`) are defined in `MaterialApp` in `main.dart`.
- `MainNavigationScreen` likely serves as the entry point after login, hosting the `BottomNavBar` and displaying different primary screens based on `NavigationProvider`.
- `go_router` is used for more advanced navigation needs, including deep linking capabilities.
- `CustomDrawer` (accessed via "More" in `BottomNavBar`) provides another layer of navigation to less frequently accessed screens.

**4.4. Backend (Supabase):**

- **Database:** PostgreSQL is used, with tables for `users`, `tasks`, `meetings`, `branches`, `task_comments`, `user_devices`, `error_logs`.
- **Authentication:** Supabase Auth handles user accounts and sessions.
- **Row Level Security (RLS):** Implemented on `users` and `tasks` tables to control data access based on user roles and ownership. A custom SQL function `get_current_user_role()` is key to this.
- **Edge Functions:**
  - `check_user_exists`: Likely for validating user existence.
  - `send-notification`: Handles the server-side logic for sending push notifications via OneSignal.
    (Note: Edge Function code is on the Supabase dashboard, not in the repo).

**4.5. UI/UX Overview:**

- **Theming:** Both light and dark themes are defined (`lib/utils/theme.dart` and `lib/config/theme.dart` - potential conflict/overlap to review). The theme in `lib/utils/theme.dart` uses a palette of Primary Blue, Warm Orange, Forest Green. `GoogleFonts.inter` is the primary font.
- **Common Widgets:** Extensive use of custom reusable widgets (`CustomButton`, `CustomInput`, `CustomCard`, `TaskCard`, `BranchCard`, etc.) ensures UI consistency.
- **Layout:** Standard Flutter layout widgets are used. Screens like Login/Register feature decorative frosted glass effects.
- **Iconography:** A mix of Material Icons and Remixicon.

## 5. Services and Integrations

- **Supabase:** Core backend for data, auth, and functions.
- **OneSignal:** For push notifications, integrated via `NotificationService` and a Supabase Edge Function.
- **Location Services (`geolocator`, `geocoding`, `google_maps_flutter`):**
  - Used by `LocationService` to fetch and validate device location.
  - `LocationField` widget for user input.
  - Google Maps for displaying branch locations (requires API key setup).
- **Local Storage (`shared_preferences`):** Used by `PreferencesService` for "remember me" login functionality.
- **Deep Linking (`app_links`):** Used in `main.dart` for email verification link handling.
- **Permissions (`permission_handler`):** Used by `PermissionsService` for OS-level permission requests (location, notifications, camera, storage). `PermissionsService` also defines app-level role-based permissions.
- **Environment Variables (`flutter_dotenv`):** Manages API keys and configurations from `.env` file.

## 6. Data Models (`lib/models/`)

- **`UserModel`:** Represents users with ID, display name, email, role, phone, photo URL, branch affiliation, timestamps, active status, email verification, notification settings.
- **`TaskModel`:** Represents tasks with ID, title, description, creator, assignee, due date, branch, status, priority, timestamps.
- **`MeetingModel`:** Represents meetings with ID, title, description, date/time, type (global/local), branch, category, organizer, location, virtual meeting details, attendees, status.
- **`ChurchBranchModel`:** Represents church branches with ID, name, location, address, description, pastor, departments, members, timestamps.
- **`CommentModel`:** Represents comments on tasks, with ID, task ID, user ID, content, and timestamp.

## 7. User Roles and Permissions

- **Roles Defined:** `admin`, `pastor`, `worker`, `member`.
- **RLS Policies (Supabase):**
  - **`users` table:** Admins full access; Pastors read all; Users read/update own; New users insert own.
  - **`tasks` table:** Admins full access; Workers/Pastors create/update; Creators read own; Assignees read own & update status/reminder.
- **App-Level Permissions (`PermissionsService`):** Defines boolean flags for capabilities (e.g., `manage_users`, `create_tasks`) based on roles. Used for conditional UI rendering/access.

## 8. Setup and Configuration

- **Environment Variables:** Requires a `.env` file with `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`.
- **Supabase Project Setup:**
  - Database schema setup using provided SQL files (`rls_policies_*.sql`).
  - Authentication providers (Email) enabled.
  - Edge Functions (`check_user_exists`, `send-notification`) deployed on Supabase dashboard.
- **Platform-Specific:**
  - **Android:** Requires Google Maps API key in `AndroidManifest.xml`. Permissions for Internet, Location. Deep link intent filter for `agbcapp://`.
  - **iOS:** Requires Google Maps API key in `AppDelegate.swift`. Usage descriptions for Location, Camera, Photo Library, etc., in `Info.plist`. Deep link URL scheme `agbc://`. Background mode for remote notifications. `GoogleService-Info.plist` may be needed.
- **Flutter Dependencies:** `flutter pub get`.

## 9. Potential Future Enhancements / Areas for Review

- **Full Meeting Module Implementation:** RSVP tracking, agenda/minute attachments, user interface for scheduling and viewing.
- **Prayer Request Module Implementation:** UI for submission, viewing, and moderation.
- **Dynamic Daily Bible Verse:** Fetching verse from an API or internal source.
- **Enhanced User Profile Editing:** Dedicated UI for users to update their profile details, email, password.
- **File Attachments:** For tasks or meetings (e.g., `TaskModel` has an 'attachments' field commented out in `SupabaseProvider`).
- **Refined Pastor/Worker Permissions:** Current RLS for task updates by workers/pastors is broad; might need to be scoped to tasks they created or are in their branch/department.
- **Department-Level Management:** Further integration of 'departments' in user roles and resource allocation.
- **Internationalization/Localization:** `intl` package is present, suggesting plans, but full implementation would require string resource files.
- **Testing:** Expand unit, widget, and integration tests.
- **Theme Consistency:** Resolve potential conflict/overlap between `lib/config/theme.dart` and `lib/utils/theme.dart`.
- **iOS Deep Link Scheme:** Consider aligning `agbc` with Android's `agbcapp` for consistency if a single link format is desired.
- **iOS `NSAppTransportSecurity`:** Restrict `NSAllowsArbitraryLoads` for production.
- **Supabase Storage Policies:** If Supabase Storage is used for profile pictures or other files, appropriate bucket policies will be needed.
