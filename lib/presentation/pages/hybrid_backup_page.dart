import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/local_backup_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/backup_permission_service.dart';
import '../../core/services/auto_backup_service.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';

class HybridBackupPage extends StatefulWidget {
  const HybridBackupPage({super.key});

  @override
  State<HybridBackupPage> createState() => _HybridBackupPageState();
}

class _HybridBackupPageState extends State<HybridBackupPage> {
  bool _isLoading = false;
  bool _isSignedIn = false;
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
      // Initialize local backup service
      await LocalBackupService.instance.initialize();

      // Get local backups
      final localBackups =
          await LocalBackupService.instance.getAvailableBackups();
      final lastBackup = LocalBackupService.instance.lastBackupDate;
      final isAutoBackupEnabled =
          await AutoBackupService.instance.isAutoBackupEnabled();
      final lastAutoBackup = AutoBackupService.instance.lastAutoBackupDate;

      setState(() {
        _isSignedIn = true;
        _availableBackups = localBackups;
        _lastBackupDate = lastBackup;
        _isAutoBackupEnabled = isAutoBackupEnabled;
        _lastAutoBackupDate = lastAutoBackup;
      });
    } catch (e) {
      // Fallback to empty state
      setState(() {
        _isSignedIn = false;
        _availableBackups = [];
        _lastBackupDate = null;
        _isAutoBackupEnabled = false;
        _lastAutoBackupDate = null;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    final success = await LocalBackupService.instance.signIn();

    if (success) {
      await _checkStatus();
      _showSuccessSnackBar('✅ Local backup service ready!');
    } else {
      _showErrorSnackBar('❌ Failed to initialize local backup');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    await LocalBackupService.instance.signOut();

    setState(() {
      _isSignedIn = false;
      _availableBackups = [];
      _lastBackupDate = null;
      _isLoading = false;
    });

    _showSuccessSnackBar('✅ Local backup service disabled');
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      // Check if user can perform manual backup
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

      // Perform the backup
      final success = await LocalBackupService.instance.createBackup();

      if (success) {
        // Reset backup ad status after successful backup
        await BackupPermissionService.instance.resetBackupAdStatus();
        await _refreshBackups();
        _showSuccessSnackBar('✅ Backup created successfully!');
      } else {
        _showErrorSnackBar('❌ Failed to create backup');
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

      // Restore from local backup
      success = await LocalBackupService.instance.restoreFromBackup(backup.id);

      if (success) {
        // Reset backup ad status after successful restore
        await BackupPermissionService.instance.resetBackupAdStatus();
        // Refresh transactions in the app
        context.read<TransactionBloc>().add(const LoadTransactionsEvent());
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
                title: const Text('🔄 Restore Backup'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Are you sure you want to restore from this backup?'),
                    SizedBox(height: 16.h),
                    Text(
                      '📅 Date: ${backup.formattedDate}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('📊 Size: ${backup.formattedSize}'),
                    const Text('📍 Location: Local Device'),
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
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Restore',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _refreshBackups() async {
    if (!_isSignedIn) return;

    setState(() => _isLoading = true);

    final backups = await LocalBackupService.instance.getAvailableBackups();
    final lastBackup = LocalBackupService.instance.lastBackupDate;
    final isAutoBackupEnabled =
        await AutoBackupService.instance.isAutoBackupEnabled();
    final lastAutoBackup = AutoBackupService.instance.lastAutoBackupDate;

    setState(() {
      _availableBackups = backups;
      _lastBackupDate = lastBackup;
      _isAutoBackupEnabled = isAutoBackupEnabled;
      _lastAutoBackupDate = lastAutoBackup;
      _isLoading = false;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💾 Local Backup'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountSection(),
                    SizedBox(height: 24.h),
                    _buildBackupSection(),
                    SizedBox(height: 24.h),
                    _buildBackupHistorySection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildAccountSection() {
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
                  'Local Backup',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
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
                          'Backup Status:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          'Local Device Storage',
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
            SizedBox(height: 16.h),
            Text(
              'Your data is backed up locally on your device. Backups are stored securely and automatically cleaned up after 30 days.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
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

            // Auto Backup Status
            FutureBuilder<DateTime?>(
              future: Future.value(
                BackupPermissionService.instance.lastAutoBackupDate,
              ),
              builder: (context, snapshot) {
                final lastAutoBackup = snapshot.data;
                final nextAutoBackup =
                    BackupPermissionService.instance.nextAutoBackupDate;

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.purple[600]),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto Backup (Every 4 days):',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.purple[700],
                              ),
                            ),
                            if (lastAutoBackup != null) ...[
                              Text(
                                'Last: ${_formatDate(lastAutoBackup)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                              if (nextAutoBackup != null)
                                Text(
                                  'Next: ${_formatDate(nextAutoBackup)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.purple[600],
                                  ),
                                ),
                            ] else ...[
                              Text(
                                'No previous auto backup',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
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
                            'Last manual backup:',
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Create Backup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
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
                const Spacer(),
                Text(
                  '${_availableBackups.length} backups',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_availableBackups.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey[400]),
                    SizedBox(height: 8.h),
                    Text(
                      'No backups available',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableBackups.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final backup = _availableBackups[index];
                  return _buildBackupItem(backup);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(dynamic backup) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(Icons.backup, color: Colors.purple[600], size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.formattedDate,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  backup.formattedSize,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _restoreBackup(backup),
            icon: Icon(Icons.download, color: Colors.green[600]),
            tooltip: 'Restore this backup',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
