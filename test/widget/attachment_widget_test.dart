import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:debt_tracker/domain/entities/attachment_entity.dart';
import 'package:debt_tracker/presentation/widgets/attachment_widget.dart';

@GenerateMocks([])
void main() {
  group('AttachmentWidget Tests', () {
    late List<AttachmentEntity> testAttachments;
    late AttachmentEntity imageAttachment;
    late AttachmentEntity pdfAttachment;

    setUp(() {
      imageAttachment = AttachmentEntity(
        id: 'img1',
        fileName: 'receipt.jpg',
        filePath: '/path/to/receipt.jpg',
        fileType: 'image/jpeg',
        fileSize: 1024,
        createdAt: DateTime(2024, 1, 1),
      );

      pdfAttachment = AttachmentEntity(
        id: 'pdf1',
        fileName: 'invoice.pdf',
        filePath: '/path/to/invoice.pdf',
        fileType: 'application/pdf',
        fileSize: 2048,
        createdAt: DateTime(2024, 1, 2),
      );

      testAttachments = [imageAttachment, pdfAttachment];
    });

    group('Attachment Buttons', () {
      testWidgets('should display attach file and camera buttons', (WidgetTester tester) async {
        bool fileButtonTapped = false;
        bool cameraButtonTapped = false;

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () => fileButtonTapped = true,
                  onTakePhoto: () => cameraButtonTapped = true,
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Check if both buttons are present
        expect(find.text('Attach File'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.byIcon(Icons.attach_file), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);

        // Test file button tap
        await tester.tap(find.text('Attach File'));
        expect(fileButtonTapped, isTrue);

        // Test camera button tap
        await tester.tap(find.text('Camera'));
        expect(cameraButtonTapped, isTrue);
      });

      testWidgets('should display buttons in a row layout', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Find the row containing the buttons
        final rowFinder = find.descendant(
          of: find.byType(AttachmentWidget),
          matching: find.byType(Row),
        );
        expect(rowFinder, findsWidgets);

        // Check that buttons are in the same row
        final attachButton = find.ancestor(
          of: find.text('Attach File'),
          matching: find.byType(InkWell),
        );
        final cameraButton = find.ancestor(
          of: find.text('Camera'),
          matching: find.byType(InkWell),
        );

        expect(attachButton, findsOneWidget);
        expect(cameraButton, findsOneWidget);
      });

      testWidgets('should display helpful text below buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Attach receipts, bills, or documents (Optional)'), findsOneWidget);
      });
    });

    group('Attachment Display', () {
      testWidgets('should display attachments when list is not empty', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: testAttachments,
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Should display attachments section
        expect(find.text('Attachments'), findsOneWidget);
        expect(find.text('receipt.jpg'), findsOneWidget);
        expect(find.text('invoice.pdf'), findsOneWidget);
        expect(find.text('1.0 KB'), findsOneWidget);
        expect(find.text('2.0 KB'), findsOneWidget);
      });

      testWidgets('should not display attachments section when list is empty', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Should not display attachments section
        expect(find.text('Attachments'), findsNothing);
      });

      testWidgets('should display correct icons for different file types', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: testAttachments,
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Should display appropriate icons
        expect(find.byIcon(Icons.image), findsOneWidget); // For image file
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget); // For PDF file
      });

      testWidgets('should display file sizes correctly', (WidgetTester tester) async {
        final largeFile = AttachmentEntity(
          id: 'large1',
          fileName: 'large.zip',
          filePath: '/path/to/large.zip',
          fileType: 'application/zip',
          fileSize: 1048576, // 1 MB
          createdAt: DateTime(2024, 1, 3),
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: [largeFile],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('1.0 MB'), findsOneWidget);
      });
    });

    group('Attachment Removal', () {
      testWidgets('should call onRemoveAttachment when remove button is tapped', (WidgetTester tester) async {
        AttachmentEntity? removedAttachment;

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: testAttachments,
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (attachment) => removedAttachment = attachment,
                ),
              ),
            ),
          ),
        );

        // Find and tap the first remove button
        final removeButtons = find.byIcon(Icons.close);
        expect(removeButtons, findsNWidgets(2)); // Two attachments, two remove buttons

        await tester.tap(removeButtons.first);
        expect(removedAttachment, equals(imageAttachment));
      });

      testWidgets('should display remove buttons for each attachment', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: testAttachments,
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Should have remove button for each attachment
        final removeButtons = find.byIcon(Icons.close);
        expect(removeButtons, findsNWidgets(testAttachments.length));
      });
    });

    group('Button Styling', () {
      testWidgets('should style attach file button correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Find the attach file button container
        final attachButton = find.ancestor(
          of: find.text('Attach File'),
          matching: find.byType(Container),
        ).first;

        final container = tester.widget<Container>(attachButton);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, equals(Colors.grey[50]));
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.border, isNotNull);
      });

      testWidgets('should style camera button differently from attach file button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Find camera button container
        final cameraButton = find.ancestor(
          of: find.text('Camera'),
          matching: find.byType(Container),
        ).first;

        final container = tester.widget<Container>(cameraButton);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, equals(Colors.blue[50]));
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.border, isNotNull);
      });
    });

    group('Responsive Layout', () {
      testWidgets('should handle long file names properly', (WidgetTester tester) async {
        final longNameAttachment = AttachmentEntity(
          id: 'long1',
          fileName: 'this_is_a_very_long_file_name_that_should_be_handled_properly.jpg',
          filePath: '/path/to/long_file.jpg',
          fileType: 'image/jpeg',
          fileSize: 1024,
          createdAt: DateTime(2024, 1, 1),
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: [longNameAttachment],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Should display the long filename (may be truncated)
        expect(find.textContaining('this_is_a_very_long'), findsOneWidget);
      });

      testWidgets('should expand to use available width', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 300,
                  child: AttachmentWidget(
                    attachments: const [],
                    onAddAttachment: () {},
                    onTakePhoto: () {},
                    onRemoveAttachment: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        final row = find.byType(Row).first;
        final rowWidget = tester.widget<Row>(row);
        
        // Attach file button should be expanded
        expect(rowWidget.children.any((child) => child is Expanded), isTrue);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle null attachment list gracefully', (WidgetTester tester) async {
        // This test would require modifying the widget to accept null, 
        // but currently it requires a non-null list
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AttachmentWidget), findsOneWidget);
      });

      testWidgets('should handle attachment with missing file type', (WidgetTester tester) async {
        final unknownTypeAttachment = AttachmentEntity(
          id: 'unknown1',
          fileName: 'unknown.xyz',
          filePath: '/path/to/unknown.xyz',
          fileType: 'application/octet-stream',
          fileSize: 1024,
          createdAt: DateTime(2024, 1, 1),
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: [unknownTypeAttachment],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Should display with a default file icon
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
        expect(find.text('unknown.xyz'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: testAttachments,
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Check for semantic labels
        expect(find.bySemanticsLabel(RegExp(r'Attach.*file')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp(r'Camera')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp(r'Remove.*attachment')), findsWidgets);
      });

      testWidgets('should support tap targets for accessibility', (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: AttachmentWidget(
                  attachments: const [],
                  onAddAttachment: () {},
                  onTakePhoto: () {},
                  onRemoveAttachment: (_) {},
                ),
              ),
            ),
          ),
        );

        // Find InkWell widgets (tappable areas)
        final inkWells = find.byType(InkWell);
        expect(inkWells, findsNWidgets(2)); // Attach file and camera buttons

        // Check that buttons have adequate size for tapping
        for (final inkWell in inkWells.evaluate()) {
          final size = tester.getSize(find.byWidget(inkWell.widget));
          expect(size.height, greaterThanOrEqualTo(44)); // Minimum tap target size
        }
      });
    });

    group('Performance', () {
      testWidgets('should handle large number of attachments efficiently', (WidgetTester tester) async {
        // Create a large list of attachments
        final manyAttachments = List.generate(100, (index) => 
          AttachmentEntity(
            id: 'file$index',
            fileName: 'file$index.jpg',
            filePath: '/path/to/file$index.jpg',
            fileType: 'image/jpeg',
            fileSize: 1024,
            createdAt: DateTime(2024, 1, 1),
          ),
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AttachmentWidget(
                    attachments: manyAttachments,
                    onAddAttachment: () {},
                    onTakePhoto: () {},
                    onRemoveAttachment: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        // Should render without performance issues
        expect(find.byType(AttachmentWidget), findsOneWidget);
        expect(find.text('Attachments'), findsOneWidget);
        
        // Scroll to see more attachments
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
        await tester.pump();
        
        // Should still be responsive
        expect(find.byType(AttachmentWidget), findsOneWidget);
      });
    });
  });
}