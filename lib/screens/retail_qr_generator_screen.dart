import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/services/haptic_service.dart';
import 'package:visiontag/utils/qr_generator.dart';
import 'dart:io';

class RetailQRGeneratorScreen extends StatefulWidget {
  const RetailQRGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<RetailQRGeneratorScreen> createState() => _RetailQRGeneratorScreenState();
}

class _RetailQRGeneratorScreenState extends State<RetailQRGeneratorScreen> {
  final TtsService _ttsService = TtsService();
  final _formKey = GlobalKey<FormState>();
  final uuid = const Uuid();

  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _collectionController = TextEditingController();

  // Dropdown selections
  String _colorName = '';
  String _colorHex = '#000000';
  String _size = 'M';
  String _texture = 'Smooth';
  String _material = '';
  String _washingInstruction = 'Machine wash cold';
  String _dryingInstruction = 'Tumble dry low';
  String _ironingInstruction = 'Iron on low';
  bool _recyclable = false;
  double _discount = 0;

  String? _qrData;
  int _currentFieldIndex = 0;
  Offset? _startFocalPoint;

  bool _isDialogOpen = false;
  bool _swipeProcessed = false;

  final List<String> _fieldNames = [
    'Item Name', 'Color', 'Size', 'Texture', 'Price',
    'Discount', 'Material', 'Recyclable', 'Washing Instructions',
    'Drying Instructions', 'Ironing Instructions', 'Manufacturer', 'Collection'
  ];

  // Dropdown options
  final Map<String, String> _colorOptions = {
    'Black': '#000000',
    'White': '#FFFFFF',
    'Red': '#FF0000',
    'Blue': '#0000FF',
    'Green': '#008000',
    'Yellow': '#FFFF00',
    'Purple': '#800080',
    'Orange': '#FFA500',
    'Pink': '#FFC0CB',
    'Brown': '#A52A2A',
    'Gray': '#808080',
    'Navy': '#000080',
    'Maroon': '#800000',
    'Olive': '#808000',
    'Teal': '#008080',
    'Silver': '#C0C0C0',
    'Gold': '#FFD700',
    'Beige': '#F5F5DC',
    'Cream': '#FFFDD0',
    'Turquoise': '#40E0D0',
  };

  final List<String> _sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  final List<String> _textureOptions = [
    'Smooth', 'Rough', 'Soft', 'Silky', 'Fuzzy', 'Knitted', 'Woven', 'Ribbed', 'Corduroy', 'Velvet'
  ];

  final List<String> _materialOptions = [
    'Cotton', 'Polyester', 'Wool', 'Silk', 'Linen', 'Denim', 'Leather', 'Nylon',
    'Spandex', 'Rayon', 'Acrylic', 'Cashmere', 'Bamboo', 'Hemp', 'Modal', 'Viscose'
  ];

  final List<String> _washingOptions = [
    'Machine wash cold', 'Machine wash warm', 'Hand wash only', 'Dry clean only',
    'Machine wash delicate', 'Do not wash', 'Wash separately'
  ];

  final List<String> _dryingOptions = [
    'Tumble dry low', 'Tumble dry medium', 'Tumble dry high', 'Air dry',
    'Hang dry', 'Lay flat to dry', 'Do not tumble dry'
  ];

