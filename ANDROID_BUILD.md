# Building the Android APK

The project is export-ready: `export_presets.cfg` already contains an **Android** preset with
the package name, SDK levels, architectures and screen settings filled in. What is left is
installing the Android toolchain on your machine — it cannot be installed inside a build
container, and no APK is produced by the repository itself.

## One-time setup (about 10 minutes)

1. **Godot 4.3** — standard build, not the .NET one.
2. **Export templates** — in Godot: `Editor → Manage Export Templates → Download and Install`.
3. **JDK 17** — Temurin 17 or Android Studio's bundled JDK.
4. **Android SDK** — Android Studio, or command-line tools. In the SDK Manager install:
   - Android SDK Platform **34**
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android SDK Command-line Tools
5. **Point Godot at them** — `Editor → Editor Settings → Export → Android`:
   - **Android SDK Path** → your `.../Android/Sdk`
   - **Java SDK Path** → your JDK 17 folder
   - **Debug Keystore** → `~/.android/debug.keystore`
     (alias `androiddebugkey`, store/key password `android`)

## Build

**From the editor:** `Project → Export… → Android → Export Project…`
Write to `build/life-empire.apk`. Untick *Export With Debug* for a release build.

**From the command line:**

```bash
mkdir -p build

# Debug APK — signed with the auto-generated debug keystore
godot --headless --path . --export-debug "Android" build/life-empire.apk

# Release APK — needs your own keystore configured in Editor Settings
godot --headless --path . --export-release "Android" build/life-empire.apk
```

## Install on a phone

```bash
adb devices                     # confirm the phone is connected
adb install -r build/life-empire.apk
```

Or copy the APK to the phone and open it, allowing "install from unknown sources".

## Release signing (for Play Store)

`build/`, `*.apk`, `*.aab` and `*.keystore` are git-ignored, so keys never reach the
repository.

```bash
keytool -genkey -v -keystore lifeempire-release.keystore \
  -alias lifeempire -keyalg RSA -keysize 2048 -validity 10000
```

Then in `Editor Settings → Export → Android` set **Release Keystore**, **Release Username**
and **Release Password**, and export with *Export With Debug* unticked.

## Settings already applied in the preset

| Setting | Value | Why |
|---|---|---|
| Package name | `com.cricketaddict567.lifeempire` | Must be unique on Play; change if you prefer |
| Min SDK | 24 (Android 7.0) | Covers ~98% of active devices |
| Target SDK | 34 (Android 14) | Play Store requirement |
| Architectures | arm64-v8a + armeabi-v7a | Modern phones plus older 32-bit devices |
| Renderer | GL Compatibility | Works on low-end GPUs; set in `project.godot` |
| Orientation | Portrait | Set in `project.godot` |
| Texture import | ETC2/ASTC | Required by Android |
| Immersive mode | On | Full-screen, no system bars |

`tools/` is excluded from the export so the test harness never ships inside the APK.
