import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class GoogleDriveService {
  static const String _backupFolderName = 'DebtTrackerBackups';
  static const String _backupFilePrefix = 'debt_tracker_backup_';
  static const String _lastBackupDateKey = 'last_backup_date';
  static const String _userEmailKey = 'backup_user_email';
  static const int _maxBackupRetentionDays = 15;

  static GoogleDriveService? _instance;
  static GoogleDriveService get instance =>
      _instance ??= GoogleDriveService._();
  GoogleDriveService._();

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _googleSignIn = GoogleSignIn.instance;

    // Initialize the Google Sign-In instance for mobile (Android/iOS)
    await _googleSignIn!.initialize(
      // Web Client ID for Google Drive API access
      serverClientId:
          '694593410619-6o519rlaspfobkgm6nt65b1e9vfsi1s5.apps.googleusercontent.com',
      // Explicitly set the Android client ID
      clientId:
          '694593410619-2h85f1cg6mlqshv9shja53i45375jli6.apps.googleusercontent.com',
    );
  }

  // Authentication Methods
  Future<bool> signIn() async {
    try {
      await initialize();

      final account = await _googleSignIn!.authenticate();
      if (account == null) return false;

      _currentUser = account;
      await _prefs?.setString(_userEmailKey, account.email);

      // Initialize Drive API with new authorization system
      const scopes = ['https://www.googleapis.com/auth/drive.file'];
      final authorization = await account.authorizationClient
          .authorizationForScopes(scopes);
      if (authorization != null) {
        final authenticateClient = GoogleAuthClient({
          'Authorization': 'Bearer ${authorization.accessToken}',
        });
        _driveApi = drive.DriveApi(authenticateClient);
      }

      AppLogger.info('Google Drive sign-in successful: ${account.email}');
      return true;
    } catch (e) {
      AppLogger.error('Google Drive sign-in failed', e);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      _currentUser = null;
      _driveApi = null;
      await _prefs?.remove(_userEmailKey);
      AppLogger.info('Google Drive sign-out successful');
    } catch (e) {
      AppLogger.error('Google Drive sign-out failed', e);
    }
  }

  Future<bool> isSignedIn() async {
    try {
      await initialize();
      final account = await _googleSignIn!.attemptLightweightAuthentication();
      if (account != null) {
        _currentUser = account;
        const scopes = ['https://www.googleapis.com/auth/drive.file'];
        final authorization = await account.authorizationClient
            .authorizationForScopes(scopes);
        if (authorization != null) {
          final authenticateClient = GoogleAuthClient({
            'Authorization': 'Bearer ${authorization.accessToken}',
          });
          _driveApi = drive.DriveApi(authenticateClient);
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Error checking Google Drive sign-in status', e);
      return false;
    }
  }

  String? get userEmail =>
      _currentUser?.email ?? _prefs?.getString(_userEmailKey);

  // Backup Methods
  Future<bool> createBackup() async {
    try {
      if (!await isSignedIn()) {
        AppLogger.error('User not signed in to Google Drive');
        return false;
      }

      // Get all transactions from database
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final transactionMaps = await db.query('transactions');
      final transactions =
          transactionMaps.map((map) => TransactionModel.fromMap(map)).toList();

      // Create backup data
      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'user_email': userEmail,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/backup_temp.json');
      await tempFile.writeAsString(jsonEncode(backupData));

      // Upload to Google Drive
      final fileName =
          '$_backupFilePrefix${DateTime.now().millisecondsSinceEpoch}.json';
      final folderId = await _getOrCreateBackupFolder();

      final driveFile =
          drive.File()
            ..name = fileName
            ..parents = [folderId];

      final media = drive.Media(tempFile.openRead(), tempFile.lengthSync());
      await _driveApi!.files.create(driveFile, uploadMedia: media);

      // Clean up temp file
      await tempFile.delete();

      // Update last backup date
      await _prefs?.setString(
        _lastBackupDateKey,
        DateTime.now().toIso8601String(),
      );

      // Clean up old backups
      await _cleanupOldBackups();

      AppLogger.info('Backup created successfully: $fileName');
      return true;
    } catch (e) {
      AppLogger.error('Backup creation failed', e);
      return false;
    }
  }

  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      if (!await isSignedIn()) return [];

      final folderId = await _getOrCreateBackupFolder();
      final fileList = await _driveApi!.files.list(
        q: "parents in '$folderId' and name contains '$_backupFilePrefix'",
        orderBy: 'createdTime desc',
      );

      final backups = <BackupInfo>[];
      for (final file in fileList.files ?? []) {
        if (file.name != null && file.createdTime != null) {
          backups.add(
            BackupInfo(
              id: file.id!,
              name: file.name!,
              createdAt: file.createdTime!,
              size: file.size != null ? int.parse(file.size!) : 0,
            ),
          );
        }
      }

      return backups;
    } catch (e) {
      AppLogger.error('Failed to get available backups', e);
      return [];
    }
  }

  Future<bool> restoreFromBackup(String backupId) async {
    try {
      if (!await isSignedIn()) return false;

      // Download backup file
      final media = await _driveApi!.files.get(
        backupId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      final bytes = <int>[];
      await for (final chunk in (media as drive.Media).stream) {
        bytes.addAll(chunk);
      }

      final backupData = jsonDecode(String.fromCharCodes(bytes));

      // Validate backup data
      if (backupData['transactions'] == null) {
        AppLogger.error('Invalid backup data: no transactions found');
        return false;
      }

      // Clear current transactions and restore from backup
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        // Clear existing transactions
        await txn.delete('transactions');

        // Insert backup transactions
        for (final transactionMap in backupData['transactions']) {
          await txn.insert('transactions', transactionMap);
        }
      });

      AppLogger.info('Data restored successfully from backup');
      return true;
    } catch (e) {
      AppLogger.error('Restore from backup failed', e);
      return false;
    }
  }

  // Helper Methods
  Future<String> _getOrCreateBackupFolder() async {
    final folderList = await _driveApi!.files.list(
      q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder'",
    );

    if (folderList.files?.isNotEmpty == true) {
      return folderList.files!.first.id!;
    }

    // Create folder
    final folder =
        drive.File()
          ..name = _backupFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await _driveApi!.files.create(folder);
    return createdFolder.id!;
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final cutoffDate = DateTime.now().subtract(
        const Duration(days: _maxBackupRetentionDays),
      );
      final folderId = await _getOrCreateBackupFolder();

      final fileList = await _driveApi!.files.list(
        q: "parents in '$folderId' and name contains '$_backupFilePrefix'",
      );

      for (final file in fileList.files ?? []) {
        if (file.createdTime != null &&
            file.createdTime!.isBefore(cutoffDate)) {
          await _driveApi!.files.delete(file.id!);
          AppLogger.info('Deleted old backup: ${file.name}');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup old backups', e);
    }
  }

  // Auto Backup Methods
  Future<bool> shouldPerformAutoBackup() async {
    final lastBackupString = _prefs?.getString(_lastBackupDateKey);
    if (lastBackupString == null) return true;

    try {
      final lastBackup = DateTime.parse(lastBackupString);
      final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
      return daysSinceBackup >= 1; // Daily backup
    } catch (e) {
      return true; // If parsing fails, perform backup
    }
  }

  DateTime? get lastBackupDate {
    final lastBackupString = _prefs?.getString(_lastBackupDateKey);
    if (lastBackupString == null) return null;
    try {
      return DateTime.parse(lastBackupString);
    } catch (e) {
      return null;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

class BackupInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;

  const BackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
