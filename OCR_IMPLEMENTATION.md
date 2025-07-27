# OCR Receipt Scanning Implementation

This document explains the OCR (Optical Character Recognition) implementation for scanning receipts and automatically adding expenses to your financial planner app.

## Features

- **Camera Integration**: Take photos of receipts directly in the app
- **Gallery Selection**: Choose existing receipt images from your device
- **PDF Upload**: Upload PDF receipts for processing
- **Text Recognition**: Extract text from receipt images using Google ML Kit
- **Smart Parsing**: Automatically identify items, prices, quantities, and totals
- **Individual Item Management**: Edit categories and quantities for each item
- **Batch Saving**: Save all items as separate expenses at once
- **Receipt Storage**: Automatically save receipt images and PDFs for future reference

## Architecture

### Core Services

1. **OCRService** (`lib/core/services/ocr_service.dart`)
   - Handles text recognition using Google ML Kit
   - Parses receipt data (items, prices, totals, dates)
   - Manages receipt image storage

2. **CameraService** (`lib/core/services/camera_service.dart`)
   - Manages camera permissions and initialization
   - Handles image capture and gallery selection
   - Provides camera controller management

3. **PDFService** (`lib/core/services/pdf_service.dart`)
   - Handles PDF file selection and processing
   - Manages PDF storage and retrieval
   - Provides PDF-specific utilities

### Screens

1. **ReceiptScannerScreen** (`lib/features/expenses/screens/receipt_scanner_screen.dart`)
   - Camera interface for taking receipt photos
   - Gallery selection option
   - Processing status indicators

2. **ReceiptItemsScreen** (`lib/features/expenses/screens/receipt_items_screen.dart`)
   - Displays scanned items with editing capabilities
   - Category selection for each item
   - Quantity adjustment
   - Batch saving functionality

## Dependencies Added

```yaml
dependencies:
  camera: ^0.10.5+9              # Camera functionality
  image_picker: ^1.0.7           # Image selection from gallery
  google_mlkit_text_recognition: ^0.11.0  # OCR text recognition
  permission_handler: ^11.3.0    # Camera and storage permissions
  image: ^4.1.7                  # Image processing
  http: ^1.2.0                   # HTTP requests (if needed)
  dio: ^5.4.0+1                  # HTTP client (if needed)
  file_picker: ^8.0.0+1          # PDF file selection
```

## Permissions Required

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan receipts and add expenses automatically.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select receipt images for scanning.</string>
```

## How It Works

### 1. Receipt Scanning Process

1. **User initiates scan**: Tap camera icon in bottom navigation or expenses screen
2. **Choose input method**: 
   - Take photo with camera
   - Select image from gallery
   - Upload PDF file
3. **Permission handling**: App requests necessary permissions
4. **Processing**: 
   - For images: Google ML Kit extracts text
   - For PDFs: Extract text or convert to images for OCR
5. **Data parsing**: App parses text to identify:
   - Store name
   - Date
   - Individual items with prices
   - Quantities
   - Total amount

### 2. Text Parsing Logic

The OCR service uses regular expressions to identify:
- **Prices**: `RM?\s*\d+\.\d{2}|\d+\.\d{2}` (e.g., RM 12.99, 12.99)
- **Dates**: `\d{1,2}[/-]\d{1,2}[/-]\d{2,4}` (e.g., 12/25/2023)
- **Quantities**: `^\d+\s+` (e.g., "2 " at start of line)

### 3. Item Management

After scanning, users can:
- **Edit categories**: Select from predefined expense categories
- **Adjust quantities**: Increase/decrease item quantities
- **Remove items**: Delete incorrectly detected items
- **Save individually**: Save items as separate expenses

## Usage Instructions

### For Users

1. **Access Scanner**:
   - Tap the camera icon in the bottom navigation
   - Or tap the camera icon in the expenses screen

2. **Choose Input Method**:
   - **Camera**: Take photo of receipt
   - **Gallery**: Select existing image
   - **PDF**: Upload PDF receipt file

3. **Process Receipt**:
   - For photos: Position receipt in frame, ensure good lighting
   - For PDFs: Select file from device storage
   - Tap "Scan Receipt" or wait for processing

4. **Review Items**:
   - Check detected items and prices
   - Select appropriate categories
   - Adjust quantities if needed
   - Remove any incorrect items

5. **Save Expenses**:
   - Tap "Save All" to add all items as separate expenses
   - Each item becomes a separate expense entry

### For Developers

#### Adding OCR to New Screens

```dart
import 'package:go_router/go_router.dart';

// Navigate to scanner
context.go('/receipt-scanner');

// Navigate with result
context.push('/receipt-items', extra: scanResult);
```

#### Customizing OCR Parsing

Edit `OCRService._parseReceiptText()` method to improve parsing for specific receipt formats:

```dart
ReceiptScanResult _parseReceiptText(List<String> textBlocks) {
  // Add custom parsing logic here
  // Modify regular expressions for better detection
  // Add support for different receipt formats
}
```

#### Adding New Categories

Update `AppConstants.expenseCategories` in `lib/shared/constants/app_constants.dart`:

```dart
static const List<String> expenseCategories = [
  'Food & Dining',
  'Transportation',
  'Shopping',
  // Add new categories here
];
```

## Troubleshooting

### Common Issues

1. **Camera not working**:
   - Check camera permissions in device settings
   - Ensure camera is not being used by another app
   - Restart the app

2. **Poor text recognition**:
   - Ensure good lighting
   - Hold camera steady
   - Make sure text is clear and not blurry
   - Try different angles

3. **Incorrect item detection**:
   - Manually edit items in the review screen
   - Remove incorrect items
   - Adjust categories and quantities

4. **App crashes on scan**:
   - Check device has sufficient memory
   - Ensure Google Play Services are updated (Android)
   - Restart the app

### Performance Optimization

- **Image quality**: Use 85% quality for faster processing
- **Image size**: Limit to 1920x1080 for optimal performance
- **Memory management**: Dispose camera controller properly
- **Background processing**: Consider moving OCR to isolate for large images

## Future Enhancements

1. **Machine Learning**: Train custom models for better receipt recognition
2. **Cloud OCR**: Use cloud services for improved accuracy
3. **Receipt Templates**: Support for different receipt formats
4. **Auto-categorization**: ML-based category suggestions
5. **Receipt History**: View and manage saved receipt images
6. **Export**: Export receipt data to various formats
7. **Multi-language**: Support for receipts in different languages

## Testing

### Manual Testing

1. Test with various receipt types:
   - Grocery store receipts
   - Restaurant receipts
   - Gas station receipts
   - Online purchase receipts

2. Test edge cases:
   - Poor quality images
   - Different lighting conditions
   - Various receipt formats
   - Different text orientations

### Automated Testing

```dart
// Example test for OCR service
test('should parse receipt text correctly', () async {
  final ocrService = OCRService();
  final result = await ocrService.scanReceipt(testImageFile);
  
  expect(result.items.length, greaterThan(0));
  expect(result.totalAmount, greaterThan(0));
});
```

## Security Considerations

1. **Image Storage**: Receipt images are stored locally on device
2. **Data Privacy**: No receipt data is sent to external servers
3. **Permissions**: Only request necessary camera and storage permissions
4. **Data Handling**: Process images locally using Google ML Kit

## Support

For issues or questions about the OCR implementation:
1. Check the troubleshooting section above
2. Review the code comments for implementation details
3. Test with different receipt types
4. Consider updating dependencies for latest features 