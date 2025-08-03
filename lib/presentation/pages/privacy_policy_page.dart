import 'package:debt_tracker/presentation/widgets/ad_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App info header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.teal[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 48.sp,
                          color: Colors.teal[600],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Debt Tracker',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.teal[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Effective date
                  Text(
                    'Effective Date: June 28, 2025',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Introduction
                  _buildSection(
                    'Introduction',
                    'Geo Paul built the Debt Tracker app as a free app. This SERVICE is provided by Geo Paul at no cost and is intended for use as is.\n\nThis page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decides to use our Service.',
                  ),

                  // Information Collection
                  _buildSection(
                    '1. Information Collection and Use',
                    'We do NOT collect, store, or share any personal or sensitive user data.\n\nAll data you enter (such as amounts owed or borrowed) is stored locally on your device and is not transmitted to any server or third party.\n\nYour financial information remains completely private and under your control.',
                  ),

                  // Local Storage
                  _buildSection(
                    '2. Local Data Storage',
                    'All your transactions, debts, and financial data are stored exclusively on your device using local database technology.\n\nThis means:\n• Your data never leaves your device\n• No internet connection is required for core functionality\n• We cannot access your financial information\n• Your privacy is fully protected',
                  ),

                  // Authentication
                  _buildSection(
                    '3. Biometric Authentication',
                    'If you choose to enable biometric authentication (Face ID, Touch ID, or fingerprint), this feature is handled entirely by your device\'s secure authentication system.\n\nWe do not store or have access to your biometric data. All authentication is processed locally on your device.',
                  ),

                  // Advertising
                  _buildSection(
                    '4. Advertising',
                    'The app displays advertisements provided by third-party ad networks such as Google AdMob.\n\nThese third-party services may collect certain information automatically, including but not limited to:\n• Your device\'s IP address\n• Device ID and advertising ID\n• App usage statistics\n• Location data (if permitted)\n\nThis information is used for showing relevant advertisements. Please refer to Google\'s Privacy Policy (https://policies.google.com/privacy) for more information on how user data is handled by their ad services.',
                  ),

                  // Premium Features
                  _buildSection(
                    '5. Premium Features',
                    'When you watch rewarded ads to unlock premium features or remove ads temporarily, this interaction is handled by our ad network partners.\n\nNo personal financial data from your debt tracking is shared during these ad interactions.',
                  ),

                  // Data Security
                  _buildSection(
                    '6. Data Security',
                    'Since the app does not collect or store user data on external servers, your data remains secure on your device.\n\nWe recommend you:\n• Protect your device with a screen lock\n• Use biometric authentication when available\n• Keep your device software updated\n• Regularly backup your device to prevent data loss',
                  ),

                  // Permissions
                  _buildSection(
                    '7. App Permissions',
                    'The app may request the following permissions:\n\n• Biometric/Fingerprint: For secure app access (optional)\n• Storage: For local data storage\n• Network: For displaying advertisements\n\nAll permissions are used solely for their stated purpose and do not compromise your privacy.',
                  ),

                  // Data Retention
                  _buildSection(
                    '8. Data Retention',
                    'Since all data is stored locally on your device, you have full control over data retention.\n\nYou can:\n• Delete individual transactions\n• Clear all app data through device settings\n• Uninstall the app to remove all data\n\nWe do not retain any of your data on external servers.',
                  ),

                  // Children's Privacy
                  _buildSection(
                    '9. Children\'s Privacy',
                    'Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.\n\nIf you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we can take necessary actions.',
                  ),

                  // Changes to Policy
                  _buildSection(
                    '10. Changes to This Privacy Policy',
                    'We may update our Privacy Policy from time to time. You are advised to review this page periodically for any changes.\n\nWe will notify you of any significant changes by posting the new Privacy Policy within the app and updating the effective date above.',
                  ),

                  // Contact Information
                  _buildSection(
                    '11. Contact Us',
                    'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.\n\nEmail: geopaul.dev@gmail.com\n\nWe are committed to protecting your privacy and will respond to your inquiries promptly.',
                  ),
                  const AdBannerWidget(
        
            ),

                  SizedBox(height: 40.h), // Extra space before button
                ],
              ),
            ),
          ),

          // Bottom close button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              child: Text(
                'Close',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
