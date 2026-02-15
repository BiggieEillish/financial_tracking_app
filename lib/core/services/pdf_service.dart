import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'ocr_service.dart';
import 'receipt_parser.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final ReceiptParser _receiptParser = ReceiptParser();

  /// Pick a PDF file from device storage
  Future<File?> pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        return file;
      }
      return null;
    } catch (e) {
      print('Error picking PDF file: $e');
      return null;
    }
  }

  /// Process PDF receipt by extracting text and parsing it
  Future<ReceiptScanResult> processPDFReceipt(File pdfFile) async {
    try {
      final savedPdfPath = await _savePDFToLocal(pdfFile);

      // Extract text from PDF using Syncfusion
      final textLines = await _extractTextFromPDF(pdfFile);

      if (textLines.isNotEmpty) {
        // Parse using the strategy-based parser
        final result = _receiptParser.parse(textLines);
        return ReceiptScanResult(
          items: result.items,
          totalAmount: result.totalAmount,
          storeName: result.storeName,
          date: result.date,
          receiptImagePath: savedPdfPath,
        );
      }

      // Fallback if no text extracted
      return ReceiptScanResult(
        items: [],
        totalAmount: 0.0,
        storeName: 'PDF Receipt',
        date: DateTime.now(),
        receiptImagePath: savedPdfPath,
      );
    } catch (e) {
      print('Error processing PDF receipt: $e');
      rethrow;
    }
  }

  /// Extract text lines from a PDF file using Syncfusion
  Future<List<String>> _extractTextFromPDF(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final allLines = <String>[];
      for (int i = 0; i < document.pages.count; i++) {
        final String pageText =
            PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        final lines = pageText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        allLines.addAll(lines);
      }

      document.dispose();
      return allLines;
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return [];
    }
  }

  /// Save PDF to local storage
  Future<String> _savePDFToLocal(File pdfFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(appDir.path, 'receipts'));

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedPath = path.join(receiptsDir.path, fileName);

      await pdfFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  /// Get PDF file from saved path
  Future<File?> getReceiptPDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting receipt PDF: $e');
      return null;
    }
  }

  /// Check if file is a PDF
  bool isPDFFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return extension == '.pdf';
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }
}
