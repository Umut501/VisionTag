import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider with ChangeNotifier {
  // Theme settings
  ThemeMode _themeMode = ThemeMode.system;
  bool _useHighContrast = false;
  double _textScaleFactor = 1.0;

  // TTS settings
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  bool _announceActions = true;
  bool _verboseMode = false;

  // Navigation settings
  bool _simplifiedNavigation = false;
  int _itemsPerPage = 4;

  AccessibilityProvider() {
    _loadSettings();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get useHighContrast => _useHighContrast;
  double get textScaleFactor => _textScaleFactor;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  bool get announceActions => _announceActions;
  bool get verboseMode => _verboseMode;
  bool get simplifiedNavigation => _simplifiedNavigation;
  int get itemsPerPage => _itemsPerPage;

  // Load settings from storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    _useHighContrast = prefs.getBool('useHighContrast') ?? false;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _speechRate = prefs.getDouble('speechRate') ?? 0.5;
    _pitch = prefs.getDouble('pitch') ?? 1.0;
    _volume = prefs.getDouble('volume') ?? 1.0;
    _announceActions = prefs.getBool('announceActions') ?? true;
    _verboseMode = prefs.getBool('verboseMode') ?? false;
    _simplifiedNavigation = prefs.getBool('simplifiedNavigation') ?? false;
    _itemsPerPage = prefs.getInt('itemsPerPage') ?? 4;

    notifyListeners();
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setBool('useHighContrast', _useHighContrast);
    await prefs.setDouble('textScaleFactor', _textScaleFactor);
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setDouble('pitch', _pitch);
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('announceActions', _announceActions);
    await prefs.setBool('verboseMode', _verboseMode);
    await prefs.setBool('simplifiedNavigation', _simplifiedNavigation);
    await prefs.setInt('itemsPerPage', _itemsPerPage);
  }

  // Setters
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _saveSettings();
  }

  void setHighContrast(bool value) {
    _useHighContrast = value;
    notifyListeners();
    _saveSettings();
  }

  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    notifyListeners();
    _saveSettings();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.1, 1.0);
    notifyListeners();
    _saveSettings();
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.5, 2.0);
    notifyListeners();
    _saveSettings();
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
    _saveSettings();
  }

  void setAnnounceActions(bool value) {
    _announceActions = value;
    notifyListeners();
    _saveSettings();
  }

  void setVerboseMode(bool value) {
    _verboseMode = value;
    notifyListeners();
    _saveSettings();
  }

  void setSimplifiedNavigation(bool value) {
    _simplifiedNavigation = value;
    notifyListeners();
    _saveSettings();
  }

  void setItemsPerPage(int items) {
    _itemsPerPage = items.clamp(1, 9);
    notifyListeners();
    _saveSettings();
  }

  // Reset all settings to default
  void resetToDefaults() {
    _themeMode = ThemeMode.system;
    _useHighContrast = false;
    _textScaleFactor = 1.0;
    _speechRate = 0.5;
    _pitch = 1.0;
    _volume = 1.0;
    _announceActions = true;
    _verboseMode = false;
    _simplifiedNavigation = false;
    _itemsPerPage = 4;

    notifyListeners();
    _saveSettings();
  }
}
