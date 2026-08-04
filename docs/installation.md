# 📦 Installation Guide

How to get **MapAnytime Market app** (Flutter) running from a clean machine — the SDK, the platform toolchains, Gradle, the IDE and its extensions, the third-party accounts, and the local backend it talks to.

> Already have Flutter + Android Studio + your IDE working? Jump to [Step 7 — Get the project](#step-7--get-the-project).

---

## 0. What you are installing

| Layer | What | Needed for |
|---|---|---|
| Flutter SDK 3.44.x (Dart 3.12.2) | The framework + `flutter` CLI | Everything |
| Android Studio + Android SDK 36 | Android build tools, emulator, bundled JDK 21 | Android builds |
| Gradle 9.1 | Android build system — **auto-installed by the wrapper** | Android builds |
| VS Code *or* Android Studio + Flutter/Dart plugins | Editing, debugging, hot reload | Day-to-day work |
| Xcode + CocoaPods *(macOS only)* | iOS build tools | iOS builds |
| Visual Studio 2022/2026 (Desktop C++) | MSVC toolchain | Windows desktop builds |
| Chrome | Web target | `flutter run -d chrome` |
| Mapbox account (2 tokens) | Map rendering + native SDK download | Map screens, Android/iOS builds |
| Node 20+ & Docker Desktop | Runs `mapanytime-api` locally | Real data instead of a dead `BASE_URL` |

Reference environment (verified working, `flutter doctor` clean):

```
Flutter 3.44.2 • channel stable • Dart 3.12.2 • DevTools 2.57.0
Android SDK 36.1.0 • build-tools 36.1.0 • emulator 36.6.11
Java: OpenJDK 21.0.10 (bundled with Android Studio)
Gradle 9.1.0 • AGP 9.0.1 • Kotlin 2.3.20
Windows 11 Pro 25H2 • Visual Studio Community 2026 18.7.1
```

`pubspec.yaml` pins `sdk: ^3.12.2`, so **Dart 3.12.2 or newer** is required — that means Flutter **3.44.0+**. Older Flutter versions will fail on `flutter pub get`.

---

## Step 1 — Install the Flutter SDK

### Windows

1. Download the stable SDK zip from [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).
2. Extract to a path with **no spaces and no admin-only permissions** — e.g. `C:\src\flutter` (this is where the reference machine has it). Do **not** use `C:\Program Files\`.
3. Add `C:\src\flutter\bin` to your user `Path`:
   - Start → "Edit environment variables for your account" → `Path` → New → `C:\src\flutter\bin` → OK.
   - Open a **new** terminal afterwards.
4. Verify:
   ```powershell
   flutter --version
   ```

### macOS / Linux

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
flutter --version
```

### Then, on every OS

```bash
flutter doctor
```

Fix anything with a ✗ or ! before continuing. The next steps cover the usual offenders.

---

## Step 2 — Android Studio & the Android SDK

Install [Android Studio](https://developer.android.com/studio) even if you plan to code in VS Code — it is the delivery mechanism for the Android SDK, the emulator, and the JDK.

### 2.1 SDK components

First launch → **More Actions → SDK Manager**:

**SDK Platforms** tab
- ✅ **Android API 36** — the project sets `compileSdk = 36` in [android/app/build.gradle.kts](../android/app/build.gradle.kts)
- ✅ (optional) an older API image if you want to test on it

**SDK Tools** tab (tick *Show Package Details* to pin versions)
- ✅ **Android SDK Build-Tools 36.1.0**
- ✅ **Android SDK Command-line Tools (latest)** — required by `flutter doctor --android-licenses`
- ✅ **Android SDK Platform-Tools** (`adb`)
- ✅ **Android Emulator**
- ✅ **Google USB Driver** *(Windows only, for physical devices)*

### 2.2 Accept licenses

```bash
flutter doctor --android-licenses
```

Press `y` through all of them. `flutter doctor` must show **"All Android licenses accepted"**.

### 2.3 A device to run on

- **Emulator**: **Device Manager → Add a device** → any Pixel image with **API 34+**.
- **Physical phone**: enable **USB debugging** (Settings → About phone → tap *Build number* ×7 → Developer options → USB debugging), then accept the RSA prompt when you plug it in.

```bash
flutter devices     # your device must appear here
```

### 2.4 Android Studio plugins

Install from **Settings → Plugins → Marketplace** (needed only if you edit code in Android Studio — skip if you use VS Code):

| Plugin | Why |
|---|---|
| **Flutter** | Run/debug configs, hot reload, widget inspector. Installing it prompts to install **Dart** too — accept. |
| **Dart** | Analyzer, formatter, quick fixes (auto-installed with Flutter) |
| **Kotlin** | Bundled by default — needed for the `MainActivity` and Gradle Kotlin DSL files |

After installing, **restart** and point Android Studio at the SDK: **Settings → Languages & Frameworks → Flutter → Flutter SDK path** = `C:\src\flutter`.

---

## Step 3 — Gradle & the JDK

**You do not install Gradle manually.** The repo ships the Gradle *wrapper* (`android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar`), which downloads and caches the exact version the project needs on first build:

```properties
# android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.1.0-all.zip
```

That download lands in `~/.gradle/wrapper/dists` (Windows: `%USERPROFILE%\.gradle\wrapper\dists`) and is shared across projects. **The first Android build therefore takes 5–15 minutes** — Gradle 9.1, AGP 9.0.1, Kotlin 2.3.20 and the Mapbox native SDK all come down at once. Do not interrupt it.

### The JDK

Gradle needs a JDK; the Android Studio bundle provides **JDK 21**, and the project compiles to **Java 17 bytecode** (`sourceCompatibility`/`targetCompatibility`/`jvmTarget` are all 17). No separate JDK install is needed. If `flutter doctor` cannot find it:

```bash
flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
```

Do **not** set a system `JAVA_HOME` pointing at JDK 8 or 11 — AGP 9 requires 17+.

### Memory

[android/gradle.properties](../android/gradle.properties) requests a large heap:

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m
```

On a machine with ≤ 8 GB RAM, lower `-Xmx8G` to `-Xmx2G` or the daemon will fail to start.

### Running Gradle directly (rarely needed)

```bash
cd android
./gradlew tasks            # macOS/Linux
.\gradlew.bat tasks        # Windows PowerShell
./gradlew --stop           # kill stuck daemons
./gradlew clean
```

Prefer `flutter clean` + `flutter run` for everyday work. Installing a standalone Gradle via `choco`/`brew`/SDKMAN is **not** required and can cause version mismatches — if you already have one on `PATH`, it is ignored by the wrapper.

---

## Step 4 — iOS toolchain *(macOS only — skip on Windows)*

```bash
xcode-select --install
sudo xcodebuild -runFirstLaunch
sudo gem install cocoapods
```

Open `ios/Runner.xcworkspace` once in Xcode and set a **Team** under *Signing & Capabilities* before running on a physical iPhone. The repo has no committed `Podfile` — Flutter generates it on the first `flutter run` / `flutter build ios`.

---

## Step 5 — Desktop & web targets *(optional)*

- **Windows desktop**: install **Visual Studio 2022 or newer** with the **"Desktop development with C++"** workload (this is Visual Studio, not VS Code — they are different products).
- **Web**: install **Google Chrome**. Note that the map does not render on web — `mapbox_maps_flutter` is mobile-only and [bootstrap.dart:20](../lib/bootstrap.dart#L20) deliberately skips Mapbox init on unsupported platforms so the rest of the app still loads.

---

## Step 6 — IDE setup & extensions

Pick **one** primary editor. VS Code is what this repo is configured for ([.vscode/launch.json](../.vscode/launch.json) ships the run targets).

### 6.1 VS Code extensions

Required — nothing works without these two:

| Extension | ID | Why |
|---|---|---|
| **Flutter** | `Dart-Code.flutter` | Run/debug, hot reload, device picker, DevTools. Pulls in Dart automatically. |
| **Dart** | `Dart-Code.dart-code` | Analyzer, `dart format`, quick fixes, `very_good_analysis` lint surfacing |

Strongly recommended for this codebase:

| Extension | ID | Why |
|---|---|---|
| **Error Lens** | `usernamehw.errorlens` | Shows analyzer errors inline — the lint set is strict and CI-gated |
| **Code Spell Checker** | `streetsidesoftware.code-spell-checker` | The repo already ships a `cSpell.words` list in the workspace settings |
| **Markdown Preview Mermaid Support** | `bierner.markdown-mermaid` | The README's architecture diagrams are Mermaid |
| **GitLens** | `eamodio.gitlens` | Blame/history while reviewing architecture changes |

Only if you also work on `mapanytime-api` in the same window:

| Extension | ID |
|---|---|
| **ESLint** | `dbaeumer.vscode-eslint` |
| **Prettier** | `esbenp.prettier-vscode` |
| **Prisma** | `Prisma.prisma` |
| **Docker** | `ms-azuretools.vscode-docker` |

Install them all in one shot:

```powershell
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
code --install-extension usernamehw.errorlens
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension bierner.markdown-mermaid
code --install-extension eamodio.gitlens
```

To have VS Code prompt every new contributor automatically, create `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "Dart-Code.flutter",
    "Dart-Code.dart-code",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker",
    "bierner.markdown-mermaid"
  ]
}
```

### 6.2 Useful VS Code settings

Format-on-save keeps you clear of the CI formatting gate:

```json
{
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true,
    "editor.rulers": [80]
  },
  "dart.lineLength": 80
}
```

### 6.3 Android Studio as the primary IDE

Install the **Flutter** plugin (see [Step 2.4](#24-android-studio-plugins)); it creates the run configurations itself. Choose the entry point per configuration (`lib/main_dev.dart` or `lib/main_prod.dart`) under **Run → Edit Configurations → Dart entrypoint**.

### 6.4 What ships in the repo

- [.vscode/launch.json](../.vscode/launch.json) — **Flutter: Dev** and **Flutter: Prod** launch configs, ready in the Run panel
- [analysis_options.yaml](../analysis_options.yaml) — `very_good_analysis` rule set, `public_member_api_docs` disabled
- [devtools_options.yaml](../devtools_options.yaml) — DevTools extension enablement

---

## Step 7 — Get the project

```bash
git clone <repo-url>
cd mapanytime-market-app
flutter pub get
flutter gen-l10n
```

`pubspec.yaml` has `generate: true`, so localizations are also generated automatically on build — running `flutter gen-l10n` manually just gets your IDE to resolve `context.l10n` immediately.

Android's `android/local.properties` (containing `flutter.sdk=...`) is generated on the first Android build. If Gradle complains `flutter.sdk not set in local.properties`, run `flutter build apk --debug` once, or create the file by hand:

```properties
flutter.sdk=C:\\src\\flutter
sdk.dir=C:\\Users\\<you>\\AppData\\Local\\Android\\sdk
```

---

## Step 8 — Environment files

The app ships two env files, both declared as assets in `pubspec.yaml` and loaded at runtime by `flutter_dotenv`:

| File | Loaded by | Purpose |
|---|---|---|
| `.env.dev` | `lib/main.dart` (default) | Local development |
| `.env.prod` | `lib/main_prod.dart` | Deployed EC2 backend |

Keys read by [app_config.dart](../lib/core/config/app_config.dart):

| Key | Meaning | Example |
|---|---|---|
| `ENVIRONMENT` | `dev` or `prod` | `dev` |
| `APP_NAME` | Shown in logs / app label | `MapAnytime Market (Dev)` |
| `BASE_URL` | API root, **including** `/api/v1` | `http://192.168.1.20:4002/api/v1` |
| `ENABLE_LOGGING` | Verbose logger + Dio logs | `true` in dev, `false` in prod |
| `MAPBOX_PUBLIC_TOKEN` | Mapbox `pk.…` token | see Step 9 |

