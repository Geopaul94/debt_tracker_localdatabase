#!/bin/bash

echo "🔧 Google Sign-In Setup Script for Debt Tracker"
echo "================================================"
echo ""

# Check if google-services.json exists
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json found"
else
    echo "❌ google-services.json not found"
    echo "   Please follow the setup guide in docs/Google_Sign_In_Setup_Guide.md"
    echo "   Replace android/app/google-services.json.template with your actual config"
fi

# Check if GoogleService-Info.plist exists
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
else
    echo "❌ GoogleService-Info.plist not found"
    echo "   Please add your GoogleService-Info.plist to ios/Runner/"
fi

# Check package dependencies
echo ""
echo "📦 Checking package dependencies..."
flutter pub get

# Check if all required packages are available
echo ""
echo "🔍 Checking required packages..."
if grep -q "google_sign_in" pubspec.yaml; then
    echo "✅ google_sign_in package found"
else
    echo "❌ google_sign_in package missing"
fi

if grep -q "googleapis" pubspec.yaml; then
    echo "✅ googleapis package found"
else
    echo "❌ googleapis package missing"
fi

if grep -q "googleapis_auth" pubspec.yaml; then
    echo "✅ googleapis_auth package found"
else
    echo "❌ googleapis_auth package missing"
fi

echo ""
echo "🚀 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Follow the setup guide in docs/Google_Sign_In_Setup_Guide.md"
echo "2. Configure your Google Cloud Project"
echo "3. Add your OAuth credentials"
echo "4. Test the Google Sign-In functionality"
echo ""
echo "For help, see: docs/Google_Sign_In_Setup_Guide.md" 