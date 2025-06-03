import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GestureProvider with ChangeNotifier {
  // Gesture settings
  bool _enableSwipeNavigation = true;
  bool _enableShakeToRepeat = true;
  bool _enableLongPressHelp = true;
  bool _enableDoubleTapBack = true;  
  // Haptic feedback settings
  bool _enableHapticFeedback = true;
  HapticIntensity _hapticIntensity = HapticIntensity.medium;

  // Getters
  bool get enableSwipeNavigation => _enableSwipeNavigation;
  bool get enableShakeToRepeat => _enableShakeToRepeat;
  bool get enableLongPressHelp => _enableLongPressHelp;
  bool get enableDoubleTapBack => _enableDoubleTapBack;
  bool get enableHapticFeedback => _enableHapticFeedback;
  HapticIntensity get hapticIntensity => _hapticIntensity;

  // Setters
  void setSwipeNavigation(bool value) {
    _enableSwipeNavigation = value;
    notifyListeners();
  }

  void setShakeToRepeat(bool value) {
    _enableShakeToRepeat = value;
    notifyListeners();
  }

  void setLongPressHelp(bool value) {
    _enableLongPressHelp = value;
    notifyListeners();
  }

  void setDoubleTapBack(bool value) {
    _enableDoubleTapBack = value;
    notifyListeners();
  }

  void setHapticFeedback(bool value) {
    _enableHapticFeedback = value;
    notifyListeners();
  }

  void setHapticIntensity(HapticIntensity intensity) {
    _hapticIntensity = intensity;
    notifyListeners();
  }

  // Trigger haptic feedback based on settings
  void triggerHaptic({HapticType type = HapticType.selection}) {
    if (!_enableHapticFeedback) return;

    switch (type) {
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.impact:
        switch (_hapticIntensity) {
          case HapticIntensity.light:
            HapticFeedback.lightImpact();
            break;
          case HapticIntensity.medium:
            HapticFeedback.mediumImpact();
            break;
          case HapticIntensity.heavy:
            HapticFeedback.heavyImpact();
            break;
        }
        break;
      case HapticType.warning:
        HapticFeedback.vibrate();
        break;
    }
  }
}

enum HapticIntensity { light, medium, heavy }
enum HapticType { selection, impact, warning }