import 'dart:io';
import 'package:flutter/material.dart';
import 'package:visiontag/screens/home_mode_screen.dart';
import 'package:visiontag/screens/retail_mode_screen.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/gesture_provider.dart';
import 'package:visiontag/providers/accessibility_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService();
  int _selectedIndex = 0; // 0 for home mode, 1 for retail mode
  Offset? _startFocalPoint;
  double _initialScale = 1.0;
  bool _hasReturnedFromSubScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceCurrentMode());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ttsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _hasReturnedFromSubScreen) {
      // We've returned from a sub-screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceReturnToMainScreen();
        _hasReturnedFromSubScreen = false;
      });
    }
  }

  void _announceCurrentMode() {
    if (_hasReturnedFromSubScreen) {
      _announceReturnToMainScreen();
      _hasReturnedFromSubScreen = false;
      return;
    }
    
    final modeName = _selectedIndex == 0 ? "Home Mode" : "Retail Mode";
    _ttsService.speak(
      "Welcome to VisionTag. You are currently in the main screen. $modeName is selected. "
      "Double tap anywhere to enter $modeName. Swipe down to select retail mode. Pinch to exit application.",
      priority: SpeechPriority.high,
    );
  }

  void _announceReturnToMainScreen() async {
    final modeName = _selectedIndex == 0 ? "Home Mode" : "Retail Mode";
    await Future.delayed(const Duration(milliseconds: 700));
    _ttsService.speak(
      "You are currently in the main screen. $modeName is selected. "
      "Double tap anywhere to enter $modeName. Swipe down to select retail mode. Pinch to exit application.",
      priority: SpeechPriority.high,
    );
  }

  void _switchMode(int direction) {
    setState(() {
      _selectedIndex = (_selectedIndex + direction).clamp(0, 1);
    });
    
    if (_selectedIndex == 1) {
      _ttsService.speak("Retail Mode is selected. "
      "Double tap anywhere to enter Retail Mode. Swipe up to select home mode.",
          priority: SpeechPriority.high);
    }
    else {
      _ttsService.speak("Home Mode is selected. "
      "Double tap anywhere to enter Home Mode. Swipe down to select retail mode.",
          priority: SpeechPriority.high);
    }
  }

  void _enterSelectedMode() async {
    _hasReturnedFromSubScreen = true;
    
    if (_selectedIndex == 0) {
      _ttsService.speak("Entering Home Mode", priority: SpeechPriority.high);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeModeScreen()),
      );
    } else {
      _ttsService.speak("Entering Retail Mode", priority: SpeechPriority.high);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RetailModeScreen()),
      );
    }
    
    // When we return, announce that we're back in main screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceReturnToMainScreen();
      _hasReturnedFromSubScreen = false;
    });
  }

  void _handlePinch(double scale) {
    if (scale < 0.7) {
      _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
      Future.delayed(const Duration(milliseconds: 3000), () {
        exit(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();

    return Scaffold(
      body: GestureDetector(
        onScaleStart: (details) {
          _initialScale = 1.0;
          _startFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          // Pinch to exit
          if (details.scale < 0.7) {
            _handlePinch(details.scale);
          }
          // Swipe detection (up/down for mode switch)
          if (_startFocalPoint != null) {
            final dy = details.focalPoint.dy - _startFocalPoint!.dy;
            if (dy < -80) {
              _switchMode(-1);
              _startFocalPoint = null;
            } else if (dy > 80) {
              _switchMode(1);
              _startFocalPoint = null;
            }
          }
        },
        // Global double tap - enters the currently selected mode
        onDoubleTap: _enterSelectedMode,
        onLongPress: _announceCurrentMode,
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
                  hint: "Tap to select, double tap anywhere to enter",
                  button: true,
                  selected: _selectedIndex == 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                        _ttsService.speak(
                            "Home Mode selected. Double tap anywhere to enter.");
                      },
                      // Remove individual onDoubleTap since we handle it globally
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
                                    'Double tap anywhere to enter',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 16),
                                const Icon(
                                  Icons.swipe_up_rounded,
                                  size: 40,
                                  color: Colors.white70,
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
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                child: Semantics(
                  label:
                      "Retail Mode. Scan and explore clothing items while shopping.",
                  hint: "Tap to select, double tap anywhere to enter",
                  button: true,
                  selected: _selectedIndex == 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                        _ttsService.speak(
                            "Retail Mode selected. Double tap anywhere to enter.");
                      },
                      // Remove individual onDoubleTap since we handle it globally
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
                                    Theme.of(context).colorScheme.onPrimary,
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
                                          .onPrimary,
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
                                            .onPrimary,
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
                                        .onPrimary
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Double tap anywhere to enter',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 16),
                                const Icon(
                                  Icons.swipe_down_rounded,
                                  size: 40,
                                  color: Colors.white70,
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
}