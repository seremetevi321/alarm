import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../theme/app_theme.dart';
import '../services/alarm_service.dart';

enum _Phase { unknown, up, down }

class PushUpCounter extends StatefulWidget {
  final int alarmId;
  final int targetReps;
  final VoidCallback onCompleted;

  const PushUpCounter({
    super.key,
    required this.alarmId,
    this.targetReps = 10,
    required this.onCompleted,
  });

  @override
  State<PushUpCounter> createState() => _PushUpCounterState();
}

class _PushUpCounterState extends State<PushUpCounter> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  // Более узкий зазор между порогами — засчитывает даже неполное сгибание руки
  static const double _downThreshold = 110;
  static const double _upThreshold = 135;
  // Меньше кадров подтверждения — быстрее реагирует на смену направления
  static const int _requiredConsecutiveFrames = 2;
  // Минимальная уверенность модели в точке, чтобы мы её вообще использовали
  static const double _minLikelihood = 0.5;
  // Меньшее окно сглаживания — меньше задержка реакции
  static const int _smoothingWindow = 3;

  final List<double> _recentAngles = [];
  _Phase _phase = _Phase.unknown;
  int _consecutiveCount = 0;
  bool _volumeLowered = false;

  int _repCount = 0;
  bool _isProcessing = false;
  String _statusText = 'Найдите тело в кадре';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      setState(() => _statusText = 'Камера не найдена на этом устройстве');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    await _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        if (poses.isNotEmpty) {
          _handlePose(poses.first);
        } else {
          setState(() => _statusText = 'Найдите тело в кадре');
        }
      }
    } catch (_) {
      // Игнорируем отдельные сбойные кадры
    }

    _isProcessing = false;
  }

  void _handlePose(Pose pose) {
    final angle = _getReliableElbowAngle(pose);

    if (angle == null) {
      setState(() => _statusText = 'Не вижу руки целиком, отойдите дальше');
      return;
    }

    // Сглаживание — усредняем последние несколько кадров
    _recentAngles.add(angle);
    if (_recentAngles.length > _smoothingWindow) {
      _recentAngles.removeAt(0);
    }
    final smoothedAngle = _recentAngles.reduce((a, b) => a + b) / _recentAngles.length;

    // Пока не набрали достаточно кадров для сглаживания — ничего не решаем
    if (_recentAngles.length < _smoothingWindow) {
      setState(() => _statusText = 'Калибровка...');
      return;
    }

    _evaluatePhase(smoothedAngle);
  }

  void _evaluatePhase(double smoothedAngle) {
    if (smoothedAngle < _downThreshold) {
      if (_phase == _Phase.down) {
        _consecutiveCount = 0; // уже в этой фазе, просто остаёмся
      } else {
        _consecutiveCount++;
        if (_consecutiveCount >= _requiredConsecutiveFrames) {
          setState(() {
            _phase = _Phase.down;
            _statusText = 'Вниз! Теперь поднимитесь';
            _consecutiveCount = 0;
          });
        }
      }
    } else if (smoothedAngle > _upThreshold) {
      if (_phase == _Phase.up) {
        _consecutiveCount = 0;
      } else {
        _consecutiveCount++;
        if (_consecutiveCount >= _requiredConsecutiveFrames) {
          final wasDown = _phase == _Phase.down;
          setState(() {
            _phase = _Phase.up;
            _consecutiveCount = 0;
          });

          // Засчитываем повторение только если перед этим реально
          // зафиксировали нижнюю точку
          if (wasDown) {
            _repCount++;
            setState(() => _statusText = 'Отлично! Ещё раз');

            if (!_volumeLowered) {
              _volumeLowered = true;
              AlarmService.lowerVolume(widget.alarmId);
            }

            if (_repCount >= widget.targetReps) {
              _cameraController?.stopImageStream();
              widget.onCompleted();
            }
          } else {
            setState(() => _statusText = 'Опуститесь ниже для засчёта');
          }
        }
      }
    } else {
      // Угол в промежуточной зоне между порогами — сбрасываем счётчик
      // подтверждения, чтобы не накапливать шум между состояниями
      _consecutiveCount = 0;
    }
  }

  // Возвращает средний угол по обеим рукам, используя только те точки,
  // в которых модель достаточно уверена. Если видна только одна рука —
  // используем её.
  double? _getReliableElbowAngle(Pose pose) {
    final leftAngle = _getArmAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final rightAngle = _getArmAngle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );

    if (leftAngle != null && rightAngle != null) {
      return (leftAngle + rightAngle) / 2;
    }
    return leftAngle ?? rightAngle;
  }

  double? _getArmAngle(
    Pose pose,
    PoseLandmarkType shoulderType,
    PoseLandmarkType elbowType,
    PoseLandmarkType wristType,
  ) {
    final shoulder = pose.landmarks[shoulderType];
    final elbow = pose.landmarks[elbowType];
    final wrist = pose.landmarks[wristType];

    if (shoulder == null || elbow == null || wrist == null) return null;

    if (shoulder.likelihood < _minLikelihood ||
        elbow.likelihood < _minLikelihood ||
        wrist.likelihood < _minLikelihood) {
      return null;
    }

    return _calculateAngle(shoulder, elbow, wrist);
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    var angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: Text(
          _statusText,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: CameraPreview(_cameraController!),
                ),
                // Лёгкая рамка-индикатор — подсвечивается акцентным цветом,
                // когда тело уверенно распознано
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _recentAngles.length >= _smoothingWindow
                          ? AppTheme.accent.withOpacity(0.7)
                          : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Анимированная смена цифр счётчика
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Text(
            '$_repCount / ${widget.targetReps}',
            key: ValueKey(_repCount),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _statusText,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}