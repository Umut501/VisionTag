import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initTts() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Configure high quality voice if available
    List<dynamic>? voices = await _flutterTts.getVoices;
    if (voices != null) {
      for (var voice in voices) {
        if (voice is Map && voice['name'] != null) {
          if (voice['name'].toString().toLowerCase().contains('enhanced')) {
            await _flutterTts.setVoice(voice['name']);
            break;
          }
        }
      }
    }

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initTts();
    }

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }
}
