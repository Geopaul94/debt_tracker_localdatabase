# 🔑 Google Sign-In Setup Guide for Cloud Backup

## ❌ **Current Issue**
Cloud backup Google Sign-in is failing because the `google-services.json` file is missing or incorrectly configured.

## ✅ **Solution: Complete Google Sign-In Setup**

### **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select existing project
3. Enter project name: `debt-tracker-app` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create project"

### **Step 2: Add Android App to Firebase**

1. In Firebase console, click "Add app" → Android icon
2. **Package name**: `com.geo.debit_tracker` (MUST match exactly)
3. **App nickname**: `Debt Tracker` (optional)
4. **Debug signing certificate SHA-1**: Get from terminal:

```bash
# For debug builds (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release builds (production) - use your release keystore
keytool -list -v -keystore your-release-key.keystore -alias your-alias-name
```

5. Copy the SHA-1 fingerprint and paste it
6. Click "Register app"

### **Step 3: Download google-services.json**

1. Download the `google-services.json` file
2. **CRITICAL**: Place it in `android/app/` directory
3. **Replace** the template file `android/app/google-services.json.template`

### **Step 4: Enable APIs**

Go to [Google Cloud Console](https://console.cloud.google.com/):

1. Select your Firebase project
2. Go to "APIs & Services" → "Library"
3. Enable these APIs:
   - **Google Drive API**
   - **Google Sign-In API** 
   - **Firebase Authentication API**

### **Step 5: Configure OAuth 2.0**

1. In Google Cloud Console → "Credentials"
2. Find your Android OAuth 2.0 client
3. **Package name**: `com.geo.debit_tracker`
4. **SHA-1 fingerprints**: Add both debug and release fingerprints
5. **Authorized redirect URIs**: Leave empty for mobile

### **Step 6: Update Gradle Dependencies**

Verify in `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth")
    implementation("com.google.gms:google-services")
}
```

### **Step 7: Test the Setup**

1. Run the app in debug mode
2. Go to "Cloud Backup" in settings
3. Try "Sign In with Google"
4. Should show Google account picker

## 🔧 **Troubleshooting**

### **Error: "Sign-in failed"**
```
✅ Check SHA-1 fingerprint is correct
✅ Verify package name matches exactly: com.geo.debit_tracker  
✅ Ensure google-services.json is in android/app/
✅ APIs are enabled in Google Cloud Console
```

### **Error: "Invalid client ID"**
```
✅ Download fresh google-services.json from Firebase
✅ Clean and rebuild: flutter clean && flutter build apk
✅ Check OAuth client configuration
```

### **Error: "Network error"**
```
✅ Internet connection working
✅ Google Play Services updated on device
✅ Try on different device/emulator
```

## 📱 **For Production Release**

1. **Generate release SHA-1**:
```bash
keytool -list -v -keystore debt-tracker-key.jks -alias upload
```

2. **Add to Firebase console**:
   - Project Settings → General → Your apps
   - Add fingerprint → Paste release SHA-1

3. **Download updated google-services.json**
4. **Test on signed APK before Play Store release**

## 🎯 **Test Checklist**

- [ ] google-services.json exists in android/app/
- [ ] Package name matches: com.geo.debit_tracker
- [ ] SHA-1 fingerprints added to Firebase
- [ ] Google Drive API enabled
- [ ] Sign-in works in debug mode
- [ ] Sign-in works in release mode
- [ ] Cloud backup upload/download functional

---

## 📞 **Need Help?**

If you're still having issues:

1. **Check the exact error** in terminal/logcat
2. **Verify all steps** completed exactly as written
3. **Try with a fresh Firebase project** if needed
4. **Test on a different device** to rule out device issues

The most common issue is **incorrect SHA-1 fingerprint** - make sure you're using the right one for your build type (debug vs release)! 