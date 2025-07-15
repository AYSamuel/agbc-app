# Grace Portal Development Guide

This document outlines the comprehensive development plan for the Grace Portal, detailing each sprint, its objectives, and step-by-step implementation instructions with code examples and best practices. This guide is designed to ensure a structured, maintainable, and scalable application build.

## Table of Contents

1.  [Introduction](#introduction)
2.  [Architectural Principles](#architectural-principles)
3.  [Sprint 0: Project Foundation](#sprint-0-project-foundation)
4.  [Sprint 1: Core User Authentication & Profile](#sprint-1-core-user-authentication--profile)
5.  [Sprint 2: Foundational App Structure & Branch Management (Admin)](#sprint-2-foundational-app-structure--branch-management-admin)
6.  [Sprint 3: Comprehensive Task Management](#sprint-3-comprehensive-task-management)
7.  [Sprint 4: Push Notifications & User Engagement](#sprint-4-push-notifications--user-engagement)
8.  [Sprint 5: Meeting Management Module (Phase 1)](#sprint-5-meeting-management-module-phase-1)
9.  [Sprint 6: Enhancements & Polish](#sprint-6-enhancements--polish)
10. [Future Sprints (Post-MVP)](#future-sprints-post-mvp)

## 1. Introduction

The Grace Portal is designed to streamline various church management and community engagement processes. This guide provides a detailed roadmap for its development, broken down into manageable sprints, ensuring a systematic approach to building a robust and feature-rich application.

## 2. Architectural Principles

To ensure the application is scalable, maintainable, and easy to extend, the following architectural principles will be strictly adhered to:

- **Separation of Concerns:** Each part of the application will have a distinct responsibility. UI components will handle presentation, services will encapsulate business logic and API interactions, models will define data structures, and providers will manage application state.
- **Component-Based UI:** The user interface will be built using small, reusable, and self-contained widgets. This promotes consistency, reduces code duplication, and simplifies UI development and testing.
- **Service-Oriented Architecture:** Business logic, external API calls (e.g., Supabase, OneSignal), and complex computations will be encapsulated within dedicated service classes. This keeps the UI clean and focused solely on presentation.
- **State Management with Provider:** The `provider` package will be used for efficient and reactive state management. This allows different parts of the application to access and react to changes in shared data without tight coupling.
- **Clean Code Practices:** Emphasis will be placed on writing readable, well-commented, and clearly named code. This includes consistent formatting, meaningful variable names, and adherence to Dart/Flutter best practices.
- **Data Immutability:** Data models will be designed to be immutable where possible, promoting predictable state changes and simplifying debugging.
- **Error Handling:** Robust error handling mechanisms will be implemented at all layers of the application, providing informative feedback to users and developers.
- **Security:** Security considerations, especially with user authentication and data access (e.g., Supabase RLS), will be paramount from the initial stages.

---

## 3. Sprint 0: Project Foundation

**Goal:** Prepare the complete development and deployment pipeline. This initial 'sprint' is crucial for establishing the foundational environment, project structure, and backend services that all subsequent development will rely upon. It ensures a stable and organized starting point for the entire project.

### 3.1. Step 1: Project Setup & Structuring

This step involves initializing the Flutter project and setting up a logical directory structure to maintain code organization and separation of concerns from the very beginning.

#### 3.1.1. Initialize Flutter Project

Open your terminal or command prompt and execute the following commands. This will create a new Flutter project named `grace_portal` and navigate into its root directory.

```bash
flutter create grace_portal
cd grace_portal
```

#### 3.1.2. Establish Directory Structure

Within the `lib/` directory of your newly created Flutter project, create the following subdirectories. This structure promotes modularity and makes it easier to locate specific types of files (e.g., all API-related code in `api/`, all UI screens in `screens/`).

- `lib/api/`: For API client configurations and direct API interactions.
- `lib/config/`: For application-wide configurations, themes, and routing setup.
- `lib/constants/`: For static constant values, such as strings, numbers, or enum definitions.
- `lib/models/`: For Dart classes that represent data structures (e.g., `UserModel`, `TaskModel`).
- `lib/providers/`: For classes that manage and provide application state using the `provider` package.
- `lib/screens/`: For full-page UI components (e.g., `LoginScreen`, `HomeScreen`).
- `lib/services/`: For business logic and external service integrations (e.g., `AuthService`, `NotificationService`).
- `lib/utils/`: For utility functions, helpers, and common methods.
- `lib/widgets/`: For reusable UI components that are smaller than a full screen (e.g., `CustomButton`, `CustomTextField`).

#### 3.1.3. Add Dependencies to `pubspec.yaml`

Open the `pubspec.yaml` file located at the root of your project. Under the `dependencies` section, add the following packages. These packages are essential for connecting to Supabase, managing environment variables, handling state, routing, logging, and using custom fonts.

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Service Integration
  supabase_flutter: ^2.5.0 # Official Supabase client for Flutter
  flutter_dotenv: ^5.1.0 # For loading environment variables from a .env file

  # State Management & Navigation
  provider: ^6.1.2 # A popular state management solution
  go_router: ^14.1.0 # Declarative routing package for Flutter

  # Utilities
  logging: ^1.2.0 # For structured logging
  google_fonts: ^6.2.1 # To easily use Google Fonts in your app

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0 # Recommended lints for Flutter projects

flutter:
  uses-material-design: true
  assets:
    - .env # Declare .env file as an asset to be loaded by flutter_dotenv
    - assets/fonts/ # If you plan to add custom fonts manually
    - assets/images/ # For any image assets
```

After modifying `pubspec.yaml`, save the file and run `flutter pub get` in your terminal to download and link the new dependencies.

### 3.2. Step 2: Supabase Backend Setup

This step involves setting up your Supabase project, defining the initial database schema, and configuring Row Level Security (RLS) policies to ensure data integrity and security.

#### 3.2.1. Create Supabase Project

1.  Navigate to the [Supabase website](https://supabase.com).
2.  Sign up or log in to your account.
3.  Click on

the 'New Project' button. 4. Provide a name for your project (e.g., `grace_portal`). 5. Choose a strong database password and a suitable region. 6. Click 'Create new project'.

Once the project is provisioned, navigate to your project's settings. You will need your **Project URL** and **`anon` public key** from the 'API' section. Keep these secure, as they will be used to connect your Flutter application to Supabase.

#### 3.2.2. Database Schema Setup

Navigate to the 'SQL Editor' in your Supabase dashboard. Create a new query and execute the following SQL statements. These commands will create the `branches` and `users` tables, define a custom `user_role` enum, and set up functions and triggers to manage user profiles automatically upon authentication.

```sql
-- Create the branches table first as users will reference it
CREATE TABLE public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    location TEXT,
    address TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create a custom type for user roles for data integrity
CREATE TYPE public.user_role AS ENUM ('admin', 'pastor', 'worker', 'member');

-- Create the users table (references auth.users)
-- This table stores additional profile information for authenticated users.
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    phone_number TEXT,
    location TEXT,
    photo_url TEXT,
    role user_role NOT NULL DEFAULT 'member',
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Function to get the role of the currently authenticated user
-- This is crucial for Row Level Security (RLS) policies.
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS user_role AS $$
DECLARE
    user_role_value user_role;
BEGIN
    SELECT role INTO user_role_value FROM public.users WHERE id = auth.uid();
    RETURN user_role_value;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to automatically insert a new user profile when a user signs up
-- This trigger ensures that every new entry in `auth.users` has a corresponding profile in `public.users`.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, display_name, photo_url)
    VALUES (new.id, new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'photo_url');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function on new user creation in auth schema
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

#### 3.2.3. Row Level Security (RLS) Policies

Row Level Security is a powerful feature in Supabase that allows you to define fine-grained access control policies for your database tables. This ensures that users can only access data they are authorized to see or modify.

1.  In your Supabase dashboard, navigate to 'Authentication' -> 'Policies'.
2.  Enable RLS for the `users` and `branches` tables.
3.  Execute the following SQL statements in the SQL Editor to apply the initial security rules:

```sql
-- Policies for 'branches' table
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- Policy:


Allow all users to read branches
CREATE POLICY "Allow all users to read branches" ON public.branches
FOR SELECT USING (true);

-- Policy: Allow admins full access to branches
CREATE POLICY "Allow admins full access to branches" ON public.branches
FOR ALL USING (get_current_user_role() = 'admin')
WITH CHECK (get_current_user_role() = 'admin');

-- Policies for 'users' table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow users to view their own profile
CREATE POLICY "Allow users to view their own profile" ON public.users
FOR SELECT USING (auth.uid() = id);

-- Policy: Allow admins and pastors to view all profiles
CREATE POLICY "Allow admins and pastors to view all profiles" ON public.users
FOR SELECT USING (get_current_user_role() IN ('admin', 'pastor'));

-- Policy: Allow users to update their own profile
CREATE POLICY "Allow users to update their own profile" ON public.users
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

### 3.3. Step 3: Environment Configuration

Managing sensitive information like API keys and database URLs requires careful handling. `flutter_dotenv` allows us to load these variables from a `.env` file, keeping them out of source control and separate from the main codebase.

#### 3.3.1. Create `.env` file

In the root directory of your Flutter project (the same level as `pubspec.yaml`), create a new file named `.env`. This file will contain your Supabase project URL and `anon` key.

```
SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

**Important Security Note:** Immediately add `.env` to your `.gitignore` file to prevent it from being committed to your version control system. This is a critical security best practice.

```
# .gitignore

# Flutter/Dart specific
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.vscode/

# Environment variables
.env
```

#### 3.3.2. Load Environment Variables

Create a utility class to load and provide these environment variables throughout your application. This centralizes access to configuration and makes it easy to manage.

**File:** `lib/config/app_config.dart`

```dart
// lib/config/app_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A utility class to manage and access application-wide configurations,
/// particularly environment variables loaded from the .env file.
class AppConfig {
  /// Returns the Supabase project URL from environment variables.
  /// Throws an error if the variable is not found, ensuring critical config is present.
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? (throw Exception('SUPABASE_URL not found in .env'));

  /// Returns the Supabase anonymous public key from environment variables.
  /// Throws an error if the variable is not found.
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? (throw Exception('SUPABASE_ANON_KEY not found in .env'));

  /// Loads environment variables from the .env file.
  /// This method must be called before accessing any environment variables.
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
```

### 3.4. Step 4: Core Services & App Initialization

This step focuses on initializing the Supabase client and setting up the fundamental authentication service that will manage user sessions and state throughout the application.

#### 3.4.1. Initialize in `main.dart`

The `main.dart` file is the entry point of your Flutter application. It's where you perform essential setup tasks, such as initializing services and providers, before the UI is rendered. We will also set up a basic `AuthGate` to handle initial routing based on authentication status.

**File:** `lib/main.dart`

```dart
// lib/main.dart

import 'package:grace_portal/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/config/theme.dart'; // Import the theme file

void main() async {
  // Ensure Flutter widgets are initialized before any plugin calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file.
  await AppConfig.load();

  // Initialize Supabase client with the loaded URL and anonymous key.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: true, // Set to false in production
  );

  // Run the main application widget.
  runApp(const GracePortalApp());
}

/// The root widget of the Grace Portal application.
/// It sets up the MultiProvider for state management and defines the app's theme.
class GracePortalApp extends StatelessWidget {
  const GracePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide AuthService to the widget tree. It will manage authentication state.
        ChangeNotifierProvider(create: (ctx) => AuthService()),
        // Other providers will be added here in subsequent sprints.
      ],
      child: MaterialApp(
        title: 'Grace Portal',
        theme: AppTheme.lightTheme, // Apply the light theme
        darkTheme: AppTheme.darkTheme, // Apply the dark theme
        themeMode: ThemeMode.system, // Use system theme preference
        home: const AuthGate(), // The initial screen that checks authentication status
      ),
    );
  }
}

/// A simple widget that acts as an authentication gate.
/// It listens to Supabase authentication changes and displays a placeholder
/// for either the home screen (if logged in) or the login screen (if logged out).
/// This will be replaced by `go_router` in Sprint 1.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          // User is logged in, show a placeholder for the home screen.
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Welcome! You are logged in.", style: TextStyle(fontSize: 20)),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Navigating to Home..."),
                ],
              ),
            ),
          );
        } else {
          // User is not logged in, show a placeholder for the login screen.
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Please log in.", style: TextStyle(fontSize: 20)),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Navigating to Login..."),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
```

#### 3.4.2. Create `AuthService` (Initial Version)

This initial version of `AuthService` will handle the basic sign-up, sign-in, and sign-out operations with Supabase. It extends `ChangeNotifier` so that widgets can listen to changes in authentication status.

**File:** `lib/services/auth_service.dart`

```dart
// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class to manage user authentication (sign-up, sign-in, sign-out)
/// and notify listeners about authentication state changes.
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the currently authenticated user, or null if no user is logged in.
  User? get currentUser => _supabase.auth.currentUser;

  /// Attempts to sign up a new user with email, password, and display name.
  /// Additional user metadata can be passed to be stored in the auth.users table
  /// and subsequently used by the `handle_new_user` trigger in Supabase.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName}, // Passed to Supabase auth.users table
      );
      // No need to call notifyListeners() here, as the onAuthStateChange stream
      // in main.dart (or later, in the enhanced AuthService) will handle state updates.
    } on AuthException catch (e) {
      debugPrint("Sign up error: ${e.message}");
      rethrow; // Re-throw the exception to be caught by the UI for error display.
    }
  }

  /// Attempts to sign in an existing user with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Similar to signUp, state changes are handled by stream listeners.
    } on AuthException catch (e) {
      debugPrint("Sign in error: ${e.message}");
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // State changes are handled by stream listeners.
  }
}
```

### 3.5. Step 5: Basic UI & Theming

Establishing a consistent visual identity early on is crucial for a professional-looking application. This step defines the app's color palette, typography, and overall theme.

#### 3.5.1. Create Theme File

**File:** `lib/config/theme.dart`

```dart
// lib/config/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the application's visual themes (light and dark modes).
/// Uses Google Fonts for typography and a consistent color palette.
class AppTheme {
  // Define custom color constants for easy reuse.
  static const Color primaryBlue = Color(0xFF007AFF); // A vibrant blue, common in iOS apps
  static const Color warmOrange = Color(0xFFFF9500); // A warm, inviting orange
  static const Color forestGreen = Color(0xFF34C759); // A natural green
  static const Color lightGrey = Color(0xFFF2F2F7); // Light background for light theme
  static const Color darkBackground = Color(0xFF1C1C1E); // Dark background for dark theme
  static const Color darkCard = Color(0xFF2C2C2E); // Card background for dark theme

  /// Returns the light theme data for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
        secondary: warmOrange,
        primary: primaryBlue,
      ),
      scaffoldBackgroundColor: lightGrey, // Light grey background for screens
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Apply Google Fonts to the entire text theme.
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1, // Subtle shadow under app bar
        iconTheme: const IconThemeData(color: Colors.black87), // Icons in app bar
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ), // Title text style
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryBlue,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, // Background color for ElevatedButton
          foregroundColor: Colors.white, // Text color for ElevatedButton
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners for buttons
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue, // Text color for TextButton
          textStyle: GoogleFonts.inter(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Background color for input fields
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2), // Highlight on focus
        ),
        hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Returns the dark theme data for the application.
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
        secondary: warmOrange,
        primary: primaryBlue,
        background: darkBackground,
        surface: darkCard,
      ),
      scaffoldBackgroundColor: darkBackground,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryBlue,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: GoogleFonts.inter(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

This completes Sprint 0. The project is now fully configured with a robust backend connection, a foundational authentication service, and a well-defined theme, ready for feature development. We have established a strong base for building a scalable and maintainable application.

---

## 4. Sprint 1: Core User Authentication & Profile

**Goal:** Implement a complete and secure user authentication flow (Registration, Login, Logout) and provide a basic, read-only profile screen. This sprint builds the essential gateway into the application, allowing users to securely access their accounts.

### 4.1. Step 1: Data Model for the User

Before building any user interface components that display user information, it is crucial to define a clear and robust data model. This model will represent the structure of user data as it is retrieved from the Supabase database, ensuring type safety and consistency throughout the application.

#### 4.1.1. Create `UserModel`

This class will represent a user's profile data stored in the `public.users` table. It includes a `fromJson` factory constructor to easily parse data from Supabase query responses. The `@immutable` annotation from `package:flutter/foundation.dart` is used to indicate that instances of this class are unchangeable once created, promoting predictable state management.

**File:** `lib/models/user_model.dart`

```dart
// lib/models/user_model.dart

import 'package:flutter/foundation.dart';

/// Represents the data structure for a user profile in the application.
/// This model corresponds to the `public.users` table in the Supabase database.
/// It is marked as immutable to encourage predictable state management.
@immutable
class UserModel {
  final String id;
  final String? displayName;
  final String email; // Email is fetched from auth.users, not the public table
  final String? phoneNumber;
  final String? location;
  final String? photoUrl;
  final String role;
  final String? branchName; // We'll store the branch name for easy display

  /// Constructor for the UserModel.
  const UserModel({
    required this.id,
    this.displayName,
    required this.email,
    this.phoneNumber,
    this.location,
    this.photoUrl,
    required this.role,
    this.branchName,
  });

  /// Factory constructor to create a UserModel from a JSON map.
  /// This is used to parse the response from the Supabase database.
  ///
  /// [json] is a map, typically from Supabase, representing a row from the `public.users` table.
  /// [email] is passed separately as it comes from the `auth.user` object, not directly from `public.users`.
  factory UserModel.fromJson(Map<String, dynamic> json, String email) {
    // When fetching user data, we often join with the 'branches' table.
    // This logic extracts the branch name if the join was successful.
    final branchData = json['branches'];
    String? branchName;
    if (branchData != null && branchData is Map<String, dynamic>) {
      branchName = branchData['name'];
    }

    return UserModel(
      id: json['id'],
      displayName: json['display_name'],
      email: email, // Use the email from the auth object for consistency
      phoneNumber: json['phone_number'],
      location: json['location'],
      photoUrl: json['photo_url'],
      role: json['role'] ?? 'member', // Default to 'member' if the role is not explicitly set
      branchName: branchName,
    );
  }

  /// A static constant representing an empty or unauthenticated user.
  /// Useful for initializing user state before a user logs in.
  static const empty = UserModel(id: '', email: '', role: 'member');
}
```

### 4.2. Step 2: Enhance `AuthService` to Manage User State

The `AuthService` from Sprint 0 was a basic wrapper around Supabase authentication methods. In Sprint 1, it needs to evolve into a central hub for managing the application's current user state, including their profile data (`UserModel`). It will actively listen to Supabase authentication changes and update the `UserModel` accordingly, notifying any listening widgets.

#### 4.2.1. Update `AuthService`

This enhanced `AuthService` will:

- Hold the `UserModel` of the currently logged-in user.
- Listen to Supabase's `onAuthStateChange` stream to automatically update the user profile when a user logs in or out.
- Fetch the user's detailed profile from the `public.users` table after a successful login.
- Provide a `isLoggedIn` getter for quick authentication status checks.

**File:** `lib/services/auth_service.dart`

```dart
// lib/services/auth_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/models/user_model.dart';

/// A service class responsible for managing user authentication state and user profile data.
/// It listens to Supabase authentication changes and provides the current user's details.
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authStateSubscription;

  // Private field to hold the current user's profile data.
  UserModel _userProfile = UserModel.empty;

  /// Public getter to access the current user's profile.
  UserModel get userProfile => _userProfile;

  /// Checks if a user is currently logged in.
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  /// Constructor for AuthService.
  /// Initializes the authentication state listener.
  AuthService() {
    // Listen to auth state changes immediately when the service is instantiated.
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null) {
        // If a session exists, a user is logged in. Fetch their detailed profile.
        _fetchUserProfile(session.user.id, session.user.email!); // Email is guaranteed to be non-null here
      } else {
        // If no session, the user is logged out. Clear the profile.
        _userProfile = UserModel.empty;
      }
      // Notify all widgets listening to this service about the change.
      notifyListeners();
    });
  }

  /// Disposes of the stream subscription when the service is no longer needed
  /// to prevent memory leaks.
  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  /// Fetches the user's profile from the `public.users` table in Supabase.
  /// This method is called internally when the authentication state changes to logged in.
  Future<void> _fetchUserProfile(String userId, String email) async {
    try {
      // Perform a join with the 'branches' table to get the branch name directly.
      // `.single()` is used because we expect exactly one user profile for a given ID.
      final response = await _supabase
          .from('users')
          .select('*, branches(name)') // Select all user fields and the 'name' from the joined 'branches' table
          .eq('id', userId)
          .single();

      _userProfile = UserModel.fromJson(response, email);
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      // If fetching the profile fails, it indicates a potential data inconsistency.
      // In such cases, it's safer to sign out the user to prevent them from being in a broken state.
      await signOut();
    } finally {
      // Ensure listeners are notified even if an error occurs during fetching,
      // so UI can react (e.g., show a loading indicator or error message).
      notifyListeners();
    }
  }

  /// Attempts to sign up a new user.
  /// The `displayName`, `phoneNumber`, and `location` are passed as `data`
  /// to Supabase's `signUp` method. This data is then accessible by the
  /// `handle_new_user` trigger in Supabase to populate the `public.users` table.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    String? location,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'phone_number': phoneNumber,
          'location': location,
        }, // Metadata for the new user
      );
      // The `onAuthStateChange` stream listener in the constructor will automatically
      // detect the new session and trigger `_fetchUserProfile`.
    } on AuthException catch (e) {
      debugPrint("Sign up error: ${e.message}");
      rethrow; // Re-throw the exception so the UI can display an appropriate error message.
    }
  }

  /// Attempts to sign in an existing user.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // The `onAuthStateChange` stream listener handles subsequent profile fetching.
    } on AuthException catch (e) {
      debugPrint("Sign in error: ${e.message}");
      rethrow;
    }
  }

  /// Signs out the current user from Supabase.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // The `onAuthStateChange` stream listener will detect the logout and clear the user profile.
  }
}
```

**Best Practice Note:** By centralizing user profile management within `AuthService` and leveraging Supabase's `onAuthStateChange` stream, we ensure that the application's user state is always synchronized with the backend. This pattern reduces boilerplate code in UI widgets and promotes a single source of truth for user data.

### 4.3. Step 3: Create Reusable UI Components (Widgets)

To maintain a consistent user interface, reduce code duplication, and improve maintainability, it's a best practice to create reusable UI components (widgets). These widgets encapsulate common UI patterns and can be easily customized through their parameters.

#### 4.3.1. `CustomTextField`

A standardized text input field with common styling and validation capabilities.

**File:** `lib/widgets/custom_text_field.dart`

```dart
// lib/widgets/custom_text_field.dart

