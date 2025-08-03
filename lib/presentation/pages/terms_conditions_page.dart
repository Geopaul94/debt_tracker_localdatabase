import 'package:debt_tracker/presentation/widgets/ad_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions'),
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
                          Icons.description,
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
                          'Terms & Conditions',
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
                    'Welcome to Debt Tracker! These Terms and Conditions ("Terms") govern your use of the Debt Tracker mobile application ("Service") operated by Geo Paul ("us", "we", or "our").\n\nBy downloading, installing, or using our app, you agree to be bound by these Terms. If you disagree with any part of these terms, then you may not access the Service.',
                  ),

                  // App Description
                  _buildSection(
                    '1. Description of Service',
                    'Debt Tracker is a personal finance management application designed to help users track debts, loans, and financial transactions.\n\nKey features include:\n• Local data storage for privacy\n• Transaction tracking and management\n• Biometric authentication options\n• Premium features via ad viewing\n• Currency conversion support\n\nThe app is provided free of charge with optional premium features.',
                  ),

                  // User Responsibilities
                  _buildSection(
                    '2. User Responsibilities',
                    'By using our Service, you agree to:\n\n• Provide accurate financial information for your personal tracking\n• Use the app only for lawful purposes\n• Not attempt to reverse engineer or modify the app\n• Respect intellectual property rights\n• Not use the app to track illegal financial activities\n• Keep your device secure to protect your financial data\n• Not share your biometric authentication with others',
                  ),

                  // Data and Privacy
                  _buildSection(
                    '3. Data Storage and Privacy',
                    'Your financial data is stored locally on your device only. We do not have access to your personal financial information.\n\nYou acknowledge that:\n• You are responsible for backing up your data\n• Uninstalling the app will permanently delete all data\n• We cannot recover lost data from your device\n• All data remains under your complete control',
                  ),

                  // Premium Features
                  _buildSection(
                    '4. Premium Features and Advertising',
                    'The app offers premium features that can be unlocked by:\n• Watching rewarded video advertisements\n• Temporary 2-hour ad-free access\n\nRegarding advertisements:\n• Ads are provided by third-party networks (Google AdMob)\n• Ad content is controlled by ad networks, not by us\n• You can remove ads temporarily by watching rewarded ads\n• We are not responsible for ad network data collection practices',
                  ),

                  // Biometric Authentication
                  _buildSection(
                    '5. Biometric Authentication',
                    'If you choose to enable biometric authentication:\n\n• This feature uses your device\'s built-in security systems\n• We do not store or access your biometric data\n• You can disable this feature at any time in settings\n• You are responsible for managing device-level biometric settings\n• Authentication failures are handled by your device\'s OS',
                  ),

                  // Intellectual Property
                  _buildSection(
                    '6. Intellectual Property',
                    'The Debt Tracker app and its original content, features, and functionality are owned by Geo Paul and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.\n\nYou may not:\n• Copy, modify, or distribute the app\n• Reverse engineer the source code\n• Create derivative works\n• Use our trademarks without permission',
                  ),

                  // Disclaimers
                  _buildSection(
                    '7. Disclaimers and Limitations',
                    'IMPORTANT: This app is for personal financial tracking only and should not be considered as:\n\n• Professional financial advice\n• Legal advice regarding debts or loans\n• A substitute for professional accounting services\n• Investment guidance\n\nThe Service is provided "AS IS" and "AS AVAILABLE" without warranties of any kind. We do not guarantee that:\n• The app will be error-free or uninterrupted\n• Data will never be lost due to device issues\n• All features will work on every device\n• The app will meet all your specific needs',
                  ),

                  // Limitation of Liability
                  _buildSection(
                    '8. Limitation of Liability',
                    'To the maximum extent permitted by law, Geo Paul shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation:\n\n• Loss of financial data\n• Device malfunctions\n• Third-party ad network issues\n• Biometric authentication failures\n• Currency conversion inaccuracies\n\nOur total liability shall not exceed the amount you paid for the app (which is zero for the free version).',
                  ),

                  // Device Compatibility
                  _buildSection(
                    '9. Device Compatibility and Requirements',
                    'The app is designed for mobile devices running supported operating systems. You are responsible for ensuring:\n\n• Your device meets minimum system requirements\n• Your device has sufficient storage space\n• Your operating system is supported and updated\n• Biometric hardware is functional (if using authentication)\n\nWe may discontinue support for older operating system versions with reasonable notice.',
                  ),

                  // Termination
                  _buildSection(
                    '10. Termination',
                    'You may stop using our Service at any time by uninstalling the app from your device.\n\nWe may suspend or terminate your access to the Service if you violate these Terms, though enforcement is limited since the app works offline.\n\nUpon termination:\n• Your right to use the app ceases immediately\n• Local data remains on your device until you delete it\n• These Terms survive termination where applicable',
                  ),

                  // Updates and Changes
                  _buildSection(
                    '11. App Updates and Changes',
                    'We may update the app from time to time to:\n• Add new features\n• Fix bugs and improve performance\n• Enhance security\n• Update for new operating system versions\n\nUpdates may be:\n• Automatic through your device\'s app store\n• Optional, but recommended for security\n• Required for continued functionality\n\nWe reserve the right to modify or discontinue features with reasonable notice.',
                  ),

                  // Changes to Terms
                  _buildSection(
                    '12. Changes to Terms',
                    'We reserve the right to modify these Terms at any time. When we make changes:\n\n• We will update the "Effective Date" at the top\n• Significant changes will be communicated through the app\n• Continued use after changes constitutes acceptance\n• You should review these Terms periodically\n\nIf you disagree with updated Terms, you should stop using the Service.',
                  ),

                  // Governing Law
                  _buildSection(
                    '13. Governing Law and Disputes',
                    'These Terms shall be governed by and construed in accordance with the laws of [Your Jurisdiction], without regard to its conflict of law provisions.\n\nAny disputes arising from these Terms or the use of the Service shall be resolved through:\n• Good faith negotiation first\n• Binding arbitration if negotiation fails\n• Small claims court for eligible disputes\n\nYou waive any right to participate in class action lawsuits.',
                  ),

                  // Severability
                  _buildSection(
                    '14. Severability',
                    'If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary so that these Terms shall otherwise remain in full force and effect.',
                  ),

                  // Contact Information
                  _buildSection(
                    '15. Contact Information',
                    'If you have any questions about these Terms and Conditions, please contact us:\n\nEmail: geopaul.dev@gmail.com\nDeveloper: Geo Paul\n\nWe will respond to your inquiries promptly and work to resolve any concerns you may have about these Terms.',
                  ),

                  // Final Acknowledgment
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(top: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.amber[600],
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'By using Debt Tracker, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40.h), // Extra space before button
                ],
              ),
            ),
          ),
const AdBannerWidget(
        
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
                  offset: Offset(0, -2),
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
