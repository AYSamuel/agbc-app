# AGBC App

**GRACE PORTAL** is a comprehensive church management tool designed to streamline administrative tasks and enhance member engagement. This Flutter-based application provides a centralized platform for managing church activities, member communication, and organizational workflows.

**For Church Administrators:**

- **Efficient Task Management:** Assign, track, and manage tasks for various church departments and volunteers. Ensure accountability and smooth execution of church operations.
- **Simplified Meeting Coordination:** Schedule, organize, and manage meetings with ease. Send out invitations, track RSVPs, and share meeting agendas and minutes.
- **Centralized Member Database:** Maintain an organized and up-to-date directory of church members, facilitating better communication and pastoral care.
- **Branch Management:** For churches with multiple locations, the app offers tools to manage activities and communication across different branches seamlessly.
- **Real-time Updates & Notifications:** Keep the congregation informed with instant updates on events, announcements, and important news through push notifications.

**For Church Members:**

- **Stay Connected:** Receive timely updates on church events, news, and prayer requests.
- **Access to Resources:** Easily find information on past sermons, upcoming events, and church group activities.
- **Engage with the Community:** Connect with fellow members, participate in discussions, and volunteer for church activities.
- **Personalized Experience:** (Future Feature) Access personalized content and recommendations based on interests and involvement.

AGBC App aims to empower church leaders with robust management tools and foster a more connected and engaged church community.

## Features

- **User Authentication & Role-Based Access Control:**
  - Secure user registration and login (email/password, potentially social logins).
  - Differentiated user roles (e.g., Super Admin, Branch Admin, Member) with specific permissions for accessing and managing different app sections.
- **Comprehensive Task Management:**
  - Create, assign, and track tasks for individuals or groups.
  - Set due dates, priority levels, and categorize tasks (e.g., by department, project, or event).
  - Monitor task progress with status updates (e.g., To Do, In Progress, Completed).
  - Notifications for new task assignments and upcoming deadlines.
- **Advanced Meeting Scheduling & Management:**
  - Schedule one-time or recurring meetings and church events.
  - Send automated invitations and reminders to attendees.
  - Track attendance and manage RSVPs.
  - Attach agendas, minutes, and other relevant documents to meeting entries.
- **Multi-Branch Management:**
  - Manage information and activities for multiple church locations or campuses.
  - Store and display branch-specific details: address, contact information, service times, and map/location data.
  - Filter content and communication based on user's assigned or preferred branch.
- **Prayer Requests Module:**
  - Members can submit prayer requests through the app.
  - Option for requests to be public (visible to other members) or private (visible only to admins/pastoral team).
  - Members can view and pray for public requests, potentially with features to indicate "I prayed for this."
  - Admins can manage and moderate prayer requests.
- **Daily Bible Verse Display:**
  - Shows a daily inspirational Bible verse on the home screen or a dedicated section.
- **User Profile Management:**
  - Users can view and update their personal information (e.g., name, contact details, profile picture).
  - Preferences for notifications and app settings.
- **Real-time Data Sync with Supabase:**
  - All data is synchronized in real-time across devices, ensuring up-to-date information for all users.
- **Push Notification System:**
  - Contextual notifications for important updates, new task assignments, meeting reminders, new prayer requests, announcements, and other relevant events.

## Technology Stack

This project leverages a modern stack to deliver a robust and scalable church management application:

- **Programming Language: Dart**
  - The language used to build Flutter applications, known for its performance and developer-friendly features.
- **Framework: Flutter**
  - Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
- **Backend-as-a-Service (BaaS): Supabase**
  - Provides the backend infrastructure, including a PostgreSQL database, authentication, real-time subscriptions, and storage. The `supabase_flutter` client library is used for interaction.
- **State Management: Provider**
  - A wrapper around InheritedWidget to make it easier to manage and propagate state throughout the application.
- **Navigation: GoRouter**
  - A declarative routing package for Flutter that simplifies navigation, linking, and handling deep links.
- **Local Storage: shared_preferences**
  - Used for storing simple key-value data persistently on the device (e.g., user preferences).
