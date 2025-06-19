# 📱 Google AdMob Setup Guide for Production

This guide will help you set up Google AdMob for your debt tracker app to start earning revenue.

## 🚀 **Step 1: Create AdMob Account**

1. Go to [Google AdMob](https://admob.google.com/)
2. Sign in with your Google account
3. Complete the account setup process
4. Add your app to AdMob

## 📋 **Step 2: Configure App Settings**

### **For Android:**
1. Add your Android app package name: `com.example.debit_tracker`
2. Get your **App ID** from AdMob console
3. Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_ACTUAL_APP_ID~YOUR_APP_ID"/>
```

### **For iOS:**
1. Add your iOS bundle identifier
2. Get your **App ID** from AdMob console  
3. Add to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-YOUR_ACTUAL_APP_ID~YOUR_APP_ID</string>
```

## 🎯 **Step 3: Create Ad Units**

Create these ad units in your AdMob dashboard:

### **1. Banner Ad Unit**
- Name: "Home Screen Banner"
- Type: Banner
- Size: 320x50 (Standard Banner)

### **2. Interstitial Ad Unit**  
- Name: "Transaction Complete Interstitial"
- Type: Interstitial
- Format: Display

### **3. Rewarded Ad Unit** (Optional)
- Name: "Premium Features Reward"
- Type: Rewarded
- Format: Video

## 🔧 **Step 4: Update Ad Unit IDs**

Replace the test IDs in `lib/core/services/ad_service.dart`:

```dart
// Replace these with your REAL Ad Unit IDs
static final String _bannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_UNIT_ID'     // Android
    : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_UNIT_ID';    // iOS

static final String _interstitialAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ID'   // Android  
    : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ID';  // iOS

static final String _rewardedAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_REWARDED_ID'       // Android
    : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_REWARDED_ID';      // iOS
```

## 💡 **Step 5: Monetization Strategy**

### **Current Implementation:**

1. **Banner Ads:**
   - Show at bottom of home screen
   - Show between transaction lists (every 6 items)

2. **Interstitial Ads:**
   - Show after every 3 transaction additions
   - Non-intrusive timing

3. **Future Enhancements:**
   - Rewarded ads for premium features
   - Native ads in transaction lists
   - Ad-free subscription option

## 📊 **Step 6: Revenue Optimization**

### **Ad Placement Best Practices:**
- ✅ Banner ads in natural breaks
- ✅ Interstitials after user actions
- ✅ Rewarded ads for value exchange
- ❌ Too many ads (poor UX)
- ❌ Ads during critical tasks

### **Expected Revenue:**
- **eCPM**: $1-5 (varies by location)
- **Monthly Revenue**: Depends on DAU
- **Optimization**: A/B test ad placements

## 🛡️ **Step 7: Privacy & Compliance**

### **GDPR/CCPA Compliance:**
```dart
// Add to RequestConfiguration
await MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(
    testDeviceIds: ['YOUR_TEST_DEVICE_ID'],
    tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
    tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
    maxAdContentRating: MaxAdContentRating.g, // General audience
  ),
);
```

### **Privacy Policy Requirements:**
Your app MUST have a privacy policy that mentions:
- Data collection by Google AdMob
- Use of advertising identifiers
- Third-party ad networks
- User consent mechanisms

## 🧪 **Step 8: Testing**

### **Before Production:**
1. Test with real ad units on physical devices
2. Verify ad loading and display
3. Check revenue tracking in AdMob console
4. Test on different screen sizes
5. Verify GDPR consent flow

### **Test Device Setup:**
```dart
// Add your device ID for testing
testDeviceIds: ['YOUR_DEVICE_ADVERTISING_ID'],
```

## 📈 **Step 9: Launch Checklist**

- [ ] AdMob account approved
- [ ] Real ad unit IDs implemented
- [ ] App IDs added to manifests
- [ ] Privacy policy published
- [ ] GDPR compliance implemented
- [ ] Testing completed on real devices
- [ ] Revenue tracking verified

## 💰 **Expected Monetization Timeline**

- **Week 1-2**: Setup and testing
- **Week 3-4**: Initial revenue generation
- **Month 2+**: Optimization and scaling
- **Month 3+**: Consider premium features

## ⚠️ **Important Notes**

1. **Don't click your own ads** - This violates AdMob policies
2. **Follow AdMob policies** - Risk of account suspension
3. **Monitor performance** - Use AdMob analytics
4. **User experience first** - Balance ads with UX
5. **Regular updates** - Keep ad SDK updated

## 🆘 **Troubleshooting**

### **Common Issues:**
- **Ads not showing**: Check internet, ad unit IDs
- **Low fill rate**: Try different ad sizes/types  
- **App crashes**: Update Google Mobile Ads SDK
- **Revenue issues**: Check AdMob dashboard for insights

### **Support Resources:**
- [AdMob Help Center](https://support.google.com/admob)
- [Flutter AdMob Documentation](https://developers.google.com/admob/flutter)
- AdMob Community Forums

---

**Ready to monetize your debt tracker app! 🚀💰** 