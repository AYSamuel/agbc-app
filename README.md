# AGBC App

A Flutter application for managing church activities, tasks, and meetings.

## Features

- User authentication and role-based access control
- Task management with assignments and status tracking
- Meeting scheduling and management
- Branch management for different church locations
- Real-time updates using Supabase
- Push notifications for important updates

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Supabase account and project

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/agbc-app.git
cd agbc-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the root directory with your Supabase credentials:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Run the app:
```bash
flutter run
```

## Project Structure

- `lib/`
  - `models/` - Data models
  - `screens/` - UI screens
  - `services/` - Business logic and API services
  - `providers/` - State management
  - `widgets/` - Reusable UI components
  - `utils/` - Utility functions and constants

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
