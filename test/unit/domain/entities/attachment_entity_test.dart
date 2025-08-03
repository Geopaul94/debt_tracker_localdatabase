import 'package:flutter_test/flutter_test.dart';
import 'package:debt_tracker/domain/entities/attachment_entity.dart';

void main() {
  group('AttachmentEntity', () {
    late AttachmentEntity attachmentEntity;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      attachmentEntity = AttachmentEntity(
        id: 'test_id',
        fileName: 'receipt.jpg',
        filePath: '/path/to/receipt.jpg',
        fileType: 'image/jpeg',
        fileSize: 1024,
        createdAt: testDate,
      );
    });

    group('Constructor', () {
      test('should create attachment entity with all required fields', () {
        expect(attachmentEntity.id, 'test_id');
        expect(attachmentEntity.fileName, 'receipt.jpg');
        expect(attachmentEntity.filePath, '/path/to/receipt.jpg');
        expect(attachmentEntity.fileType, 'image/jpeg');
        expect(attachmentEntity.fileSize, 1024);
        expect(attachmentEntity.createdAt, testDate);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = attachmentEntity.toJson();

        expect(json['id'], 'test_id');
        expect(json['fileName'], 'receipt.jpg');
        expect(json['filePath'], '/path/to/receipt.jpg');
        expect(json['fileType'], 'image/jpeg');
        expect(json['fileSize'], 1024);
        expect(json['createdAt'], testDate.toIso8601String());
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'json_id',
          'fileName': 'invoice.pdf',
          'filePath': '/path/to/invoice.pdf',
          'fileType': 'application/pdf',
          'fileSize': 2048,
          'createdAt': '2024-02-01T12:00:00.000',
        };

        final entity = AttachmentEntity.fromJson(json);

        expect(entity.id, 'json_id');
        expect(entity.fileName, 'invoice.pdf');
        expect(entity.filePath, '/path/to/invoice.pdf');
        expect(entity.fileType, 'application/pdf');
        expect(entity.fileSize, 2048);
        expect(entity.createdAt, DateTime(2024, 2, 1, 12, 0, 0));
      });

      test('should maintain data integrity through JSON round trip', () {
        final json = attachmentEntity.toJson();
        final reconstructed = AttachmentEntity.fromJson(json);

        expect(reconstructed.id, attachmentEntity.id);
        expect(reconstructed.fileName, attachmentEntity.fileName);
        expect(reconstructed.filePath, attachmentEntity.filePath);
        expect(reconstructed.fileType, attachmentEntity.fileType);
        expect(reconstructed.fileSize, attachmentEntity.fileSize);
        expect(reconstructed.createdAt, attachmentEntity.createdAt);
      });
    });

    group('File Size Formatting', () {
      test('should format bytes correctly', () {
        final smallFile = AttachmentEntity(
          id: 'small',
          fileName: 'small.txt',
          filePath: '/path/small.txt',
          fileType: 'text/plain',
          fileSize: 512,
          createdAt: testDate,
        );

        expect(smallFile.formattedFileSize, '512 B');
      });

      test('should format kilobytes correctly', () {
        final mediumFile = AttachmentEntity(
          id: 'medium',
          fileName: 'medium.jpg',
          filePath: '/path/medium.jpg',
          fileType: 'image/jpeg',
          fileSize: 1536, // 1.5 KB
          createdAt: testDate,
        );

        expect(mediumFile.formattedFileSize, '1.5 KB');
      });

      test('should format megabytes correctly', () {
        final largeFile = AttachmentEntity(
          id: 'large',
          fileName: 'large.mp4',
          filePath: '/path/large.mp4',
          fileType: 'video/mp4',
          fileSize: 2097152, // 2 MB
          createdAt: testDate,
        );

        expect(largeFile.formattedFileSize, '2.0 MB');
      });

      test('should format gigabytes correctly', () {
        final hugeFile = AttachmentEntity(
          id: 'huge',
          fileName: 'huge.zip',
          filePath: '/path/huge.zip',
          fileType: 'application/zip',
          fileSize: 1073741824, // 1 GB
          createdAt: testDate,
        );

        expect(hugeFile.formattedFileSize, '1.0 GB');
      });

      test('should handle zero file size', () {
        final emptyFile = AttachmentEntity(
          id: 'empty',
          fileName: 'empty.txt',
          filePath: '/path/empty.txt',
          fileType: 'text/plain',
          fileSize: 0,
          createdAt: testDate,
        );

        expect(emptyFile.formattedFileSize, '0 B');
      });

      test('should format fractional sizes with appropriate precision', () {
        final fractionalFile = AttachmentEntity(
          id: 'fractional',
          fileName: 'fractional.txt',
          filePath: '/path/fractional.txt',
          fileType: 'text/plain',
          fileSize: 1234, // 1.205... KB
          createdAt: testDate,
        );

        expect(fractionalFile.formattedFileSize, '1.2 KB');
      });
    });

    group('File Type Detection', () {
      test('should detect image files correctly', () {
        final imageFiles = [
          ('image.jpg', 'image/jpeg'),
          ('photo.png', 'image/png'),
          ('picture.gif', 'image/gif'),
          ('graphic.bmp', 'image/bmp'),
          ('vector.svg', 'image/svg+xml'),
        ];

        for (final (fileName, fileType) in imageFiles) {
          final entity = AttachmentEntity(
            id: 'test',
            fileName: fileName,
            filePath: '/path/$fileName',
            fileType: fileType,
            fileSize: 1024,
            createdAt: testDate,
          );

          expect(entity.isImage, isTrue, reason: '$fileName should be detected as image');
        }
      });

      test('should detect PDF files correctly', () {
        final pdfFile = AttachmentEntity(
          id: 'pdf',
          fileName: 'document.pdf',
          filePath: '/path/document.pdf',
          fileType: 'application/pdf',
          fileSize: 1024,
          createdAt: testDate,
        );

        expect(pdfFile.isPdf, isTrue);
        expect(pdfFile.isImage, isFalse);
      });

      test('should not detect non-image files as images', () {
        final nonImageFiles = [
          ('document.pdf', 'application/pdf'),
          ('text.txt', 'text/plain'),
          ('audio.mp3', 'audio/mpeg'),
          ('video.mp4', 'video/mp4'),
          ('archive.zip', 'application/zip'),
        ];

        for (final (fileName, fileType) in nonImageFiles) {
          final entity = AttachmentEntity(
            id: 'test',
            fileName: fileName,
            filePath: '/path/$fileName',
            fileType: fileType,
            fileSize: 1024,
            createdAt: testDate,
          );

          expect(entity.isImage, isFalse, reason: '$fileName should not be detected as image');
        }
      });

      test('should not detect non-PDF files as PDFs', () {
        final nonPdfFiles = [
          ('image.jpg', 'image/jpeg'),
          ('text.txt', 'text/plain'),
          ('document.doc', 'application/msword'),
        ];

        for (final (fileName, fileType) in nonPdfFiles) {
          final entity = AttachmentEntity(
            id: 'test',
            fileName: fileName,
            filePath: '/path/$fileName',
            fileType: fileType,
            fileSize: 1024,
            createdAt: testDate,
          );

          expect(entity.isPdf, isFalse, reason: '$fileName should not be detected as PDF');
        }
      });

      test('should handle case-insensitive MIME type detection', () {
        final upperCaseEntity = AttachmentEntity(
          id: 'test',
          fileName: 'image.jpg',
          filePath: '/path/image.jpg',
          fileType: 'IMAGE/JPEG',
          fileSize: 1024,
          createdAt: testDate,
        );

        expect(upperCaseEntity.isImage, isTrue);
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when all properties match', () {
        final entity1 = AttachmentEntity(
          id: 'same_id',
          fileName: 'same.jpg',
          filePath: '/same/path.jpg',
          fileType: 'image/jpeg',
          fileSize: 1024,
          createdAt: testDate,
        );

        final entity2 = AttachmentEntity(
          id: 'same_id',
          fileName: 'same.jpg',
          filePath: '/same/path.jpg',
          fileType: 'image/jpeg',
          fileSize: 1024,
          createdAt: testDate,
        );

        expect(entity1, equals(entity2));
        expect(entity1.hashCode, equals(entity2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        final entity1 = attachmentEntity;
        final entity2 = AttachmentEntity(
          id: 'different_id',
          fileName: attachmentEntity.fileName,
          filePath: attachmentEntity.filePath,
          fileType: attachmentEntity.fileType,
          fileSize: attachmentEntity.fileSize,
          createdAt: attachmentEntity.createdAt,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when file names differ', () {
        final entity1 = attachmentEntity;
        final entity2 = AttachmentEntity(
          id: attachmentEntity.id,
          fileName: 'different.jpg',
          filePath: attachmentEntity.filePath,
          fileType: attachmentEntity.fileType,
          fileSize: attachmentEntity.fileSize,
          createdAt: attachmentEntity.createdAt,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when file sizes differ', () {
        final entity1 = attachmentEntity;
        final entity2 = AttachmentEntity(
          id: attachmentEntity.id,
          fileName: attachmentEntity.fileName,
          filePath: attachmentEntity.filePath,
          fileType: attachmentEntity.fileType,
          fileSize: 2048,
          createdAt: attachmentEntity.createdAt,
        );

        expect(entity1, isNot(equals(entity2)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty file name', () {
        final entity = AttachmentEntity(
          id: 'test',
          fileName: '',
          filePath: '/path/',
          fileType: 'application/octet-stream',
          fileSize: 0,
          createdAt: testDate,
        );

        expect(entity.fileName, '');
        expect(entity.isImage, isFalse);
        expect(entity.isPdf, isFalse);
      });

      test('should handle special characters in file name', () {
        final entity = AttachmentEntity(
          id: 'test',
          fileName: 'receipt #1 (copy).jpg',
          filePath: '/path/receipt #1 (copy).jpg',
          fileType: 'image/jpeg',
          fileSize: 1024,
          createdAt: testDate,
        );

        expect(entity.fileName, 'receipt #1 (copy).jpg');
        expect(entity.isImage, isTrue);
      });

      test('should handle unicode file names', () {
        final entity = AttachmentEntity(
          id: 'test',
          fileName: '收据.jpg',
          filePath: '/path/收据.jpg',
          fileType: 'image/jpeg',
          fileSize: 1024,
          createdAt: testDate,
        );

        expect(entity.fileName, '收据.jpg');
        expect(entity.isImage, isTrue);
      });

      test('should handle very large file sizes', () {
        final entity = AttachmentEntity(
          id: 'test',
          fileName: 'huge.zip',
          filePath: '/path/huge.zip',
          fileType: 'application/zip',
          fileSize: 999999999999, // Very large number
          createdAt: testDate,
        );

        expect(entity.fileSize, 999999999999);
        expect(entity.formattedFileSize, contains('GB'));
      });

      test('should handle unknown MIME types', () {
        final entity = AttachmentEntity(
          id: 'test',
          fileName: 'unknown.xyz',
          filePath: '/path/unknown.xyz',
          fileType: 'application/xyz',
          fileSize: 1024,
          createdAt: testDate,
        );

        expect(entity.isImage, isFalse);
        expect(entity.isPdf, isFalse);
      });
    });

    group('toString', () {
      test('should provide useful string representation', () {
        final stringRep = attachmentEntity.toString();

        expect(stringRep, contains('AttachmentEntity'));
        expect(stringRep, contains('test_id'));
        expect(stringRep, contains('receipt.jpg'));
        expect(stringRep, contains('1024'));
      });
    });
  });
}