import 'package:flutter/material.dart';

/// A reusable custom text input field with predefined styling and optional validation.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator; // Validator function for form validation
  final Widget? suffixIcon;

  /// Constructor for CustomTextField.
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      // Obscure text for password fields, toggled by `isPassword`.
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator, // Assign the provided validator function
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon, // Optional suffix icon (e.g., for password visibility toggle)
        hintText: hintText,
        // Styling for the input field border.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
          borderSide: BorderSide.none, // No visible border by default, theme handles it
        ),
        filled: true, // Enable background fill
        fillColor: Theme.of(context).inputDecorationTheme.fillColor, // Use theme's fill color
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Padding inside the field
      ),
    );
  }
}
```

#### 4.3.2. `CustomButton`

A standardized button widget with consistent styling, loading state, and disabled state.

**File:** `lib/widgets/custom_button.dart`

```dart
// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';

/// A reusable custom button with predefined styling, loading indicator, and disabled state.
class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isLoading; // Indicates if the button should show a loading spinner

  /// Constructor for CustomButton.
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Button takes full available width
      height: 50, // Fixed height for consistency
      child: ElevatedButton(
        // If `isLoading` is true, the button is disabled and `onPressed` is null.
        onPressed: isLoading ? null : onPressed,
        style: Theme.of(context).elevatedButtonTheme.style, // Use theme's ElevatedButton style
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white) // Show spinner when loading
            : Text(
                text,
                style: Theme.of(context).elevatedButtonTheme.style?.textStyle?.copyWith(color: Colors.white), // Use theme's text style
              ),
      ),
    );
  }
}
```

### 4.4. Step 4: Build the Authentication Screens

With the reusable UI components in place, we can now construct the full authentication screens for user login and registration. These screens will interact with the `AuthService` to perform authentication operations.

#### 4.4.1. `LoginScreen`

This screen provides the interface for existing users to log into the application. It uses `CustomTextField` for input and `CustomButton` for submission, along with form validation.

**File:** `lib/screens/auth/login_screen.dart`

```dart
// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart'; // Import go_router for navigation

