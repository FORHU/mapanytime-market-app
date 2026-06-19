# 🚀 Absolute Beginner's Getting Started Guide

Welcome! If you are completely new to Flutter, or just setting up a brand new computer for development, this guide will hold your hand from downloading your very first tool all the way to running the production version of this enterprise app.

---

## 🛠️ Phase 1: Downloading the Core Tools

Before you can write or run any code, your computer needs the following software installed.

### 1. Download the Flutter SDK
Flutter is the core framework.
- **Download**: Go to [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) and download the SDK for your operating system.
- **Setup**: Extract the zip file and add the `flutter/bin` folder to your system's `PATH` environment variable.
- **Verify**: Open a new terminal and type `flutter doctor` to ensure it is installed correctly.

### 2. Download an IDE (Code Editor)
You need a place to write code. We highly recommend **Visual Studio Code (VS Code)** as it is lightweight and fast.
- **VS Code (Recommended)**: 
  - Download from [code.visualstudio.com](https://code.visualstudio.com/).
  - Once installed, open VS Code, click on "Extensions" (Ctrl+Shift+X), search for **"Flutter"**, and click **Install** on the official extension by Dart Code.
- **Android Studio (Required for Android)**:
  - Download from [developer.android.com/studio](https://developer.android.com/studio).
  - Even if you use VS Code to write code, you will need Android Studio installed to use Android Emulators and the Android SDK.
- **Xcode (Required for iOS - Mac Only)**:
  - Download from the **Mac App Store**.
  - Required to compile the app for iPhones and use the iOS Simulator.
  - After installing, run `sudo xcodebuild -license` in your terminal to accept the Apple license.

### 3. Download Git
Git is required to download this template and manage versions.
- **Download**: Get it from [git-scm.com/downloads](https://git-scm.com/downloads) and run the installer (you can click "Next" through all the default options).

---

## ⚙️ Phase 2: Windows Setup (Windows Users Only)

If you are developing on Windows, Flutter plugins require symlink support. You **must** enable Developer Mode:
1. Open Windows Settings (Run `start ms-settings:developers` in your terminal).
2. Toggle "Developer Mode" to **ON**.
3. **Restart your IDE** (close VS Code/Android Studio entirely and reopen it).

---

## 📦 Phase 3: Cloning & Packages

Now that your computer has the tools, let's download the actual code.

1. Open your terminal and run:
```bash
git clone <your-repo-url>
cd mapanytime_market_app
```

2. Download all the required third-party packages and generate localizations:
```bash
flutter pub get
flutter gen-l10n
```

---

## 🧩 Phase 4: Understanding the Dependencies

This enterprise framework relies on a few critical, carefully chosen packages to enforce its architecture. Here is a high-level overview of what you just installed:

- **[flutter_riverpod](https://pub.dev/packages/flutter_riverpod)**: The state management engine. Controls all data flow and dependency injection.
- **[fpdart](https://pub.dev/packages/fpdart)**: A functional programming toolkit. Used exclusively for our `Either<Failure, Success>` error handling model to prevent UI crashes.
- **[dio](https://pub.dev/packages/dio)** & **[dio_smart_retry](https://pub.dev/packages/dio_smart_retry)**: The networking layer. Handles API requests, header injection, and automatic exponential backoff retries.
- **[go_router](https://pub.dev/packages/go_router)**: The routing engine. Handles all navigation and deep linking.
- **[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)**: Used to safely store sensitive data (like authentication JWT tokens) natively on the device.
- **[very_good_analysis](https://pub.dev/packages/very_good_analysis)**: The strictest linting rules available for Flutter, used to enforce our code quality standards.

---

## 🔐 Phase 5: Setting Up Environments

This enterprise app relies on injected environment configurations. It will **not** compile without valid `.env` files. You must manually create them.

1. **Create `.env.dev`** in the root folder (next to `pubspec.yaml`) and paste this:
```env
ENV=dev
API_BASE_URL=https://dev.api.example.com
ENABLE_LOGGING=true
APP_NAME=MyApp (Dev)
```

2. **Create `.env.prod`** in the root folder and paste this:
```env
ENV=prod
API_BASE_URL=https://api.example.com
ENABLE_LOGGING=false
APP_NAME=MyApp
```

---

## 🚀 Phase 6: Running the App (Dev to Prod)

Because the app relies on environment variables, you **cannot** just run `flutter run` or click the standard "Play" button without configuring the environment flag.

### Option A: Using the Terminal

**To run the Dev environment:**
```bash
flutter run --dart-define-from-file=.env.dev -t lib/main_dev.dart
```

**To run the Production environment:**
```bash
flutter run --dart-define-from-file=.env.prod -t lib/main_prod.dart
```

### Option B: Using VS Code (Highly Recommended)

We can automate this process so you can just press `F5` to run the app.

1. Create a folder named `.vscode` in the root of the project.
2. Create a file inside it named `launch.json`.
3. Paste the following configuration to set up a dropdown menu for Dev and Prod:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter: Run (Dev)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "toolArgs": ["--dart-define-from-file=.env.dev"]
    },
    {
      "name": "Flutter: Run (Prod)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_prod.dart",
      "toolArgs": ["--dart-define-from-file=.env.prod"]
    }
  ]
}
```

Now, open the **Run and Debug** tab in VS Code (Ctrl+Shift+D). You will see a dropdown at the top where you can select either **"Flutter: Run (Dev)"** or **"Flutter: Run (Prod)"**. 

Select one and press **F5** (or the green play button). The app will build and launch perfectly!
