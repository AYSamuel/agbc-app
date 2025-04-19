# AGBC App

A Flutter-based mobile application for AGBC (Assembly of God Bible Church) that provides a modern digital platform for church members and visitors.

## Features

- **Authentication System**: Secure user login and registration using Firebase Authentication
- **Location Services**: Integration with geolocation and geocoding for location-based features
- **Push Notifications**: Firebase Cloud Messaging for important church announcements and updates
- **Cloud Storage**: Firebase Storage for managing media files and documents
- **Real-time Database**: Cloud Firestore for storing and syncing data in real-time
- **Modern UI**: Clean and responsive interface using Material Design and Google Fonts

## Technical Stack

- **Framework**: Flutter
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Messaging
- **Location Services**: Geolocator and Geocoding
- **State Management**: Provider
- **Environment Management**: flutter_dotenv

## Project Structure

```
lib/
├── config/         # Configuration files and constants
├── models/         # Data models and classes
├── providers/      # State management providers
├── screens/        # UI screens and pages
├── services/       # Business logic and API services
├── utils/          # Utility functions and helpers
└── widgets/        # Reusable UI components
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Firebase account and project setup
- Google Maps API key (for location features)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up environment variables:
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Open `.env` and replace the placeholder values with your actual Firebase configuration
   - You can find these values in your Firebase Console under Project Settings
4. Run the app:
   ```bash
   flutter run
   ```

## Development

- Follow the Flutter style guide and best practices
- Use the provided linter rules in `analysis_options.yaml`
- Run tests using `flutter test`
- Generate mock files using `build_runner` when needed

## Contributing

Please read the contribution guidelines before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
