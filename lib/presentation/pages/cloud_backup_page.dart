// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../core/services/local_backup_service.dart';
// import '../../core/services/premium_service.dart';
// import '../../core/services/auto_backup_service.dart';
// import '../../core/services/backup_permission_service.dart';
// import '../bloc/transacton_bloc/transaction_bloc.dart';
// import '../bloc/transacton_bloc/transaction_event.dart';

// class CloudBackupPage extends StatefulWidget {
//   const CloudBackupPage({Key? key}) : super(key: key);

//   @override
//   State<CloudBackupPage> createState() => _CloudBackupPageState();
// }

// class _CloudBackupPageState extends State<CloudBackupPage> {
//   bool _isLoading = false;
//   bool _isSignedIn = false;
//   String? _userEmail;
//   List<BackupInfo> _availableBackups = [];
//   DateTime? _lastBackupDate;
//   bool _isAutoBackupEnabled = false;
//   DateTime? _lastAutoBackupDate;

//   @override
//   void initState() {
//     super.initState();
//     _checkSignInStatus();
//   }

//   Future<void> _checkSignInStatus() async {
//     setState(() => _isLoading = true);

//     await LocalBackupService.instance.initialize();
//     final isSignedIn = await LocalBackupService.instance.isSignedIn();

//     if (isSignedIn) {
//       final userEmail = LocalBackupService.instance.userEmail;
//       final backups = await LocalBackupService.instance.getAvailableBackups();
//       final lastBackup = LocalBackupService.instance.lastBackupDate;
//       final isAutoBackupEnabled =
//           await AutoBackupService.instance.isAutoBackupEnabled();
//       final lastAutoBackup = AutoBackupService.instance.lastAutoBackupDate;

//       setState(() {
//         _isSignedIn = true;
//         _userEmail = userEmail;
//         _availableBackups = backups;
//         _lastBackupDate = lastBackup;
//         _isAutoBackupEnabled = isAutoBackupEnabled;
//         _lastAutoBackupDate = lastAutoBackup;
//       });
//     }

//     setState(() => _isLoading = false);
//   }

//   Future<void> _signIn() async {
//     setState(() => _isLoading = true);

//     final success = await LocalBackupService.instance.signIn();

//     if (success) {
//       await _checkSignInStatus();
//       _showSuccessSnackBar('✅ Local backup service ready!');
//     } else {
//       _showErrorSnackBar('❌ Failed to initialize local backup');
//     }

//     setState(() => _isLoading = false);
//   }

//   Future<void> _signOut() async {
//     setState(() => _isLoading = true);

//     await LocalBackupService.instance.signOut();

//     setState(() {
//       _isSignedIn = false;
//       _userEmail = null;
//       _availableBackups = [];
//       _lastBackupDate = null;
//       _isLoading = false;
//     });

//     _showSuccessSnackBar('✅ Local backup service disabled');
//   }

//   Future<void> _createBackup() async {
//     setState(() => _isLoading = true);

//     try {
//       // Check if user can perform manual backup
//       final canBackup =
//           await BackupPermissionService.instance.canPerformManualBackup();

//       if (!canBackup) {
//         // Show ad to get backup permission
//         final adShown = await BackupPermissionService.instance.showBackupAd();
//         if (!adShown) {
//           _showErrorSnackBar('❌ Please watch an ad to enable backup');
//           setState(() => _isLoading = false);
//           return;
//         }
//       }

//       // Perform the backup
//       final success = await LocalBackupService.instance.createBackup();

//       if (success) {
//         // Reset backup ad status after successful backup
//         await BackupPermissionService.instance.resetBackupAdStatus();
//         await _refreshBackups();
//         _showSuccessSnackBar('✅ Backup created successfully!');
//       } else {
//         _showErrorSnackBar('❌ Failed to create backup');
//       }
//     } catch (e) {
//       _showErrorSnackBar('❌ Error creating backup: $e');
//     }

//     setState(() => _isLoading = false);
//   }

//   Future<void> _restoreBackup(BackupInfo backup) async {
//     // Show confirmation dialog
//     final confirmed = await _showRestoreConfirmationDialog(backup);
//     if (!confirmed) return;

//     setState(() => _isLoading = true);

//     try {
//       // Check if user can perform manual backup (same permission for restore)
//       final canRestore =
//           await BackupPermissionService.instance.canPerformManualBackup();

