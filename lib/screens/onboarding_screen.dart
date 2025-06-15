import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visiontag/screens/home_screen.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/widgets/gesture_detector_widget.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/gesture_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

int statusPage = 0;

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TtsService _ttsService = TtsService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to VisionTag",
      description:
          "Your accessible wardrobe assistant. Let's learn how to use the app with simple gestures.",
      instruction: "Swipe left to continue",
      gestureType: GestureType.swipeLeft,
    ),
    OnboardingPage(
      title: "Basic Navigation",
      description:
          "Tap once to hear information. Double tap to select or activate.",
      instruction: "Try double tapping anywhere on the screen",
      gestureType: GestureType.doubleTap,
    ),
    OnboardingPage(
      title: "Change Item Status",
      description:
          "Hold anywhere on the screen to change item status.",
      instruction: "Try holding anywhere on the screen.",
      gestureType: GestureType.longPress,
    ),
    OnboardingPage(
      title: "Swipe Gestures",
      description: "Fling left or right to browse item pages.",
      instruction: "Fling left to continue",
      gestureType: GestureType.swipeLeft,
    ),
    OnboardingPage(
      title: "Help Gesture",
      description: "Shake your device gently for help.",
      instruction: "Try shaking your device",
      gestureType: GestureType.shake,
    ),
    OnboardingPage(
      title: "Tutorial Complete",
      description: "Swipe right to go to previous page.",
      instruction: "Double tap to finish the tutorial",
      gestureType: GestureType.check,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    _speakCurrentPage();
  }

  void _speakCurrentPage() {
    final page = _pages[_currentPage];
    _ttsService.speak(
      "${page.title}. ${page.description}. ${page.instruction}",
      priority: SpeechPriority.high,
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    _ttsService.speak(
      "Tutorial complete! Welcome to VisionTag",
      priority: SpeechPriority.high,
    );

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetectorWidget(
        onSwipeRight: _previousPage,
        onSwipeLeft: _nextPage,
        onDoubleTap: () {
          if (_currentPage == 1) {
            _ttsService.speak("Great! You've mastered double tap.",
                priority: SpeechPriority.high);
            Future.delayed(const Duration(seconds: 2), _nextPage);
          } else if (_currentPage == 5) {
            _completeOnboarding();
          }
        },
        onLongPress: () {
          if (_currentPage == 3) {
            _ttsService.speak("Excellent!",
                priority: SpeechPriority.high);
            Future.delayed(const Duration(seconds: 3), _nextPage);
          } else if (_currentPage == 2) {
            statusPage = 1;
            _ttsService.speak("Excellent!",
                priority: SpeechPriority.high);
            Future.delayed(const Duration(seconds: 1), _nextPage);
          }
        },
        onShake: () {
          if (_currentPage == 4) {
            _ttsService.speak("Perfect! Shake gesture detected.",
                priority: SpeechPriority.high);
            Future.delayed(const Duration(seconds: 2), _nextPage);
          }
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
            _speakCurrentPage();

            // Haptic feedback
            context
                .read<GestureProvider>()
                .triggerHaptic(type: HapticType.selection);
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            return _buildPage(_pages[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForGesture(page.gestureType),
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Text(
              page.instruction,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          /*if (_currentPage == _pages.length - 1)
            ElevatedButton(
              onPressed: _completeOnboarding,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text('Start Using VisionTag'),
              ),
            ),*/
        ],
      ),
    );
  }

  IconData _getIconForGesture(GestureType type) {
    switch (type) {
      case GestureType.swipeRight:
        return Icons.swipe_right;
      case GestureType.swipeLeft:
        return Icons.swipe_left;
      case GestureType.check:
        return Icons.check_circle;
      case GestureType.doubleTap:
        return Icons.touch_app;
      case GestureType.longPress:
      if (statusPage == 1) {
          return Icons.check_circle;
        } else{
          return Icons.clean_hands;
        }
      case GestureType.shake:
        return Icons.vibration;
      default:
        return Icons.gesture;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String instruction;
  final GestureType gestureType;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.instruction,
    required this.gestureType,
  });
}

enum GestureType {
  swipeRight,
  swipeLeft,
  doubleTap,
  longPress,
  shake,
  check,
}
