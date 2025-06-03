import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/gesture_provider.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class GestureDetectorWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onShake;
  final VoidCallback? onDoubleTapTwoFingers;
  final bool enableShake;
  final String? helpText;

  const GestureDetectorWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onShake,
    this.onDoubleTapTwoFingers,
    this.enableShake = true,
    this.helpText,
  }) : super(key: key);

  @override
  State<GestureDetectorWidget> createState() => _GestureDetectorWidgetState();
}

class _GestureDetectorWidgetState extends State<GestureDetectorWidget> {
  final TtsService _ttsService = TtsService();
  
  // Gesture detection variables
  Offset? _initialPosition;
  DateTime? _lastTapTime;
  int _tapCount = 0;
  Timer? _tapTimer;
  
  // Shake detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  final double _shakeThreshold = 20.0;  // change to adjust shake sensitivity

  @override
  void initState() {
    super.initState();
    if (widget.enableShake && widget.onShake != null) {
      _initShakeDetection();
    }
  }

  void _initShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final provider = context.read<GestureProvider>();
      if (!provider.enableShakeToRepeat) return;

      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );

      if (acceleration > _shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds > 1000) {
          _lastShakeTime = now;
          widget.onShake?.call();
          provider.triggerHaptic(type: HapticType.impact);
        }
      }
    });
  }

  void _handleTap() {
    final provider = context.read<GestureProvider>();
    provider.triggerHaptic(type: HapticType.selection);

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 500), () {
      if (_tapCount == 1) {
        widget.onTap?.call();
      } else if (_tapCount == 2) {
        widget.onDoubleTap?.call();
      }
      _tapCount = 0;
    });
  }

  void _handleLongPress() {
    final provider = context.read<GestureProvider>();
    
    if (provider.enableLongPressHelp && widget.helpText != null) {
      provider.triggerHaptic(type: HapticType.impact);
      _ttsService.speak(widget.helpText!, priority: SpeechPriority.high);
    }
    
    widget.onLongPress?.call();
  }

  void _handlePanStart(DragStartDetails details) {
    _initialPosition = details.globalPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_initialPosition == null) return;

    final dx = details.globalPosition.dx - _initialPosition!.dx;
    final dy = details.globalPosition.dy - _initialPosition!.dy;
    
    final provider = context.read<GestureProvider>();
    if (!provider.enableSwipeNavigation) return;

    // Determine swipe direction
    if (dx.abs() > dy.abs()) {
      if (dx > 50) {
        widget.onSwipeRight?.call();
        provider.triggerHaptic(type: HapticType.selection);
        _initialPosition = null;
      } else if (dx < -50) {
        widget.onSwipeLeft?.call();
        provider.triggerHaptic(type: HapticType.selection);
        _initialPosition = null;
      }
    } else {
      if (dy > 50) {
        widget.onSwipeDown?.call();
        provider.triggerHaptic(type: HapticType.selection);
        _initialPosition = null;
      } else if (dy < -50) {
        widget.onSwipeUp?.call();
        provider.triggerHaptic(type: HapticType.selection);
        _initialPosition = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
  onTap: _handleTap,
  onLongPress: _handleLongPress,
  onScaleStart: (details) {
    // Handle the start of scaling/panning
    _handlePanStart(DragStartDetails(
      globalPosition: details.focalPoint,
      localPosition: details.localFocalPoint,
    ));
  },
  onScaleUpdate: (details) {
    // Handle two-finger double tap
    if (details.pointerCount == 2 && widget.onDoubleTapTwoFingers != null) {
      final provider = context.read<GestureProvider>();
      if (provider.enableDoubleTapBack) {
        widget.onDoubleTapTwoFingers!.call();
        provider.triggerHaptic(type: HapticType.impact);
      }
    }
    
    // Handle pan updates (single finger drag)
    if (details.pointerCount == 1) {
      _handlePanUpdate(DragUpdateDetails(
        globalPosition: details.focalPoint,
        localPosition: details.localFocalPoint,
        delta: details.focalPointDelta,
      ));
    }
  },
  child: widget.child,
);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _tapTimer?.cancel();
    super.dispose();
  }
}