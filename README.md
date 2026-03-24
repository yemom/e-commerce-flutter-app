E-Commerce Flutter App
Author

Name: Esrom Basazinaw
GitHub: https://github.com/yemom

Project Repository: https://github.com/yemom/e-commerce-flutter-app

Project Description

This project is a mobile E-Commerce application built with Flutter.
The application demonstrates a modern shopping UI where users can browse products, view product details, and manage a shopping cart.

The app is designed as a cross-platform mobile application that can run on both Android and iOS devices using a single codebase.

This project is mainly intended for learning Flutter UI design and mobile app architecture.

Features
Product listing screen
Product detail view
Shopping cart interface
Modern Flutter UI components
Cross-platform mobile support (Android & iOS)
Project Structure
e-commerce-flutter-app
│
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── lib/                  # Main Flutter source code
│   ├── main.dart         # Application entry point
│   ├── models/           # Product and data models
│   ├── pages/            # App screens
│   ├── widgets/          # Reusable UI components
│   └── theme/            # UI theme configuration
│
├── assets/               # Images and static resources
├── test/                 # Unit and widget tests
├── pubspec.yaml          # Project dependencies
└── README.md
Requirements

Before running the project install:

Flutter SDK
Dart SDK
Android Studio or VS Code
Android Emulator or Physical Device

Check Flutter installation:

flutter doctor
How to Install the Project

Clone the repository:

git clone https://github.com/yemom/e-commerce-flutter-app.git

Navigate to the project folder:

cd e-commerce-flutter-app

Install dependencies:

flutter pub get
How to Run the Application

Run the app using:

flutter run

This command will:

Build the Flutter application
Launch it on an emulator or connected device.
How to Build APK

To generate an Android APK file:

flutter build apk

The APK will be available in:

build/app/outputs/flutter-apk/
How to Run Tests

To run the Flutter test suite:

flutter test

The tests are located in:

test/
Technologies Used
Flutter
Dart
Material UI
Android / iOS SDK
Future Improvements
User authentication
Product search
Payment integration
Backend API integration
Order management