//       if (!canRestore) {
//         // Show ad to get backup permission
//         final adShown = await BackupPermissionService.instance.showBackupAd();
//         if (!adShown) {
//           _showErrorSnackBar('❌ Please watch an ad to enable restore');
//           setState(() => _isLoading = false);
//           return;
//         }
//       }

//       // Perform the restore
//       final success = await LocalBackupService.instance.restoreFromBackup(
//         backup.id,
//       );

//       if (success) {
//         // Reset backup ad status after successful restore
//         await BackupPermissionService.instance.resetBackupAdStatus();
//         // Refresh transactions in the app
//         context.read<TransactionBloc>().add(LoadTransactionsEvent());
//         _showSuccessSnackBar('✅ Data restored successfully!');
//       } else {
//         _showErrorSnackBar('❌ Failed to restore data');
//       }
//     } catch (e) {
//       _showErrorSnackBar('❌ Error restoring data: $e');
//     }

//     setState(() => _isLoading = false);
//   }

//   Future<bool> _showRestoreConfirmationDialog(BackupInfo backup) async {
//     return await showDialog<bool>(
//           context: context,
//           builder:
//               (context) => AlertDialog(
//                 title: Text('🔄 Restore Backup'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Are you sure you want to restore from this backup?'),
//                     SizedBox(height: 16.h),
//                     Text(
//                       '📅 Date: ${backup.formattedDate}',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text('📊 Size: ${backup.formattedSize}'),
//                     SizedBox(height: 16.h),
//                     Container(
//                       padding: EdgeInsets.all(12.w),
//                       decoration: BoxDecoration(
//                         color: Colors.orange[50],
//                         borderRadius: BorderRadius.circular(8.r),
//                         border: Border.all(color: Colors.orange[200]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.warning_amber_rounded,
//                             color: Colors.orange[600],
//                           ),
//                           SizedBox(width: 8.w),
//                           Expanded(
//                             child: Text(
//                               'This will replace all your current data!',
//                               style: TextStyle(color: Colors.orange[700]),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(false),
//                     child: Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => Navigator.of(context).pop(true),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                     ),
//                     child: Text(
//                       'Restore',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//         ) ??
//         false;
//   }

//   Future<void> _refreshBackups() async {
//     if (!_isSignedIn) return;

//     setState(() => _isLoading = true);

//     final backups = await LocalBackupService.instance.getAvailableBackups();
//     final lastBackup = LocalBackupService.instance.lastBackupDate;
//     final isAutoBackupEnabled =
//         await AutoBackupService.instance.isAutoBackupEnabled();
//     final lastAutoBackup = AutoBackupService.instance.lastAutoBackupDate;

//     setState(() {
//       _availableBackups = backups;
//       _lastBackupDate = lastBackup;
//       _isAutoBackupEnabled = isAutoBackupEnabled;
//       _lastAutoBackupDate = lastAutoBackup;
//       _isLoading = false;
//     });
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('💾 Local Backup'), centerTitle: true),
//       body:
//           _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: EdgeInsets.all(16.w),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildAccountSection(),
//                     SizedBox(height: 24.h),
//                     _buildBackupSection(),
//                     SizedBox(height: 24.h),
//                     _buildBackupHistorySection(),
//                   ],
//                 ),
//               ),
//     );
//   }

//   Widget _buildAccountSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.storage, color: Colors.teal[600], size: 24.sp),
//                 SizedBox(width: 12.w),
//                 Text(
//                   'Local Backup',
//                   style: TextStyle(
//                     fontSize: 18.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.h),
//             Container(
//               padding: EdgeInsets.all(12.w),
//               decoration: BoxDecoration(
//                 color: Colors.green[50],
//                 borderRadius: BorderRadius.circular(8.r),
//                 border: Border.all(color: Colors.green[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green[600]),
//                   SizedBox(width: 12.w),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Backup Status:',
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             color: Colors.green[700],
//                           ),
//                         ),
//                         Text(
//                           'Local Device Storage',
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green[800],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16.h),
//             Text(
//               'Your data is backed up locally on your device. Backups are stored securely and automatically cleaned up after 30 days.',
//               style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBackupSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.backup, color: Colors.blue[600], size: 24.sp),
//                 SizedBox(width: 12.w),
//                 Text(
//                   'Backup Your Data',
//                   style: TextStyle(
//                     fontSize: 18.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.h),

