import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tes/liveness/states.dart';
import 'package:tes/liveness/utils.dart';
import 'package:tes/screen/result.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

enum _FaceError { noFace, multiFace }

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen>
    with WidgetsBindingObserver {
  _FaceError? _faceError;
  final _stateText = ValueNotifier("");
  bool _isProcessingImage = false;
  final List<XFile> _photos = [];
  double _imageWidth = 0;
  double _imageHeight = 0;
  bool _needUpdateImageInfo = true;
  int _consecutiveEmptyFacesTimes = 0;

  CameraController? _controller;
  CameraDescription? _camera;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.9,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late LivenessContext _livenessContext;

  _LivenessScreenState() {
    _livenessContext = LivenessContext(
      states: [
        FrontFaceState(5),
        isLeftSideFaceState(1),
        isRightSideFaceState(1),   
        BlinkState(1),   
      ],
      stateChangeCallback: ({required next, required retry}) async {
        final file = await _takePhoto();
        if (file != null) {
          _photos.add(file);
          next();
        } else {
          retry();
        }
      },
      onCompleted: (photoCount) async {
        try {
          setState(() => _isLoading = true);
          final List<Uint8List> compressedPhotos = [];
          if (_photos.length >= photoCount) {
            final photos = _photos.sublist(_photos.length - photoCount, _photos.length);
            for (final photo in photos) {
              final bytes = await FlutterImageCompress.compressWithFile(
                photo.path,
                quality: 75,
                autoCorrectionAngle: true,
              );
              if (bytes == null) {
                _showErrorDialog("Failed to compress image");
                return;
              }
              compressedPhotos.add(bytes);
            }   
            try {
              final uri = Uri.parse("http://192.168.1.13:5000/api/upload");
              final request = http.MultipartRequest('POST', uri);   
              request.headers.addAll({
                'Accept': 'application/json',
                'Content-Type': 'multipart/form-data',
              });

              
              request.files.add(
                http.MultipartFile.fromBytes(
                  'file', 
                  compressedPhotos.last,
                  filename: 'smile.jpg',
                  contentType: MediaType('image', 'jpeg'),
                ),
              );

              
              request.fields['type'] = 'smile';

              final streamedResponse = await request.send();
              final response = await http.Response.fromStream(streamedResponse);   
              print('Response status: ${response.statusCode}');
              print('Response body: ${response.body}');

              if (response.statusCode == 200) {
                final result = jsonDecode(response.body);
                
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(
                        result: result,
                        imageBytes: compressedPhotos.last,
                      ),
                    ),
                  );
                }
              } else {
                throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
              }
            } catch (e) {
              print('Error uploading: $e');
              _showErrorDialog("Failed to upload photo: $e");
            }
          } else {
            _showErrorDialog("Not enough photos captured");
          }
        } catch (e) {
          log("Error in onCompleted: $e");
          _showErrorDialog("An error occurred");
        }finally {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initCameraController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {   
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController();
    }
  }

  Future<void> _initCameraController() async {
    final cameras = await availableCameras();
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == CameraLensDirection.front) {
        _camera = cameras[i];
        break;
      }
    }
    if (_camera == null) {
      log("Front camera not found!");
      return;
    }

    final controller = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {});
        controller.startImageStream((image) {
          _processImage(image);
        });
      }
    } on CameraException catch (e) {
      log("initializeCameraController failed", error: e);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }   
  void _processImage(CameraImage image) async {
    if (_livenessContext.isCompleted || _isProcessingImage) return;
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null || inputImage.metadata == null) {
      return;
    }
    _isProcessingImage = true;

    if (_needUpdateImageInfo) {
      final imageSize = inputImage.metadata!.size;
      final rotatiton = inputImage.metadata!.rotation;
      switch (rotatiton) {
        case InputImageRotation.rotation180deg:
        case InputImageRotation.rotation0deg:
          _imageWidth = imageSize.width;
          _imageHeight = imageSize.height;
          break;
        case InputImageRotation.rotation270deg:
        case InputImageRotation.rotation90deg:
          _imageWidth = imageSize.height;
          _imageHeight = imageSize.width;
          break;
      }
      _needUpdateImageInfo = false;
    }

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.length > 1) {
      _onFaceError(_FaceError.multiFace);
      _livenessContext.reset();
    } else if (faces.isEmpty ||
        !DetectionUtils.isWholeFace(faces.first, _imageWidth, _imageHeight)) {
      _consecutiveEmptyFacesTimes++;
      if (_consecutiveEmptyFacesTimes >= 5) {
        _consecutiveEmptyFacesTimes = 0;
        _onFaceError(_FaceError.noFace);
        _livenessContext.reset();
      }
    } else {
      _consecutiveEmptyFacesTimes = 0;
      final face = faces.first;
      _onFaceFrame(_livenessContext.currentState);
      _livenessContext.handle(face);
    }
    _isProcessingImage = false;
  }

  void _onFaceError(_FaceError error) {
    _faceError = error;
    switch (error) {
      case _FaceError.noFace:
        _stateText.value = "No faces detected";
      case _FaceError.multiFace:
        _stateText.value = "Multiple faces detected";
    }
  }

  void _onFaceFrame(LivenessState state) {
    _faceError = null;
    if (state is FrontFaceState) {
      _stateText.value = "Please look at the camera";
    } else if (state is isLeftSideFaceState) {
      _stateText.value = "Please show your Left side face";
    } else if (state is isRightSideFaceState) {
      _stateText.value = "Please show your Right side face";      
    } else if (state is BlinkState) {
      _stateText.value = "Please blink";
    }         
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = _controller;
    final camera = _camera;
    if (controller == null ||
        !controller.value.isInitialized ||
        camera == null) {
      return null;
    }

    
    final sensorOrientation = camera.sensorOrientation;
    var rotationCompensation =
        _orientations[controller.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {   
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {   
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(rotationCompensation);
    if (rotation == null) return null;   
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || format != InputImageFormat.nv21) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;   
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow),
    );
  }

  Future<XFile?> _takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }
    try {
      return await controller.takePicture();
    } on CameraException catch (e, s) {
      log("take photo failed", error: e, stackTrace: s);
      return null;
    }
  }
  
  bool _isLoading = false;
  Widget _buildLoadingOverlay() {
  return Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Processing...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}



  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Widget _cameraPreview() {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return const SizedBox();
    } else {
      return SizedBox(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cameraController.value.previewSize?.height,
                height: cameraController.value.previewSize?.width,
                child: CameraPreview(cameraController),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liveness"),
        centerTitle: true,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded)),
      ),
      body: SizedBox.expand(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _stateText,
              builder: (context, value, child) {
                return Text(
                  value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _faceError == null ? Colors.black : Colors.red),
                );
              },
            ),
            if (_isLoading) _buildLoadingOverlay(),
            const SizedBox(height: 20),
            FractionallySizedBox(widthFactor: 0.72, child: _cameraPreview()),
          ],
        ),
      ),
    );
  }
}
