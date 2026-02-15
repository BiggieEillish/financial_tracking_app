import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'receipt_parser.dart';

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final String? category;

  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category,
  });

  @override
  String toString() {
    return 'ReceiptItem(name: $name, price: $price, quantity: $quantity, category: $category)';
  }
}

class ReceiptScanResult {
  final List<ReceiptItem> items;
  final double totalAmount;
  final String? storeName;
  final DateTime? date;
  final String? receiptImagePath;

  ReceiptScanResult({
    required this.items,
    required this.totalAmount,
    this.storeName,
    this.date,
    this.receiptImagePath,
  });
}

class _TextLineInfo {
  final String text;
  final double top;
  final double left;
  final double height;

  _TextLineInfo({
    required this.text,
    this.top = 0,
    this.left = 0,
    this.height = 20,
  });
}

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ReceiptParser _receiptParser = ReceiptParser();

  Future<ReceiptScanResult> scanReceipt(File imageFile) async {
    try {
      // Read the image
      final inputImage = InputImage.fromFile(imageFile);

      // Recognize text
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Collect all text lines with their bounding box positions
      final List<_TextLineInfo> allLines = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          allLines.add(_TextLineInfo(
            text: line.text,
            top: line.boundingBox.top,
            left: line.boundingBox.left,
            height: line.boundingBox.height,
          ));
        }
      }

      // Merge text lines at the same vertical position into full lines
      final List<String> textLines = _reconstructLines(allLines);

      // Debug output
      print('=== OCR Recognized ${textLines.length} lines ===');
      for (final line in textLines) {
        print('OCR: "$line"');
      }
      print('=== End OCR Output ===');

      // Parse receipt data using strategy-based parser
      final result = _receiptParser.parse(textLines);

      // Save image to local storage
      final savedImagePath = await _saveImageToLocal(imageFile);

      return ReceiptScanResult(
        items: result.items,
        totalAmount: result.totalAmount,
        storeName: result.storeName,
        date: result.date,
        receiptImagePath: savedImagePath,
      );
    } catch (e) {
      print('Error scanning receipt: $e');
      rethrow;
    }
  }

  /// Merges TextLines at the same vertical position into single lines.
  /// Handles OCR engines that split item names and prices into separate
  /// text regions even though they appear on the same visual line.
  List<String> _reconstructLines(List<_TextLineInfo> lines) {
    if (lines.isEmpty) return [];

    // Sort by vertical position
    lines.sort((a, b) => a.top.compareTo(b.top));

    // Group lines that are at approximately the same Y position
    final List<List<_TextLineInfo>> rows = [];
    List<_TextLineInfo> currentRow = [lines.first];

    for (int i = 1; i < lines.length; i++) {
      final rowTop = currentRow.first.top;
      final currTop = lines[i].top;
      final rowHeight = currentRow.first.height;

      // If within 60% of line height, consider same row
      if ((currTop - rowTop).abs() < rowHeight * 0.6) {
        currentRow.add(lines[i]);
      } else {
        rows.add(currentRow);
        currentRow = [lines[i]];
      }
    }
    rows.add(currentRow);

    // For each row, sort left-to-right and concatenate
    return rows.map((row) {
      row.sort((a, b) => a.left.compareTo(b.left));
      return row.map((l) => l.text).join(' ');
    }).toList();
  }

  Future<ReceiptScanResult> scanReceiptFromBytes(Uint8List imageBytes) async {
    try {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'temp_receipt.jpg'));
      await tempFile.writeAsBytes(imageBytes);

      return await scanReceipt(tempFile);
    } catch (e) {
      print('Error scanning receipt from bytes: $e');
      rethrow;
    }
  }

  Future<String> _saveImageToLocal(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(appDir.path, 'receipts'));

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(receiptsDir.path, fileName);

      // Copy the image to the receipts directory
      await imageFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  Future<File?> getReceiptImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting receipt image: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
