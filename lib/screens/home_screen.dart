import 'package:flutter/material.dart';
import 'package:visiontag/screens/home_mode_screen.dart';
import 'package:visiontag/screens/retail_mode_screen.dart';
import 'package:visiontag/screens/settings_screen.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/widgets/gesture_detector_widget.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/gesture_provider.dart';
import 'package:visiontag/providers/accessibility_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _ttsService = TtsService();
  int _selectedIndex = 0; // 0 for home mode, 1 for retail mode

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    final accessibilityProvider = context.read<AccessibilityProvider>();
    await _ttsService.initTts(accessibilityProvider: accessibilityProvider);

    // Add a small delay to ensure the screen is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    _speakWelcome();
  }

  void _speakWelcome() {
    _ttsService.speak(
      "Welcome to VisionTag. ${_selectedIndex == 0 ? 'Home Mode' : 'Retail Mode'} is selected. "
      "Swipe up or down to switch modes. Double tap to enter selected mode. "
      "Long press for help. Triple tap for settings.",
      priority: SpeechPriority.high,
    );
  }

  void _switchMode(int direction) {
    final provider = context.read<GestureProvider>();
    provider.triggerHaptic(type: HapticType.selection);

    setState(() {
      _selectedIndex = (_selectedIndex + direction).clamp(0, 1);
    });

    final modeName = _selectedIndex == 0 ? "Home Mode" : "Retail Mode";
    _ttsService.speak("$modeName selected. Double tap to enter.",
        priority: SpeechPriority.high);
  }

  void _enterSelectedMode() {
    final provider = context.read<GestureProvider>();
    provider.triggerHaptic(type: HapticType.impact);

    if (_selectedIndex == 0) {
      _ttsService.speak("Entering Home Mode", priority: SpeechPriority.high);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeModeScreen()),
      );
    } else {
      _ttsService.speak("Entering Retail Mode", priority: SpeechPriority.high);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RetailModeScreen()),
      );
    }
  }

  void _openSettings() {
    final provider = context.read<GestureProvider>();
    provider.triggerHaptic(type: HapticType.impact);

    _ttsService.speak("Opening settings", priority: SpeechPriority.high);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _handleSectionTap(int sectionIndex) {
    final provider = context.read<GestureProvider>();
    provider.triggerHaptic(type: HapticType.selection);

    setState(() => _selectedIndex = sectionIndex);
    final modeName = sectionIndex == 0 ? "Home Mode" : "Retail Mode";
    _ttsService.speak("$modeName selected. Double tap to enter.",
        priority: SpeechPriority.normal);
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();

    return Scaffold(
      body: GestureDetectorWidget(
        onSwipeUp: () => _switchMode(-1),
        onSwipeDown: () => _switchMode(1),
        onDoubleTap: _enterSelectedMode,
        onLongPress: () => _speakWelcome(),
        onTripleTap: _openSettings,
        onShake: () => _ttsService.repeatLastSpoken(),
        helpText:
            "Home screen. Swipe up or down to switch between Home and Retail modes. "
            "Double tap to enter the selected mode. Triple tap for settings.",
        child: Column(
          children: [
            // Home Mode Section
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                color: _selectedIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                child: Semantics(
                  label:
                      "Home Mode. Manage your wardrobe and scan clothing items at home.",
                  hint: "Tap to select, double tap to enter",
                  button: true,
                  selected: _selectedIndex == 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleSectionTap(0),
                      onDoubleTap: () {
                        if (_selectedIndex == 0) {
                          _enterSelectedMode();
                        } else {
                          setState(() => _selectedIndex = 0);
                          _ttsService.speak(
                              "Home Mode selected. Double tap again to enter.");
                        }
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home,
                                size: _selectedIndex == 0 ? 100 : 80,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Home Mode',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: _selectedIndex == 0
                                          ? 32 *
                                              accessibilityProvider
                                                  .textScaleFactor
                                          : 28 *
                                              accessibilityProvider
                                                  .textScaleFactor,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Manage your wardrobe',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                ),
                              ),
                              if (_selectedIndex == 0) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Double tap to enter',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Divider with gesture indicator
            Container(
              height: 4,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Retail Mode Section
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                color: _selectedIndex == 1
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                child: Semantics(
                  label:
                      "Retail Mode. Scan and explore clothing items while shopping.",
                  hint: "Tap to select, double tap to enter",
                  button: true,
                  selected: _selectedIndex == 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleSectionTap(1),
                      onDoubleTap: () {
                        if (_selectedIndex == 1) {
                          _enterSelectedMode();
                        } else {
                          setState(() => _selectedIndex = 1);
                          _ttsService.speak(
                              "Retail Mode selected. Double tap again to enter.");
                        }
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: _selectedIndex == 1 ? 100 : 80,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Retail Mode',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                      fontSize: _selectedIndex == 1
                                          ? 32 *
                                              accessibilityProvider
                                                  .textScaleFactor
                                          : 28 *
                                              accessibilityProvider
                                                  .textScaleFactor,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Shop with confidence',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
                                ),
                              ),
                              if (_selectedIndex == 1) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Double tap to enter',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
