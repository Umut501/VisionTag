import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/services/haptic_service.dart';
import 'package:visiontag/services/speech_service.dart';
import 'package:visiontag/utils/qr_generator.dart';
import 'dart:io';

// Custom gesture recognizer for multi-touch
class _MultiTouchGestureRecognizer extends ScaleGestureRecognizer {
  _MultiTouchGestureRecognizer() : super();

  Function(ScaleStartDetails)? onStart;
  Function(ScaleUpdateDetails)? onUpdate;
  Function(ScaleEndDetails)? onEnd;

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void resolve(GestureDisposition disposition) {
    super.resolve(disposition);
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
  }

  @override
  String get debugDescription => 'multi_touch';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
  }
}

class RetailQRGeneratorScreen extends StatefulWidget {
  const RetailQRGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<RetailQRGeneratorScreen> createState() => _RetailQRGeneratorScreenState();
}

class _RetailQRGeneratorScreenState extends State<RetailQRGeneratorScreen> {
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();
  final _formKey = GlobalKey<FormState>();
  final uuid = const Uuid();
  
  // Speech recognition state
  bool _speechEnabled = false;
  bool _isListening = false;
  String _recognizedText = '';
  
  // Form controllers for better accessibility
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _colorHexController = TextEditingController(text: '#000000');
  final _textureController = TextEditingController(text: 'Smooth');
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _materialController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _collectionController = TextEditingController();
  final _washingController = TextEditingController(text: 'Machine wash cold');
  final _dryingController = TextEditingController(text: 'Tumble dry low');
  final _ironingController = TextEditingController(text: 'Iron on low');

  // Form data
  String _size = 'M';
  bool _recyclable = false;
  String? _qrData;
  int _currentFieldIndex = 0;
  Offset? _startFocalPoint;

