import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../providers/clothing_provider.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/retail_qr_generator_screen.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../models/clothing_item_details.dart';

class RetailModeScreen extends StatefulWidget {
  const RetailModeScreen({Key? key}) : super(key: key);

  @override
  State<RetailModeScreen> createState() => _RetailModeScreenState();
}

class _RetailModeScreenState extends State<RetailModeScreen> {
  final TtsService _ttsService = TtsService();
  ClothingItem? _scannedItem;
  int _focusedIndex = 0; // 0 = Scan, 1 = Create QR
  bool _announcementMade = false;
  Offset? _startFocalPoint;
  Set<int> _activePointers = {};
  bool _isMultiTouch = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceCurrentSelection();
    });
  }

  void _announceCurrentSelection() {
    if (_scannedItem != null) return;
    
    String announcement = "Retail Mode. ";
    if (_focusedIndex == 0) {
      announcement += "Scan Item selected. Swipe down to select Create QR Code. Double tap to scan clothing items. ";
    } else {
      announcement += "Create QR Code selected. Swipe up to select Scan Item. Double tap to create QR codes. ";
    }
    announcement += "Swipe left to return to Home Mode. Pinch to exit application.";
    
    _ttsService.speak(announcement, priority: SpeechPriority.high);
  }

  void _showHelp() {
    HapticService.medium();
    _ttsService.speak(
        "Retail Mode Help. "
        "Swipe up or down to select between Scan Item and Create QR Code. "
        "Double tap to activate selected option. "
        "When viewing an item, swipe left to add to wardrobe, "
        "swipe right to scan another item. "
        "Long press to share item details.",
        priority: SpeechPriority.high);
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail Mode'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _ttsService.speak("Returning to main screen", priority: SpeechPriority.high);
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _scannedItem == null ? _buildSelectionInterface() : _buildItemDetails(),
    );
  }

  Widget _buildSelectionInterface() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_announcementMade) {
        _announcementMade = true;
        _announceCurrentSelection();
      }
    });

    return Listener(
      onPointerDown: (details) {
        _activePointers.add(details.pointer);
        _isMultiTouch = _activePointers.length >= 2;
      },
      onPointerUp: (details) {
        _activePointers.remove(details.pointer);
        _isMultiTouch = _activePointers.length >= 2;
      },
      onPointerCancel: (details) {
        _activePointers.remove(details.pointer);
        _isMultiTouch = _activePointers.length >= 2;
      },
      child: GestureDetector(
        onScaleStart: (details) {
          _startFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) async {
          if (details.scale < 0.7) {
            _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
            await Future.delayed(const Duration(milliseconds: 1000));
            exit(0);
          }
          
          if (_startFocalPoint != null && details.scale > 0.9 && details.scale < 1.1) {
            final dx = details.focalPoint.dx - _startFocalPoint!.dx;
            final dy = details.focalPoint.dy - _startFocalPoint!.dy;
            
            if (!_isMultiTouch) {
              if (dy.abs() > dx.abs() && dy.abs() > 50) {
                if (dy > 0) {
                  // Swipe down
                  setState(() {
                    _focusedIndex = _focusedIndex == 0 ? 1 : 0;
                  });
                  _announceCurrentSelection();
                  _startFocalPoint = null;
                } else {
                  // Swipe up
                  setState(() {
                    _focusedIndex = _focusedIndex == 0 ? 1 : 0;
                  });
                  _announceCurrentSelection();
                  _startFocalPoint = null;
                }
              }
              else if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
                _ttsService.speak("Returning to main screen", priority: SpeechPriority.high);
                Future.delayed(const Duration(milliseconds: 2500), () {
                  if (mounted) {
                    Navigator.of(context).maybePop();
                  }
                });
                _startFocalPoint = null;
              }
            }
          }
        },
        onScaleEnd: (details) {
          _startFocalPoint = null;
        },
        onDoubleTap: () {
          if (_focusedIndex == 0) {
            _scanQrCode();
          } else {
            _createQrCode();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Scan Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _focusedIndex == 0 ? [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ] : [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: _focusedIndex == 0 ? 120 : 100,
                        color: _focusedIndex == 0 ? Colors.white : Colors.white70,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Scan Item',
                        style: TextStyle(
                          fontSize: _focusedIndex == 0 ? 32 : 28,
                          color: _focusedIndex == 0 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_focusedIndex != 0) ...[
                        Icon(
                          Icons.swipe_up_rounded,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Divider
              Container(
                height: 4,
                color: Theme.of(context).dividerColor,
              ),

              // Create QR Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _focusedIndex == 1 ? [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      ] : [
                        Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_rounded,
                        size: _focusedIndex == 1 ? 120 : 100,
                        color: _focusedIndex == 1 ? Colors.white : Colors.white70,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create QR Code',
                        style: TextStyle(
                          fontSize: _focusedIndex == 1 ? 32 : 28,
                          color: _focusedIndex == 1 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_focusedIndex != 1) ...[
                        Icon(
                          Icons.swipe_down_rounded,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetails() {
    if (_scannedItem == null) return const SizedBox.shrink();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        // Swipe left - add to wardrobe
        if (details.primaryVelocity! < -200) {
          _addToWardrobe();
        }
        // Swipe right - scan another
        else if (details.primaryVelocity! > 200) {
          _scanAnother();
        }
      },
      onLongPress: _shareItem,
      child: ClothingItemDetails(
        item: _scannedItem!,
        onAddToWardrobe: _addToWardrobe,
        onScanAnother: _scanAnother,
        onShare: _shareItem,
      ),
    );
  }

  Future<void> _scanQrCode() async {
    HapticService.selection();
    _ttsService.speak("Opening scanner", priority: SpeechPriority.high);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScan: (data) {
            _processScannedItem(data);
          },
        ),
      ),
    );
  }

  void _createQrCode() {
    HapticService.selection();
    _ttsService.speak("Opening QR code creator", priority: SpeechPriority.high);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RetailQRGeneratorScreen(),
      ),
    );
  }

  void _processScannedItem(String data) {
    try {
      final itemData = json.decode(data);
      setState(() {
        _scannedItem = ClothingItem.fromJson(
          Map<String, dynamic>.from(itemData),
        );
      });

      HapticService.success();
      _ttsService.speak(
        "Item scanned successfully. ${_scannedItem!.accessibilityDescription}",
        priority: SpeechPriority.high,
      );
    } catch (e) {
      HapticService.error();
      _ttsService.speak("Invalid QR code. Please try again", priority: SpeechPriority.high);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code format')),
      );
    }
  }

  void _addToWardrobe() {
    if (_scannedItem == null) return;

    final provider = Provider.of<ClothingProvider>(context, listen: false);

    if (provider.getItemById(_scannedItem!.id) != null) {
      HapticService.warning();
      _ttsService.speak(
        "This item is already in your wardrobe",
        priority: SpeechPriority.high,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item already in wardrobe')),
      );
    } else {
      _showAddToWardrobeConfirmation();
    }
  }

  void _showAddToWardrobeConfirmation() {
    if (_scannedItem == null) return;

    HapticService.medium();
    _ttsService.speak(
      "Add ${_scannedItem!.name} to wardrobe? "
      "Swipe up for yes, swipe down for no.",
      priority: SpeechPriority.high,
    );

    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity == null) return;

          // Swipe up - Yes
          if (details.primaryVelocity! < -200) {
            Navigator.pop(context);
            _confirmAddToWardrobe();
          }
          // Swipe down - No
          else if (details.primaryVelocity! > 200) {
            Navigator.pop(context);
            HapticService.light();
            _ttsService.speak("Cancelled", priority: SpeechPriority.high);
          }
        },
        child: AlertDialog(
          title: const Text('Add to Wardrobe'),
          content: Text('Add ${_scannedItem!.name} to your wardrobe?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                HapticService.light();
                _ttsService.speak("Cancelled", priority: SpeechPriority.high);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmAddToWardrobe();
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAddToWardrobe() async {
    final provider = Provider.of<ClothingProvider>(context, listen: false);
    final success = await provider.addItem(_scannedItem!);

    if (success) {
      HapticService.success();
      _ttsService.speak(
        "Success! ${_scannedItem!.name} added to wardrobe",
        priority: SpeechPriority.high,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to wardrobe')),
      );

      // Clear the scanned item after adding
      setState(() {
        _scannedItem = null;
        _announcementMade = false; // Reset so announcement plays again
      });
    }
  }

  void _scanAnother() {
    HapticService.swipe();
    setState(() {
      _scannedItem = null;
      _announcementMade = false; // Reset so announcement plays again
    });
    _ttsService.speak(
      "Ready to scan another item",
      priority: SpeechPriority.high,
    );
  }

  void _shareItem() {
    if (_scannedItem == null) return;

    HapticService.selection();
    _ttsService.speak(
      "Sharing ${_scannedItem!.name} details",
      priority: SpeechPriority.high,
    );

    // In a real app, implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon')),
    );
  }
}