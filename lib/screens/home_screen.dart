import 'package:flutter/material.dart';
import 'package:visiontag/screens/home-mode-screen.dart';
import 'package:visiontag/screens/retail_mode_screen.dart';
import 'package:visiontag/services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    _ttsService.speak(
        "Welcome to VisionTag. Tap the top half of the screen for Home Mode or the bottom half for Retail Mode");
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

// In home_screen.dart, modify the build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Home Mode Button (Top Half)
          Expanded(
            child: GestureDetector(
              onTap: () {
                _ttsService.speak("Home Mode. Double tap to enter.");
              },
              onDoubleTap: () {
                _ttsService.speak("Opening Home Mode");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeModeScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      size: 80,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Home Mode',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Manage your wardrobe and scan clothing items at home',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Retail Mode Button (Bottom Half)
          Expanded(
            child: GestureDetector(
              onTap: () {
                _ttsService.speak("Retail Mode. Double tap to enter.");
              },
              onDoubleTap: () {
                _ttsService.speak("Opening Retail Mode");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RetailModeScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Retail Mode',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Scan and explore clothing items while shopping',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
