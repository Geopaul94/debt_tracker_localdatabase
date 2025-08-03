import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UpdateNotificationDialog extends StatelessWidget {
  final String version;
  final List<String> updates;
  final VoidCallback onClose;

  const UpdateNotificationDialog({
    super.key,
    required this.version,
    required this.updates,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            // mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: Colors.teal[600],
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Icon(
                  Icons.system_update,
                  color: Colors.white,
                  size: 30.sp,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Title
              Text(
                'App Updated! 🎉',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              
              SizedBox(height: 8.h),
              
              // Version
              Text(
                'Version $version',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.teal[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // Updates list
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s New:',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...updates.map((update) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 6.h, right: 8.w),
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: Colors.teal[600],
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              update,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Close button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Got it! 👍',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 