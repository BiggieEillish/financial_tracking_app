import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'ocr_service.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final OCRService _ocrService = OCRService();

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

  /// Process PDF receipt by converting to image and using OCR
  /// Note: This is a simplified approach that treats PDFs as images
  Future<ReceiptScanResult> processPDFReceipt(File pdfFile) async {
    try {
      // For now, we'll save the PDF and return a basic result
      // In a full implementation, you'd convert PDF to images first
      final savedPdfPath = await _savePDFToLocal(pdfFile);

      // Create a basic result - in practice, you'd extract text from PDF
      return ReceiptScanResult(
        items: [
          ReceiptItem(
            name: 'PDF Receipt',
            price: 0.0,
            quantity: 1,
            category: 'Other',
          ),
        ],
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

      // Copy the PDF to the receipts directory
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