- **Push Notifications: OneSignal**
  - A service for sending targeted push notifications to keep users informed about important updates and events. The `onesignal_flutter` SDK is integrated.
- **Location Services:**
  - `geolocator` & `geocoding`: For fetching device location and converting coordinates to addresses (and vice-versa), likely used for branch location features.
  - `google_maps_flutter`: For displaying interactive maps within the application, such as branch locations.
- **UI Libraries & Utilities:**
  - `google_fonts`: For using a wide variety of custom fonts from Google Fonts.
  - `remixicon`: Provides a rich set of open-source icons.
  - `intl`: Used for internationalization (i18n) and localization (l10n), such as formatting dates and numbers.
- **Environment Management: flutter_dotenv**
  - Manages environment-specific configurations (like API keys) securely.
- **Deep Linking: app_links**
  - Handles incoming URI-based links to navigate users to specific content within the app.
- **Permissions: permission_handler**
  - Manages runtime permissions for accessing device capabilities like location, camera, etc.

## Getting Started

This guide will help you get the AGBC App running on your local machine for development and testing.

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK:** Latest stable version (e.g., 3.x.x). The project is configured for Dart SDK `>=3.2.3 <4.0.0`. You can find installation instructions on the [Flutter official website](https://flutter.dev/docs/get-started/install).
- **Dart SDK:** Comes bundled with the Flutter SDK.
- **Node.js:** Recommended (e.g., LTS version). Needed if you plan to work with Supabase Edge Functions locally or use certain project scripts. Download from [Node.js official website](https://nodejs.org/).
- **Supabase Account:** You'll need a Supabase project. If you don't have one, create it at [Supabase](https://supabase.com/).
- **Git:** For cloning the repository.

### Setup Steps

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/yourusername/agbc-app.git
    cd agbc-app
    ```

    _(Replace `yourusername/agbc-app.git` with the actual repository URL if different)_

2.  **Configure Supabase:**

    - **Create a Project:** If you haven't already, create a new project on [Supabase](https://app.supabase.io).
    - **Database Schema & Policies:**
      - Navigate to the "SQL Editor" in your Supabase project dashboard.
      - Execute the SQL scripts found in the root of this repository to set up necessary tables and Row Level Security (RLS) policies:
        - `rls_policies_users_table.sql`
        - `rls_policies_tasks_table.sql`
      - _(Review these SQL files for any specific order or additional instructions.)_
    - **Authentication:**
      - Go to "Authentication" -> "Providers" in your Supabase project.
      - Enable "Email" as a provider. Ensure "Enable email signups" is toggled on.
      - If the app uses other authentication methods (e.g., Google, Apple), enable them here as well.
      - Under "Authentication" -> "Settings", review email templates and other settings like "Enable email confirmations" if required by the app.
    - **Storage (if applicable):**
      - If the app uses Supabase Storage (e.g., for user profile pictures, event images), navigate to "Storage" in your Supabase project.
      - Create the necessary buckets (e.g., `avatars`, `event_images`).
      - Set up storage policies for access control as needed. Consult the app's specific storage implementation for bucket names and policies.
    - **API Keys:**
      - Go to "Project Settings" -> "API".
      - You will find your `Project URL` (this is your `SUPABASE_URL`) and the `anon` `public` key (this is your `SUPABASE_ANON_KEY`).

3.  **Set Up Environment Variables:**

    - In the root directory of the project, you'll find example environment files: `.env.example` and `env.example.template`.
    - Create a new file named `.env` by copying one of these examples:
      ```bash
      cp .env.example .env
      ```
    - Open the `.env` file and update it with your specific credentials and configurations:

      ```dotenv
      # Supabase Configuration
      SUPABASE_URL=your_supabase_project_url # Found in Supabase Project Settings -> API
      SUPABASE_ANON_KEY=your_supabase_anon_key # Found in Supabase Project Settings -> API (anon public key)

      # OneSignal Configuration (for Push Notifications)
      ONESIGNAL_APP_ID=your_onesignal_app_id # Get this from your OneSignal dashboard
      ONESIGNAL_REST_API_KEY=your_onesignal_rest_api_key # Get this from your OneSignal dashboard (if server-side sending is used)

      # App Configuration (Optional - check if used by the app's config)
      APP_NAME=Grace Portal
      APP_ENV=development # Set to 'development' for local work, 'production' for releases
      ```

    - **Purpose of variables:**
      - `SUPABASE_URL`: The unique URL for your Supabase project backend.
      - `SUPABASE_ANON_KEY`: The public anonymous key for your Supabase project, allowing client-side access according to your RLS policies.
      - `ONESIGNAL_APP_ID`: Your OneSignal application ID, used by the client-side SDK.
      - `ONESIGNAL_REST_API_KEY`: Your OneSignal REST API Key, used for sending notifications from a backend (if applicable).
      - `APP_NAME`: Application name, might be used for display or configuration.
      - `APP_ENV`: Environment indicator (e.g., `development`, `staging`, `production`).

4.  **Platform-Specific Setup (Google Maps):**

    - This app uses `google_maps_flutter`, which requires API keys for Google Maps.
    - **Android:**
      - Obtain a Google Maps API key from the [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
      - Add the API key to your `android/app/src/main/AndroidManifest.xml` file:
        ```xml
        <application>
            ...
            <meta-data android:name="com.google.android.geo.API_KEY"
                       android:value="YOUR_ANDROID_API_KEY_HERE"/>
            ...
        </application>
        ```
    - **iOS:**

      - Obtain a Google Maps API key (it can be the same key as Android or a new one).
      - Add the API key to your `ios/Runner/AppDelegate.swift` file:

        ```swift
        import UIKit
        import Flutter
        import GoogleMaps // Add this import

        @UIApplicationMain
        @objc class AppDelegate: FlutterAppDelegate {
          override func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
          ) -> Bool {
            GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE") // Add this line
            GeneratedPluginRegistrant.register(with: self)
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
          }
        }
        ```

    - Ensure the Google Maps SDK is enabled for your project in the Google Cloud Console for both Android and iOS platforms.

5.  **Install Flutter Dependencies:**

    ```bash
    flutter pub get
    ```

6.  **Run the App:**
    - Ensure an emulator is running or a device is connected.
    - Use the following command to run the app:
      ```bash
      flutter run
      ```
    - To run on a specific platform (if multiple are configured):
      ```bash
      flutter run -d <deviceId>
      # e.g., flutter run -d chrome, flutter run -d emulator-5554
      ```

### Troubleshooting (Example)

- **Error: "MissingPluginException" after adding a new package:**
  - Try stopping the app completely and restarting it (`flutter run`). Sometimes a hot reload/restart isn't enough.
  - Ensure `flutter pub get` was successful.
- **Supabase login issues:**
  - Double-check your `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the `.env` file.
  - Verify that email/password authentication is enabled in your Supabase project settings.
  - Check RLS policies on your `users` table if you can sign up but not log in.

## Project Structure

The repository is organized as follows, adhering to standard Flutter project conventions:

- `lib/`: Contains all the Dart code for the application.
  - `main.dart`: The main entry point of the Flutter application.
  - `config/`: Holds application-level configurations, such as theme definitions (`theme.dart`), app-specific constants, and routes (`app_config.dart`).
  - `models/`: Defines the data structures and model classes (e.g., `user_model.dart`, `task_model.dart`).
  - `providers/`: State management classes using the Provider package (e.g., `branches_provider.dart`, `supabase_provider.dart`).
  - `screens/`: UI view components, representing different pages or screens of the app (e.g., `login_screen.dart`, `home_screen.dart`).
  - `services/`: Houses business logic, API communication (e.g., `auth_service.dart`, `notification_service.dart`), and other utility services.
  - `widgets/`: Contains reusable UI components shared across multiple screens (e.g., `custom_button.dart`, `task_card.dart`).
  - `utils/`: General utility functions, helper classes, and constants not specific to a single domain (e.g., `role_utils.dart`).
- `assets/`: Stores static assets like images (e.g., `logo.png`), fonts, and other resource files.
  - `images/`: Contains image files used in the app.
- `supabase/`: Includes Supabase-specific configurations and backend code.
  - `functions/`: Contains code for Supabase Edge Functions (e.g., `check_user_exists`, `send-notification`).
  - `migrations/`: (If used) SQL files for database schema migrations, managed by the Supabase CLI.
    _(Note: The initial schema setup scripts like `rls_policies_tasks_table.sql` are currently in the root, but ongoing migrations might be placed here)._
- `android/`: Contains Android-specific project files and configurations.
- `ios/`: Contains iOS-specific project files and configurations.
- `web/`: Contains web-specific project files and configurations (if Flutter for Web is enabled).
- `windows/`: Contains Windows-specific project files and configurations (if Flutter for Desktop is enabled).
- `linux/`: Contains Linux-specific project files and configurations (if Flutter for Desktop is enabled).
- `macos/`: Contains macOS-specific project files and configurations (if Flutter for Desktop is enabled).
- `test/`: Includes all unit tests, widget tests, and integration tests for the application (e.g., `widget_test.dart`).
- `.env.example`, `env.example.template`: Template files for environment variables. `.env` (gitignored) stores actual secrets.
- `pubspec.yaml`: The project's manifest file, defining dependencies, assets, and other metadata.
- `README.md`: This file, providing an overview and guide to the project.

## Screenshots

_(Screenshots will be added soon to provide a visual overview of the application.)_

**How to Add Screenshots:**

1.  Create a directory named `screenshots` in the root of the project (or in the `assets` directory, e.g., `assets/screenshots/`).
2.  Place your screenshot images (e.g., in PNG or JPG format) in this directory.
3.  Embed the screenshots in this section using Markdown:
    ```markdown
    ![Caption for Screenshot 1](screenshots/screen1.png 'Optional Hover Title')
    ![Caption for Screenshot 2](assets/screenshots/screen2.png 'Optional Hover Title')
    ```
    Alternatively, you can use an external image hosting service and link the images here.

**Suggested Screenshots to Include:**

- Login/Register Screen
- Home Screen / Main Dashboard
- Task Management View (e.g., list of tasks, task details)
- Meeting Schedule View (e.g., calendar, list of meetings)
- Branch List / Branch Details Screen
- User Profile Screen
- Admin Panel / User Management Screen (if applicable)
- Prayer Requests Screen
- Daily Bible Verse display (if prominent)

## Contributing

We welcome contributions to the AGBC App! If you'd like to help improve the project, please follow these steps:

1.  **Discuss Major Changes:** Before starting significant work, please open an issue on the repository to discuss your proposed changes, new features, or architectural improvements. This helps ensure alignment with the project's goals and avoids duplicate efforts.
2.  **Fork the Repository:** Create your own fork of the AGBC App repository.
3.  **Create a Feature Branch:** Work on your changes in a dedicated feature branch:
    ```bash
    git checkout -b feature/your-amazing-feature
    ```
4.  **Develop Your Feature:** Make your changes, including clear comments and documentation where necessary.
    - **Code Style:** Please adhere to the Dart code style guidelines defined in the `analysis_options.yaml` file. Run `dart format .` to format your code.
    - **Tests:** If you're adding new features or fixing bugs, please write appropriate unit or widget tests and ensure all existing tests pass. Run tests using:
      ```bash
      flutter test
      ```
5.  **Commit Your Changes:** Use clear and descriptive commit messages:
    ```bash
    git commit -m 'feat: Add some amazing feature'
    # (or fix: ..., chore: ..., etc.)
    ```
6.  **Push to Your Branch:**
    ```bash
    git push origin feature/your-amazing-feature
    ```
7.  **Open a Pull Request:** Submit a pull request from your feature branch to the main project repository. Provide a clear description of your changes in the PR.

## Privacy Policy

The privacy policy for GRACE PORTAL is available at: [https://aysamuel.github.io/agbc-app/privacy-policy.html](https://aysamuel.github.io/agbc-app/privacy-policy.html)

## License

This project is intended to be licensed under the MIT License.

We recommend creating a `LICENSE` file in the root of the repository and including the full text of the MIT License. You can obtain the MIT License text from the [Open Source Initiative website](https://opensource.org/licenses/MIT).