  final List<String> _fieldNames = [
    'Item Name', 'Color Name', 'Color Hex', 'Size', 'Texture', 'Price', 
    'Discount', 'Material', 'Recyclable', 'Washing Instructions', 
    'Drying Instructions', 'Ironing Instructions', 'Manufacturer', 'Collection'
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speechService.initialize(
      onError: (error) => _ttsService.speak("Speech recognition error: $error"),
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          _stopListening();
        }
      },
    );
    
    await _ttsService.initTts();
    _announceScreenInfo();
  }

  void _announceScreenInfo() {
    _ttsService.speak(
      "Retail QR Code Generator. You have ${_fieldNames.length} fields to fill. "
      "Currently on field ${_currentFieldIndex + 1}: ${_fieldNames[_currentFieldIndex]}. "
      "Swipe up and down to navigate between fields. "
      "Double tap to record your voice for current field. "
      "Single finger swipe left to go back. "
      "Pinch to exit application. "
      "Long press for help.",
      priority: SpeechPriority.high,
    );
  }

  void _announceCurrentField() {
    if (_currentFieldIndex < _fieldNames.length) {
      final fieldName = _fieldNames[_currentFieldIndex];
      String currentValue = _getCurrentFieldValue();
      _ttsService.speak(
        "Field ${_currentFieldIndex + 1} of ${_fieldNames.length}: $fieldName. "
        "Current value: $currentValue. "
        "Double tap to record your voice.",
        priority: SpeechPriority.high,
      );
    }
  }

  String _getCurrentFieldValue() {
    switch (_currentFieldIndex) {
      case 0: return _nameController.text.isEmpty ? "empty" : _nameController.text;
      case 1: return _colorController.text.isEmpty ? "empty" : _colorController.text;
      case 2: return _colorHexController.text;
      case 3: return _size;
      case 4: return _textureController.text;
      case 5: return _priceController.text.isEmpty ? "empty" : "${_priceController.text} dollars";
      case 6: return "${_discountController.text} percent";
      case 7: return _materialController.text.isEmpty ? "empty" : _materialController.text;
      case 8: return _recyclable ? "yes" : "no";
      case 9: return _washingController.text;
      case 10: return _dryingController.text;
      case 11: return _ironingController.text;
      case 12: return _manufacturerController.text.isEmpty ? "empty" : _manufacturerController.text;
      case 13: return _collectionController.text.isEmpty ? "empty" : _collectionController.text;
      default: return "unknown";
    }
  }

  void _navigateToField(int direction) {
    setState(() {
      _currentFieldIndex = (_currentFieldIndex + direction).clamp(0, _fieldNames.length - 1);
    });
    HapticService.selection();
    _announceCurrentField();
  }

  void _editCurrentField() {
    HapticService.medium();
    
    // Special cases for non-text fields
    if (_currentFieldIndex == 3) { // Size dropdown
      _showSizeDialog();
      return;
    }
    
    if (_currentFieldIndex == 8) { // Recyclable toggle
      _toggleRecyclable();
      return;
    }

    // Start voice input for text fields
    _startVoiceInput();
  }

  Future<void> _startVoiceInput() async {
    if (!_speechEnabled) {
      // Fallback to dialog input
      _showSpeechInputDialog();
      return;
    }

    final fieldName = _fieldNames[_currentFieldIndex];
    
    // Stop any current TTS
    await _ttsService.stop();
    
    // Play beep sound and announce
    HapticService.medium();
    _ttsService.speak("Recording $fieldName. Please speak after the beep sound.", priority: SpeechPriority.high);
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Make a beep sound (haptic feedback as substitute)
    HapticService.heavy();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _startListening();
  }

  void _showSpeechInputDialog() {
    final fieldName = _fieldNames[_currentFieldIndex];
    final controller = _getControllerForField(_currentFieldIndex);
    
    showDialog(
      context: context,
      builder: (context) => SpeechInputDialog(
        fieldName: fieldName,
        initialValue: controller?.text,
        onResult: (text) {
          Navigator.pop(context);
          _processSpeechResult(text);
        },
        onCancel: () {
          Navigator.pop(context);
          _ttsService.speak("Cancelled input for $fieldName");
        },
      ),
    );
  }

  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });
      
      await _speechService.listen(
        onResult: _onSpeechResult,
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _recognizedText = result.recognizedWords;
    });
    
    if (result.finalResult) {
      _stopListening();
      _processSpeechResult(_recognizedText);
    }
  }

  void _stopListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      await _speechService.stop();
    }
  }

  void _processSpeechResult(String text) async {
    if (text.isEmpty) {
      _ttsService.speak("No speech detected. Try again.");
      return;
    }

    final fieldName = _fieldNames[_currentFieldIndex];
    
    // Set the recognized text to the appropriate field
    _setFieldValue(text);
    
    // Read back what was recognized
    _ttsService.speak("I heard: $text for $fieldName. Is this correct? Double tap to confirm, swipe up or down to try again.");
    
    // Show confirmation dialog
    _showConfirmationDialog(fieldName, text);
  }

  void _setFieldValue(String value) {
    final controller = _getControllerForField(_currentFieldIndex);
    if (controller != null) {
      controller.text = value;
    }
    setState(() {});
  }

  void _showConfirmationDialog(String fieldName, String recognizedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $fieldName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recognized: "$recognizedText"'),
            const SizedBox(height: 16),
            Text('Is this correct for $fieldName?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ttsService.speak("Please try recording again");
              _startVoiceInput(); // Try again
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ttsService.speak("$fieldName set to $recognizedText");
              // Move to next field automatically
              if (_currentFieldIndex < _fieldNames.length - 1) {
                _navigateToField(1);
              } else {
                _ttsService.speak("All fields completed. You can now generate the QR code.");
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSizeDialog() {
    final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes.map((size) => 
            ListTile(
              title: Text(size),
              selected: _size == size,
              onTap: () {
                setState(() {
                  _size = size;
                });
                Navigator.pop(context);
                _ttsService.speak("Size set to $size");
              },
            ),
          ).toList(),
        ),
      ),
    ).then((_) {
      _announceCurrentField();
    });
  }

  void _toggleRecyclable() {
    setState(() {
      _recyclable = !_recyclable;
    });
    _ttsService.speak("Recyclable set to ${_recyclable ? 'yes' : 'no'}");
  }

  TextEditingController? _getControllerForField(int index) {
    switch (index) {
      case 0: return _nameController;
      case 1: return _colorController;
      case 2: return _colorHexController;
      case 4: return _textureController;
      case 5: return _priceController;
      case 6: return _discountController;
      case 7: return _materialController;
      case 9: return _washingController;
      case 10: return _dryingController;
      case 11: return _ironingController;
      case 12: return _manufacturerController;
      case 13: return _collectionController;
      default: return null;
    }
  }

  TextInputType _getKeyboardType(int index) {
    if (index == 5 || index == 6) { // Price, Discount
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  @override
  void dispose() {
    _speechService.dispose();
    _nameController.dispose();
    _colorController.dispose();
    _colorHexController.dispose();
    _textureController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _materialController.dispose();
    _manufacturerController.dispose();
    _collectionController.dispose();
    _washingController.dispose();
    _dryingController.dispose();
    _ironingController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Retail QR Code'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticService.swipe();
            _ttsService.speak("Returning to retail mode");
            Navigator.pop(context);
          },
        ),
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _startFocalPoint = details.focalPoint;
          print("🎯 Scale start: ${details.focalPoint}");
        },
        onScaleUpdate: (details) {
          print("🎯 Scale update: scale=${details.scale}, focal=${details.focalPoint}");
          
          // Exit app with pinch
          if (details.scale < 0.7) {
            print("🎯 Pinch detected! Scale: ${details.scale}");
            HapticService.heavy();
            _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
            Future.delayed(const Duration(milliseconds: 1000), () {
              exit(0);
            });
            return;
          }
          
          if (_startFocalPoint != null && details.scale > 0.8 && details.scale < 1.2) {
            final dx = details.focalPoint.dx - _startFocalPoint!.dx;
            final dy = details.focalPoint.dy - _startFocalPoint!.dy;
            
            print("🎯 Swipe detected: dx=$dx, dy=$dy");
            
            // Swipe navigation
            if (dy.abs() > dx.abs() && dy.abs() > 50) {
              print("🎯 Vertical swipe: dy=$dy");
              if (dy > 0) {
                _navigateToField(1); // Down - next field
              } else {
                _navigateToField(-1); // Up - previous field
              }
              _startFocalPoint = null;
            }
            // Single finger swipe left to go back
            else if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
              print("🎯 Left swipe detected! dx=$dx");
              HapticService.swipe();
              _ttsService.speak("Returning to retail mode");
              Navigator.pop(context);
              _startFocalPoint = null;
            }
          }
        },
        onScaleEnd: (details) {
          _startFocalPoint = null;
          print("🎯 Scale end");
        },
        onDoubleTap: () {
          if (_qrData != null) {
            _handleQRAction();
          } else {
            _editCurrentField();
          }
        },
        onLongPress: () {
          if (_qrData != null) {
            _announceQRInstructions();
          } else {
            _announceScreenInfo();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_qrData != null) _buildQRCodeDisplay() else _buildFormView(),
            ],
          ),
        ),
      ),
      floatingActionButton: _qrData == null ? FloatingActionButton.extended(
        onPressed: _generateQRCode,
        icon: const Icon(Icons.qr_code),
        label: const Text('Generate QR'),
        tooltip: 'Generate QR Code',
      ) : null,
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current field indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Field (${_currentFieldIndex + 1}/${_fieldNames.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _fieldNames[_currentFieldIndex],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Value: ${_getCurrentFieldValue()}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.swipe_vertical, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Swipe up/down to navigate fields'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.touch_app, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Double tap to edit current field'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Generate QR to create shareable code'),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Form progress
        LinearProgressIndicator(
          value: (_currentFieldIndex + 1) / _fieldNames.length,
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        const SizedBox(height: 8),
        Text(
          'Progress: ${_currentFieldIndex + 1} of ${_fieldNames.length} fields',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildQRCodeDisplay() {
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QR Code Generated Successfully',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Attach this QR code to the clothing item for retail use',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Double tap to record voice input'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Tap Edit button to modify information'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _qrData = null;
                        _currentFieldIndex = 0;
                      });
                      _ttsService.speak("Returning to form to edit information");
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Information'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _handleQRAction,
                    icon: const Icon(Icons.share),
                    label: const Text('Share QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _announceQRInstructions() {
    _ttsService.speak(
      "QR Code generated successfully for retail use. Double tap to share the QR code with others. "
      "Use the Edit Information button to modify the item details. "
      "This QR code can be attached to clothing items in retail stores.",
      priority: SpeechPriority.high,
    );
  }

  void _handleQRAction() {
    HapticService.success();
    
    // Save or share the QR code using the existing retail functionality
    final fileName = '${_nameController.text.replaceAll(' ', '_')}_retail_qr';
    QrGenerator.shareQrCode(_qrData!, fileName);

    _ttsService.speak("Sharing QR code for ${_nameController.text}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing QR code for ${_nameController.text}')),
    );
  }

  void _generateQRCode() {
    // Validate required fields
    if (_nameController.text.isEmpty) {
      _ttsService.speak("Item name is required");
      return;
    }
    if (_colorController.text.isEmpty) {
      _ttsService.speak("Color name is required");
      return;
    }
    if (_priceController.text.isEmpty) {
      _ttsService.speak("Price is required");
      return;
    }
    if (_materialController.text.isEmpty) {
      _ttsService.speak("Material is required");
      return;
    }
    if (_manufacturerController.text.isEmpty) {
      _ttsService.speak("Manufacturer is required");
      return;
    }
    if (_collectionController.text.isEmpty) {
      _ttsService.speak("Collection is required");
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      _ttsService.speak("Invalid price format");
      return;
    }

    final discount = double.tryParse(_discountController.text);
    if (discount == null || discount < 0 || discount > 100) {
      _ttsService.speak("Invalid discount. Must be between 0 and 100 percent");
      return;
    }

    final Map<String, String> laundryInstructions = {
      'Washing': _washingController.text,
      'Drying': _dryingController.text,
      'Ironing': _ironingController.text,
    };

    final clothingItem = ClothingItem(
      id: uuid.v4(),
      name: _nameController.text,
      color: _colorController.text,
      colorHex: _colorHexController.text,
      size: _size,
      texture: _textureController.text,
      price: price,
      discount: discount,
      material: _materialController.text,
      recyclable: _recyclable,
      laundryInstructions: laundryInstructions,
      manufacturer: _manufacturerController.text,
      collection: _collectionController.text,
    );

    final qrData = jsonEncode(clothingItem.toJson());

    setState(() {
      _qrData = qrData;
    });

    HapticService.success();
    _ttsService.speak("Retail QR code generated successfully for ${_nameController.text}");
  }
}