//             // Manual Backup Status
//             FutureBuilder<bool>(
//               future: PremiumService.instance.isPremiumUnlocked(),
//               builder: (context, premiumSnapshot) {
//                 return FutureBuilder<bool>(
//                   future:
//                       BackupPermissionService.instance.canPerformManualBackup(),
//                   builder: (context, permissionSnapshot) {
//                     final isPremium = premiumSnapshot.data ?? false;
//                     final canBackup = permissionSnapshot.data ?? false;

//                     return Container(
//                       padding: EdgeInsets.all(12.w),
//                       decoration: BoxDecoration(
//                         color: canBackup ? Colors.green[50] : Colors.orange[50],
//                         borderRadius: BorderRadius.circular(8.r),
//                         border: Border.all(
//                           color:
//                               canBackup
//                                   ? Colors.green[200]!
//                                   : Colors.orange[200]!,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             canBackup ? Icons.check_circle : Icons.warning,
//                             color:
//                                 canBackup
//                                     ? Colors.green[600]
//                                     : Colors.orange[600],
//                           ),
//                           SizedBox(width: 12.w),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Manual Backup:',
//                                   style: TextStyle(
//                                     fontSize: 12.sp,
//                                     color:
//                                         canBackup
//                                             ? Colors.green[700]
//                                             : Colors.orange[700],
//                                   ),
//                                 ),
//                                 Text(
//                                   isPremium
//                                       ? '✅ Premium - Always Available'
//                                       : canBackup
//                                       ? '✅ Ad Watched - Available'
//                                       : '⏳ Watch Ad to Enable',
//                                   style: TextStyle(
//                                     fontSize: 14.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color:
//                                         canBackup
//                                             ? Colors.green[800]
//                                             : Colors.orange[800],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),

//             SizedBox(height: 16.h),

//             // Auto Backup Status
//             FutureBuilder<DateTime?>(
//               future: Future.value(
//                 BackupPermissionService.instance.lastAutoBackupDate,
//               ),
//               builder: (context, snapshot) {
//                 final lastAutoBackup = snapshot.data;
//                 final nextAutoBackup =
//                     BackupPermissionService.instance.nextAutoBackupDate;

//                 return Container(
//                   padding: EdgeInsets.all(12.w),
//                   decoration: BoxDecoration(
//                     color: Colors.purple[50],
//                     borderRadius: BorderRadius.circular(8.r),
//                     border: Border.all(color: Colors.purple[200]!),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.schedule, color: Colors.purple[600]),
//                       SizedBox(width: 12.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Auto Backup (Every 4 days):',
//                               style: TextStyle(
//                                 fontSize: 12.sp,
//                                 color: Colors.purple[700],
//                               ),
//                             ),
//                             if (lastAutoBackup != null) ...[
//                               Text(
//                                 'Last: ${_formatDate(lastAutoBackup)}',
//                                 style: TextStyle(
//                                   fontSize: 14.sp,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.purple[800],
//                                 ),
//                               ),
//                               if (nextAutoBackup != null)
//                                 Text(
//                                   'Next: ${_formatDate(nextAutoBackup)}',
//                                   style: TextStyle(
//                                     fontSize: 12.sp,
//                                     color: Colors.purple[600],
//                                   ),
//                                 ),
//                             ] else ...[
//                               Text(
//                                 'No previous auto backup',
//                                 style: TextStyle(
//                                   fontSize: 14.sp,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.purple[800],
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),

//             SizedBox(height: 16.h),

//             if (_lastBackupDate != null) ...[
//               Container(
//                 padding: EdgeInsets.all(12.w),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(8.r),
//                   border: Border.all(color: Colors.blue[200]!),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.schedule, color: Colors.blue[600]),
//                     SizedBox(width: 12.w),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Last manual backup:',
//                             style: TextStyle(
//                               fontSize: 12.sp,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                           Text(
//                             _formatDate(_lastBackupDate!),
//                             style: TextStyle(
//                               fontSize: 14.sp,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[800],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 16.h),
//             ],

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: _createBackup,
//                 icon: Icon(Icons.backup),
//                 label: Text('Create Backup'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[600],
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: 12.h),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBackupHistorySection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.history, color: Colors.purple[600], size: 24.sp),
//                 SizedBox(width: 12.w),
//                 Text(
//                   'Backup History',
//                   style: TextStyle(
//                     fontSize: 18.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Spacer(),
//                 Text(
//                   '${_availableBackups.length} backups',
//                   style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.h),
//             if (_availableBackups.isEmpty) ...[
//               Center(
//                 child: Column(
//                   children: [
//                     Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey[400]),
//                     SizedBox(height: 8.h),
//                     Text(
//                       'No backups available',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ] else ...[
//               ListView.separated(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: _availableBackups.length,
//                 separatorBuilder: (context, index) => SizedBox(height: 8.h),
//                 itemBuilder: (context, index) {
//                   final backup = _availableBackups[index];
//                   return _buildBackupItem(backup);
//                 },
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBackupItem(BackupInfo backup) {
//     return Container(
//       padding: EdgeInsets.all(12.w),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(8.r),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8.w),
//             decoration: BoxDecoration(
//               color: Colors.purple[100],
//               borderRadius: BorderRadius.circular(6.r),
//             ),
//             child: Icon(Icons.backup, color: Colors.purple[600], size: 20.sp),
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   backup.formattedDate,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   backup.formattedSize,
//                   style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: () => _restoreBackup(backup),
//             icon: Icon(Icons.download, color: Colors.green[600]),
//             tooltip: 'Restore this backup',
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }



