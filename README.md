# UniFound 🎓

UniFound is a comprehensive cross-platform application built with Flutter and Firebase designed to help university students map, report, and recover lost and found items on campus. 

## 🌟 Features

- **User Authentication:** Secure email/password login and registration.
- **Reporting System:** Create and browse detailed posts of lost or found items with images, locations, and descriptions.
- **Real-time Feed:** Scroll through active items instantly with Shimmer skeleton loading.
- **Offline Reliability:** Detects when you lose connection and alerts you via a top banner.
- **Moderation:** Community-driven moderation allowing users to report inappropriate items. Items reported 3 or more times are automatically hidden.
- **User Profiles:** Customize your avatar, name, and phone number.
- **Real-time Messaging:** Chat instantly with others to coordinate returning items.

## 🛠 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Authentication, Cloud Firestore (NoSQL Database), Firebase Storage (Image Hosting).
- **State Management:** Provider
- **Image Handling:** image_picker
- **Additional Tools:** shimmer, connectivity_plus, package_info_plus

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.10.0 or higher)
- Android Studio / VS Code
- A valid Firebase Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/unifound.git
   cd unifound
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Make sure you have `flutterfire_cli` installed, then run:
   ```bash
   flutterfire configure
   ```
   This will generate `firebase_options.dart`.

4. **Run the App:**
   ```bash
   flutter run
   ```

## 📁 Project Structure

- `lib/models/`: Data models for Users, Items, Chats.
- `lib/providers/`: State management logic for Auth, Items, and Chats.
- `lib/screens/`: UI Views organized by feature (Auth, Home, Posts, Profile, Chat).
- `lib/services/`: Direct interaction with Firebase (Auth, Database, Storage).
- `lib/utils/`: Constants, Theme colors, and input validators.
- `lib/widgets/`: Reusable components like Custom Buttons, Input Fields, and Loading Skeletons.

## 🤝 Contribution Guidelines

We welcome contributions! Please follow these steps:
1. Fork the repo and create your feature branch.
2. Ensure you add `try-catch` blocks and user-friendly error banners or snackbars to all new features.
3. Validate user inputs completely using the `Validators` utility.
4. Run `flutter analyze` before committing to ensure `const` constructors and no unused imports.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
