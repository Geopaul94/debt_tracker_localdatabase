#!/bin/bash
echo "Building and launching Debt Tracker..."

# Build the APK
flutter build apk --debug

# Install and launch
adb install build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk
adb shell am start -n com.geo.debit_tracker.debug/com.geo.debit_tracker.MainActivity

echo "App launched successfully!" 