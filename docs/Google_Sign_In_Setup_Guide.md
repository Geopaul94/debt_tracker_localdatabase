# Google Sign-In & Google Drive API Setup Guide

This guide will help you configure Google Sign-In and Google Drive API for the Debt Tracker app's cloud backup feature.

## Prerequisites

1. A Google Cloud Project
2. Google Cloud Console access
3. Android Studio (for Android configuration)
4. Xcode (for iOS configuration)

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Google Drive API
   - Google Sign-In API

## Step 2: Configure OAuth Consent Screen

1. In Google Cloud Console, go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type
3. Fill in the required information:
   - App name: "Debt Tracker"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/drive.file`
   - `https://www.googleapis.com/auth/userinfo.email`
5. Add test users (your email addresses)

## Step 3: Create OAuth 2.0 Credentials

### For Android:

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "Android" as application type
4. Fill in the details:
   - Package name: `com.geo.debit_tracker`
   - SHA-1 certificate fingerprint: Get this from your keystore
5. Download the `google-services.json` file

### For iOS:

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "iOS" as application type
4. Fill in the details:
   - Bundle ID: `com.geo.debitTracker` (or your actual bundle ID)
5. Download the `GoogleService-Info.plist` file

### For Web (optional, for testing):

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "Web application" as application type
4. Add authorized JavaScript origins:
   - `http://localhost:3000` (for testing)
   - Your production domain

## Step 4: Configure Android

1. Replace `android/app/google-services.json.template` with your actual `google-services.json`
2. Update the package name in `google-services.json` to match your app's package name
3. Add your SHA-1 fingerprint to the OAuth client configuration

### Getting SHA-1 Fingerprint:

For debug builds:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

For release builds:
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

## Step 5: Configure iOS

1. Add `GoogleService-Info.plist` to your iOS project:
   - Open Xcode
   - Right-click on your project in the navigator
   - Select "Add Files to [ProjectName]"
   - Choose your `GoogleService-Info.plist` file
   - Make sure it's added to your target

2. Update your `ios/Runner/Info.plist` to include URL schemes:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from your `GoogleService-Info.plist`.

## Step 6: Enable Google Drive API

1. In Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google Drive API"
3. Click on it and press "Enable"

## Step 7: Test the Configuration

1. Build and run your app
2. Navigate to the Cloud Backup page
3. Try signing in with Google
4. If successful, you should see your email address displayed
5. Try creating a backup to Google Drive

## Troubleshooting

### Common Issues:

1. **"developer_error"**: 
   - Check that your `google-services.json` is properly configured
   - Verify the package name matches your app
   - Ensure the SHA-1 fingerprint is correct

2. **"network_error"**:
   - Check your internet connection
   - Verify the Google APIs are enabled

3. **"sign_in_canceled"**:
   - User cancelled the sign-in process
   - This is normal behavior

4. **"access_denied"**:
   - Check that your OAuth consent screen is properly configured
   - Verify that your email is added as a test user

### Debug Steps:

1. Check the console logs for detailed error messages
2. Verify all configuration files are in the correct locations
3. Ensure the Google Cloud Project has billing enabled (required for some APIs)
4. Check that the OAuth consent screen is published or in testing mode

## Security Notes

1. Never commit your `google-services.json` or `GoogleService-Info.plist` files to public repositories
2. Use different OAuth client IDs for debug and release builds
3. Regularly rotate your API keys
4. Monitor your Google Cloud Console for any unusual activity

## Additional Resources

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Drive API Documentation](https://developers.google.com/drive/api)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Flutter Google Services Plugin](https://pub.dev/packages/googleapis)

## Support

If you encounter issues after following this guide:

1. Check the Flutter and Google Sign-In documentation
2. Verify your Google Cloud Console configuration
3. Test with a simple Flutter app first
4. Check the GitHub issues for the google_sign_in package 