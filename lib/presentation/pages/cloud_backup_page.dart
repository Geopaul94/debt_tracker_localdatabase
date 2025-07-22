import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/google_drive_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/auto_backup_service.dart';
import '../../injection/injection_container.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';

class CloudBackupPage extends StatefulWidget {
  const CloudBackupPage({Key? key}) : super(key: key);

  @override
  State<CloudBackupPage> createState() => _CloudBackupPageState();
}

class _CloudBackupPageState extends State<CloudBackupPage> {
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  List<BackupInfo> _availableBackups = [];
  DateTime? _lastBackupDate;
  bool _isAutoBackupEnabled = false;
  DateTime? _lastAutoBackupDate;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);

    await GoogleDriveService.instance.initialize();
    final isSignedIn = await GoogleDriveService.instance.isSignedIn();

    if (isSignedIn) {
      final userEmail = GoogleDriveService.instance.userEmail;
      final backups = await GoogleDriveService.instance.getAvailableBackups();
      final lastBackup = GoogleDriveService.instance.lastBackupDate;
      final isAutoBackupEnabled =
          await AutoBackupService.instance.isAutoBackupEnabled();
      final lastAutoBackup = AutoBackupService.instance.lastAutoBackupDate;

      setState(() {
        _isSignedIn = true;
        _userEmail = userEmail;
        _availableBackups = backups;
        _lastBackupDate = lastBackup;
        _isAutoBackupEnabled = isAutoBackupEnabled;
        _lastAutoBackupDate = lastAutoBackup;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    final success = await GoogleDriveService.instance.signIn();

    if (success) {
      await _checkSignInStatus();
      _showSuccessSnackBar('✅ Successfully signed in to Google Drive!');
    } else {
      _showErrorSnackBar('❌ Failed to sign in to Google Drive');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    await GoogleDriveService.instance.signOut();

    setState(() {
      _isSignedIn = false;
      _userEmail = null;
      _availableBackups = [];
      _lastBackupDate = null;
      _isLoading = false;
    });

    _showSuccessSnackBar('✅ Successfully signed out');
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    final success = await GoogleDriveService.instance.createBackup();

    if (success) {
      await _refreshBackups();
      _showSuccessSnackBar('✅ Backup created successfully!');
    } else {
      _showErrorSnackBar('❌ Failed to create backup');
    }

    setState(() => _isLoading = false);
  }



  Future<void> _restoreBackup(BackupInfo backup) async {
    // Show confirmation dialog
    final confirmed = await _showRestoreConfirmationDialog(backup);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await GoogleDriveService.instance.restoreFromBackup(
      backup.id,
    );

    if (success) {
      // Refresh transactions in the app
      context.read<TransactionBloc>().add(LoadTransactionsEvent());
      _showSuccessSnackBar('✅ Data restored successfully!');
    } else {
      _showErrorSnackBar('❌ Failed to restore data');
    }

    setState(() => _isLoading = false);
  }

  Future<bool> _showRestoreConfirmationDialog(BackupInfo backup) async {
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

  Future<void> _refreshBackups() async {
    if (!_isSignedIn) return;

    setState(() => _isLoading = true);

    final backups = await GoogleDriveService.instance.getAvailableBackups();
    final lastBackup = GoogleDriveService.instance.lastBackupDate;
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
        title: Text('☁️ Cloud Backup'),
        centerTitle: true,
        actions: [
          if (_isSignedIn)
            IconButton(icon: Icon(Icons.refresh), onPressed: _refreshBackups),
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
                    _buildAccountSection(),
                    SizedBox(height: 24.h),
                    if (_isSignedIn) ...[
                      _buildBackupSection(),
                      SizedBox(height: 24.h),
                      _buildBackupHistorySection(),
                    ],
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
                Icon(
                  Icons.account_circle,
                  color: Colors.teal[600],
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Google Account',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_isSignedIn) ...[
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
                            'Signed in as:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            _userEmail ?? 'Unknown',
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: Icon(Icons.logout),
                  label: Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Connect your Google account to backup your data to Google Drive.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _signIn,
                  icon: Icon(Icons.login),
                  label: Text('Sign In with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: Icon(Icons.cloud_upload),
                label: Text('Create Backup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            FutureBuilder<bool>(
              future: PremiumService.instance.isPremiumUnlocked(),
              builder: (context, snapshot) {
                final isPremium = snapshot.data ?? false;
                if (!isPremium) {
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue[600]),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Free users can backup/restore to Google Drive from day 1!',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.green[600]),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Premium users get unlimited backups without ads',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color:
                            _isAutoBackupEnabled
                                ? Colors.blue[50]
                                : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color:
                              _isAutoBackupEnabled
                                  ? Colors.blue[200]!
                                  : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAutoBackupEnabled
                                    ? Icons.backup
                                    : Icons.backup_outlined,
                                color:
                                    _isAutoBackupEnabled
                                        ? Colors.blue[600]
                                        : Colors.grey[600],
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Automatic Daily Backup',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _isAutoBackupEnabled
                                            ? Colors.blue[800]
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _isAutoBackupEnabled
                                          ? Colors.green[100]
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  _isAutoBackupEnabled ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _isAutoBackupEnabled
                                            ? Colors.green[700]
                                            : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_lastAutoBackupDate != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Last auto backup: ${_formatDate(_lastAutoBackupDate!)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                          SizedBox(height: 8.h),
                          Text(
                            _isAutoBackupEnabled
                                ? 'Your data is automatically backed up daily'
                                : 'Sign in to Google Drive to enable automatic backups',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  _isAutoBackupEnabled
                                      ? Colors.blue[700]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
                Spacer(),
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
                physics: NeverScrollableScrollPhysics(),
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

  Widget _buildBackupItem(BackupInfo backup) {
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
