import 'package:flutter/services.dart';

class HapticService {
  /// Hafif bir titreşim sağlar
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Orta şiddette bir titreşim sağlar
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Güçlü bir titreşim sağlar
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Seçim yapıldığında titreşim sağlar
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Başarılı bir işlem için titreşim sağlar
  static void success() {
    HapticFeedback.vibrate();
  }

  /// Uyarı için titreşim sağlar
  static void warning() {
    HapticFeedback.vibrate();
  }

  /// Hata için titreşim sağlar
  static void error() {
    HapticFeedback.vibrate();
  }

  /// Kaydırma hareketi için titreşim sağlar
  static void swipe() {
    HapticFeedback.lightImpact();
  }

  /// Üç kez dokunma için titreşim sağlar
  static void tripleTap() {
    HapticFeedback.mediumImpact();
  }
}