/// A screen for user login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  bool _isLoading = false; // State to manage loading indicator on button
  bool _obscurePassword = true; // State to toggle password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process.
  /// Validates the form, calls the AuthService, and handles success/failure.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    setState(() => _isLoading = true); // Show loading indicator
    try {
      await context.read<AuthService>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      // On successful login, the `AuthService` will notify its listeners,
      // and `go_router` (configured in main.dart) will automatically redirect to the home screen.
    } catch (e) {
      // Display error message to the user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loading indicator
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), // App bar with title
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // Padding around the content
        child: Form(
          key: _formKey, // Assign the form key for validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Spacing
              Text('Welcome Back!', style: Theme.of(context).textTheme.headlineMedium), // Title text
              const SizedBox(height: 40),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                isPassword: _obscurePassword,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 40),
              CustomButton(
                onPressed: _login,
                text: 'Login',
                isLoading: _isLoading,
              ),
              TextButton(
                onPressed: () {
                  context.go('/register'); // Navigate to the registration screen using go_router
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 4.4.2. `RegisterScreen`

This screen allows new users to create an account. It includes fields for email, password, display name, phone number, and location, and performs client-side validation before calling the `AuthService`.

**File:** `lib/screens/auth/register_screen.dart`

```dart
// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';

/// A screen for new user registration.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Handles the registration process.
  /// Validates the form, calls the AuthService, and handles success/failure.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            displayName: _displayNameController.text.trim(),
            phoneNumber: _phoneNumberController.text.trim(),
            location: _locationController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please check your email for verification.')),
        );
        context.go('/login'); // Redirect to login after successful registration
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')), // App bar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text('Create Your Account', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                isPassword: _obscurePassword,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                isPassword: _obscureConfirmPassword,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please confirm your password' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _displayNameController,
                hintText: 'Display Name',
                prefixIcon: Icons.person,
                validator: (val) => val == null || val.isEmpty ? 'Please enter your display name' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _phoneNumberController,
                hintText: 'Phone Number (Optional)',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _locationController,
                hintText: 'Location (Optional)',
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 40),
              CustomButton(
                onPressed: _register,
                text: 'Register',
                isLoading: _isLoading,
              ),
              TextButton(
                onPressed: () {
                  context.go('/login'); // Navigate back to login
                },
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4.5. Step 5: Implement Routing and the `AuthGate`

Effective navigation is crucial for a smooth user experience. `go_router` is a declarative routing package that integrates well with `ChangeNotifier` (like our `AuthService`) to automatically redirect users based on authentication state. The `AuthGate` concept is now fully managed by `go_router`'s `redirect` functionality.

#### 4.5.1. Setup `go_router`

This `AppRouter` class defines all the routes in the application and includes a `redirect` function that checks the authentication status using `AuthService`. This ensures that unauthenticated users are always redirected to the login screen, and authenticated users are sent to the home screen if they try to access authentication-related routes.

**File:** `lib/config/router.dart`

```dart
// lib/config/router.dart

import 'package:grace_portal/screens/auth/login_screen.dart';
import 'package:grace_portal/screens/auth/register_screen.dart';
import 'package:grace_portal/screens/home_screen.dart'; // Placeholder for now, will be built in Sprint 2
import 'package:grace_portal/screens/profile/profile_screen.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Manages all application routes and handles authentication-based redirection.
class AppRouter {
  final AuthService authService;

  /// Constructor requiring an instance of AuthService to listen for auth state changes.
  AppRouter({required this.authService});

  /// The GoRouter instance configured with all application routes and redirection logic.
  late final GoRouter router = GoRouter(
    // `refreshListenable` makes GoRouter re-evaluate its routes whenever AuthService notifies listeners.
    refreshListenable: authService,
    // The initial route when the app starts.
    initialLocation: '/login',
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Main Application Routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(), // This will be the main dashboard/home screen
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Add more routes here as features are developed (e.g., /tasks, /meetings)
    ],
    /// The redirect function is called before any route is built.
    /// It determines if the user should be redirected based on their authentication status.
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authService.isLoggedIn;
      // Check if the current location is one of the authentication-related screens.
      final bool isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Scenario 1: User is NOT logged in and trying to access a protected route.
      // Redirect them to the login screen.
      if (!loggedIn && !isLoggingIn) {
        return '/login';
      }

      // Scenario 2: User IS logged in and trying to access an authentication screen.
      // Redirect them to the home screen.
      if (loggedIn && isLoggingIn) {
        return '/home';
      }

      // Scenario 3: No redirection needed. Proceed to the requested route.
      return null;
    },
    // Optional: Error handling for routes not found.
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
```

#### 4.5.2. Integrate Router into `main.dart`

Now, modify your `main.dart` file to use the `AppRouter` and `MaterialApp.router`. This setup replaces the simple `AuthGate` from Sprint 0 with a more sophisticated and scalable routing solution.

**File:** `lib/main.dart` (Updated)

```dart
// lib/main.dart

import 'package:grace_portal/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/config/theme.dart';
import 'package:grace_portal/config/router.dart'; // Import the new router

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: true,
  );

  runApp(const GracePortalApp());
}

/// The root widget of the Grace Portal application.
/// It sets up the MultiProvider for state management and integrates `go_router`.
class GracePortalApp extends StatelessWidget {
  const GracePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthService is provided here, and its changes will trigger route refreshes.
        ChangeNotifierProvider(create: (ctx) => AuthService()),
        // Other providers will be added here in subsequent sprints.
      ],
      child: Builder(
        // Builder is used to get a context that has access to the `AuthService` provider.
        builder: (context) {
          // Retrieve the AuthService instance.
          final authService = Provider.of<AuthService>(context, listen: false);
          // Initialize the AppRouter with the AuthService.
          final router = AppRouter(authService: authService).router;

          return MaterialApp.router(
            title: 'Grace Portal',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router, // Assign the configured GoRouter instance
          );
        }
      ),
    );
  }
}
```

### 4.6. Step 6: Build the Profile Screen

The profile screen provides a read-only view of the currently logged-in user's information. It demonstrates how to consume the `UserModel` from the `AuthService` and display it using well-structured UI components.

#### 4.6.1. `ProfileScreen`

This screen uses a `Consumer` widget from the `provider` package to reactively display the `UserModel` data. It also includes a logout button that calls the `AuthService`'s `signOut` method.

**File:** `lib/screens/profile/profile_screen.dart`

```dart
// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/services/auth_service.dart';

/// A screen displaying the current user's profile information.
/// It is read-only in this sprint.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer listens to AuthService and rebuilds when `userProfile` changes.
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final UserModel user = authService.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();
                  // GoRouter will automatically redirect to the login screen after logout.
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          body: user.id.isEmpty // Check if user data is loaded (empty means not loaded or logged out)
              ? const Center(child: CircularProgressIndicator()) // Show loading indicator
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(context, user), // Header with avatar and name
                    const SizedBox(height: 24),
                    _buildInfoCard(user), // Card displaying detailed info
                  ],
                ),
        );
      },
    );
  }

  /// Builds the top section of the profile screen with avatar and display name.
  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          // Display user's photo if available, otherwise a default person icon.
          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onPrimary) // Icon for no photo
              : null,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), // Background for avatar
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName ?? 'N/A', // Display name, or 'N/A' if null
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  /// Builds a card containing various pieces of user information.
  Widget _buildInfoCard(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _InfoRow(icon: Icons.badge, title: 'Role', value: user.role.toUpperCase()), // Display role in uppercase
            _InfoRow(icon: Icons.church, title: 'Branch', value: user.branchName ?? 'Not Assigned'),
            _InfoRow(icon: Icons.phone, title: 'Phone', value: user.phoneNumber ?? 'N/A'),
            _InfoRow(icon: Icons.location_on, title: 'Location', value: user.location ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}

/// A private helper widget to display a single row of information (icon, title, value).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor), // Icon with primary color
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
```

This concludes Sprint 1. The application now features a complete, secure, and stateful user authentication system, along with a basic profile viewing capability. The architecture emphasizes separation of concerns, reusable components, and reactive state management, laying a solid foundation for future development.

---

## 5. Sprint 2: Foundational App Structure & Branch Management (Admin)

**Goal:** Establish the main application navigation structure (bottom navigation bar and drawer) and provide administrators with the tools to manage church branches. This sprint builds the skeleton of the app that will house all future features and introduces the first role-based functionality.

### 5.1. Step 1: Data Models for Branch and Permissions

We need to define the data structure for a church branch and create a service to manage user permissions based on their roles.

#### 5.1.1. `ChurchBranchModel`

This model represents a single church branch, corresponding to the `public.branches` table in Supabase.

**File:** `lib/models/branch_model.dart`

```dart
// lib/models/branch_model.dart

import 'package:flutter/foundation.dart';

/// Represents a church branch.
@immutable
class ChurchBranchModel {
  final String id;
  final String name;
  final String? location;
  final String? address;
  final String? description;

  const ChurchBranchModel({
    required this.id,
    required this.name,
    this.location,
    this.address,
    this.description,
  });

  factory ChurchBranchModel.fromJson(Map<String, dynamic> json) {
    return ChurchBranchModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      address: json['address'],
      description: json['description'],
    );
  }
}
```

#### 5.1.2. `PermissionsService`

This service will provide a centralized way to check user capabilities based on their role. This is more scalable than checking roles directly in the UI, as permissions can be easily updated in one place.

**File:** `lib/services/permissions_service.dart`

```dart
// lib/services/permissions_service.dart

import 'package:grace_portal/models/user_model.dart';

/// A service to manage user permissions based on their role.
class PermissionsService {
  final UserModel _user;

  PermissionsService(this._user);

  /// Checks if the user has admin-level capabilities.
  bool get canManageBranches => _user.role == 'admin';

  /// Checks if the user can create or assign tasks.
  bool get canManageTasks => ['admin', 'pastor', 'worker'].contains(_user.role);

  /// Checks if the user can schedule meetings.
  bool get canManageMeetings => ['admin', 'pastor'].contains(_user.role);
}
```

### 5.2. Step 2: Main Navigation Structure

We will build the main navigation screen which will contain a bottom navigation bar to switch between the primary sections of the app (Home, Tasks, Meetings, Prayer) and a drawer for less frequently accessed items like Profile and Settings.

#### 5.2.1. `MainNavigationScreen`

This stateful widget will manage the currently selected tab and display the corresponding screen.

**File:** `lib/screens/main_navigation_screen.dart`

```dart
// lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:grace_portal/screens/home_screen.dart';
import 'package:grace_portal/screens/tasks/tasks_screen.dart'; // To be created
import 'package:grace_portal/screens/meetings/meetings_screen.dart'; // To be created
import 'package:grace_portal/screens/prayer/prayer_screen.dart'; // To be created
import 'package:grace_portal/widgets/custom_drawer.dart'; // To be created

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // List of screens to be displayed for each tab.
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TasksScreen(), // Placeholder for now
    MeetingsScreen(), // Placeholder for now
    PrayerScreen(), // Placeholder for now
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grace Portal'),
        elevation: 1,
      ),
      drawer: const CustomDrawer(), // Add the custom drawer
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Meetings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.church),
            label: 'Prayer',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      ),
    );
  }
}
```

#### 5.2.2. Create Placeholder Screens

Create simple placeholder widgets for the screens that are not yet built.

**Example File:** `lib/screens/tasks/tasks_screen.dart`

```dart
// lib/screens/tasks/tasks_screen.dart

import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tasks Screen - Coming Soon!', style: TextStyle(fontSize: 20)),
    );
  }
}
```

_(Create similar placeholders for `MeetingsScreen` and `PrayerScreen`)_

#### 5.2.3. `CustomDrawer` Widget

This widget will contain navigation links to the Profile screen and, importantly, a conditional link to the Branch Management screen for admins.

**File:** `lib/widgets/custom_drawer.dart`

```dart
// lib/widgets/custom_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/permissions_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final permissions = PermissionsService(authService.userProfile);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(authService.userProfile.displayName ?? 'User'),
            accountEmail: Text(authService.userProfile.email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: authService.userProfile.photoUrl != null
                  ? NetworkImage(authService.userProfile.photoUrl!)
                  : null,
              child: authService.userProfile.photoUrl == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              context.go('/profile');
            },
          ),
          // Conditionally show the Branch Management link
          if (permissions.canManageBranches)
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Manage Branches'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                context.go('/manage-branches');
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authService.signOut();
              // The router will handle redirection automatically
            },
          ),
        ],
      ),
    );
  }
}
```

### 5.3. Step 3: Branch Management (Admin-Only)

This section involves creating the UI and logic for administrators to create, view, and delete church branches.

#### 5.3.1. `BranchesProvider`

This provider will manage the state of the branches, fetching them from Supabase and handling create/delete operations.

**File:** `lib/providers/branches_provider.dart`

```dart
// lib/providers/branches_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/models/branch_model.dart';

class BranchesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<ChurchBranchModel> _branches = [];
  bool _isLoading = false;

  List<ChurchBranchModel> get branches => _branches;
  bool get isLoading => _isLoading;

  BranchesProvider() {
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.from('branches').select();
      _branches = (response as List)
          .map((json) => ChurchBranchModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetching branches: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBranch(String name, String? location, String? address) async {
    try {
      await _supabase.from('branches').insert({
        'name': name,
        'location': location,
        'address': address,
      });
      await fetchBranches(); // Refresh the list after adding
    } catch (e) {
      debugPrint("Error adding branch: $e");
      rethrow;
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await _supabase.from('branches').delete().eq('id', id);
      await fetchBranches(); // Refresh the list after deleting
    } catch (e) {
      debugPrint("Error deleting branch: $e");
      rethrow;
    }
  }
}
```

#### 5.3.2. `BranchManagementScreen`

This screen will display a list of all branches and provide options to add or delete them.

**File:** `lib/screens/admin/branch_management_screen.dart`

```dart
// lib/screens/admin/branch_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:grace_portal/widgets/custom_button.dart';

class BranchManagementScreen extends StatelessWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BranchesProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Branches')),
        body: Consumer<BranchesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              itemCount: provider.branches.length,
              itemBuilder: (context, index) {
                final branch = provider.branches[index];
                return ListTile(
                  title: Text(branch.name),
                  subtitle: Text(branch.location ?? 'No location'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, provider, branch.id),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddBranchDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Branch'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location (e.g., City)'),
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Full Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await context.read<BranchesProvider>().addBranch(
                      nameController.text,
                      locationController.text,
                      addressController.text,
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BranchesProvider provider, String branchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This will permanently delete the branch.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await provider.deleteBranch(branchId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

### 5.4. Step 4: Update Routing and App Structure

Finally, we need to integrate the new screens and providers into the main application structure.

#### 5.4.1. Update `AppRouter`

Add the new routes for the `MainNavigationScreen` (which will now be the primary home route) and the `BranchManagementScreen`.

**File:** `lib/config/router.dart` (Additions)

```dart
// In AppRouter class
// ... (existing routes)
GoRoute(
  path: '/main',
  builder: (context, state) => const MainNavigationScreen(),
),
GoRoute(
  path: '/manage-branches',
  builder: (context, state) => const BranchManagementScreen(),
  redirect: (context, state) {
    // Add a route-level guard for extra security
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissions = PermissionsService(authService.userProfile);
    if (!permissions.canManageBranches) return '/main'; // Redirect if not admin
    return null;
  },
),

// In the main redirect logic:
// Change the redirect for logged-in users to '/main'
if (loggedIn && isLoggingIn) {
  return '/main';
}
```

#### 5.4.2. Update `main.dart`

Add the `BranchesProvider` to the `MultiProvider` list.

**File:** `lib/main.dart` (Addition)

```dart
// In GracePortalApp widget, MultiProvider providers list:
ChangeNotifierProvider(create: (ctx) => BranchesProvider()),
```

This concludes Sprint 2. The application now has a scalable navigation structure and the first piece of role-based functionality, allowing administrators to manage church branches. The use of providers and services keeps the architecture clean and maintainable.

---

## 6. Sprint 3: Comprehensive Task Management

**Goal:** Deliver a fully functional task management system for all relevant user roles (Admin, Pastor, Worker). This includes creating, assigning, viewing, and updating the status of tasks.

### 6.1. Step 1: Data Models for Tasks and Comments

We need to define the data structures for tasks and their associated comments.

#### 6.1.1. `TaskModel`

This model represents a single task, corresponding to a new `public.tasks` table in Supabase.

**SQL for `tasks` table:**

```sql
CREATE TYPE public.task_status AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'cancelled'
);

CREATE TYPE public.task_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);

CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
    assigned_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    due_date TIMESTAMPTZ,
    status task_status NOT NULL DEFAULT 'pending',
    priority task_priority NOT NULL DEFAULT 'medium',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for tasks table
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Admins and Pastors can see all tasks
CREATE POLICY "Admins and Pastors can view all tasks" ON public.tasks
FOR SELECT USING (get_current_user_role() IN ('admin', 'pastor'));

-- Workers and Members can only see tasks assigned to them or their branch
CREATE POLICY "Workers and Members can view their own tasks" ON public.tasks
FOR SELECT USING (
    auth.uid() = assigned_to OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND branch_id = tasks.branch_id)
);

-- Only Admins, Pastors, and Workers can create tasks
CREATE POLICY "Admins, Pastors, Workers can create tasks" ON public.tasks
FOR INSERT WITH CHECK (get_current_user_role() IN ('admin', 'pastor', 'worker'));

-- Only Admins, Pastors, and assigned_to can update tasks
CREATE POLICY "Admins, Pastors, and assigned_to can update tasks" ON public.tasks
FOR UPDATE USING (get_current_user_role() IN ('admin', 'pastor') OR auth.uid() = assigned_to)
WITH CHECK (get_current_user_role() IN ('admin', 'pastor') OR auth.uid() = assigned_to);

-- Only Admins and Pastors can delete tasks
CREATE POLICY "Admins and Pastors can delete tasks" ON public.tasks
FOR DELETE USING (get_current_user_role() IN ('admin', 'pastor'));
```

**File:** `lib/models/task_model.dart`

```dart
// lib/models/task_model.dart

import 'package:flutter/foundation.dart';

enum TaskStatus { pending, inProgress, completed, cancelled }
enum TaskPriority { low, medium, high, urgent }

@immutable
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String? assignedToId;
  final String? assignedToName; // Joined from users table
  final String? assignedById;
  final String? assignedByName; // Joined from users table
  final String? branchId;
  final String? branchName; // Joined from branches table
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.assignedToId,
    this.assignedToName,
    this.assignedById,
    this.assignedByName,
    this.branchId,
    this.branchName,
    this.dueDate,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final assignedToUser = json['assigned_to_user'];
    final assignedByUser = json['assigned_by_user'];
    final branch = json['branches'];

    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignedToId: json['assigned_to'],
      assignedToName: assignedToUser != null ? assignedToUser['display_name'] : null,
      assignedById: json['assigned_by'],
      assignedByName: assignedByUser != null ? assignedByUser['display_name'] : null,
      branchId: json['branch_id'],
      branchName: branch != null ? branch['name'] : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      status: TaskStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => TaskStatus.pending),
      priority: TaskPriority.values.firstWhere(
          (e) => e.toString().split('.').last == json['priority'],
          orElse: () => TaskPriority.medium),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedToId,
      'assigned_by': assignedById,
      'branch_id': branchId,
      'due_date': dueDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedToId,
    String? assignedToName,
    String? assignedById,
    String? assignedByName,
    String? branchId,
    String? branchName,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedById: assignedById ?? this.assignedById,
      assignedByName: assignedByName ?? this.assignedByName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

#### 6.1.2. `CommentModel`

This model represents a comment on a task, corresponding to a new `public.comments` table in Supabase.

**SQL for `comments` table:**

```sql
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for comments table
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read comments
CREATE POLICY "All authenticated users can read comments" ON public.comments
FOR SELECT USING (auth.uid() IS NOT NULL);

-- Authenticated users can create comments
CREATE POLICY "Authenticated users can create comments" ON public.comments
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update their own comments" ON public.comments
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments" ON public.comments
FOR DELETE USING (auth.uid() = user_id);
```

**File:** `lib/models/comment_model.dart`

```dart
// lib/models/comment_model.dart

import 'package:flutter/foundation.dart';

@immutable
class CommentModel {
  final String id;
  final String taskId;
  final String userId;
  final String userName; // Joined from users table
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    return CommentModel(
      id: json['id'],
      taskId: json['task_id'],
      userId: json['user_id'],
      userName: user != null ? user['display_name'] : 'Unknown User',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

### 6.2. Step 2: `TasksProvider` and `UsersProvider`

We need providers to manage the state of tasks and to fetch a list of users for task assignment.

#### 6.2.1. `TasksProvider`

This provider will handle all CRUD operations for tasks and manage the list of tasks displayed in the app.

**File:** `lib/providers/tasks_provider.dart`

```dart
// lib/providers/tasks_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/models/task_model.dart';
import 'package:grace_portal/services/auth_service.dart';

class TasksProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TasksProvider(this._authService) {
    _authService.addListener(_onAuthServiceChange);
    _onAuthServiceChange(); // Initial fetch based on current auth state
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthServiceChange);
    super.dispose();
  }

  void _onAuthServiceChange() {
    if (_authService.isLoggedIn) {
      fetchTasks();
    } else {
      _tasks = [];
      notifyListeners();
    }
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Select task details, and join user and branch display names
      final response = await _supabase
          .from('tasks')
          .select('*, assigned_to_user:users!tasks_assigned_to_fkey(display_name), assigned_by_user:users!tasks_assigned_by_fkey(display_name), branches(name)')
          .order('due_date', ascending: true);

      _tasks = (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    String? description,
    String? assignedToId,
    String? branchId,
    DateTime? dueDate,
    TaskPriority? priority,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in to create task.');
      }

      await _supabase.from('tasks').insert({
        'title': title,
        'description': description,
        'assigned_to': assignedToId,
        'assigned_by': currentUserId,
        'branch_id': branchId,
        'due_date': dueDate?.toIso8601String(),
        'priority': priority?.toString().split('.').last ?? 'medium',
      });
      await fetchTasks();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      await _supabase.from('tasks').update({
        'status': newStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
      await fetchTasks();
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      await fetchTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }
}
```

#### 6.2.2. `UsersProvider`

This provider will fetch a list of all users, primarily for task assignment dropdowns. Note that due to RLS, users will only see what they are allowed to see.

**File:** `lib/providers/users_provider.dart`

```dart
// lib/providers/users_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/models/user_model.dart';

class UsersProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  UsersProvider() {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Select users, joining branch name for display if needed
      final response = await _supabase
          .from('users')
          .select('id, display_name, email, role, branches(name)')
          .order('display_name', ascending: true);

      _users = (response as List)
          .map((json) => UserModel.fromJson(json, json['email'] ?? '')) // Email might not be directly in public.users
          .toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 6.3. Step 3: UI for Task Management

We will build the screens for viewing, creating, and updating tasks.

#### 6.3.1. `TasksScreen`

This screen will display a list of tasks, with filtering and sorting options.

**File:** `lib/screens/tasks/tasks_screen.dart`

```dart
// lib/screens/tasks/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/providers/tasks_provider.dart';
import 'package:grace_portal/models/task_model.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/permissions_service.dart';
import 'package:grace_portal/widgets/task_card.dart'; // To be created

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    // Fetch tasks when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final permissions = PermissionsService(authService.userProfile);
    final tasksProvider = context.watch<TasksProvider>();

    // Filter tasks based on selected status
    final filteredTasks = tasksProvider.tasks.where((task) {
      if (_selectedStatusFilter == null) return true;
      return task.status == _selectedStatusFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          // Filter dropdown
          PopupMenuButton<TaskStatus?>(
            onSelected: (TaskStatus? result) {
              setState(() {
                _selectedStatusFilter = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<TaskStatus?>>[
              const PopupMenuItem<TaskStatus?>(
                value: null,
                child: Text('All Tasks'),
              ),
              ...TaskStatus.values.map((status) => PopupMenuItem<TaskStatus>(
                value: status,
                child: Text(status.toString().split('.').last.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: tasksProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTasks.isEmpty
              ? const Center(child: Text('No tasks found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => context.go('/task-details/${task.id}'),
                    );
                  },
                ),
      floatingActionButton: permissions.canManageTasks
          ? FloatingActionButton(
              onPressed: () => context.go('/create-task'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
```

#### 6.3.2. `TaskCard` Widget

A reusable widget to display a summary of a single task.

**File:** `lib/widgets/task_card.dart`

```dart
// lib/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:grace_portal/models/task_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending: return Colors.orange;
      case TaskStatus.inProgress: return Colors.blue;
      case TaskStatus.completed: return Colors.green;
      case TaskStatus.cancelled: return Colors.red;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return Colors.grey;
      case TaskPriority.medium: return Colors.blue;
      case TaskPriority.high: return Colors.orange;
      case TaskPriority.urgent: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: _getStatusColor(task.status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description ?? 'No description provided.',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Assigned to: ${task.assignedToName ?? 'N/A'}'),
                  const Spacer(),
                  Icon(Icons.flag, size: 18, color: _getPriorityColor(task.priority)),
                  const SizedBox(width: 4),
                  Text(task.priority.toString().split('.').last.toUpperCase()),
                ],
              ),
              const SizedBox(height: 8),
              if (task.dueDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 6.3.3. `CreateTaskScreen`

This screen allows authorized users to create new tasks.

**File:** `lib/screens/tasks/create_task_screen.dart`

```dart
// lib/screens/tasks/create_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/providers/tasks_provider.dart';
import 'package:grace_portal/providers/users_provider.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';
import 'package:grace_portal/models/task_model.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/models/branch_model.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  UserModel? _selectedAssignee;
  ChurchBranchModel? _selectedBranch;
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<TasksProvider>().addTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            assignedToId: _selectedAssignee?.id,
            branchId: _selectedBranch?.id,
            dueDate: _selectedDueDate,
            priority: _selectedPriority,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
        context.pop(); // Go back to tasks list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();
    final branchesProvider = context.watch<BranchesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Task')),
      body: usersProvider.isLoading || branchesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      hintText: 'Task Title',
                      validator: (val) => val!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: 'Description (Optional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Assignee Dropdown
                    DropdownButtonFormField<UserModel>(
                      decoration: const InputDecoration(
                        labelText: 'Assign Task To (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedAssignee,
                      onChanged: (UserModel? newValue) {
                        setState(() {
                          _selectedAssignee = newValue;
                        });
                      },
                      items: usersProvider.users.map<DropdownMenuItem<UserModel>>((UserModel user) {
                        return DropdownMenuItem<UserModel>(
                          value: user,
                          child: Text(user.displayName ?? user.email),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Branch Dropdown
                    DropdownButtonFormField<ChurchBranchModel>(
                      decoration: const InputDecoration(
                        labelText: 'Assign to Branch (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedBranch,
                      onChanged: (ChurchBranchModel? newValue) {
                        setState(() {
                          _selectedBranch = newValue;
                        });
                      },
                      items: branchesProvider.branches.map<DropdownMenuItem<ChurchBranchModel>>((ChurchBranchModel branch) {
                        return DropdownMenuItem<ChurchBranchModel>(
                          value: branch,
                          child: Text(branch.name),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Due Date Picker
                    ListTile(
                      title: Text(_selectedDueDate == null
                          ? 'Select Due Date (Optional)'
                          : 'Due Date: ${DateFormat('MMM dd, yyyy').format(_selectedDueDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDueDate(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    const SizedBox(height: 16),
                    // Priority Dropdown
                    DropdownButtonFormField<TaskPriority>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPriority,
                      onChanged: (TaskPriority? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                      items: TaskPriority.values.map<DropdownMenuItem<TaskPriority>>((TaskPriority priority) {
                        return DropdownMenuItem<TaskPriority>(
                          value: priority,
                          child: Text(priority.toString().split('.').last.toUpperCase()),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      onPressed: _createTask,
                      text: 'Create Task',
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
```

#### 6.3.4. `TaskDetailsScreen`

This screen will display the full details of a task and allow for status updates.

**File:** `lib/screens/tasks/task_details_screen.dart`

```dart
// lib/screens/tasks/task_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/providers/tasks_provider.dart';
import 'package:grace_portal/models/task_model.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/permissions_service.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  TaskModel? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    setState(() => _isLoading = true);
    try {
      // Re-fetch specific task to ensure latest data
      final response = await Supabase.instance.client
          .from('tasks')
          .select('*, assigned_to_user:users!tasks_assigned_to_fkey(display_name), assigned_by_user:users!tasks_assigned_by_fkey(display_name), branches(name)')
          .eq('id', widget.taskId)
          .single();
      setState(() {
        _task = TaskModel.fromJson(response);
      });
    } catch (e) {
      debugPrint('Error fetching task details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load task details: ${e.toString()}')),
        );
        context.pop(); // Go back if task not found or error
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    if (_task == null) return;
    setState(() => _isLoading = true);
    try {
      await context.read<TasksProvider>().updateTaskStatus(_task!.id, newStatus);
      await _fetchTaskDetails(); // Refresh details after update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task status updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask() async {
    if (_task == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await context.read<TasksProvider>().deleteTask(_task!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully!')),
          );
          context.pop(); // Go back to tasks list after deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete task: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final permissions = PermissionsService(authService.userProfile);

    if (_isLoading || _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_task!.title),
        actions: [
          if (permissions.canManageTasks || authService.currentUser?.id == _task!.assignedToId)
            PopupMenuButton<TaskStatus>(
              onSelected: _updateTaskStatus,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<TaskStatus>>[
                ...TaskStatus.values.map((status) => PopupMenuItem<TaskStatus>(
                  value: status,
                  child: Text('Mark as ${status.toString().split('.').last.replaceAll('_', ' ').toUpperCase()}'),
                )).toList(),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          if (permissions.canManageTasks)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _task!.description ?? 'No description provided.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.info_outline, 'Status', _task!.status.toString().split('.').last.replaceAll('_', ' ').toUpperCase()),
            _buildDetailRow(Icons.flag, 'Priority', _task!.priority.toString().split('.').last.toUpperCase()),
            if (_task!.assignedToName != null)
              _buildDetailRow(Icons.person_outline, 'Assigned To', _task!.assignedToName!),
            if (_task!.assignedByName != null)
              _buildDetailRow(Icons.person_add_alt_1, 'Assigned By', _task!.assignedByName!),
            if (_task!.branchName != null)
              _buildDetailRow(Icons.church, 'Branch', _task!.branchName!),
            if (_task!.dueDate != null)
              _buildDetailRow(Icons.calendar_today, 'Due Date', DateFormat('MMM dd, yyyy').format(_task!.dueDate!)),
            _buildDetailRow(Icons.access_time, 'Created At', DateFormat('MMM dd, yyyy HH:mm').format(_task!.createdAt)),
            _buildDetailRow(Icons.update, 'Last Updated', DateFormat('MMM dd, yyyy HH:mm').format(_task!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
```

### 6.4. Step 4: Update Routing and Providers

Integrate the new task management screens and providers into the application.

#### 6.4.1. Update `AppRouter`

Add the new routes for task creation and task details.

**File:** `lib/config/router.dart` (Additions)

```dart
// In AppRouter class, within the routes list:
GoRoute(
  path: '/create-task',
  builder: (context, state) => const CreateTaskScreen(),
  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissions = PermissionsService(authService.userProfile);
    if (!permissions.canManageTasks) return '/main'; // Only authorized roles can create tasks
    return null;
  },
),
GoRoute(
  path: '/task-details/:taskId',
  builder: (context, state) => TaskDetailsScreen(taskId: state.pathParameters['taskId']!),
),
```

#### 6.4.2. Update `main.dart`

Add `TasksProvider` and `UsersProvider` to the `MultiProvider` list. Note that `TasksProvider` depends on `AuthService`, so ensure `AuthService` is listed before it.

**File:** `lib/main.dart` (Additions)

```dart
// In GracePortalApp widget, MultiProvider providers list:
ChangeNotifierProvider(create: (ctx) => AuthService()), // Must be before TasksProvider
ChangeNotifierProvider(create: (ctx) => BranchesProvider()),
ChangeNotifierProvider(create: (ctx) => UsersProvider()), // New
ChangeNotifierProvider(create: (ctx) => TasksProvider(ctx.read<AuthService>())), // New, depends on AuthService
```

#### 6.4.3. Update `PermissionsService`

Ensure `canManageTasks` is correctly defined.

**File:** `lib/services/permissions_service.dart` (Confirmation)

```dart
// lib/services/permissions_service.dart

// ... (existing code)

class PermissionsService {
  final UserModel _user;

  PermissionsService(this._user);

  bool get canManageBranches => _user.role == 'admin';
  bool get canManageTasks => ['admin', 'pastor', 'worker'].contains(_user.role);
  bool get canManageMeetings => ['admin', 'pastor'].contains(_user.role);
}
```

This concludes Sprint 3. The application now has a robust task management system, including data models, providers for state management, and UI screens for creation, viewing, and status updates. Role-based access control ensures that only authorized users can perform specific actions.

---

## 7. Sprint 4: Push Notifications & User Engagement

**Goal:** Integrate a robust push notification system to keep users informed about important updates, especially regarding task assignments and other relevant events. This enhances user engagement and ensures timely communication.

### 7.1. Step 1: OneSignal Integration

OneSignal is a popular push notification service that provides SDKs for various platforms, including Flutter. We will integrate the `onesignal_flutter` SDK into our application.

#### 7.1.1. Add OneSignal Dependency

Open `pubspec.yaml` and add the `onesignal_flutter` dependency:

```yaml
dependencies:
  # ... existing dependencies
  onesignal_flutter: ^5.0.0 # For push notifications
```

Run `flutter pub get`.

#### 7.1.2. OneSignal Setup (Platform Specific)

**Android:**

1.  **`android/app/build.gradle`**: Ensure `minSdkVersion` is at least 21.
    ```gradle
    android {
        defaultConfig {
            minSdkVersion 21
            // ...
        }
    }
    ```
2.  **`android/app/src/main/AndroidManifest.xml`**: Add the following permissions inside the `<manifest>` tag, but outside the `<application>` tag:
    ```xml
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- For Android 13+ -->
    ```
3.  **`android/app/src/main/AndroidManifest.xml`**: Add the OneSignal service and receiver inside the `<application>` tag:
    ```xml
    <application ...>
        <service
            android:name="com.onesignal.flutter.OneSignalFirebaseMessagingService"
            android:exported="false" />
        <receiver
            android:name="com.onesignal.flutter.OneSignalNotificationOpenedHandlerExtension"
            android:exported="false" />
        <!-- ... other activities and services -->
    </application>
    ```

**iOS:**

1.  **Enable Push Notifications Capability**: In Xcode, select your project, go to `Signing & Capabilities`, and add the `Push Notifications` capability.
2.  **Enable Background Modes**: Also in `Signing & Capabilities`, add `Background Modes` and check `Remote notifications`.
3.  **`ios/Runner/Info.plist`**: Add the following to enable notification permissions prompt:
    ```xml
    <key>OneSignal_app_id</key>
    <string>YOUR_ONESIGNAL_APP_ID</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>
    ```

#### 7.1.3. Create `NotificationService`

This service will handle the initialization of OneSignal and manage device registration.

**File:** `lib/services/notification_service.dart`

```dart
// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service to handle push notification setup and management using OneSignal.
class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initializes OneSignal with the provided App ID and sets up listeners.
  Future<void> initOneSignal(String oneSignalAppId) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);

    OneSignal.initialize(oneSignalAppId);

    // Request permission for notifications (iOS & Android 13+)
    OneSignal.Notifications.requestPermission(true);

    // Set up listeners for notification clicks and foreground notifications
    OneSignal.Notifications.addEventListener(OSNotificationButtonEvent.clicked, (event) {
      debugPrint('Notification button clicked: ${event.notification.notificationId}');
    });
    OneSignal.Notifications.addEventListener(OSNotificationWillDisplayEvent.willDisplay, (event) {
      debugPrint('Notification will display: ${event.notification.notificationId}');
      // Complete notification display so it shows up
      event.notification.display();
    });

    // Listen for changes in the device state (e.g., player ID changes)
    OneSignal.User.addObserver(this._onOneSignalUserChanged);
  }

  /// Callback for when the OneSignal user state changes.
  /// This is where we update the user_devices table in Supabase.
  void _onOneSignalUserChanged(OSUserChangedEvent event) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final oneSignalPlayerId = event.current.pushSubscription.id;

    if (currentUserId != null && oneSignalPlayerId != null) {
      debugPrint('OneSignal Player ID changed: $oneSignalPlayerId for user $currentUserId');
      try {
        // Upsert (insert or update) the player ID for the current user.
        // This ensures we always have the latest player ID for sending notifications.
        await _supabase.from('user_devices').upsert(
          {
            'user_id': currentUserId,
            'player_id': oneSignalPlayerId,
            'platform': Theme.of(WidgetsBinding.instance.platformDispatcher.views.first).platform.toString(),
            'last_active': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id', // Conflict on user_id to update existing entry
        );
        debugPrint('OneSignal Player ID saved to Supabase.');
      } catch (e) {
        debugPrint('Error saving OneSignal Player ID to Supabase: $e');
      }
    }
  }

  /// Sends a push notification to a specific user or all users.
  /// This method will typically be called from a Supabase Edge Function or backend.
  /// For testing purposes, you can call it directly.
  static Future<void> sendNotification({
    required List<String> playerIds,
    required String heading,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    // This is a simplified example. In a real app, you'd use a backend service
    // or Supabase Edge Function to send notifications securely.
    // For direct sending from client, you'd need OneSignal REST API key, which is not recommended.
    // This method is primarily for demonstration or internal testing.
    debugPrint('Attempting to send notification to player IDs: $playerIds');
    // OneSignal.postNotification(OSCreateNotification(contents: contents, playerIds: playerIds));
  }
}
```

#### 7.1.4. Update `main.dart` for OneSignal Initialization

We need to initialize `NotificationService` early in the app lifecycle.

**File:** `lib/main.dart` (Additions)

```dart
// lib/main.dart

// ... existing imports
import 'package:grace_portal/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: true,
  );

  // Initialize OneSignal after Supabase
  final notificationService = NotificationService();
  await notificationService.initOneSignal('YOUR_ONESIGNAL_APP_ID'); // Replace with your OneSignal App ID

  runApp(const GracePortalApp());
}

// ... rest of main.dart
```

### 7.2. Step 2: Supabase Database Setup for Devices

We need a table to store the OneSignal player IDs associated with each user.

#### 7.2.1. SQL for `user_devices` table

**SQL Editor in Supabase:**

```sql
CREATE TABLE public.user_devices (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    player_id TEXT NOT NULL UNIQUE,
    platform TEXT, -- e.g., 'android', 'ios'
    last_active TIMESTAMPTZ DEFAULT now()
);

-- RLS for user_devices table
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Users can only see and update their own device info
CREATE POLICY "Users can manage their own device info" ON public.user_devices
FOR ALL USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Admins can see all device info (optional, for debugging/admin panel)
CREATE POLICY "Admins can view all user devices" ON public.user_devices
FOR SELECT USING (get_current_user_role() = 'admin');
```

### 7.3. Step 3: Backend Notification Logic (Supabase Edge Function)

Sending notifications directly from the client is generally not recommended due to security concerns (exposing API keys). A Supabase Edge Function provides a secure and scalable way to send notifications from the backend.

#### 7.3.1. Create `send-notification` Edge Function

This function will receive a user ID and message, then use the OneSignal REST API to send a push notification to the associated `player_id`.

**Prerequisites:**

- Install Supabase CLI: `npm install -g supabase-cli`
- Login: `supabase login`
- Link your project: `supabase link --project-ref YOUR_PROJECT_REF`

**Create the function:**

```bash
supabase functions new send-notification
```

This will create a new directory `supabase/functions/send-notification`. Edit `index.ts` inside this directory.

**File:** `supabase/functions/send-notification/index.ts`

```typescript
// supabase/functions/send-notification/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.0';

// Load OneSignal API Key and App ID from environment variables
// Set these in your Supabase project settings -> Edge Functions -> Configuration
const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID');
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY');

serve(async req => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  try {
    const { user_id, heading, content, data } = await req.json();

    if (!user_id || !heading || !content) {
      return new Response(JSON.stringify({ error: 'Missing user_id, heading, or content' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // Use service role key for RLS bypass
      { auth: { persistSession: false } },
    );

    // Fetch the player_id for the given user_id
    const { data: deviceData, error: deviceError } = await supabaseClient
      .from('user_devices')
      .select('player_id')
      .eq('user_id', user_id)
      .single();

    if (deviceError || !deviceData) {
      console.error('Error fetching player ID:', deviceError?.message || 'No device data found');
      return new Response(JSON.stringify({ error: 'User device not found or database error' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const player_id = deviceData.player_id;

    const notificationPayload = {
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: [player_id],
      headings: { en: heading },
      contents: { en: content },
      data: data || {},
    };

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(notificationPayload),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error('OneSignal API error:', result);
      return new Response(JSON.stringify({ error: 'Failed to send notification', details: result }), {
        status: response.status,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error('Function error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
```

**Deploy the function:**

```bash
supabase functions deploy send-notification --no-verify-jwt
```

**Configure Environment Variables in Supabase:**
Go to your Supabase project dashboard -> Edge Functions -> Configuration. Add the following environment variables:

- `ONESIGNAL_APP_ID`: Your OneSignal App ID
- `ONESIGNAL_REST_API_KEY`: Your OneSignal REST API Key (found in OneSignal dashboard -> Settings -> Keys & IDs)

#### 7.3.2. Triggering Notifications from Flutter

Now, modify the `TasksProvider` to call this Edge Function when a task is assigned or its status changes.

**File:** `lib/providers/tasks_provider.dart` (Modification)

```dart
// lib/providers/tasks_provider.dart

// ... existing imports
import 'package:supabase_flutter/supabase_flutter.dart';

// Add this utility function to call the Edge Function
Future<void> _callSendNotificationEdgeFunction({
  required String userId,
  required String heading,
  required String content,
  Map<String, dynamic>? data,
}) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'send-notification',
      body: {
        'user_id': userId,
        'heading': heading,
        'content': content,
        'data': data,
      },
    );
    debugPrint('Notification function response: ${response.data}');
  } catch (e) {
    debugPrint('Error calling notification function: $e');
  }
}

class TasksProvider extends ChangeNotifier {
  // ... existing code

  Future<void> addTask({
    required String title,
    String? description,
    String? assignedToId,
    String? branchId,
    DateTime? dueDate,
    TaskPriority? priority,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in to create task.');
      }

      final insertedTask = await _supabase.from('tasks').insert({
        'title': title,
        'description': description,
        'assigned_to': assignedToId,
        'assigned_by': currentUserId,
        'branch_id': branchId,
        'due_date': dueDate?.toIso8601String(),
        'priority': priority?.toString().split('.').last ?? 'medium',
      }).select().single(); // Select the inserted task to get its ID

      await fetchTasks();

      // Send notification to the assigned user if applicable
      if (assignedToId != null) {
        final assignedUser = _authService.userProfile; // This might not be the assigned user
        // You would need to fetch the assigned user's display name here if you want to personalize the message
        // For simplicity, we'll use a generic message.
        _callSendNotificationEdgeFunction(
          userId: assignedToId,
          heading: 'New Task Assigned!',
          content: 'You have been assigned a new task: $title',
          data: {'task_id': insertedTask['id']},
        );
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      final updatedTask = await _supabase.from('tasks').update({
        'status': newStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId).select().single(); // Select updated task to get details

      await fetchTasks();

      // Send notification to the assigned user about status change
      if (updatedTask['assigned_to'] != null) {
        _callSendNotificationEdgeFunction(
          userId: updatedTask['assigned_to'],
          heading: 'Task Status Updated!',
          content: 'Your task "${updatedTask['title']}" is now ${newStatus.toString().split('.').last.replaceAll('_', ' ').toUpperCase()}.',
          data: {'task_id': updatedTask['id']},
        );
      }
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }

  // ... rest of TasksProvider
}
```

### 7.4. Step 4: Admin Broadcast (Optional)

For testing or administrative purposes, you might want a simple way to send a broadcast notification to all users.

#### 7.4.1. Add Broadcast Button to Admin Screen

This would typically be in a new `AdminDashboardScreen` or similar. For now, we can add it to `BranchManagementScreen` as a temporary measure.

**File:** `lib/screens/admin/branch_management_screen.dart` (Modification)

```dart
// lib/screens/admin/branch_management_screen.dart

// ... existing imports
import 'package:grace_portal/services/auth_service.dart'; // For current user role
import 'package:grace_portal/services/permissions_service.dart'; // For permissions

// Add this function inside _BranchManagementScreenState or as a global utility
Future<void> _sendBroadcastNotification(BuildContext context) async {
  final supabase = Supabase.instance.client;
  try {
    // Fetch all player IDs from user_devices table
    final { data: devices, error } = await supabase
        .from('user_devices')
        .select('player_id');

    if (error != null) {
      throw Exception('Failed to fetch device IDs: ${error.message}');
    }

    final List<String> playerIds = (devices as List).map((e) => e['player_id'] as String).toList();

    if (playerIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No devices registered for notifications.')),
        );
      }
      return;
    }

    // Call the Edge Function for each player ID (or send a single notification to multiple IDs if OneSignal supports it directly)
    // For simplicity, we'll call the Edge Function for each. A more efficient way would be to modify the Edge Function
    // to accept a list of user_ids or player_ids.
    for (final playerId in playerIds) {
      await supabase.functions.invoke(
        'send-notification',
        body: {
          'user_id': playerId, // This would need to be user_id, not player_id, if the function fetches player_id
          'heading': 'Grace Portal Broadcast',
          'content': 'This is a test broadcast message from the admin!',
        },
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast notification sent successfully!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send broadcast: ${e.toString()}')),
      );
    }
  }
}

// In BranchManagementScreen build method, add a button:
// Add this button, perhaps in the AppBar actions or as another FloatingActionButton
// Ensure only admins can see it

// Example: Add to AppBar actions
appBar: AppBar(
  title: const Text('Manage Branches'),
  actions: [
    if (permissions.canManageBranches) // Check if current user is admin
      IconButton(
        icon: const Icon(Icons.notifications_active),
        onPressed: () => _sendBroadcastNotification(context),
        tooltip: 'Send Broadcast Notification',
      ),
  ],
),
```

**Note on Broadcast Implementation:** The example above for `_sendBroadcastNotification` is a simplified client-side approach. For a true broadcast, the `send-notification` Edge Function should be modified to accept a list of `player_ids` or `user_ids` and send a single API call to OneSignal for efficiency. The current implementation would call the Edge Function multiple times, which is less efficient for large user bases. A more robust solution would involve a new Edge Function specifically for broadcasts that fetches all player IDs and sends a single OneSignal request.

This concludes Sprint 4. The application now has integrated push notifications, allowing for real-time communication and enhanced user engagement. The backend logic for sending notifications is securely handled by a Supabase Edge Function.

---

## 8. Sprint 5: Meeting Management Module (Phase 1)

**Goal:** Implement the administrative side of meeting management, allowing authorized users (Admins, Pastors) to schedule and manage meetings. Additionally, provide a basic viewing interface for all members to see upcoming meetings.

### 8.1. Step 1: Data Model for Meetings

We need to define the data structure for meetings, corresponding to a new `public.meetings` table in Supabase.

#### 8.1.1. `MeetingModel`

This model represents a single meeting.

**SQL for `meetings` table:**

```sql
CREATE TYPE public.meeting_type AS ENUM (
    'one_time',
    'recurring'
);

CREATE TABLE public.meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    meeting_type meeting_type NOT NULL DEFAULT 'one_time',
    recurrence_rule TEXT, -- e.g., 'FREQ=WEEKLY;BYDAY=MO,WE,FR'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for meetings table
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read meetings
CREATE POLICY "All authenticated users can read meetings" ON public.meetings
FOR SELECT USING (auth.uid() IS NOT NULL);

-- Only Admins and Pastors can create meetings
CREATE POLICY "Admins and Pastors can create meetings" ON public.meetings
FOR INSERT WITH CHECK (get_current_user_role() IN ('admin', 'pastor'));

-- Only Admins and Pastors can update meetings
CREATE POLICY "Admins and Pastors can update meetings" ON public.meetings
FOR UPDATE USING (get_current_user_role() IN ('admin', 'pastor'))
WITH CHECK (get_current_user_role() IN ('admin', 'pastor'));

-- Only Admins and Pastors can delete meetings
CREATE POLICY "Admins and Pastors can delete meetings" ON public.meetings
FOR DELETE USING (get_current_user_role() IN ('admin', 'pastor'));
```

**File:** `lib/models/meeting_model.dart`

```dart
// lib/models/meeting_model.dart

import 'package:flutter/foundation.dart';

enum MeetingType { oneTime, recurring }

@immutable
class MeetingModel {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? branchId;
  final String? branchName; // Joined from branches table
  final String? createdById;
  final String? createdByName; // Joined from users table
  final MeetingType meetingType;
  final String? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetingModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.branchId,
    this.branchName,
    this.createdById,
    this.createdByName,
    required this.meetingType,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    final branch = json['branches'];
    final createdByUser = json['created_by_user'];

    return MeetingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'],
      branchId: json['branch_id'],
      branchName: branch != null ? branch['name'] : null,
      createdById: json['created_by'],
      createdByName: createdByUser != null ? createdByUser['display_name'] : null,
      meetingType: MeetingType.values.firstWhere(
          (e) => e.toString().split('.').last == json['meeting_type'],
          orElse: () => MeetingType.oneTime),
      recurrenceRule: json['recurrence_rule'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'branch_id': branchId,
      'created_by': createdById,
      'meeting_type': meetingType.toString().split('.').last,
      'recurrence_rule': recurrenceRule,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### 8.2. Step 2: `MeetingsProvider`

This provider will manage the state of meetings, fetching them from Supabase and handling create/delete operations.

**File:** `lib/providers/meetings_provider.dart`

```dart
// lib/providers/meetings_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/services/auth_service.dart';

class MeetingsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService;
  List<MeetingModel> _meetings = [];
  bool _isLoading = false;

  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;

  MeetingsProvider(this._authService) {
    _authService.addListener(_onAuthServiceChange);
    _onAuthServiceChange(); // Initial fetch based on current auth state
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthServiceChange);
    super.dispose();
  }

  void _onAuthServiceChange() {
    if (_authService.isLoggedIn) {
      fetchMeetings();
    } else {
      _meetings = [];
      notifyListeners();
    }
  }

  Future<void> fetchMeetings() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Select meeting details, and join user and branch display names
      final response = await _supabase
          .from('meetings')
          .select('*, created_by_user:users!meetings_created_by_fkey(display_name), branches(name)')
          .order('start_time', ascending: true);

      _meetings = (response as List)
          .map((json) => MeetingModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching meetings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeeting({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? branchId,
    MeetingType? meetingType,
    String? recurrenceRule,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in to create meeting.');
      }

      await _supabase.from('meetings').insert({
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': location,
        'branch_id': branchId,
        'created_by': currentUserId,
        'meeting_type': meetingType?.toString().split('.').last ?? 'one_time',
        'recurrence_rule': recurrenceRule,
      });
      await fetchMeetings();
    } catch (e) {
      debugPrint('Error adding meeting: $e');
      rethrow;
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _supabase.from('meetings').delete().eq('id', meetingId);
      await fetchMeetings();
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      rethrow;
    }
  }
}
```

### 8.3. Step 3: UI for Meeting Management

We will build the screens for viewing and scheduling meetings.

#### 8.3.1. `MeetingsScreen`

This screen will display a list of upcoming meetings.

**File:** `lib/screens/meetings/meetings_screen.dart`

```dart
// lib/screens/meetings/meetings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/providers/meetings_provider.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/permissions_service.dart';
import 'package:grace_portal/widgets/meeting_card.dart'; // To be created

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingsProvider>().fetchMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final permissions = PermissionsService(authService.userProfile);
    final meetingsProvider = context.watch<MeetingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
      ),
      body: meetingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : meetingsProvider.meetings.isEmpty
              ? const Center(child: Text('No upcoming meetings found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: meetingsProvider.meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetingsProvider.meetings[index];
                    return MeetingCard(
                      meeting: meeting,
                      onTap: () => context.go('/meeting-details/${meeting.id}'),
                    );
                  },
                ),
      floatingActionButton: permissions.canManageMeetings
          ? FloatingActionButton(
              onPressed: () => context.go('/schedule-meeting'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
```

#### 8.3.2. `MeetingCard` Widget

A reusable widget to display a summary of a single meeting.

**File:** `lib/widgets/meeting_card.dart`

```dart
// lib/widgets/meeting_card.dart

import 'package:flutter/material.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:intl/intl.dart';

class MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                meeting.description ?? 'No description provided.',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMM dd, yyyy HH:mm').format(meeting.startTime)),
                  const Text(' - '),
                  Text(DateFormat('HH:mm').format(meeting.endTime)),
                ],
              ),
              const SizedBox(height: 8),
              if (meeting.location != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(meeting.location!),
                  ],
                ),
              if (meeting.branchName != null)
                Row(
                  children: [
                    Icon(Icons.church, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(meeting.branchName!),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 8.3.3. `ScheduleMeetingScreen`

This screen allows authorized users to schedule new meetings.

**File:** `lib/screens/meetings/schedule_meeting_screen.dart`

```dart
// lib/screens/meetings/schedule_meeting_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/providers/meetings_provider.dart';
import 'package:grace_portal/providers/branches_provider.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/models/branch_model.dart';
import 'package:intl/intl.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  ChurchBranchModel? _selectedBranch;
  MeetingType _selectedMeetingType = MeetingType.oneTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, {required bool isStart}) async {
    DateTime initialDate = (isStart ? _selectedStartDate : _selectedEndDate) ?? DateTime.now();
    TimeOfDay initialTime = (isStart ? _selectedStartTime : _selectedEndTime) ?? TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _selectedStartDate = pickedDate;
            _selectedStartTime = pickedTime;
          } else {
            _selectedEndDate = pickedDate;
            _selectedEndTime = pickedTime;
          }
        });
      }
    }
  }

  Future<void> _scheduleMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartDate == null || _selectedStartTime == null ||
        _selectedEndDate == null || _selectedEndTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both start and end date/time.')),
        );
      }
      return;
    }

    final DateTime finalStartTime = DateTime(
      _selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day,
      _selectedStartTime!.hour, _selectedStartTime!.minute,
    );
    final DateTime finalEndTime = DateTime(
      _selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day,
      _selectedEndTime!.hour, _selectedEndTime!.minute,
    );

    if (finalEndTime.isBefore(finalStartTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time cannot be before start time.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<MeetingsProvider>().addMeeting(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            startTime: finalStartTime,
            endTime: finalEndTime,
            location: _locationController.text.trim(),
            branchId: _selectedBranch?.id,
            meetingType: _selectedMeetingType,
            recurrenceRule: _selectedMeetingType == MeetingType.recurring ? 'TODO: Implement recurrence rule' : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting scheduled successfully!')),
        );
        context.pop(); // Go back to meetings list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule meeting: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesProvider = context.watch<BranchesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule New Meeting')),
      body: branchesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      hintText: 'Meeting Title',
                      validator: (val) => val!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: 'Description (Optional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _locationController,
                      hintText: 'Location (Optional)',
                      prefixIcon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    // Branch Dropdown
                    DropdownButtonFormField<ChurchBranchModel>(
                      decoration: const InputDecoration(
                        labelText: 'Associated Branch (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedBranch,
                      onChanged: (ChurchBranchModel? newValue) {
                        setState(() {
                          _selectedBranch = newValue;
                        });
                      },
                      items: branchesProvider.branches.map<DropdownMenuItem<ChurchBranchModel>>((ChurchBranchModel branch) {
                        return DropdownMenuItem<ChurchBranchModel>(
                          value: branch,
                          child: Text(branch.name),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Start Date/Time Picker
                    ListTile(
                      title: Text(_selectedStartDate == null
                          ? 'Select Start Date & Time'
                          : 'Start: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day, _selectedStartTime!.hour, _selectedStartTime!.minute))}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, isStart: true),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    const SizedBox(height: 16),
                    // End Date/Time Picker
                    ListTile(
                      title: Text(_selectedEndDate == null
                          ? 'Select End Date & Time'
                          : 'End: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day, _selectedEndTime!.hour, _selectedEndTime!.minute))}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, isStart: false),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    const SizedBox(height: 16),
                    // Meeting Type Dropdown
                    DropdownButtonFormField<MeetingType>(
                      decoration: const InputDecoration(
                        labelText: 'Meeting Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedMeetingType,
                      onChanged: (MeetingType? newValue) {
                        setState(() {
                          _selectedMeetingType = newValue!;
                        });
                      },
                      items: MeetingType.values.map<DropdownMenuItem<MeetingType>>((MeetingType type) {
                        return DropdownMenuItem<MeetingType>(
                          value: type,
                          child: Text(type.toString().split('.').last.replaceAll('one_time', 'One-Time').replaceAll('recurring', 'Recurring')),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      onPressed: _scheduleMeeting,
                      text: 'Schedule Meeting',
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
```

#### 8.3.4. `MeetingDetailsScreen`

This screen will display the full details of a meeting and allow for deletion by authorized users.

**File:** `lib/screens/meetings/meeting_details_screen.dart`

```dart
// lib/screens/meetings/meeting_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/providers/meetings_provider.dart';
import 'package:grace_portal/models/meeting_model.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/services/permissions_service.dart';
import 'package:intl/intl.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailsScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  MeetingModel? _meeting;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeetingDetails();
  }

  Future<void> _fetchMeetingDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('meetings')
          .select('*, created_by_user:users!meetings_created_by_fkey(display_name), branches(name)')
          .eq('id', widget.meetingId)
          .single();
      setState(() {
        _meeting = MeetingModel.fromJson(response);
      });
    } catch (e) {
      debugPrint('Error fetching meeting details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load meeting details: ${e.toString()}')),
        );
        context.pop(); // Go back if task not found or error
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMeeting() async {
    if (_meeting == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this meeting?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await context.read<MeetingsProvider>().deleteMeeting(_meeting!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting deleted successfully!')),
          );
          context.pop(); // Go back to meetings list after deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete meeting: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final permissions = PermissionsService(authService.userProfile);

    if (_isLoading || _meeting == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meeting Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_meeting!.title),
        actions: [
          if (permissions.canManageMeetings)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMeeting,
              tooltip: 'Delete Meeting',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _meeting!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _meeting!.description ?? 'No description provided.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.calendar_today, 'Start Time', DateFormat('MMM dd, yyyy HH:mm').format(_meeting!.startTime)),
            _buildDetailRow(Icons.calendar_today, 'End Time', DateFormat('MMM dd, yyyy HH:mm').format(_meeting!.endTime)),
            if (_meeting!.location != null)
              _buildDetailRow(Icons.location_on, 'Location', _meeting!.location!),
            if (_meeting!.branchName != null)
              _buildDetailRow(Icons.church, 'Branch', _meeting!.branchName!),
            if (_meeting!.createdByName != null)
              _buildDetailRow(Icons.person_add_alt_1, 'Created By', _meeting!.createdByName!),
            _buildDetailRow(Icons.event, 'Type', _meeting!.meetingType.toString().split('.').last.replaceAll('one_time', 'One-Time').replaceAll('recurring', 'Recurring')),
            if (_meeting!.recurrenceRule != null && _meeting!.meetingType == MeetingType.recurring)
              _buildDetailRow(Icons.repeat, 'Recurrence', _meeting!.recurrenceRule!),
            _buildDetailRow(Icons.access_time, 'Created At', DateFormat('MMM dd, yyyy HH:mm').format(_meeting!.createdAt)),
            _buildDetailRow(Icons.update, 'Last Updated', DateFormat('MMM dd, yyyy HH:mm').format(_meeting!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
```

### 8.4. Step 4: Update Routing and Providers

Integrate the new meeting management screens and providers into the application.

#### 8.4.1. Update `AppRouter`

Add the new routes for meeting scheduling and meeting details.

**File:** `lib/config/router.dart` (Additions)

```dart
// In AppRouter class, within the routes list:
GoRoute(
  path: '/schedule-meeting',
  builder: (context, state) => const ScheduleMeetingScreen(),
  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissions = PermissionsService(authService.userProfile);
    if (!permissions.canManageMeetings) return '/main'; // Only authorized roles can schedule meetings
    return null;
  },
),
GoRoute(
  path: '/meeting-details/:meetingId',
  builder: (context, state) => MeetingDetailsScreen(meetingId: state.pathParameters['meetingId']!),
),
```

#### 8.4.2. Update `main.dart`

Add `MeetingsProvider` to the `MultiProvider` list. Ensure it's placed after `AuthService` as it depends on it.

**File:** `lib/main.dart` (Additions)

```dart
// In GracePortalApp widget, MultiProvider providers list:
ChangeNotifierProvider(create: (ctx) => AuthService()),
ChangeNotifierProvider(create: (ctx) => BranchesProvider()),
ChangeNotifierProvider(create: (ctx) => UsersProvider()),
ChangeNotifierProvider(create: (ctx) => TasksProvider(ctx.read<AuthService>())),
ChangeNotifierProvider(create: (ctx) => MeetingsProvider(ctx.read<AuthService>())), // New
```

#### 8.4.3. Update `PermissionsService`

Ensure `canManageMeetings` is correctly defined.

**File:** `lib/services/permissions_service.dart` (Confirmation)

```dart
// lib/services/permissions_service.dart

// ... (existing code)

class PermissionsService {
  final UserModel _user;

  PermissionsService(this._user);

  bool get canManageBranches => _user.role == 'admin';
  bool get canManageTasks => ['admin', 'pastor', 'worker'].contains(_user.role);
  bool get canManageMeetings => ['admin', 'pastor'].contains(_user.role);
}
```

This concludes Sprint 5. The application now supports basic meeting management, allowing authorized users to schedule meetings and all users to view them. The foundation for more advanced meeting features is now in place.

---

## 9. Sprint 6: Enhancements & Polish

**Goal:** Refine existing features, add smaller, high-value enhancements, and improve the overall user experience. This sprint focuses on polish, usability, and integrating utility features like dynamic content and location services.

### 9.1. Step 1: Dynamic Daily Verse

Integrating a dynamic daily Bible verse can enhance the spiritual engagement of the app. We will replace the static placeholder on the `HomeScreen` with a verse fetched from an external API.

#### 9.1.1. Choose a Bible API

For this example, we'll use a public API like `bible-api.com` or `esv.org` (requires API key). For simplicity, let's assume `bible-api.com` which is generally open for non-commercial use without an API key for basic verse fetching.

**API Endpoint Example:** `https://bible-api.com/john%203:16?translation=kjv`

#### 9.1.2. Create `BibleService`

This service will handle fetching the daily verse.

**File:** `lib/services/bible_service.dart`

```dart
// lib/services/bible_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A service to fetch Bible verses from an external API.
class BibleService {
  final String _baseUrl = 'https://bible-api.com/';

  /// Fetches a random or specific Bible verse.
  /// For simplicity, this example fetches a fixed verse. For a truly random verse,
  /// you would need a more sophisticated API or a local database of verses.
  Future<Map<String, dynamic>> fetchDailyVerse() async {
    try {
      // Example: Fetch John 3:16 from KJV
      final response = await http.get(Uri.parse('${_baseUrl}john%203:16?translation=kjv'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'verse': data['text'],
          'reference': data['reference'],
        };
      } else {
        debugPrint('Failed to load verse: ${response.statusCode}');
        return {'verse': 'Failed to load daily verse.', 'reference': 'Error'};
      }
    } catch (e) {
      debugPrint('Error fetching daily verse: $e');
      return {'verse': 'Error fetching daily verse.', 'reference': 'Error'};
    }
  }
}
```

#### 9.1.3. Update `HomeScreen`

Modify the `HomeScreen` to display the fetched daily verse.

**File:** `lib/screens/home_screen.dart`

```dart
// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:grace_portal/services/bible_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _dailyVerse = 'Loading daily verse...';
  String _verseReference = '';

  @override
  void initState() {
    super.initState();
    _fetchVerse();
  }

  Future<void> _fetchVerse() async {
    final bibleService = BibleService();
    final verseData = await bibleService.fetchDailyVerse();
    setState(() {
      _dailyVerse = verseData['verse'];
      _verseReference = verseData['reference'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '"$_dailyVerse"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Text(
              '- $_verseReference',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(
              'Welcome to Grace Portal!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Add other home screen content here
          ],
        ),
      ),
    );
  }
}
```

### 9.2. Step 2: User Profile Management (Editing)

Allow users to update their profile information directly from the app.

#### 9.2.1. Update `AuthService` for Profile Updates

Add a method to `AuthService` to handle updating user profiles in the `public.users` table.

**File:** `lib/services/auth_service.dart` (Addition)

```dart
// lib/services/auth_service.dart

// ... existing code

  /// Updates the user's profile information in the `public.users` table.
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? location,
    String? photoUrl,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in.');
      }

      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['display_name'] = displayName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (location != null) updates['location'] = location;
      if (photoUrl != null) updates['photo_url'] = photoUrl;

      if (updates.isNotEmpty) {
        await _supabase.from('users').update(updates).eq('id', currentUserId);
        // Re-fetch profile to update local state
        await _fetchUserProfile(currentUserId, _supabase.auth.currentUser!.email!);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Updates the user's email address.
  Future<void> updateEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
      // Supabase will send a verification email. After verification, onAuthStateChange will update.
    } on AuthException catch (e) {
      debugPrint('Error updating email: ${e.message}');
      rethrow;
    }
  }

  /// Updates the user's password.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      debugPrint('Error updating password: ${e.message}');
      rethrow;
    }
  }
```

#### 9.2.2. Create `EditProfileScreen`

This screen will allow users to modify their profile details.

**File:** `lib/screens/profile/edit_profile_screen.dart`

```dart
// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/models/user_model.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().userProfile;
    _displayNameController.text = user.displayName ?? '';
    _phoneNumberController.text = user.phoneNumber ?? '';
    _locationController.text = user.location ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().updateProfile(
            displayName: _displayNameController.text.trim(),
            phoneNumber: _phoneNumberController.text.trim(),
            location: _locationController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _displayNameController,
                hintText: 'Display Name',
                prefixIcon: Icons.person,
                validator: (val) => val!.isEmpty ? 'Display Name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneNumberController,
                hintText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                hintText: 'Location',
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _updateProfile,
                text: 'Save Changes',
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go('/change-email'), // To be created
                child: const Text('Change Email'),
              ),
              TextButton(
                onPressed: () => context.go('/change-password'), // To be created
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 9.2.3. Update `ProfileScreen` to Navigate to Edit

Add an edit button to the `ProfileScreen`.

**File:** `lib/screens/profile/profile_screen.dart` (Modification)

```dart
// lib/screens/profile/profile_screen.dart

// ... existing imports

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final UserModel user = authService.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/edit-profile'),
                tooltip: 'Edit Profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          // ... rest of the build method remains the same
        );
      },
    );
  }
  // ... rest of ProfileScreen
}
```

#### 9.2.4. Create `ChangeEmailScreen` and `ChangePasswordScreen`

These screens will handle email and password updates, leveraging the `AuthService` methods.

**File:** `lib/screens/profile/change_email_screen.dart`

```dart
// lib/screens/profile/change_email_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _newEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().updateEmail(_newEmailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent! Please check your inbox.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change email: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _newEmailController,
                hintText: 'New Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty || !val.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _changeEmail,
                text: 'Update Email',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**File:** `lib/screens/profile/change_password_screen.dart`

```dart
// lib/screens/profile/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_portal/services/auth_service.dart';
import 'package:grace_portal/widgets/custom_button.dart';
import 'package:grace_portal/widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().updatePassword(_newPasswordController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _newPasswordController,
                hintText: 'New Password',
                isPassword: _obscureNewPassword,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm New Password',
                isPassword: _obscureConfirmPassword,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: (val) => val!.isEmpty ? 'Please confirm your password' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _changePassword,
                text: 'Update Password',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 9.3. Step 3: Location Services Integration

Integrating location services will allow the app to display branch locations on a map and potentially provide directions. This requires handling platform-specific permissions.

#### 9.3.1. Add Dependencies

Add `geolocator` and `google_maps_flutter` to `pubspec.yaml`:

```yaml
dependencies:
  # ... existing dependencies
  geolocator: ^11.0.0 # For getting current location
  google_maps_flutter: ^2.6.0 # For displaying maps
  permission_handler: ^11.3.1 # For requesting permissions
```

Run `flutter pub get`.

#### 9.3.2. Platform-Specific Setup for Location

**Android:**

1.  **`android/app/src/main/AndroidManifest.xml`**: Add permissions inside `<manifest>` tag:
    ```xml
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    ```
2.  **`android/app/src/main/AndroidManifest.xml`**: Add your Google Maps API key inside the `<application>` tag:
    ```xml
    <application ...>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
        <!-- ... -->
    </application>
    ```

**iOS:**

1.  **`ios/Runner/Info.plist`**: Add the following keys:
    ```xml
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs access to your location to show nearby branches.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs access to your location to show nearby branches.</string>
    ```
2.  **`ios/Runner/AppDelegate.swift`**: Add the Google Maps import and initialization:

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
        GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY") // Add this line
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
    }
    ```

#### 9.3.3. Create `LocationService`

This service will handle requesting location permissions and getting the current location.

**File:** `lib/services/location_service.dart`

```dart
// lib/services/location_service.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service to handle location permissions and fetching the device's current location.
class LocationService {
  /// Requests location permissions from the user.
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    return status.isGranted;
  }

  /// Gets the current position of the device.
  /// Throws an exception if permissions are not granted or location services are disabled.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
```

#### 9.3.4. Display Branch Locations on Map

Modify the `BranchDetailsScreen` (or create a new `BranchMapScreen`) to display the branch's location on a Google Map.

**File:** `lib/screens/admin/branch_details_screen.dart` (New screen or modification of existing)

```dart
// lib/screens/admin/branch_details_screen.dart

import 'package:flutter/material.dart';
import 'package:grace_portal/models/branch_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // For geocoding addresses
import 'package:grace_portal/services/location_service.dart';

class BranchDetailsScreen extends StatefulWidget {
  final ChurchBranchModel branch;

  const BranchDetailsScreen({super.key, required this.branch});

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  GoogleMapController? mapController;
  LatLng? _branchLocation;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getBranchCoordinates();
  }

  Future<void> _getBranchCoordinates() async {
    if (widget.branch.address == null || widget.branch.address!.isEmpty) {
      setState(() {
        _locationError = 'No address provided for this branch.';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(widget.branch.address!);
      if (locations.isNotEmpty) {
        setState(() {
          _branchLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _locationError = 'Could not find coordinates for the provided address.';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error geocoding address: $e';
        _isLoadingLocation = false;
      });
      debugPrint('Geocoding error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.branch.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.branch.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.branch.description ?? 'No description provided.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.location_on, 'Location', widget.branch.location ?? 'N/A'),
            _buildDetailRow(Icons.map, 'Address', widget.branch.address ?? 'N/A'),
            const SizedBox(height: 20),
            Text(
              'Branch Location on Map:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : _locationError != null
                    ? Center(child: Text(_locationError!))
                    : Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: _branchLocation!,
                              zoom: 15.0,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId(widget.branch.id),
                                position: _branchLocation!,
                                infoWindow: InfoWindow(title: widget.branch.name),
                              ),
                            },
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
```

#### 9.3.5. Update `BranchManagementScreen` to Navigate to Details

Modify the `ListTile` in `BranchManagementScreen` to navigate to `BranchDetailsScreen`.

**File:** `lib/screens/admin/branch_management_screen.dart` (Modification)

```dart
// lib/screens/admin/branch_management_screen.dart

// ... existing imports
import 'package:grace_portal/screens/admin/branch_details_screen.dart'; // Import new screen

class BranchManagementScreen extends StatelessWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BranchesProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Branches')),
        body: Consumer<BranchesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              itemCount: provider.branches.length,
              itemBuilder: (context, index) {
                final branch = provider.branches[index];
                return ListTile(
                  title: Text(branch.name),
                  subtitle: Text(branch.location ?? 'No location'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => BranchDetailsScreen(branch: branch),
                    ),
                  ), // Navigate to details
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, provider, branch.id),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddBranchDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  // ... rest of BranchManagementScreen
}
```

### 9.4. Step 4: UI/UX Review and Minor Fixes

This step involves a general review of the application's user interface and experience, addressing any inconsistencies or minor bugs.

#### 9.4.1. Theme Consistency Check

Ensure that all widgets are correctly using the `AppTheme` defined in `lib/config/theme.dart`. Look for any hardcoded colors or text styles that should be replaced with theme properties.

- **Action:** Manually review all UI files (`.dart` files in `lib/screens/` and `lib/widgets/`) to ensure consistent use of `Theme.of(context)` for colors, text styles, and input decorations.

#### 9.4.2. General Usability Improvements

- **Loading Indicators:** Ensure all asynchronous operations (e.g., API calls) have appropriate loading indicators to provide feedback to the user.
- **Error Messages:** Verify that error messages are user-friendly and informative.
- **Empty States:** Implement clear messages or illustrations for empty states (e.g.,

no tasks, no meetings).

- **Form Reset/Clear:** Consider adding functionality to clear form fields after successful submission.
- **Keyboard Dismissal:** Implement `FocusScope.of(context).unfocus();` or similar to dismiss the keyboard when tapping outside text fields.

This concludes Sprint 6. The application now includes dynamic content, allows users to manage their profiles, and integrates location services for branch information. The focus on UI/UX polish ensures a more refined and user-friendly experience.

---

## 10. Future Sprints (Post-MVP)

Once the core application (MVP) is stable, deployed, and gathering user feedback, the following features can be considered for future development. These are outlined as potential future sprints, each building upon the established foundation.

### 10.1. Sprint 7: Prayer Request Module

**Goal:** Enable users to submit prayer requests and allow for their management and display within the application.

- **Features:** Prayer Request Submission, Viewing, Moderation.
- **Tasks:**
  1.  **Database Schema:** Create a `public.prayer_requests` table with fields for `user_id`, `content`, `is_public` (boolean), `status` (e.g., `pending`, `approved`, `answered`), `created_at`, `updated_at`.
  2.  **Data Model:** Define `PrayerRequestModel` in `lib/models/prayer_request_model.dart`.
  3.  **Provider:** Create `PrayerRequestsProvider` in `lib/providers/prayer_requests_provider.dart` to handle CRUD operations for prayer requests.
  4.  **UI - `PrayScreen`:** Build `lib/screens/prayer/prayer_screen.dart` (replacing the placeholder) to allow users to:
      - Submit new prayer requests (with an option for public/private).
      - View their own submitted requests.
      - View public prayer requests (if `is_public` is true and `status` is `approved`).
  5.  **Admin/Pastor Moderation UI:** Create a dedicated screen (e.g., `lib/screens/admin/prayer_moderation_screen.dart`) for Admins/Pastors to:
      - Review pending public prayer requests.
      - Approve or reject public requests.
      - Mark requests as answered.
  6.  **Notifications:** Integrate push notifications for:
      - Admins/Pastors when a new public prayer request is submitted.
      - Users when their prayer request status changes (e.g., approved, answered).

### 10.2. Sprint 8: Meeting Management (Phase 2)

**Goal:** Enhance the meeting management module with interactive features for attendees and improved content sharing.

- **Features:** RSVP, Attendance Tracking, Document Attachments.
- **Tasks:**
  1.  **Database Schema:**
      - Add an `attendees` table (`meeting_id`, `user_id`, `rsvp_status` (e.g., `going`, `not_going`, `maybe`)).
      - Implement Supabase Storage for meeting documents.
  2.  **Data Model:** Update `MeetingModel` to include document URLs.
  3.  **Provider:** Enhance `MeetingsProvider` to handle RSVP updates and document uploads/downloads.
  4.  **UI - `MeetingDetailsScreen` Enhancements:**
      - Add RSVP buttons and display attendee count/list.
      - Implement attendance tracking for Admins/Pastors.
      - Add a section for attaching and viewing meeting documents (e.g., agendas, minutes).
  5.  **Notifications:** Send reminders to users who RSVP'd for upcoming meetings.

### 10.3. Sprint 9: Advanced Features & Testing

**Goal:** Introduce more complex features and ensure the overall stability, reliability, and internationalization of the application.

- **Features:** Department Management, File Attachments for Tasks, Comprehensive Testing, Internationalization.
- **Tasks:**
  1.  **Department Management:**
      - Create a `public.departments` table.
      - Allow users to be associated with departments.
      - Implement role-based access control at the department level.
  2.  **File Attachments for Tasks:**
      - Integrate Supabase Storage for task-related file uploads.
      - Update `TaskModel` and `TasksProvider` to handle file URLs.
      - Add UI elements to `CreateTaskScreen` and `TaskDetailsScreen` for attaching and viewing files.
  3.  **Comprehensive Testing:**
      - Implement a full suite of unit tests for models, services, and providers.
      - Write widget tests for reusable UI components.
      - Develop integration tests for critical user flows (e.g., login, task creation).
  4.  **Internationalization (i18n):**
      - If required, implement multi-language support using Flutter's `intl` package.
      - Extract all user-facing strings into translation files.

---

## Acknowledgements

This development guide was created by Manus AI, an autonomous general AI agent, to provide a detailed roadmap for building the Grace Portal. The architectural principles and best practices outlined herein are based on modern software development standards and common industry conventions.

## Disclaimer

This document serves as a comprehensive guide for the development of the Grace Portal. While every effort has been made to ensure accuracy and completeness, software development is an iterative process, and unforeseen challenges or changes in requirements may arise. This guide should be used as a foundational blueprint, subject to adaptation and refinement as the project progresses. The code examples provided are illustrative and may require further testing, error handling, and optimization for production environments.

---
