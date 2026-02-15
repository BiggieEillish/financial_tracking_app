import 'ocr_service.dart';

class ReceiptParser {
  /// Parse receipt text lines into a ReceiptScanResult using multiple strategies.
  ReceiptScanResult parse(List<String> textLines) {
    // Try Malaysian format first (RM prefix), then US, then generic
    final strategies = [
      _parseMalaysianReceipt,
      _parseUSReceipt,
      _parseGenericReceipt,
    ];

    for (final strategy in strategies) {
      final result = strategy(textLines);
      if (result.items.isNotEmpty) {
        return result;
      }
    }

    // Fallback: return empty result
    return ReceiptScanResult(
      items: [],
      totalAmount: 0.0,
    );
  }

  ReceiptScanResult _parseMalaysianReceipt(List<String> textLines) {
    final items = <ReceiptItem>[];
    double totalAmount = 0.0;
    String? storeName;
    DateTime? date;
    String? pendingItemName;

    final rmPricePattern = RegExp(r'RM\s*(\d+\.\d{2})');
    final datePattern = RegExp(r'\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}');
    final quantityPattern = RegExp(r'^(\d+)\s+');

    for (String line in textLines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Store name
      if (storeName == null && line.length > 3 && !rmPricePattern.hasMatch(line)) {
        storeName = line;
        continue;
      }

      // Date
      if (date == null && datePattern.hasMatch(line)) {
        date = _tryParseDate(datePattern, line);
        if (date != null) continue;
      }

      // Items with RM prefix
      final priceMatches = rmPricePattern.allMatches(line);
      if (priceMatches.isNotEmpty) {
        final lastMatch = priceMatches.last;
        final price = double.tryParse(lastMatch.group(1)!);
        if (price != null && price > 0) {
          String itemName = line.substring(0, lastMatch.start).trim();
          int quantity = 1;

          final qMatch = quantityPattern.firstMatch(itemName);
          if (qMatch != null) {
            quantity = int.tryParse(qMatch.group(1)!) ?? 1;
            itemName = itemName.substring(qMatch.end).trim();
          }

          itemName = itemName.replaceAll(RegExp(r'[^\w\s]'), '').trim();

          if (itemName.isEmpty && pendingItemName != null) {
            itemName = pendingItemName;
            pendingItemName = null;
          }

          if (itemName.isNotEmpty) {
            if (_isSummaryLine(itemName.toLowerCase())) {
              if (_isTotalLine(itemName.toLowerCase()) || totalAmount == 0.0) {
                totalAmount = price;
              }
            } else {
              items.add(ReceiptItem(name: itemName, price: price, quantity: quantity));
            }
          }
          pendingItemName = null;
        }
      } else if (storeName != null) {
        String cleaned = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (cleaned.isNotEmpty && cleaned.length > 1) {
          pendingItemName = cleaned;
        }
      }
    }

    if (totalAmount == 0.0 && items.isNotEmpty) {
      totalAmount = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    }

    return ReceiptScanResult(
      items: items,
      totalAmount: totalAmount,
      storeName: storeName,
      date: date,
    );
  }

  ReceiptScanResult _parseUSReceipt(List<String> textLines) {
    final items = <ReceiptItem>[];
    double totalAmount = 0.0;
    String? storeName;
    DateTime? date;
    String? pendingItemName;

    final usPricePattern = RegExp(r'\$\s*(\d+\.\d{2})');
    final datePattern = RegExp(r'\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}');
    final quantityPattern = RegExp(r'^(\d+)\s+');

    for (String line in textLines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (storeName == null && line.length > 3 && !usPricePattern.hasMatch(line)) {
        storeName = line;
        continue;
      }

      if (date == null && datePattern.hasMatch(line)) {
        date = _tryParseDate(datePattern, line);
        if (date != null) continue;
      }

      final priceMatches = usPricePattern.allMatches(line);
      if (priceMatches.isNotEmpty) {
        final lastMatch = priceMatches.last;
        final price = double.tryParse(lastMatch.group(1)!);
        if (price != null && price > 0) {
          String itemName = line.substring(0, lastMatch.start).trim();
          int quantity = 1;

          final qMatch = quantityPattern.firstMatch(itemName);
          if (qMatch != null) {
            quantity = int.tryParse(qMatch.group(1)!) ?? 1;
            itemName = itemName.substring(qMatch.end).trim();
          }

          itemName = itemName.replaceAll(RegExp(r'[^\w\s]'), '').trim();

          if (itemName.isEmpty && pendingItemName != null) {
            itemName = pendingItemName;
            pendingItemName = null;
          }

          if (itemName.isNotEmpty) {
            if (_isSummaryLine(itemName.toLowerCase())) {
              if (_isTotalLine(itemName.toLowerCase()) || totalAmount == 0.0) {
                totalAmount = price;
              }
            } else {
              items.add(ReceiptItem(name: itemName, price: price, quantity: quantity));
            }
          }
          pendingItemName = null;
        }
      } else if (storeName != null) {
        String cleaned = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (cleaned.isNotEmpty && cleaned.length > 1) {
          pendingItemName = cleaned;
        }
      }
    }

    if (totalAmount == 0.0 && items.isNotEmpty) {
      totalAmount = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    }

    return ReceiptScanResult(
      items: items,
      totalAmount: totalAmount,
      storeName: storeName,
      date: date,
    );
  }

