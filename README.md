# AGBC App (Grace Portal)

A comprehensive church management tool built with Flutter and Supabase, designed to streamline administrative tasks and enhance member engagement.

## Features

- **Role-Based Access**: Secure login with differentiated roles (Admin, Pastor, Worker, Member).
- **Task Management**: Assign, track, and manage church operations efficiently.
- **Meeting Coordination**: Schedule events, track attendance, and manage RSVPs.
- **Branch Management**: Support for multiple church locations with location-based features.
- **Member Directory**: Centralized database for better communication and pastoral care.
- **Communication**: Real-time updates and targeted push notifications via OneSignal.
- **Resources**: Prayer requests, daily verses, and event calendars.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **State Management**: Provider
- **Notifications**: OneSignal
- **Maps**: Google Maps Flutter

## Getting Started

1.  **Clone the repository**:

    ```bash
    git clone <repo-url>
    cd agbc-app
    ```

2.  **Setup Environment**:
    Copy `.env.example` to `.env` and fill in your credentials:

    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ONESIGNAL_APP_ID=your_onesignal_app_id
    ```

3.  **Install Dependencies**:

    ```bash
    flutter pub get
    ```

4.  **Run the App**:
    ```bash
    flutter run
    ```

## Project Structure

- `lib/config`: Themes, routes, and app constants.
- `lib/models`: Data models (User, Task, Meeting, etc.).
- `lib/providers`: State management using Provider.
- `lib/screens`: Application screens and pages.
- `lib/services`: Business logic and API services (Auth, Storage, etc.).
- `lib/widgets`: Reusable UI components.
- `supabase/`: Backend edge functions and database migrations.

## Privacy Policy

[https://agbc-web.vercel.app/privacy-policy](https://agbc-web.vercel.app/privacy-policy)
