# 🚀 How to Run the Flutter App

This guide outlines the steps required to set up your environment, connect your devices, and run the `mapanytime-market-app` locally.

## 🛠️ 1. Prerequisites

Before running the application, ensure you have the following installed:
- **[Flutter SDK](https://docs.flutter.dev/get-started/install)**
- **[Android Studio](https://developer.android.com/studio)** (For Android emulation and Gradle syncing)
- **[Xcode](https://developer.apple.com/xcode/)** (For iOS simulation, Mac only)
- **VS Code** (Recommended) or Android Studio with Flutter/Dart plugins installed.

To verify your installation, run:
```bash
flutter doctor
```
Ensure there are no major errors.

---

## ⚙️ 2. Project Setup

### Fetch Dependencies
Download all the packages required for the project:
```bash
flutter pub get
```

### Generate Code
Since this project uses code generation (e.g., Freezed, Riverpod), you must generate the `.g.dart` files:
```bash
dart run build_runner build -d
```

### Repairing Platform Folders (If Missing)
If you just cloned the repository and notice that the `android/` or `ios/` folders are missing or corrupted, you can regenerate them safely by running:
```bash
flutter create .
```

---

## 📱 3. Connecting a Device

You must have an active device or emulator to launch the app.

### Option A: Android Emulator
1. Open **Android Studio**.
2. Go to **Tools > Device Manager**.
3. Click the **Create Device** icon (`+`).
4. Select a hardware profile (e.g., Pixel 7) and download a system image.
5. Click the **Play** button to launch the emulator.

> [!TIP]
> **Native Android Syncing:**
> If you need to make native Android changes, open Android Studio, click **Open**, and select the `android` folder specifically (not the root Flutter folder).

### Option B: iOS Simulator (Mac Only)
1. Open terminal and run:
```bash
open -a Simulator
```

### Option C: Physical Device
- **Android:** Go to your phone's Settings > Developer Options and turn on **USB Debugging**. Plug your phone into your computer via USB.
- **iOS:** Plug your iPhone into your Mac, open the `ios/Runner.xcworkspace` in Xcode, and assign a Development Team under the "Signing & Capabilities" tab.

---

## ▶️ 4. Running the Application

Once a device is connected, you can run the app from your terminal or IDE.

### Using Terminal
From the root of the project, run:
```bash
flutter run
```

If multiple devices are connected, Flutter will prompt you to choose one. You can specify a device using the `-d` flag (e.g., `flutter run -d emulator-5554`).

### Using VS Code
1. Open the project in VS Code.
2. Look at the bottom-right corner of the status bar and click the device selector to choose your emulator/device.
3. Press **F5** or go to **Run > Start Debugging**.

---

## 💡 5. Useful Commands

- **Hot Reload:** Press `r` in the terminal while `flutter run` is active to instantly see your UI changes without losing state.
- **Hot Restart:** Press `R` to completely restart the app and reset its state.
- **Run Tests:** `flutter test`
