import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:visiontag/providers/gesture_provider.dart';
import 'package:visiontag/providers/accessibility_provider.dart';
import 'package:visiontag/screens/home_screen.dart';
import 'package:visiontag/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Check if first time user
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClothingProvider()),
        ChangeNotifierProvider(create: (_) => GestureProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: MyApp(isFirstTime: isFirstTime),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({Key? key, required this.isFirstTime}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibilityProvider, child) {
        return MaterialApp(
          title: 'VisionTag',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light, accessibilityProvider),
          darkTheme: _buildTheme(Brightness.dark, accessibilityProvider),
          themeMode: accessibilityProvider.themeMode,
          home: isFirstTime ? const OnboardingScreen() : const HomeScreen(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(accessibilityProvider.textScaleFactor),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness, AccessibilityProvider provider) {
    final isDark = brightness == Brightness.dark;

    // High contrast colors based on user preference
    final primaryColor = provider.useHighContrast
        ? (isDark ? Colors.yellow : Colors.black)
        : Colors.blue;

    final backgroundColor = provider.useHighContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.grey[900]! : Colors.white);

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        onPrimary: provider.useHighContrast
            ? (isDark ? Colors.black : Colors.white)
            : Colors.white,
        secondary: provider.useHighContrast
            ? (isDark ? Colors.cyan : Colors.blue)
            : Colors.tealAccent,
        onSecondary: Colors.black,
        surface: backgroundColor,
        onSurface: isDark ? Colors.white : Colors.black,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32 * provider.textScaleFactor,
          fontWeight: FontWeight.bold,
          letterSpacing: provider.useHighContrast ? 1.5 : 1.0,
        ),
        displayMedium: TextStyle(
          fontSize: 28 * provider.textScaleFactor,
          fontWeight: FontWeight.bold,
          letterSpacing: provider.useHighContrast ? 1.5 : 1.0,
        ),
        displaySmall: TextStyle(
          fontSize: 24 * provider.textScaleFactor,
          fontWeight: FontWeight.bold,
          letterSpacing: provider.useHighContrast ? 1.5 : 1.0,
        ),
        headlineMedium: TextStyle(
          fontSize: 20 * provider.textScaleFactor,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: 18 * provider.textScaleFactor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: 16 * provider.textScaleFactor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * provider.textScaleFactor,
        ),
        labelLarge: TextStyle(
          fontSize: 14 * provider.textScaleFactor,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 56),
          textStyle: TextStyle(
            fontSize: 16 * provider.textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: provider.useHighContrast ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: provider.useHighContrast
              ? BorderSide(color: primaryColor, width: 2)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            width: provider.useHighContrast ? 2 : 1,
          ),
        ),
        filled: true,
      ),
    );
  }
}
