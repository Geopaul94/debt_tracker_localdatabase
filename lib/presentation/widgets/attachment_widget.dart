import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/attachment_entity.dart';

class AttachmentWidget extends StatelessWidget {
  final List<AttachmentEntity> attachments;
  final VoidCallback onAddAttachment;
  final VoidCallback onTakePhoto;
  final Function(AttachmentEntity) onRemoveAttachment;

  const AttachmentWidget({
    super.key,
    required this.attachments,
    required this.onAddAttachment,
    required this.onTakePhoto,
    required this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attachment buttons row
        Row(
          children: [
            // Add attachment button
            Expanded(
              child: InkWell(
                onTap: onAddAttachment,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_file, color: Colors.grey[600], size: 20.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Attach File',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Camera button
            InkWell(
              onTap: onTakePhoto,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[300]!, width: 1.5),
                  borderRadius: BorderRadius.circular(8.r),
                  color: Colors.blue[50],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue[600], size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Optional text below buttons
        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(
            'Attach receipts, bills, or documents (Optional)',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        // Show attached files
        if (attachments.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            'Attached Files (${attachments.length})',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          ...attachments.map((attachment) => _buildAttachmentItem(attachment)),
        ],
      ],
    );
  }

  Widget _buildAttachmentItem(AttachmentEntity attachment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          // File type icon
          _buildFileIcon(attachment),
          SizedBox(width: 12.w),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  attachment.formattedFileSize,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => onRemoveAttachment(attachment),
            icon: Icon(Icons.close, color: Colors.red[600], size: 20.sp),
            padding: EdgeInsets.all(4.w),
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(AttachmentEntity attachment) {
    IconData iconData;
    Color iconColor;

    if (attachment.isImage) {
      iconData = Icons.image;
      iconColor = Colors.green[600]!;
    } else if (attachment.isPdf) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red[600]!;
    } else {
      iconData = Icons.attach_file;
      iconColor = Colors.blue[600]!;
    }

    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(iconData, color: iconColor, size: 24.sp),
    );
  }
}
