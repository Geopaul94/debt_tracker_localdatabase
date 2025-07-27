import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/google_drive_service.dart';
import '../../core/services/local_backup_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/backup_permission_service.dart';
import '../../injection/injection_container.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';

class HybridBackupPage extends StatefulWidget {
  const HybridBackupPage({Key? key}) : super(key: key);

  @override
  State<HybridBackupPage> createState() => _HybridBackupPageState();
}

class _HybridBackupPageState extends State<HybridBackupPage> {
  bool _isLoading = false;
  bool _isGoogleSignedIn = false;
  String? _userEmail;
  List<dynamic> _availableBackups = [];
  DateTime? _lastBackupDate;
  bool _isAutoBackupEnabled = false;
  DateTime? _lastAutoBackupDate;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);

    try {
      // Initialize services
      await LocalBackupService.instance.initialize();
      await GoogleDriveService.instance.initialize();

      // Check Google Drive sign-in status
      final isGoogleSignedIn = await GoogleDriveService.instance.isSignedIn();

      if (isGoogleSignedIn) {
        final userEmail = GoogleDriveService.instance.userEmail;
        final cloudBackups =
            await GoogleDriveService.instance.getAvailableBackups();
        final localBackups =
            await LocalBackupService.instance.getAvailableBackups();

        setState(() {
          _isGoogleSignedIn = true;
          _userEmail = userEmail;
          _availableBackups = [...localBackups, ...cloudBackups];
          _lastBackupDate = LocalBackupService.instance.lastBackupDate;
        });
      } else {
        // Only local backups available
        final localBackups =
            await LocalBackupService.instance.getAvailableBackups();
        setState(() {
          _isGoogleSignedIn = false;
          _userEmail = null;
          _availableBackups = localBackups;
          _lastBackupDate = LocalBackupService.instance.lastBackupDate;
        });
      }
    } catch (e) {
      // Fallback to local backup only
      final localBackups =
          await LocalBackupService.instance.getAvailableBackups();
      setState(() {
        _isGoogleSignedIn = false;
        _userEmail = null;
        _availableBackups = localBackups;
        _lastBackupDate = LocalBackupService.instance.lastBackupDate;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signInToGoogle() async {
    setState(() => _isLoading = true);

    try {
      final success = await GoogleDriveService.instance.signIn();
      if (success) {
        await _checkStatus();
        _showSuccessSnackBar('✅ Successfully signed in to Google Drive!');
      } else {
        _showErrorSnackBar('❌ Failed to sign in to Google Drive');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Error signing in to Google Drive');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      // Check backup permissions
      final canBackup =
          await BackupPermissionService.instance.canPerformManualBackup();

      if (!canBackup) {
        // Show ad to get backup permission
        final adShown = await BackupPermissionService.instance.showBackupAd();
        if (!adShown) {
          _showErrorSnackBar('❌ Please watch an ad to enable backup');
          setState(() => _isLoading = false);
          return;
        }
      }

      bool success = false;

      // Always create local backup
      final localSuccess = await LocalBackupService.instance.createBackup();
      if (localSuccess) {
        success = true;
        _showSuccessSnackBar('✅ Local backup created successfully!');
      }

      // Try cloud backup if signed in
      if (_isGoogleSignedIn) {
        try {
          final cloudSuccess = await GoogleDriveService.instance.createBackup();
          if (cloudSuccess) {
            success = true;
            _showSuccessSnackBar('✅ Cloud backup created successfully!');
          }
        } catch (e) {
          _showErrorSnackBar(
            '⚠️ Local backup succeeded, but cloud backup failed',
          );
        }
      }

      // Reset backup ad status after successful backup
      if (success) {
        await BackupPermissionService.instance.resetBackupAdStatus();
        await _checkStatus();
      }
    } catch (e) {
      _showErrorSnackBar('❌ Error creating backup: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _restoreBackup(dynamic backup) async {
    // Show confirmation dialog
    final confirmed = await _showRestoreConfirmationDialog(backup);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      // Check backup permissions
      final canRestore =
          await BackupPermissionService.instance.canPerformManualBackup();

      if (!canRestore) {
        // Show ad to get backup permission
        final adShown = await BackupPermissionService.instance.showBackupAd();
        if (!adShown) {
          _showErrorSnackBar('❌ Please watch an ad to enable restore');
          setState(() => _isLoading = false);
          return;
        }
      }

      bool success = false;

      // Determine backup type and restore
      if (backup.isLocal) {
        success = await LocalBackupService.instance.restoreFromBackup(
          backup.id,
        );
      } else {
        success = await GoogleDriveService.instance.restoreFromBackup(
          backup.id,
        );
      }

      if (success) {
        // Reset backup ad status after successful restore
        await BackupPermissionService.instance.resetBackupAdStatus();
        // Refresh transactions in the app
        context.read<TransactionBloc>().add(LoadTransactionsEvent());
        _showSuccessSnackBar('✅ Data restored successfully!');
      } else {
        _showErrorSnackBar('❌ Failed to restore data');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Error restoring data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<bool> _showRestoreConfirmationDialog(dynamic backup) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('🔄 Restore Backup'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Are you sure you want to restore from this backup?'),
                    SizedBox(height: 16.h),
                    Text(
                      '📅 Date: ${backup.formattedDate}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('📊 Size: ${backup.formattedSize}'),
                    Text(
                      '📍 Location: ${backup.isLocal ? "Local Device" : "Google Drive"}',
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange[600],
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'This will replace all your current data!',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(
                      'Restore',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💾 Smart Backup'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _checkStatus),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSection(),
                    SizedBox(height: 24.h),
                    _buildBackupSection(),
                    SizedBox(height: 24.h),
                    _buildBackupHistorySection(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBackup,
        icon: Icon(Icons.backup),
        label: Text('Create Backup'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.teal[600], size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Backup Status',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Local Backup Status
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Backup:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          '✅ Always Available',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Cloud Backup Status
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _isGoogleSignedIn ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color:
                      _isGoogleSignedIn
                          ? Colors.blue[200]!
                          : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGoogleSignedIn ? Icons.cloud_done : Icons.cloud_off,
                    color:
                        _isGoogleSignedIn
                            ? Colors.blue[600]
                            : Colors.orange[600],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud Backup:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                _isGoogleSignedIn
                                    ? Colors.blue[700]
                                    : Colors.orange[700],
                          ),
                        ),
                        Text(
                          _isGoogleSignedIn
                              ? '✅ Connected as ${_userEmail ?? 'Unknown'}'
                              : '⏳ Sign in to enable',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color:
                                _isGoogleSignedIn
                                    ? Colors.blue[800]
                                    : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isGoogleSignedIn)
                    TextButton(
                      onPressed: _signInToGoogle,
                      child: Text(
                        'Sign In',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: Colors.blue[600], size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Backup Your Data',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Manual Backup Status
            FutureBuilder<bool>(
              future: PremiumService.instance.isPremiumUnlocked(),
              builder: (context, premiumSnapshot) {
                return FutureBuilder<bool>(
                  future:
                      BackupPermissionService.instance.canPerformManualBackup(),
                  builder: (context, permissionSnapshot) {
                    final isPremium = premiumSnapshot.data ?? false;
                    final canBackup = permissionSnapshot.data ?? false;

                    return Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: canBackup ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color:
                              canBackup
                                  ? Colors.green[200]!
                                  : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            canBackup ? Icons.check_circle : Icons.warning,
                            color:
                                canBackup
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manual Backup:',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        canBackup
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                  ),
                                ),
                                Text(
                                  isPremium
                                      ? '✅ Premium - Always Available'
                                      : canBackup
                                      ? '✅ Ad Watched - Available'
                                      : '⏳ Watch Ad to Enable',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        canBackup
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            SizedBox(height: 16.h),

            if (_lastBackupDate != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue[600]),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last backup:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            _formatDate(_lastBackupDate!),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            Text(
              'Tap the backup button below to create a backup. Premium users can backup anytime, others need to watch an ad.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupHistorySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple[600], size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Backup History',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            if (_availableBackups.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.backup_outlined,
                        color: Colors.grey[400],
                        size: 48.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No backups yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Create your first backup to see it here',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _availableBackups.length,
                itemBuilder: (context, index) {
                  final backup = _availableBackups[index];
                  return ListTile(
                    leading: Icon(
                      backup.isLocal ? Icons.phone_android : Icons.cloud,
                      color:
                          backup.isLocal ? Colors.green[600] : Colors.blue[600],
                    ),
                    title: Text(backup.name),
                    subtitle: Text(
                      '${backup.formattedDate} • ${backup.formattedSize}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.restore, color: Colors.orange[600]),
                      onPressed: () => _restoreBackup(backup),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final backupDate = DateTime(date.year, date.month, date.day);

    if (backupDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (backupDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
