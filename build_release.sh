#!/bin/bash

# Build Release Script for Play Store Submission
# Make sure you have completed the setup before running this script

echo "🚀 Building Debt Tracker for Play Store Release..."

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo "❌ Error: android/key.properties not found!"
    echo "Please create key.properties from the template and configure your signing key."
    echo "See PLAY_STORE_CHECKLIST.md for instructions."
    exit 1
fi

echo "✅ Found key.properties"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build App Bundle (recommended for Play Store)
echo "📦 Building App Bundle..."
flutter build appbundle --release

# Build APKs (for testing)
echo "📱 Building APKs..."
flutter build apk --release --split-per-abi

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📂 Files created:"
echo "  App Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "  APKs: build/app/outputs/flutter-apk/"
echo ""
echo "📋 Next steps:"
echo "1. Test the APK on your device"
echo "2. Upload the .aab file to Play Console"
echo "3. Follow the PLAY_STORE_CHECKLIST.md for complete submission steps"
echo ""
echo "🎉 Ready for Play Store submission!" 