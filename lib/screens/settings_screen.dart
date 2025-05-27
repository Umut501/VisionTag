import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/accessibility_provider.dart';
import 'package:visiontag/providers/gesture_provider.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/widgets/gesture_detector_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    _ttsService.speak("Settings. Customize your VisionTag experience.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: GestureDetectorWidget(
        onLongPress: () => _ttsService.speak(
          "Settings screen. Adjust text size, speech settings, gestures, and more.",
          priority: SpeechPriority.high,
        ),
        onShake: () => _ttsService.repeatLastSpoken(),
        helpText: "Settings screen. Swipe to navigate through options. "
            "Double tap to change settings.",
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Display Settings'),
              _buildDisplaySettings(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Speech Settings'),
              _buildSpeechSettings(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Gesture Settings'),
              _buildGestureSettings(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Navigation Settings'),
              _buildNavigationSettings(),
              const SizedBox(height: 24),
              
              _buildResetButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return Consumer<AccessibilityProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Column(
            children: [
              // Theme Mode
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeName(provider.themeMode)),
                leading: const Icon(Icons.brightness_6),
                onTap: () => _showThemeDialog(provider),
              ),
              const Divider(),
              
              // High Contrast
              SwitchListTile(
                title: const Text('High Contrast'),
                subtitle: const Text('Enhance visibility with stronger colors'),
                value: provider.useHighContrast,
                onChanged: (value) {
                  provider.setHighContrast(value);
                  _ttsService.speak(
                    "High contrast ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
              const Divider(),
              
              // Text Size
              ListTile(
                title: const Text('Text Size'),
                subtitle: Slider(
                  value: provider.textScaleFactor,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  label: '${(provider.textScaleFactor * 100).round()}%',
                  onChanged: (value) {
                    provider.setTextScaleFactor(value);
                  },
                  onChangeEnd: (value) {
                    _ttsService.speak(
                      "Text size set to ${(value * 100).round()} percent",
                    );
                  },
                ),
                leading: const Icon(Icons.text_fields),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeechSettings() {
    return Consumer<AccessibilityProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Column(
            children: [
              // Speech Rate
              ListTile(
                title: const Text('Speech Rate'),
                subtitle: Slider(
                  value: provider.speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(provider.speechRate * 100).round()}%',
                  onChanged: (value) {
                    provider.setSpeechRate(value);
                    _ttsService.updateSettings(provider);
                  },
                  onChangeEnd: (value) {
                    _ttsService.speak("Speech rate adjusted");
                  },
                ),
                leading: const Icon(Icons.speed),
              ),
              const Divider(),
              
              // Pitch
              ListTile(
                title: const Text('Voice Pitch'),
                subtitle: Slider(
                  value: provider.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${(provider.pitch * 100).round()}%',
                  onChanged: (value) {
                    provider.setPitch(value);
                    _ttsService.updateSettings(provider);
                  },
                  onChangeEnd: (value) {
                    _ttsService.speak("Voice pitch adjusted");
                  },
                ),
                leading: const Icon(Icons.record_voice_over),
              ),
              const Divider(),
              
              // Volume
              ListTile(
                title: const Text('Volume'),
                subtitle: Slider(
                  value: provider.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(provider.volume * 100).round()}%',
                  onChanged: (value) {
                    provider.setVolume(value);
                    _ttsService.updateSettings(provider);
                  },
                  onChangeEnd: (value) {
                    _ttsService.speak("Volume adjusted");
                  },
                ),
                leading: const Icon(Icons.volume_up),
              ),
              const Divider(),
              
              // Verbose Mode
              SwitchListTile(
                title: const Text('Verbose Mode'),
                subtitle: const Text('Provide detailed voice descriptions'),
                value: provider.verboseMode,
                onChanged: (value) {
                  provider.setVerboseMode(value);
                  _ttsService.speak(
                    "Verbose mode ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
              const Divider(),
              
              // Announce Actions
              SwitchListTile(
                title: const Text('Announce Actions'),
                subtitle: const Text('Speak when performing actions'),
                value: provider.announceActions,
                onChanged: (value) {
                  provider.setAnnounceActions(value);
                  _ttsService.speak(
                    "Action announcements ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGestureSettings() {
    return Consumer<GestureProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Column(
            children: [
              // Swipe Navigation
              SwitchListTile(
                title: const Text('Swipe Navigation'),
                subtitle: const Text('Navigate with swipe gestures'),
                value: provider.enableSwipeNavigation,
                onChanged: (value) {
                  provider.setSwipeNavigation(value);
                  _ttsService.speak(
                    "Swipe navigation ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
              const Divider(),
              
              // Shake to Repeat
              SwitchListTile(
                title: const Text('Shake to Repeat'),
                subtitle: const Text('Shake device to repeat last speech'),
                value: provider.enableShakeToRepeat,
                onChanged: (value) {
                  provider.setShakeToRepeat(value);
                  _ttsService.speak(
                    "Shake to repeat ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
              const Divider(),
              
              // Long Press Help
              SwitchListTile(
                title: const Text('Long Press for Help'),
                subtitle: const Text('Get help with long press'),
                value: provider.enableLongPressHelp,
                onChanged: (value) {
                  provider.setLongPressHelp(value);
                  _ttsService.speak(
                    "Long press help ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
              const Divider(),
              
              // Haptic Feedback
              SwitchListTile(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on interactions'),
                value: provider.enableHapticFeedback,
                onChanged: (value) {
                  provider.setHapticFeedback(value);
                  _ttsService.speak(
                    "Haptic feedback ${value ? 'enabled' : 'disabled'}",
                  );
                  if (value) {
                    provider.triggerHaptic(type: HapticType.selection);
                  }
                },
              ),
              const Divider(),
              
              // Haptic Intensity
              if (provider.enableHapticFeedback)
                ListTile(
                  title: const Text('Haptic Intensity'),
                  subtitle: Text(_getHapticIntensityName(provider.hapticIntensity)),
                  leading: const Icon(Icons.vibration),
                  onTap: () => _showHapticIntensityDialog(provider),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationSettings() {
    return Consumer<AccessibilityProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Column(
            children: [
              // Simplified Navigation
              SwitchListTile(
                title: const Text('Simplified Navigation'),
                subtitle: const Text('Reduce complexity for easier use'),
                value: provider.simplifiedNavigation,
                onChanged: (value) {
                  provider.setSimplifiedNavigation(value);
                  _ttsService.speak(
                    "Simplified navigation ${value ? 'enabled' : 'disabled'}",
                  );
                },
              ),
              const Divider(),
              
              // Items Per Page
              ListTile(
                title: const Text('Items Per Page'),
                subtitle: Text('${provider.itemsPerPage} items'),
                leading: const Icon(Icons.grid_view),
                onTap: () => _showItemsPerPageDialog(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResetButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showResetDialog(),
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getHapticIntensityName(HapticIntensity intensity) {
    switch (intensity) {
      case HapticIntensity.light:
        return 'Light';
      case HapticIntensity.medium:
        return 'Medium';
      case HapticIntensity.heavy:
        return 'Heavy';
    }
  }

  void _showThemeDialog(AccessibilityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeName(mode)),
              value: mode,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.setThemeMode(value);
                  _ttsService.speak("Theme changed to ${_getThemeName(value)}");
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHapticIntensityDialog(GestureProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haptic Intensity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HapticIntensity.values.map((intensity) {
            return RadioListTile<HapticIntensity>(
              title: Text(_getHapticIntensityName(intensity)),
              value: intensity,
              groupValue: provider.hapticIntensity,
              onChanged: (value) {
                if (value != null) {
                  provider.setHapticIntensity(value);
                  provider.triggerHaptic(type: HapticType.impact);
                  _ttsService.speak(
                    "Haptic intensity set to ${_getHapticIntensityName(value)}",
                  );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showItemsPerPageDialog(AccessibilityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Items Per Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 4, 6, 9].map((count) {
            return RadioListTile<int>(
              title: Text('$count items'),
              value: count,
              groupValue: provider.itemsPerPage,
              onChanged: (value) {
                if (value != null) {
                  provider.setItemsPerPage(value);
                  _ttsService.speak("Items per page set to $value");
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AccessibilityProvider>().resetToDefaults();
              _ttsService.speak("All settings reset to defaults");
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}