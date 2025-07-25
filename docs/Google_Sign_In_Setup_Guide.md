# Google Sign-In Setup Guide

## Problem
Google Sign-In is failing with `GoogleSignInException(code GoogleSignInExceptionCode.canceled, activity is cancelled by the user., null)`

## Solution Steps

### 1. Create Google Cloud Console Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the Google Drive API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Drive API"
   - Click "Enable"

### 2. Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type
3. Fill in required information:
   - App name: "Debt Tracker"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/drive.file`
5. Add test users (your email)

### 3. Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"
3. Choose "Android" application type
4. Fill in:
   - Package name: `com.geo.debit_tracker`
   - SHA-1 certificate fingerprint: `33:E5:1E:87:5C:E7:BC:19:DD:D6:62:3E:31:69:AE:65:91:73:8E:57`
5. Create another credential for "Web application" type
6. Note down both client IDs

### 4. Update App Configuration

Replace the client IDs in `lib/core/services/google_drive_service.dart`:

```dart
await _googleSignIn!.initialize(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  clientId: 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com',
);
```

### 5. Test the Setup

1. Clean and rebuild the app
2. Try Google Sign-In
3. Should work without cancellation errors

## Alternative: Use Test Configuration

If you want to test immediately without Google Cloud Console setup, use these test client IDs:

```dart
await _googleSignIn!.initialize(
  serverClientId: '694593410619-6o519rlaspfobkgm6nt65b1e9vfsi1s5.apps.googleusercontent.com',
  clientId: '694593410619-2h85f1cg6mlqshv9shja53i45375jli6.apps.googleusercontent.com',
);
```

But these need proper Google Cloud Console configuration to work. 