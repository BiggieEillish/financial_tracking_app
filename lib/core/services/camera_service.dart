import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;

  // Get available cameras
  Future<List<CameraDescription>> getAvailableCameras() async {
    if (_cameras != null) return _cameras!;

    try {
      _cameras = await availableCameras();
      return _cameras!;
    } catch (e) {
      print('Error getting available cameras: $e');
      return [];
    }
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Initialize camera controller
  Future<CameraController?> initializeCamera({
    CameraDescription? cameraDescription,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    try {
      if (_cameras == null) {
        await getAvailableCameras();
      }

      if (_cameras!.isEmpty) {
        print('No cameras available');
        return null;
      }

      final camera = cameraDescription ?? _cameras!.first;
      _controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      return _controller;
    } catch (e) {
      print('Error initializing camera: $e');
      return null;
    }
  }

  // Take picture using camera controller
  Future<XFile?> takePicture() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        print('Camera not initialized');
        return null;
      }

      final image = await _controller!.takePicture();
      return image;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Convert XFile to File
  Future<File?> xFileToFile(XFile xFile) async {
    try {
      return File(xFile.path);
    } catch (e) {
      print('Error converting XFile to File: $e');
      return null;
    }
  }

  // Dispose camera controller
  void dispose() {
    _controller?.dispose();
  }

  // Get camera controller
  CameraController? get controller => _controller;
}
