# Google Play Store Submission Checklist

## 📋 Pre-Submission Requirements

### ✅ App Configuration
- [x] App version: 1.0.0+1 (ready for initial release)
- [x] Application ID: com.geo.debit_tracker
- [x] Target SDK: Latest Android version
- [x] Min SDK: API 21 (Android 5.0)
- [x] AdMob integration configured
- [x] Biometric authentication implemented

### 🔧 Required Actions Before Upload

#### 1. **Create App Signing Key**
```bash
# Generate release keystore (DO THIS FIRST!)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

#### 2. **Configure Release Signing**
Create `android/key.properties`:
```
storePassword=yourStorePassword
keyPassword=yourKeyPassword
keyAlias=key
storeFile=path/to/your/key.jks
```

#### 3. **Update Build Configuration**
Update `android/app/build.gradle.kts` signing config.

#### 4. **Build Release APK/Bundle**
```bash
# For App Bundle (recommended)
flutter build appbundle --release

# For APK
flutter build apk --release --split-per-abi
```

## 📱 Play Store Console Requirements

### 🎨 App Store Assets (REQUIRED)

#### **App Icon**
- [x] Current: Available in multiple resolutions
- [ ] **ACTION NEEDED**: Verify follows Material Design guidelines

#### **Screenshots** (REQUIRED - CREATE THESE)
You need to create:
- **Phone screenshots**: 2-8 screenshots (1080x1920px or higher)
- **Tablet screenshots**: 1-8 screenshots (1200x1920px or higher)
- **Feature graphic**: 1024x500px (for Play Store listing)

#### **App Descriptions**

**Short Description (80 characters max):**
```
Track and manage your debts securely with biometric protection
```

**Full Description:**
```
Debt Tracker - Your Personal Finance Companion

Take control of your finances with Debt Tracker, a secure and lightweight app designed to help you manage and track all your debts in one place.

KEY FEATURES:
🔐 Biometric Security - Protect your financial data with fingerprint/face authentication
📊 Comprehensive Tracking - Monitor multiple debts with detailed transaction history
💰 Multi-Currency Support - Track debts in different currencies
📱 Clean Interface - Modern, intuitive design that's easy to use
💾 Private & Secure - All data stored locally on your device
📈 Visual Analytics - Clear summaries and insights into your financial status
🎯 Lightweight - Optimized for performance with minimal storage requirements

PRIVACY & SECURITY:
Your financial information never leaves your device. All data is stored locally using encrypted SQLite database with biometric protection for access.

PERFECT FOR:
✓ Personal debt management
✓ Tracking loans to friends and family
✓ Business debt monitoring
✓ Financial planning and budgeting

Download now and take the first step towards better financial management!

No registration required • No data collection • Complete privacy
```

### 🏪 Play Store Listing Requirements

#### **App Category**
- Primary: Finance
- Secondary: Personal Finance

#### **Content Rating**
- Target audience: Everyone
- Content: No sensitive content

#### **Pricing**
- Free with ads (AdMob integrated)

### 📋 Policy Requirements

#### **Privacy Policy** (REQUIRED)
You MUST create and host a privacy policy. Here's a template:

#### **Data Safety** (REQUIRED in Play Console)
Declare:
- ✅ No data collected or shared
- ✅ Data encrypted in transit and at rest
- ✅ Users can request data deletion
- ✅ Follows Families Policy

## 🚀 Submission Steps

### 1. **Google Play Console Setup**
1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details:
   - Name: "Debt Tracker"
   - Default language: English
   - Type: App
   - Free/Paid: Free

### 2. **App Content**
1. Upload screenshots
2. Upload feature graphic
3. Write app description
4. Set content rating
5. Select app category
6. Add privacy policy URL

### 3. **Release Management**
1. Create release
2. Upload app bundle (.aab file)
3. Add release notes
4. Choose release type (Internal testing → Production)

### 4. **Store Listing**
1. App icon ✅
2. Screenshots ❌ (NEED TO CREATE)
3. Feature graphic ❌ (NEED TO CREATE)
4. Descriptions ✅ (provided above)

### 5. **App Content Declarations**
1. Privacy Policy ❌ (NEED TO CREATE)
2. Data safety ✅ (No data collection)
3. Content rating ✅ (Everyone)
4. Target audience ✅ (All ages)

## ⚠️ Critical Actions Needed

1. **Create app signing keystore** (MUST DO FIRST)
2. **Take app screenshots** (2-8 phone screenshots minimum)
3. **Create feature graphic** (1024x500px)
4. **Create and host privacy policy**
5. **Update app signing configuration**
6. **Build release bundle**

## 📊 Recommended Screenshots

Capture these screens:
1. Home screen with debt list
2. Add transaction screen
3. Debt details view
4. Settings/preferences
5. Biometric authentication setup
6. Currency selection
7. Transaction history
8. Summary/analytics view

## 🎯 Release Notes Template

**Version 1.0.0**
```
🎉 Initial release of Debt Tracker!

✨ Features:
• Secure debt tracking with biometric authentication
• Multi-currency support
• Clean, intuitive interface
• Local data storage for complete privacy
• Comprehensive transaction history
• Visual debt summaries

🔐 Privacy focused - all data stays on your device
📱 Optimized for performance and minimal storage

Thank you for downloading Debt Tracker!
```

## ✅ Final Checklist Before Submission

- [ ] App signing keystore created and configured
- [ ] Release bundle built and tested
- [ ] Screenshots captured (minimum 2)
- [ ] Feature graphic created
- [ ] Privacy policy created and hosted
- [ ] App description finalized
- [ ] Content rating completed
- [ ] Data safety form filled
- [ ] Release notes written
- [ ] App tested on multiple devices

## 🔄 After Submission

1. **Review Process**: 1-3 days typically
2. **Be Ready for Updates**: Keep source code ready for quick fixes
3. **Monitor**: Check Play Console for any policy violations
4. **User Feedback**: Respond to user reviews promptly

Good luck with your app submission! 🚀 