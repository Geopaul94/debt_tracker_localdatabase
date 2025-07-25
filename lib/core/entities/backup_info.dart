class BackupInfo {
  final String id;
  final String name;
  final DateTime date;
  final int size;
  final bool isLocal;
  final String? userEmail;

  BackupInfo({
    required this.id,
    required this.name,
    required this.date,
    required this.size,
    this.isLocal = false,
    this.userEmail,
  });

  String get formattedDate {
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

  String get formattedSize {
    if (size < 1024) {
      return '${size} B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get displayName {
    if (isLocal) {
      return '📱 $name';
    } else {
      return '☁️ $name';
    }
  }
}
