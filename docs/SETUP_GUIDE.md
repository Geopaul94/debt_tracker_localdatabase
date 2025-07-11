# 🔧 Setup Guide for New Features

## 📋 Prerequisites

Before using the new cloud backup and premium features, you need to configure:

1. **Google Drive API** - For cloud backup functionality
2. **Google Play Console** - For in-app purchases
3. **AdMob** - Already configured (for rewarded ads)

## 🔐 Google Drive API Setup

### Step 1: Enable Google Drive API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Google Drive API**
4. Enable the **Google Sign-In API**

### Step 2: Configure OAuth 2.0

1. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client IDs**
2. Choose **Android** application type
3. Enter package name: `com.geo.debit_tracker`
4. Get SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. Add the SHA-1 fingerprint to the OAuth client

### Step 3: Download Configuration

1. Download the `google-services.json` file
2. Place it in `android/app/` directory

## 💰 Google Play Console Setup

### Step 1: Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console/)
2. Create new app or select existing one
3. Complete app information and policies

### Step 2: Set Up In-App Products

1. Go to **Monetize** → **Products** → **In-app products**
2. Create new managed product:
   - **Product ID**: `premium_yearly_750`
   - **Name**: "Premium Yearly Subscription"
   - **Price**: ₹750.00
   - **Description**: "Remove ads and get automatic daily backups"

3. Create second product:
   - **Product ID**: `premium_monthly_99`
   - **Name**: "Premium Monthly Subscription"  
   - **Price**: ₹99.00
   - **Description**: "Remove ads and get automatic daily backups"

### Step 3: Set Up Subscriptions (Alternative)

For recurring subscriptions instead of managed products:

1. Go to **Monetize** → **Products** → **Subscriptions**
2. Create subscription group: "Premium Plans"
3. Add base plan for yearly: `premium_yearly_750`
4. Add base plan for monthly: `premium_monthly_99`

## 🔧 Build Configuration

### Android NDK Version

The `android/app/build.gradle.kts` has been updated to use NDK version `27.0.12077973` to resolve compatibility issues.

### Permissions

Ensure these permissions are in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

## 🧪 Testing

### Test In-App Purchases

1. Upload signed APK to Google Play Console (Internal Testing track)
2. Add test accounts in Play Console
3. Install from Play Store (not sideloaded)
4. Test purchase flow

### Test Google Drive Backup

1. Run app with debug configuration
2. Sign in with Google account
3. Try manual backup/restore
4. Verify files appear in Google Drive

## 🚀 Production Deployment

### Final Checklist

- [ ] Google Drive API credentials configured
- [ ] In-app products created and activated in Play Console
- [ ] Signed APK uploaded for testing
- [ ] All permissions added to manifest
- [ ] App policies comply with Play Store requirements
- [ ] Privacy policy updated to include cloud backup

### Release Steps

1. **Build signed APK/AAB**:
   ```bash
   flutter build appbundle --release
   ```

2. **Upload to Play Console**
3. **Test in-app purchases** with test accounts
4. **Test cloud backup** functionality
5. **Submit for review**

## 🔍 Troubleshooting

### Common Issues

1. **"Google Sign-In failed"**
   - Check SHA-1 fingerprint is correctly added
   - Verify package name matches exactly
   - Ensure google-services.json is in android/app/

2. **"In-app purchase not available"**
   - Check Play Console product configuration
   - Ensure app is uploaded to testing track
   - Verify billing integration in Play Console

3. **"Background backup not working"**
   - Check device battery optimization settings
   - Verify network permissions
   - Ensure premium subscription is active

### Debug Tips

- Use `flutter logs` to view detailed error messages
- Check Google Play Console for any policy violations
- Test on real device (not emulator) for in-app purchases

## 📞 Support

For additional help:
- Check [Google Drive API documentation](https://developers.google.com/drive/api)
- Review [Play Billing documentation](https://developer.android.com/google/play/billing)
- Contact support at: geo@geopaulson.com

---

## 🎯 Next Steps

After completing this setup:

1. **Test all features** thoroughly
2. **Update app store description** with new features
3. **Create marketing materials** highlighting premium benefits
4. **Monitor analytics** for feature adoption
5. **Gather user feedback** for improvements 