  ReceiptScanResult _parseGenericReceipt(List<String> textLines) {
    final items = <ReceiptItem>[];
    double totalAmount = 0.0;
    String? storeName;
    DateTime? date;
    String? pendingItemName;

    final pricePattern = RegExp(r'(\d+\.\d{2})');
    final datePattern = RegExp(r'\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}');
    final quantityPattern = RegExp(r'^(\d+)\s+');

    for (String line in textLines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (storeName == null && line.length > 3 && !pricePattern.hasMatch(line)) {
        storeName = line;
        continue;
      }

      if (date == null && datePattern.hasMatch(line)) {
        date = _tryParseDate(datePattern, line);
        if (date != null) continue;
      }

      final priceMatches = pricePattern.allMatches(line);
      if (priceMatches.isNotEmpty) {
        final lastMatch = priceMatches.last;
        final price = double.tryParse(lastMatch.group(1)!);
        if (price != null && price > 0) {
          String itemName = line.substring(0, lastMatch.start).trim();
          int quantity = 1;

          final qMatch = quantityPattern.firstMatch(itemName);
          if (qMatch != null) {
            quantity = int.tryParse(qMatch.group(1)!) ?? 1;
            itemName = itemName.substring(qMatch.end).trim();
          }

          itemName = itemName.replaceAll(RegExp(r'[^\w\s]'), '').trim();

          if (itemName.isEmpty && pendingItemName != null) {
            itemName = pendingItemName;
            pendingItemName = null;
          }

          if (itemName.isNotEmpty) {
            if (_isSummaryLine(itemName.toLowerCase())) {
              if (_isTotalLine(itemName.toLowerCase()) || totalAmount == 0.0) {
                totalAmount = price;
              }
            } else {
              items.add(ReceiptItem(name: itemName, price: price, quantity: quantity));
            }
          }
          pendingItemName = null;
        }
      } else if (storeName != null) {
        String cleaned = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (cleaned.isNotEmpty && cleaned.length > 1) {
          pendingItemName = cleaned;
        }
      }
    }

    if (totalAmount == 0.0 && items.isNotEmpty) {
      totalAmount = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    }

    return ReceiptScanResult(
      items: items,
      totalAmount: totalAmount,
      storeName: storeName,
      date: date,
    );
  }

  DateTime? _tryParseDate(RegExp pattern, String line) {
    try {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final dateStr = match.group(0)!;
        final parts = dateStr.split(RegExp(r'[/.\-]'));
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year < 100 ? 2000 + year : year, month, day);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isSummaryLine(String lowerName) {
    const exactMatches = {
      'tax', 'sales tax', 'balance', 'change', 'cash',
      'tendered', 'paid', 'payment', 'amount', 'rounding',
      'vat', 'gst', 'sst',
    };
    if (exactMatches.contains(lowerName)) return true;
    if (lowerName.contains('total')) return true;
    if (lowerName.contains('subtotal')) return true;
    if (RegExp(r'\btax\b').hasMatch(lowerName)) return true;
    return false;
  }

  bool _isTotalLine(String lowerName) {
    return lowerName == 'total' || lowerName == 'grand total';
  }
}
