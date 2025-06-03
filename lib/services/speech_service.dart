import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SpeechRecognitionStatus {
  notInitialized,
  available,
  unavailable,
  listening,
  notListening,
  done,
  error
}

class SpeechRecognitionResult {
  final String recognizedWords;
  final bool finalResult;
  final double confidence;

  SpeechRecognitionResult({
    required this.recognizedWords,
    this.finalResult = false,
    this.confidence = 0.0,
  });
}

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  static const MethodChannel _channel = MethodChannel('speech_to_text');
  
  bool _initialized = false;
  bool _isListening = false;
  SpeechRecognitionStatus _status = SpeechRecognitionStatus.notInitialized;
  
  Function(SpeechRecognitionResult)? _onResult;
  Function(String)? _onError;
  Function(String)? _onStatus;
  
  StreamSubscription? _resultSubscription;

  /// Initialize speech recognition
  Future<bool> initialize({
    Function(String)? onError,
    Function(String)? onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;

    try {
      // Check if speech recognition is available on the platform
      final bool available = await _channel.invokeMethod('initialize');
      
      if (available) {
        _initialized = true;
        _status = SpeechRecognitionStatus.available;
        _onStatus?.call('available');
        
        // Set up result listening
        _setupResultListener();
        
        return true;
      } else {
        _status = SpeechRecognitionStatus.unavailable;
        _onStatus?.call('unavailable');
        return false;
      }
    } catch (e) {
      print('Speech initialization error: $e');
      _onError?.call('Speech recognition initialization failed: $e');
      _status = SpeechRecognitionStatus.unavailable;
      return false;
    }
  }

  void _setupResultListener() {
    // Listen for speech recognition results from platform
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSpeechResult':
          final String text = call.arguments['recognizedWords'] ?? '';
          final bool isFinal = call.arguments['finalResult'] ?? false;
          final double confidence = call.arguments['confidence']?.toDouble() ?? 0.0;
          
          _onResult?.call(SpeechRecognitionResult(
            recognizedWords: text,
            finalResult: isFinal,
            confidence: confidence,
          ));
          
          if (isFinal) {
            _isListening = false;
            _status = SpeechRecognitionStatus.done;
            _onStatus?.call('done');
          }
          break;
          
        case 'onError':
          final String error = call.arguments['error'] ?? 'Unknown error';
          _onError?.call(error);
          _isListening = false;
          _status = SpeechRecognitionStatus.error;
          _onStatus?.call('error');
          break;
          
        case 'onStatusChanged':
          final String status = call.arguments['status'] ?? 'unknown';
          _onStatus?.call(status);
          break;
      }
    });
  }

  /// Start listening for speech
  Future<void> listen({
    required Function(SpeechRecognitionResult) onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    if (!_initialized) {
      _onError?.call('Speech recognition not initialized');
      return;
    }

    if (_isListening) {
      _onError?.call('Already listening');
      return;
    }

    _onResult = onResult;
    _isListening = true;
    _status = SpeechRecognitionStatus.listening;
    _onStatus?.call('listening');

    try {
      await _channel.invokeMethod('startListening', {
        'localeId': localeId ?? 'en_US',
        'listenFor': listenFor?.inMilliseconds ?? 10000,
        'pauseFor': pauseFor?.inMilliseconds ?? 3000,
      });
    } catch (e) {
      print('Start listening error: $e');
      _onError?.call('Failed to start listening: $e');
      _isListening = false;
      _status = SpeechRecognitionStatus.error;
    }
  }

  /// Stop listening
  Future<void> stop() async {
    if (_isListening) {
      try {
        await _channel.invokeMethod('stopListening');
      } catch (e) {
        print('Stop listening error: $e');
      }
      
      _isListening = false;
      _status = SpeechRecognitionStatus.notListening;
      _onStatus?.call('notListening');
    }
  }

  /// Get current status
  SpeechRecognitionStatus get status => _status;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if speech recognition is available
  bool get isAvailable => _initialized && _status == SpeechRecognitionStatus.available;

  /// Cancel current recognition
  Future<void> cancel() async {
    await stop();
  }

  /// Dispose resources
  void dispose() {
    _resultSubscription?.cancel();
    _isListening = false;
    _onResult = null;
    _onError = null;
    _onStatus = null;
  }
}

// Widget for visual speech input (alternative to voice)
class SpeechInputDialog extends StatefulWidget {
  final String fieldName;
  final String? initialValue;
  final Function(String) onResult;
  final VoidCallback onCancel;

  const SpeechInputDialog({
    Key? key,
    required this.fieldName,
    this.initialValue,
    required this.onResult,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SpeechInputDialog> createState() => _SpeechInputDialogState();
}

class _SpeechInputDialogState extends State<SpeechInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _speechService.stop();
    _controller.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!_speechService.isAvailable) {
      // Show snackbar if speech is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available. Please type manually.'),
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speechService.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
          _controller.text = result.recognizedWords;
        });

        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
  }

  void _stopListening() async {
    await _speechService.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter ${widget.fieldName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔴 Listening... Say "${widget.fieldName}"',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.fieldName,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? Colors.red : null,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
                tooltip: _isListening ? 'Stop listening' : 'Start voice input',
              ),
            ),
            autofocus: !_speechService.isAvailable,
            onFieldSubmitted: (value) {
              widget.onResult(value);
            },
          ),
          
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recognized: "$_recognizedText"',
              style: TextStyle(
                color: Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          Text(
            'Tip: You can also type manually or use voice input',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _stopListening();
            widget.onCancel();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _stopListening();
            widget.onResult(_controller.text);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}