class AttachmentEntity {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime createdAt;

  const AttachmentEntity({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttachmentEntity.fromJson(Map<String, dynamic> json) {
    return AttachmentEntity(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AttachmentEntity copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return AttachmentEntity(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttachmentEntity &&
        other.id == id &&
        other.fileName == fileName &&
        other.filePath == filePath &&
        other.fileType == fileType &&
        other.fileSize == fileSize &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fileName.hashCode ^
        filePath.hashCode ^
        fileType.hashCode ^
        fileSize.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'AttachmentEntity(id: $id, fileName: $fileName, fileType: $fileType, fileSize: $fileSize)';
  }

  /// Returns true if this is an image file
  bool get isImage {
    return fileType.toLowerCase().startsWith('image/') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.gif') ||
        fileName.toLowerCase().endsWith('.webp');
  }

  /// Returns true if this is a PDF file
  bool get isPdf {
    return fileType.toLowerCase() == 'application/pdf' ||
        fileName.toLowerCase().endsWith('.pdf');
  }

  /// Returns a human-readable file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}