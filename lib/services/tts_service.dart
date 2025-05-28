import 'package:flutter_tts/flutter_tts.dart';
import 'package:visiontag/providers/accessibility_provider.dart';

enum SpeechPriority { low, normal, high }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String _lastSpokenText = '';
  AccessibilityProvider? _accessibilityProvider;

  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  Future<void> initTts({AccessibilityProvider? accessibilityProvider}) async {
    if (_isInitialized && accessibilityProvider == null) return;

    _accessibilityProvider = accessibilityProvider;

    await _flutterTts.setLanguage("en-US");

    if (_accessibilityProvider != null) {
      await _flutterTts.setSpeechRate(_accessibilityProvider!.speechRate);
      await _flutterTts.setVolume(_accessibilityProvider!.volume);
      await _flutterTts.setPitch(_accessibilityProvider!.pitch);
    } else {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    }

    List<dynamic>? voices = await _flutterTts.getVoices;
    if (voices != null)
    {
      for (var voice in voices) {
        if (voice is Map && voice['name'] != null) {
          String voiceName = voice['name'].toString().toLowerCase();
          if (voiceName.contains('enhanced') ||
              voiceName.contains('premium') ||
              voiceName.contains('neural')) {
            await _flutterTts.setVoice({
              "name": voice['name'],
              "locale": voice['locale'],
            });
            break;
          }
        }
      }
    }
  
    _flutterTts.setCompletionHandler(() {
      // Completion callback
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    _isInitialized = true;
  }

  Future<void> speak(String text,
      {SpeechPriority priority = SpeechPriority.normal}) async {
    if (!_isInitialized) {
      await initTts();
    }

    _lastSpokenText = text;

    if (priority == SpeechPriority.high) {
      await _flutterTts.stop();
    }

    if (_accessibilityProvider?.verboseMode ?? false) {
      text = _addVerboseDetails(text);
    }

    await _flutterTts.speak(text);
  }

  Future<void> repeatLastSpoken() async {
    if (_lastSpokenText.isNotEmpty) {
      if(_lastSpokenText.substring(0, 10)=="Repeating.")
      {
        _lastSpokenText = _lastSpokenText.substring(10).trim();
        await speak("Repeating. $_lastSpokenText", priority: SpeechPriority.high);
      } else{
        await speak("Repeating. $_lastSpokenText", priority: SpeechPriority.high);
      }
      
    } else {
      await speak("Nothing to repeat", priority: SpeechPriority.high);
    }
  }

  Future<void> announceAction(String action) async {
    if (_accessibilityProvider?.announceActions ?? true) {
      await speak(action, priority: SpeechPriority.low);
    }
  }

  // Yeni eklenen metodlar:
  Future<void> announceScreen(String screenName) async {
    await speak("Navigated to $screenName screen",
        priority: SpeechPriority.low);
  }

  Future<void> announceError(String errorMessage) async {
    await speak("Error: $errorMessage", priority: SpeechPriority.high);
  }

  String _addVerboseDetails(String text) {
    if (text.contains("button")) {
      text += ". Double tap to activate.";
    } else if (text.contains("screen")) {
      text += ". Swipe left or right to navigate between screens.";
    }
    return text;
  }

  Future<void> stop() async => await _flutterTts.stop();
  Future<void> pause() async => await _flutterTts.pause();

  Future<void> updateSettings(AccessibilityProvider provider) async {
    _accessibilityProvider = provider;
    await _flutterTts.setSpeechRate(provider.speechRate);
    await _flutterTts.setVolume(provider.volume);
    await _flutterTts.setPitch(provider.pitch);
  }

  Future<bool> isSpeaking() async {
    return await _flutterTts.isLanguageAvailable("en-US") ?? false;
  }

  Future<void> spellOut(String text) async {
    String spelled = text.split('').join(', ');
    await speak("Spelling: $spelled", priority: SpeechPriority.high);
  }

  Future<void> speakList(List<String> items, {String prefix = ""}) async {
    String listText = prefix;
    for (int i = 0; i < items.length; i++) {
      listText += "${i + 1}. ${items[i]}. ";
    }
    await speak(listText);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