// imports unchanged...
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/backup_permission_service.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';

class BackupInfo {
  final String id;
  final String formattedDate;
  final String formattedSize;

  BackupInfo({
    required this.id,
    required this.formattedDate,
    required this.formattedSize,
  });
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() => _client.close();
}

class CloudBackupPage extends StatefulWidget {
  const CloudBackupPage({Key? key}) : super(key: key);

  @override
  State<CloudBackupPage> createState() => _CloudBackupPageState();
}

class _CloudBackupPageState extends State<CloudBackupPage> {
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _userEmail;
  List<BackupInfo> _availableDriveBackups = [];
  late Database _db;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
  );
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _initDb();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
          _isSignedIn = account != null;
          _userEmail = account?.email;
        });
        if (_isSignedIn) _refreshDriveBackups();
      }
    });
    _checkSignInStatus();
  }

  Future<void> _initDb() async {
    final dbPath = path.join(await getDatabasesPath(), 'transactions.db');
    _db = await openDatabase(dbPath, version: 1);
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Sign-in check failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.disconnect().catchError((_) {});
      final account = await _googleSignIn.signIn();
      if (account != null && mounted) {
        _showSuccessSnackBar('✅ Signed in as ${account.email}');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (e.toString().contains('network_error') ||
          e.toString().contains('sign_in_canceled')) {
        _showErrorSnackBar('❌ Sign-in was cancelled or network error occurred');
      } else if (e.toString().contains('developer_error')) {
        _showErrorSnackBar(
          '❌ Google Sign-In not configured. Please check setup guide.',
        );
      } else {
        _showErrorSnackBar('❌ Sign-in failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signOut();
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _userEmail = null;
          _currentUser = null;
          _availableDriveBackups.clear();
        });
        _showSuccessSnackBar('✅ Signed out successfully');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Sign-out failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) {
      _showErrorSnackBar('Please sign in to Google first');
      return null;
    }
    try {
      final headers = await _currentUser!.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      _showErrorSnackBar('Authentication failed: $e');
      return null;
    }
  }

  Future<void> _createDriveBackup() async {
    setState(() => _isLoading = true);
    try {
      final canBackup =
          await BackupPermissionService.instance.canPerformManualBackup();
      if (!canBackup &&
          !await BackupPermissionService.instance.showBackupAd()) {
        _showErrorSnackBar('❌ Please watch an ad to enable backup');
        return;
      }

      final api = await _getDriveApi();
      if (api == null) return;

      final data = await _db.query('Transactions');
      if (data.isEmpty) {
        _showErrorSnackBar('No transactions to backup');
        return;
      }

      final content = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'transactions_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path.join(tempDir.path, fileName));
      await file.writeAsString(content);

      final driveFile =
          drive.File()
            ..name = fileName
            ..mimeType = 'application/json';
      final media = drive.Media(file.openRead(), file.lengthSync());
      await api.files.create(driveFile, uploadMedia: media);

      await BackupPermissionService.instance.resetBackupAdStatus();
      await _refreshDriveBackups();
      _showSuccessSnackBar('✅ Google Drive backup created successfully!');
    } catch (e) {
      _showErrorSnackBar('❌ Drive backup failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreDriveBackup(BackupInfo backup) async {
    final confirmed = await _showRestoreConfirmationDialog(backup);
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      final canRestore =
          await BackupPermissionService.instance.canPerformManualBackup();
      if (!canRestore &&
          !await BackupPermissionService.instance.showBackupAd()) {
        _showErrorSnackBar('❌ Please watch an ad to enable restore');
        return;
      }

      final api = await _getDriveApi();
      if (api == null) return;

      final media =
          await api.files.get(
                backup.id,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'temp_backup.json'));
      final sink = tempFile.openWrite();
      await for (var chunk in media.stream) {
        sink.add(chunk);
      }
      await sink.close();

      final content = await tempFile.readAsString();
      final data = jsonDecode(content) as List<dynamic>;

      await _db.delete('Transactions');
      for (var item in data) {
        await _db.insert('Transactions', Map<String, dynamic>.from(item));
      }

      context.read<TransactionBloc>().add(LoadTransactionsEvent());
      await BackupPermissionService.instance.resetBackupAdStatus();
      _showSuccessSnackBar('✅ Google Drive data restored successfully!');
    } catch (e) {
      _showErrorSnackBar('❌ Drive restore failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDriveBackups() async {
    if (!_isSignedIn) return;

    setState(() => _isLoading = true);
    try {
      final api = await _getDriveApi();
      if (api == null) return;

      final files = await api.files.list(
        q: "name contains 'transactions_backup' and mimeType='application/json'",
        orderBy: 'createdTime desc',
      );

      final driveBackups =
          files.files?.map((file) {
            String formattedDate = 'Unknown';
            if (file.createdTime != null) {
              try {
                // Handle both String and DateTime types from Google Drive API
                DateTime date;
                if (file.createdTime is String) {
                  date = DateTime.parse(file.createdTime as String);
                } else {
                  date = file.createdTime as DateTime;
                }
                formattedDate =
                    '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              } catch (e) {
                // If parsing fails, use a fallback
                formattedDate = 'Unknown Date';
              }
            }

            return BackupInfo(
              id: file.id!,
              formattedDate: formattedDate,
              formattedSize:
                  file.size != null
                      ? '${(int.parse(file.size!) / 1024).toStringAsFixed(2)} KB'
                      : 'Unknown',
            );
          }).toList();

      setState(() => _availableDriveBackups = driveBackups ?? []);
    } catch (e) {
      _showErrorSnackBar('❌ Error loading Drive backups: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showRestoreConfirmationDialog(BackupInfo backup) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('🔄 Restore Backup'),
                content: Text(
                  'Restore backup from:\n\n${backup.formattedDate} (${backup.formattedSize})?\n\nThis will overwrite your existing data.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Restore'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

  void _showErrorSnackBar(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('☁️ Google Drive Backup'),
        centerTitle: true,
      ),
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
                Icon(Icons.cloud, color: Colors.blue[600], size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Google Drive Backup',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Setup Guide for Developers
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700]),
                      SizedBox(width: 8.w),
                      Text(
                        'Setup Required',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Google Sign-In needs to be configured with your Google Cloud Project credentials.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.amber[700]),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• Replace google-services.json.template with your actual config\n• Add GoogleService-Info.plist for iOS\n• Enable Google Drive API in Google Cloud Console',
                    style: TextStyle(fontSize: 11.sp, color: Colors.amber[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Sign In/Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : (_isSignedIn ? _signOut : _signIn),
                icon: Icon(_isSignedIn ? Icons.logout : Icons.login),
                label: Text(
                  _isSignedIn ? 'Sign Out of Google' : 'Sign In with Google',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSignedIn ? Colors.redAccent : Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),

            if (_isSignedIn) ...[
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
            ] else ...[
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
                    Icon(Icons.info_outline, color: Colors.orange[600]),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Sign in to Google to backup your data to Google Drive',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    if (!_isSignedIn) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.backup, color: Colors.grey[600], size: 24.sp),
                  SizedBox(width: 12.w),
                  Text(
                    'Backup Your Data',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey[600]),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Please sign in to Google to access backup features',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
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

            // Backup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createDriveBackup,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Backup to Google Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),


             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createDriveBackup,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Backup to Google Drive'),
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
    if (!_isSignedIn) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.grey[600], size: 24.sp),
                  SizedBox(width: 12.w),
                  Text(
                    'Backup History',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey[600]),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Please sign in to Google to view backup history',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
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
                  '${_availableDriveBackups.length} backups',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _refreshDriveBackups,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Backups'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            if (_availableDriveBackups.isEmpty) ...[
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
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableDriveBackups.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final backup = _availableDriveBackups[index];
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
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(Icons.cloud_done, color: Colors.blue[600], size: 20.sp),
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
            onPressed: () => _restoreDriveBackup(backup),
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

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}