The socket URL is **not** configured separately — `AppConfig.socketUrl` derives it from `BASE_URL` by stripping the `/api/v1` path.

> ⚠️ These files hold real tokens. They are environment config, not templates — never paste a `sk.…` secret token into them, and keep them out of screenshots and PRs.

### Choosing `BASE_URL` in dev

| You are running on | Use |
|---|---|
| Android emulator on the same PC as the API | `http://10.0.2.2:4002/api/v1` |
| Windows desktop / web on the same PC | `http://localhost:4002/api/v1` |
| Physical phone on the **same Wi-Fi** | `http://<your-PC-LAN-IP>:4002/api/v1` (e.g. `192.168.1.20`) — requires an inbound Windows Firewall rule for TCP **4002** |
| Physical phone on **mobile data / other Wi-Fi** | the Tailscale IP (e.g. `http://100.x.x.x:4002/api/v1`) with Tailscale running on both phone and PC |

`.env.dev` already keeps these as commented alternatives — uncomment exactly one. **Changing `.env.*` requires a full restart (`flutter run` again), not a hot reload**, because the file is bundled as an asset.

Plain `http://` works because `android:usesCleartextTraffic="true"` is set in the manifest for local development.

---

## Step 9 — Mapbox tokens (two different tokens!)

Create an account at [mapbox.com](https://account.mapbox.com/) and generate **both**:

**1. Public token (`pk.…`)** — renders the map at runtime.
Put it in `.env.dev` / `.env.prod`:
```env
MAPBOX_PUBLIC_TOKEN=pk.eyJ1Ijoi...
```

**2. Secret download token (`sk.…`, scope `DOWNLOADS:READ`)** — lets Gradle/CocoaPods download the native Mapbox SDK. **Never commit this.** [android/build.gradle.kts](../android/build.gradle.kts#L8) reads it from a Gradle property or environment variable:

- **Android (all OSes)** — add to your *global* Gradle properties, outside the repo:
  - Windows: `%USERPROFILE%\.gradle\gradle.properties`
  - macOS/Linux: `~/.gradle/gradle.properties`
  ```properties
  MAPBOX_DOWNLOADS_TOKEN=sk.eyJ1Ijoi...
  ```
- **iOS (macOS)** — add to `~/.netrc`:
  ```
  machine api.mapbox.com
    login mapbox
    password sk.eyJ1Ijoi...
  ```
  then `chmod 600 ~/.netrc`.

Without the secret token, the Android build fails at dependency resolution with a **401 Unauthorized** from `api.mapbox.com`.

---

## Step 10 — Run the backend (for real data)

The app is a client of [mapanytime-api](../../mapanytime-api), which listens on port **4002**. Full instructions live in [mapanytime-api/docs/getting-started.md](../../mapanytime-api/docs/getting-started.md); the short version:

```bash
cd ../mapanytime-api
npm install                 # npm, not bun
cp .env.example .env        # then fill DATABASE_URL + token secrets
docker-compose up -d        # PostgreSQL 5432, Redis 6379, RabbitMQ 5672 (UI 15672)
npm run db:setup            # prisma generate + migrate dev
npm run db:seed             # optional sample data
npm run dev                 # API on :4002
npm run worker              # separate terminal — background/event consumer
```

Requires **Node.js 20+** and **Docker Desktop**. Sanity-check from the machine running the app:

```bash
curl http://localhost:4002/api/health/live     # process alive
curl http://localhost:4002/api/health/ready    # + postgres / redis / rabbitmq status
```

Note the health routes sit at `/api/health/*`, **outside** the `/v1` prefix that every other endpoint uses.

If you only want to work on UI, you can point `BASE_URL` at the deployed EC2 host in `.env.prod` and run the prod entry point instead.

---

## Step 11 — Run the app

```bash
flutter devices                      # pick a target id

flutter run -t lib/main_dev.dart     # dev config, logging on, no --dart-define needed
flutter run -t lib/main_prod.dart    # loads .env.prod
flutter run                          # main.dart — defaults to .env.dev
flutter run --dart-define=ENV_FILE=.env.prod   # main.dart against prod config

flutter run -d chrome                # web (no map)
flutter run -d windows               # Windows desktop
```

VS Code users get the same two targets from the Run panel — **Flutter: Dev** and **Flutter: Prod** are already defined in [.vscode/launch.json](../.vscode/launch.json).

On first launch the app asks for **location permission** (`ACCESS_FINE_LOCATION` / `NSLocationWhenInUseUsageDescription`); deny it and map-centring features stay disabled.

---

## Step 12 — Verify the install

```bash
flutter analyze     # must be clean — very_good_analysis is strict and CI-gated
dart format --set-exit-if-changed .
flutter test
```

All three are enforced in CI, so a green local run means your environment matches the build server.

---

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `401 Unauthorized` from `api.mapbox.com` during Gradle build | Missing/expired `MAPBOX_DOWNLOADS_TOKEN` in `~/.gradle/gradle.properties` — see Step 9 |
| `flutter.sdk not set in local.properties` | Missing `android/local.properties` — see Step 7 |
| Gradle daemon fails to start / OOM | `-Xmx8G` in `android/gradle.properties` exceeds your RAM — lower it |
| `Unsupported class file major version` / AGP requires Java 17 | A JDK 8/11 on `JAVA_HOME` is winning — `flutter config --jdk-dir=...` to Android Studio's `jbr` |
| Gradle download stalls or the build hangs on first run | The 9.1 distribution is still downloading; if truly stuck, `cd android && ./gradlew --stop`, delete `%USERPROFILE%\.gradle\wrapper\dists`, retry |
| `The current Dart SDK version is …` on `pub get` | Flutter older than 3.44 — run `flutter upgrade` |
| Map area is blank, rest of the app works | Bad/missing `MAPBOX_PUBLIC_TOKEN`, or you're on web/desktop where Mapbox is intentionally skipped |
| All API calls fail on a physical device, fine on emulator | `BASE_URL` still points at `localhost`/`10.0.2.2`, or port 4002 is blocked by the firewall — see Step 8 |
| Env change had no effect | `.env.*` is a bundled asset — stop and re-run, hot reload won't pick it up |
| `context.l10n` unresolved in the IDE | Run `flutter gen-l10n`, then **Dart: Restart Analysis Server** from the command palette |
| VS Code shows no devices / no hot reload | The Flutter extension isn't installed or can't find the SDK — set `dart.flutterSdkPath` to `C:\src\flutter` |
| `flutter doctor` can't find Java | `flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"` |

---

## Where to go next

- [README.md](../README.md) — architecture rules, the `Either` pattern, release checklist and production build commands
- [mapanytime-api/docs/getting-started.md](../../mapanytime-api/docs/getting-started.md) — backend setup in depth
- [mapanytime-api/docs/api-guide.md](../../mapanytime-api/docs/api-guide.md) — endpoint reference
