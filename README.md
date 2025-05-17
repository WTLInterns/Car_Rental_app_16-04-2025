# Car Rental App

A professional Flutter application for car rental services with advanced features like booking, tracking, and user/driver management.

## Project Overview

This Car Rental app follows a professional architecture with clean code principles, separation of concerns, and modern state management. It includes:

- User authentication and profile management
- Car booking and ETS (Employee Transfer Service) booking
- Real-time trip tracking
- Vehicle selection and payment processing
- Driver assignment and trip management
- Offers and notifications

## Architecture

The app follows a feature-first, layered architecture for better maintainability and scalability:

```
lib/
├── core/            # Core utilities and services
├── features/        # Feature modules
│   ├── auth/        # Authentication
│   ├── booking/     # Booking services
│   ├── payment/     # Payment processing
│   ├── trips/       # Trip management
│   ├── tracking/    # Location tracking
│   └── profile/     # User profiles
└── widgets/         # Reusable UI components
```

Each feature module follows a consistent structure:
- `blocs/`: Business logic and state management
- `models/`: Data models
- `repositories/`: Data access layer
- `screens/`: UI components

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/car_rental_app.git
   ```

2. Install dependencies:
   ```
   cd car_rental_app
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

## Development Guidelines

### Code Style

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Keep functions small and focused
- Write comments for complex logic
- Use consistent formatting (run `flutter format .` before committing)

### Architecture Guidelines

1. **Separation of Concerns**
   - UI logic should be in screens and widgets
   - Business logic should be in BLoCs/providers
   - Data access should be in repositories

2. **State Management**
   - Use Provider for simple state management
   - Use proper state immutability patterns

3. **Dependency Injection**
   - Inject dependencies through constructors
   - Avoid global singletons when possible

4. **Error Handling**
   - Handle all errors gracefully
   - Show user-friendly error messages
   - Log errors for debugging

## Migration Plan

For details on the ongoing architectural improvements, see [MIGRATION_PLAN.md](MIGRATION_PLAN.md).