  final List<String> _ironingOptions = [
    'Iron on low', 'Iron on medium', 'Iron on high', 'Do not iron',
    'Steam iron', 'Iron inside out', 'Use pressing cloth'
  ];

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    Future.delayed(const Duration(milliseconds: 200), _announceScreenInfo);
  }

  void _announceScreenInfo() {
    _ttsService.speak(
      "Retail QR Code Generator. You have ${_fieldNames.length} fields to fill. "
      "Currently on field ${_currentFieldIndex + 1}: ${_fieldNames[_currentFieldIndex]}. "
      "Swipe up and down to navigate between items. "
      "Double tap to edit current field. "
      "Single finger swipe left to go back. "
      "Pinch to exit application. "
      "When you finish all required fields, pinch out to generate the QR code. "
      "Long press for help.",
      priority: SpeechPriority.high,
    );
  }

  void _announceCurrentField() {
    if (_currentFieldIndex < _fieldNames.length) {
      final fieldName = _fieldNames[_currentFieldIndex];
      String currentValue = _getCurrentFieldValue();
      String msg =
        "Field ${_currentFieldIndex + 1} of ${_fieldNames.length}: $fieldName. "
        "Current value: $currentValue. "
        "Double tap to edit.";
      if (_currentFieldIndex > 0) {
        msg += " To save and go to previous item, swipe up.";
      }
      if (_currentFieldIndex < _fieldNames.length - 1) {
        msg += " To save and go to next item, swipe down.";
      } else {
        msg += " When all required fields are filled, pinch out to generate the QR code.";
      }
      _ttsService.speak(
        msg,
        priority: SpeechPriority.high,
      );
    }
  }

  String _getCurrentFieldValue() {
    switch (_currentFieldIndex) {
      case 0: return _nameController.text.isEmpty ? "empty" : _nameController.text;
      case 1: return _colorName.isEmpty ? "not selected" : _colorName;
      case 2: return _size;
      case 3: return _texture;
      case 4: return _priceController.text.isEmpty ? "empty" : "${_priceController.text} dollars";
      case 5: return "$_discount percent";
      case 6: return _material.isEmpty ? "not selected" : _material;
      case 7: return _recyclable ? "yes" : "no";
      case 8: return _washingInstruction;
      case 9: return _dryingInstruction;
      case 10: return _ironingInstruction;
      case 11: return _manufacturerController.text.isEmpty ? "empty" : _manufacturerController.text;
      case 12: return _collectionController.text.isEmpty ? "empty" : _collectionController.text;
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

    switch (_currentFieldIndex) {
      case 0: _showTextInputDialog('Item Name', _nameController); break;
      case 1: _showColorSelectionDialog(); break;
      case 2: _showListSelectionDialog(
        title: 'Select Size',
        options: _sizeOptions,
        currentValue: _size,
        onSelect: (val) { setState(() => _size = val); },
      ); break;
      case 3: _showListSelectionDialog(
        title: 'Select Texture',
        options: _textureOptions,
        currentValue: _texture,
        onSelect: (val) { setState(() => _texture = val); },
      ); break;
      case 4: _showPriceInputDialog(); break;
      case 5: _showListSelectionDialog(
        title: 'Select Discount',
        options: List.generate(21, (i) => '${i * 5}%'),
        currentValue: '${_discount.toInt()}%',
        onSelect: (val) { setState(() => _discount = double.parse(val.replaceAll('%', ''))); },
      ); break;
      case 6: _showListSelectionDialog(
        title: 'Select Material',
        options: _materialOptions,
        currentValue: _material,
        onSelect: (val) { setState(() => _material = val); },
      ); break;
      case 7: _toggleRecyclable(); break;
      case 8: _showListSelectionDialog(
        title: 'Washing Instructions',
        options: _washingOptions,
        currentValue: _washingInstruction,
        onSelect: (val) { setState(() => _washingInstruction = val); },
      ); break;
      case 9: _showListSelectionDialog(
        title: 'Drying Instructions',
        options: _dryingOptions,
        currentValue: _dryingInstruction,
        onSelect: (val) { setState(() => _dryingInstruction = val); },
      ); break;
      case 10: _showListSelectionDialog(
        title: 'Ironing Instructions',
        options: _ironingOptions,
        currentValue: _ironingInstruction,
        onSelect: (val) { setState(() => _ironingInstruction = val); },
      ); break;
      case 11: _showTextInputDialog('Manufacturer', _manufacturerController); break;
      case 12: _showTextInputDialog('Collection', _collectionController); break;
    }
  }

  void _showTextInputDialog(String fieldName, TextEditingController controller) {
    final textController = TextEditingController(text: controller.text);
    String lastSpokenValue = '';

    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: GestureDetector(
          onDoubleTap: () {
            if (textController.text.trim().isNotEmpty) {
              controller.text = textController.text.trim();
              Navigator.pop(context);
              setState(() {});
              _ttsService.speak("$fieldName saved as ${textController.text.trim()}");
            } else {
              _ttsService.speak("Field is empty. Please enter $fieldName or swipe left to cancel.");
            }
          },
          onTap: () {
            final currentText = textController.text.trim();
            if (currentText.isEmpty) {
              _ttsService.speak("$fieldName field is empty. Type your input then double tap to confirm, or swipe left to cancel.");
            } else if (currentText != lastSpokenValue) {
              _ttsService.speak("Current input for $fieldName is: $currentText. Double tap to confirm, or continue typing to modify. Swipe left to cancel.");
              lastSpokenValue = currentText;
            } else {
              _ttsService.speak("Double tap to confirm $currentText, or swipe left to cancel.");
            }
          },
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx < -500) {
              Navigator.pop(context);
              _ttsService.speak("Cancelled input for $fieldName");
            }
          },
          onLongPress: () {
            _ttsService.speak(
              "Text input for $fieldName. Type your text using keyboard. "
              "Single tap to hear current input. "
              "Double tap to confirm and save. "
              "Swipe left to cancel.",
              priority: SpeechPriority.high
            );
          },
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Enter $fieldName', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: fieldName,
                      border: const OutlineInputBorder(),
                      helperText: 'Type then double tap to confirm',
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) => lastSpokenValue = '',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Single tap: hear input • Double tap: confirm • Swipe left: cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() => _isDialogOpen = false);
      _announceCurrentField();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _ttsService.speak(
        "Text input dialog for $fieldName opened. "
        "Current value: ${textController.text.isEmpty ? 'empty' : textController.text}. "
        "Use keyboard to type. Single tap to hear input. Double tap to confirm. Swipe left to cancel.",
        priority: SpeechPriority.high
      );
    });
  }

  void _showColorSelectionDialog() {
    int selectedIndex = _colorOptions.keys.toList().indexOf(_colorName.isNotEmpty ? _colorName : _colorOptions.keys.first);
    final colorKeys = _colorOptions.keys.toList();

    void announceSelection() {
      final current = colorKeys[selectedIndex];
      final up = selectedIndex > 0 ? colorKeys[selectedIndex - 1] : null;
      final down = selectedIndex < colorKeys.length - 1 ? colorKeys[selectedIndex + 1] : null;
      String msg = "$current selected. ";
      if (up != null) msg += "Swipe up to select $up. ";
      if (down != null) msg += "Swipe down to select $down. ";
      msg += "Double tap to save $current.";
      _ttsService.speak(msg);
    }

    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            onVerticalDragEnd: (details) {
              bool changed = false;
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0 && selectedIndex < colorKeys.length - 1) {
                  setState(() => selectedIndex++);
                  changed = true;
                } else if (details.primaryVelocity! > 0 && selectedIndex > 0) {
                  setState(() => selectedIndex--);
                  changed = true;
                }
                if (changed) announceSelection();
              }
            },
            onDoubleTap: () {
              _colorName = colorKeys[selectedIndex];
              _colorHex = _colorOptions[_colorName]!;
              Navigator.pop(context);
              _ttsService.speak("Color saved as $_colorName");
            },
            onPanEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx < -500) {
                Navigator.pop(context);
                _ttsService.speak("Cancelled color selection");
              }
            },
            onLongPress: announceSelection,
            child: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Select Color', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ...List.generate(7, (i) {
                      int optionIndex = (selectedIndex - 3) + i;
                      if (optionIndex < 0 || optionIndex >= colorKeys.length) {
                        return const SizedBox(height: 38);
                      }
                      final colorName = colorKeys[optionIndex];
                      final colorHex = _colorOptions[colorName]!;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: selectedIndex == optionIndex
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedIndex == optionIndex
                                ? Colors.blue
                                : Colors.grey.withOpacity(0.2),
                            width: selectedIndex == optionIndex ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                          title: Text(
                            colorName,
                            style: TextStyle(
                              fontWeight: selectedIndex == optionIndex ? FontWeight.bold : FontWeight.normal,
                              fontSize: 20,
                            ),
                          ),
                          selected: selectedIndex == optionIndex,
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Swipe up/down: navigate • Double tap: confirm • Swipe left: cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() => _isDialogOpen = false);
      _announceCurrentField();
    });

    Future.delayed(const Duration(milliseconds: 500), announceSelection);
  }

  void _showListSelectionDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelect,
  }) {
    int selectedIndex = options.indexOf(currentValue.isNotEmpty ? currentValue : options.first);

    void announceSelection() {
      final current = options[selectedIndex];
      final up = selectedIndex > 0 ? options[selectedIndex - 1] : null;
      final down = selectedIndex < options.length - 1 ? options[selectedIndex + 1] : null;
      String msg = "$current selected. ";
      if (up != null) msg += "Swipe up to select $up. ";
      if (down != null) msg += "Swipe down to select $down. ";
      msg += "Double tap to save $current.";
      _ttsService.speak(msg);
    }

    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            onVerticalDragEnd: (details) {
              bool changed = false;
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0 && selectedIndex < options.length - 1) {
                  setState(() => selectedIndex++);
                  changed = true;
                } else if (details.primaryVelocity! > 0 && selectedIndex > 0) {
                  setState(() => selectedIndex--);
                  changed = true;
                }
                if (changed) announceSelection();
              }
            },
            onDoubleTap: () {
              onSelect(options[selectedIndex]);
              Navigator.pop(context);
              _ttsService.speak("$title saved as ${options[selectedIndex]}");
            },
            onPanEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx < -500) {
                Navigator.pop(context);
                _ttsService.speak("Cancelled $title selection");
              }
            },
            onLongPress: announceSelection,
            child: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ...List.generate(7, (i) {
                      int optionIndex = (selectedIndex - 3) + i;
                      if (optionIndex < 0 || optionIndex >= options.length) {
                        return const SizedBox(height: 38);
                      }
                      final option = options[optionIndex];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: selectedIndex == optionIndex
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedIndex == optionIndex
                                ? Colors.blue
                                : Colors.grey.withOpacity(0.2),
                            width: selectedIndex == optionIndex ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            option,
                            style: TextStyle(
                              fontWeight: selectedIndex == optionIndex ? FontWeight.bold : FontWeight.normal,
                              fontSize: 20,
                            ),
                          ),
                          selected: selectedIndex == optionIndex,
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Swipe up/down: navigate • Double tap: confirm • Swipe left: cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() => _isDialogOpen = false);
      _announceCurrentField();
    });

    Future.delayed(const Duration(milliseconds: 500), announceSelection);
  }

  void _showPriceInputDialog() {
    final priceController = TextEditingController(text: _priceController.text);
    String lastSpokenValue = '';

    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: GestureDetector(
          onDoubleTap: () {
            final price = double.tryParse(priceController.text.trim());
            if (price != null && price >= 0) {
              _priceController.text = priceController.text.trim();
              Navigator.pop(context);
              setState(() {});
              _ttsService.speak("Price saved as ${priceController.text.trim()} dollars");
            } else {
              _ttsService.speak("Invalid price. Please enter a valid number greater than or equal to zero, or swipe left to cancel.");
            }
          },
          onTap: () {
            final currentText = priceController.text.trim();
            if (currentText.isEmpty) {
              _ttsService.speak("Price field is empty. Enter price in dollars then double tap to confirm, or swipe left to cancel.");
            } else {
              final price = double.tryParse(currentText);
              if (price != null && price >= 0) {
                if (currentText != lastSpokenValue) {
                  _ttsService.speak("Current price is: $currentText dollars. Double tap to confirm, or continue typing to modify. Swipe left to cancel.");
                  lastSpokenValue = currentText;
                } else {
                  _ttsService.speak("Double tap to confirm $currentText dollars, or swipe left to cancel.");
                }
              } else {
                _ttsService.speak("Invalid price format. Please enter a valid number, or swipe left to cancel.");
              }
            }
          },
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx < -500) {
              Navigator.pop(context);
              _ttsService.speak("Cancelled price input");
            }
          },
          onLongPress: () {
            _ttsService.speak(
              "Price input dialog. Enter price in dollars using number keyboard. "
              "Single tap to hear current input. "
              "Double tap to confirm and save. "
              "Swipe left to cancel.",
              priority: SpeechPriority.high
            );
          },
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Enter Price', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: priceController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Price (\$)',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                      helperText: 'Enter amount then double tap to confirm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      lastSpokenValue = '';
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Single tap: hear price • Double tap: confirm • Swipe left: cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() => _isDialogOpen = false);
      _announceCurrentField();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _ttsService.speak(
        "Price input dialog opened. "
        "Current value: ${priceController.text.isEmpty ? 'empty' : '${priceController.text} dollars'}. "
        "Use number keyboard to enter price. Single tap to hear input. Double tap to confirm. Swipe left to cancel.",
        priority: SpeechPriority.high
      );
    });
  }

  void _toggleRecyclable() {
    setState(() {
      _recyclable = !_recyclable;
    });
    _ttsService.speak("Recyclable set to ${_recyclable ? 'yes' : 'no'}");
  }

  Widget _buildFormView() {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentFieldIndex + 1} / ${_fieldNames.length}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _fieldNames[_currentFieldIndex],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Current Value:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getCurrentFieldValue(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _editCurrentField,
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text(
                      'EDIT FIELD',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: (_currentFieldIndex + 1) / _fieldNames.length,
                          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progress: ${_currentFieldIndex + 1} of ${_fieldNames.length} fields completed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInstructionItem(Icons.swipe_vertical, 'Swipe'),
                        _buildInstructionItem(Icons.touch_app, 'Double Tap'),
                        _buildInstructionItem(Icons.keyboard, 'Edit'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
      body: _qrData == null
          // FORM EKRANI: Gesture ile alanlar arası geçiş, pinch ile QR oluşturma/çıkış
          ? GestureDetector(
              onScaleStart: _isDialogOpen ? null : (details) {
                _startFocalPoint = details.focalPoint;
                _swipeProcessed = false;
              },
              onScaleUpdate: _isDialogOpen ? null : (details) {
                // Pinch ile QR oluştur
                if (_qrData == null && details.scale > 1.2 && !_swipeProcessed) {
                  _swipeProcessed = true;
                  _generateQRCode();
                  return;
                }
                // Pinch ile çıkış
                if (_qrData == null && details.scale < 0.7 && !_swipeProcessed) {
                  _swipeProcessed = true;
                  HapticService.heavy();
                  _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    exit(0);
                  });
                  return;
                }
                // Swipe up/down ile alanlar arası geçiş
                if (_startFocalPoint != null && details.scale > 0.8 && details.scale < 1.2 && !_swipeProcessed) {
                  final dx = details.focalPoint.dx - _startFocalPoint!.dx;
                  final dy = details.focalPoint.dy - _startFocalPoint!.dy;
                  if (dy.abs() > dx.abs() && dy.abs() > 50) {
                    _swipeProcessed = true;
                    if (dy > 0) {
                      _navigateToField(1);
                    } else {
                      _navigateToField(-1);
                    }
                    _startFocalPoint = null;
                  } else if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
                    _swipeProcessed = true;
                    HapticService.swipe();
                    _ttsService.speak("Returning to retail mode");
                    Navigator.pop(context);
                    _startFocalPoint = null;
                  }
                }
              },
              onScaleEnd: _isDialogOpen ? null : (details) {
                _startFocalPoint = null;
                _swipeProcessed = false;
              },
              onDoubleTap: _isDialogOpen ? null : () {
                _editCurrentField();
              },
              onLongPress: _isDialogOpen ? null : () {
                _ttsService.speak(
                  "You are on the Retail QR Code Generator form. "
                  "Swipe up and down to move between fields. "
                  "Double tap to edit a field. "
                  "When all required fields are filled, pinch out to generate the QR code. "
                  "Pinch in to exit. "
                  "Swipe left to go back.",
                  priority: SpeechPriority.high,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormView(),
                  ],
                ),
              ),
            )
          // QR KOD EKRANI: gesture yönetimi zaten doğru
          : GestureDetector(
              onScaleStart: (details) {
                _startFocalPoint = details.focalPoint;
                _swipeProcessed = false;
              },
              onScaleUpdate: (details) {
                // Pinch to quit
                if (details.scale < 0.7 && !_swipeProcessed) {
                  _swipeProcessed = true;
                  HapticService.heavy();
                  _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    exit(0);
                  });
                  return;
                }
                // Sadece swipe left (geri dön) - scale 1'e yakınken
                if (_startFocalPoint != null && details.scale > 0.8 && details.scale < 1.2 && !_swipeProcessed) {
                  final dx = details.focalPoint.dx - _startFocalPoint!.dx;
                  final dy = details.focalPoint.dy - _startFocalPoint!.dy;
                  if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
                    _swipeProcessed = true;
                    _ttsService.speak("Returning to Create Retail QR Code screen");
                    setState(() {
                      _qrData = null;
                    });
                    _startFocalPoint = null;
                  }
                }
              },
              onScaleEnd: (details) {
                _startFocalPoint = null;
                _swipeProcessed = false;
              },
              onDoubleTap: () {
                _handleQRAction();
                _ttsService.speak("Sharing QR code for ${_nameController.text}");
              },
              onLongPress: () {
                _ttsService.speak(
                  "QR code screen. Double tap to share. Swipe left to go back. Pinch to exit.",
                  priority: SpeechPriority.high,
                );
              },
              behavior: HitTestBehavior.opaque, // <-- Bunu ekle
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent, // Tüm alanı kaplasın
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQRCodeDisplay(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQRCodeDisplay() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _ttsService.speak(
        "QR code generated. Double tap to share. Swipe left to go back. Pinch to exit.",
        priority: SpeechPriority.high,
      );
    });
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
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Double tap to share • Swipe left to go back • Pinch to exit",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _announceQRInstructions() {
    _ttsService.speak(
      "QR code screen. Swipe up to share. Swipe left to go back. Pinch to exit.",
      priority: SpeechPriority.high,
    );
  }

  void _handleQRAction() {
    HapticService.success();

    final fileName = '${_nameController.text.replaceAll(' ', '_')}_retail_qr';
    QrGenerator.shareQrCode(_qrData!, fileName);

    _ttsService.speak("Sharing QR code for ${_nameController.text}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing QR code for ${_nameController.text}')),
    );
  }

  void _generateQRCode() {
    if (_nameController.text.isEmpty) {
      _ttsService.speak("Item name is required");
      return;
    }
    if (_colorName.isEmpty) {
      _ttsService.speak("Color selection is required");
      return;
    }
    if (_priceController.text.isEmpty) {
      _ttsService.speak("Price is required");
      return;
    }
    if (_material.isEmpty) {
      _ttsService.speak("Material selection is required");
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

    final Map<String, String> laundryInstructions = {
      'Washing': _washingInstruction,
      'Drying': _dryingInstruction,
      'Ironing': _ironingInstruction,
    };

    final clothingItem = ClothingItem(
      id: uuid.v4(),
      name: _nameController.text,
      color: _colorName,
      colorHex: _colorHex,
      size: _size,
      texture: _texture,
      price: price,
      discount: _discount,
      material: _material,
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