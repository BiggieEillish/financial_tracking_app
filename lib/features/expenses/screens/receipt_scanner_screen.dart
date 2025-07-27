import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../shared/constants/app_constants.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final OCRService _ocrService = OCRService();
  final PDFService _pdfService = PDFService();

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _cameraService.requestCameraPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Camera permission is required to scan receipts';
        });
        return;
      }

      // Initialize camera
      _cameraController = await _cameraService.initializeCamera();

      if (_cameraController != null) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to initialize camera';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        await _processReceipt(image);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error taking picture: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickPDF() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final pdfFile = await _pdfService.pickPDFFile();
      if (pdfFile != null) {
        await _processPDFReceipt(pdfFile);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking PDF: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        await _processReceipt(image);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processPDFReceipt(File pdfFile) async {
    try {
      final result = await _pdfService.processPDFReceipt(pdfFile);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Navigate to receipt items screen
        context.push('/receipt-items', extra: result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing PDF receipt: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processReceipt(XFile imageFile) async {
    try {
      final file = await _cameraService.xFileToFile(imageFile);
      if (file == null) {
        throw Exception('Failed to convert image file');
      }

      final result = await _ocrService.scanReceipt(file);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Navigate to receipt items screen
        context.push('/receipt-items', extra: result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing receipt: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isProcessing ? null : _pickPDF,
            tooltip: 'Upload PDF',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _isProcessing ? null : _pickFromGallery,
            tooltip: 'Pick from gallery',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return _buildLoadingView();
    }

    if (_isProcessing) {
      return _buildProcessingView();
    }

    return _buildCameraView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing camera...'),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing receipt...'),
          SizedBox(height: 8),
          Text(
            'Please wait while we extract the information',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Position the receipt within the frame',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure the text is clear and well-lit',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Or upload a PDF receipt using the PDF icon above',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Receipt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
