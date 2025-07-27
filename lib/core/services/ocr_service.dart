import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<ReceiptScanResult> scanReceipt(File imageFile) async {
    try {
      // Read the image
      final inputImage = InputImage.fromFile(imageFile);

      // Recognize text
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Extract text blocks
      final List<String> textBlocks = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          textBlocks.add(line.text);
        }
      }

      // Parse receipt data
      final result = _parseReceiptText(textBlocks);

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

  ReceiptScanResult _parseReceiptText(List<String> textBlocks) {
    final List<ReceiptItem> items = [];
    double totalAmount = 0.0;
    String? storeName;
    DateTime? date;

    // Regular expressions for parsing
    final pricePattern = RegExp(r'RM?\s*\d+\.\d{2}|\d+\.\d{2}');
    final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    final quantityPattern = RegExp(r'^\d+\s+');

    for (String line in textBlocks) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Try to extract store name (usually at the top)
      if (storeName == null &&
          line.length > 3 &&
          !pricePattern.hasMatch(line)) {
        storeName = line;
        continue;
      }

      // Try to extract date
      if (date == null && datePattern.hasMatch(line)) {
        try {
          final dateMatch = datePattern.firstMatch(line);
          if (dateMatch != null) {
            final dateStr = dateMatch.group(0)!;
            // Simple date parsing - you might want to improve this
            final parts = dateStr.split(RegExp(r'[/-]'));
            if (parts.length == 3) {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              date = DateTime(year < 100 ? 2000 + year : year, month, day);
            }
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
        continue;
      }

      // Try to extract items with prices
      final priceMatches = pricePattern.allMatches(line);
      if (priceMatches.isNotEmpty) {
        final lastPriceMatch = priceMatches.last;
        final priceStr =
            lastPriceMatch.group(0)!.replaceAll(RegExp(r'RM?\s*'), '');
        final price = double.tryParse(priceStr);

        if (price != null) {
          // Extract item name (everything before the price)
          String itemName = line.substring(0, lastPriceMatch.start).trim();

          // Remove quantity if present
          final quantityMatch = quantityPattern.firstMatch(itemName);
          int quantity = 1;
          if (quantityMatch != null) {
            quantity = int.tryParse(quantityMatch.group(0)!.trim()) ?? 1;
            itemName = itemName.substring(quantityMatch.end).trim();
          }

          // Clean up item name (remove RM and other currency symbols)
          itemName = itemName.replaceAll(RegExp(r'[^\w\s]'), '').trim();

          if (itemName.isNotEmpty && price > 0) {
            // Check if this might be a total
            final lowerName = itemName.toLowerCase();
            if (lowerName.contains('total') ||
                lowerName.contains('subtotal') ||
                lowerName.contains('tax') ||
                lowerName.contains('amount')) {
              totalAmount = price;
            } else {
              items.add(ReceiptItem(
                name: itemName,
                price: price,
                quantity: quantity,
              ));
            }
          }
        }
      }
    }

    // If no total was found, sum up all items
    if (totalAmount == 0.0 && items.isNotEmpty) {
      totalAmount =
          items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    }

    return ReceiptScanResult(
      items: items,
      totalAmount: totalAmount,
      storeName: storeName,
      date: date,
    );
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
