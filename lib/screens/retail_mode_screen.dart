import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    _ttsService.announceScreen("Retail Mode");
    _ttsService.speak(
      "Swipe up to scan an item. Swipe down to create a QR code. "
      "Triple tap for help.",
    );
  }

  void _showHelp() {
    HapticService.tripleTap();
    _ttsService.speak(
        "Retail Mode Help. "
        "Swipe up to scan a clothing item's QR code. "
        "Swipe down to create a new QR code. "
        "When viewing an item, swipe left to add to wardrobe, "
        "swipe right to scan another item. "
        "Double tap to hear full details. "
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (_scannedItem != null) {
            return; // Don't handle swipes when item is displayed
          }

          if (details.primaryVelocity == null) return;

          // Swipe up - scan
          if (details.primaryVelocity! < -200) {
            _scanQrCode();
          }
          // Swipe down - create QR
          else if (details.primaryVelocity! > 200) {
            _createQrCode();
          }
        },
        child: _scannedItem == null ? _buildScanPrompt() : _buildItemDetails(),
      ),
    );
  }

  Widget _buildScanPrompt() {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        _ttsService.speak(
          "Retail Mode. Swipe up to scan, swipe down to create QR code.",
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Scan Section
            Expanded(
              child: Semantics(
                label:
                    'Scan Item. Swipe up or double tap to scan QR codes on clothing items.',
                button: true,
                child: GestureDetector(
                  onDoubleTap: _scanQrCode,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Scan Item',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Icon(
                          Icons.swipe_up_rounded,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
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
              child: Semantics(
                label:
                    'Create QR Code. Swipe down or double tap to generate QR codes for clothing items.',
                button: true,
                child: GestureDetector(
                  onDoubleTap: _createQrCode,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.8),
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_rounded,
                          size: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Create QR Code',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Icon(
                          Icons.swipe_down_rounded,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ],
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
      _ttsService.announceError("Invalid QR code. Please try again");

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
      });
    }
  }

  void _scanAnother() {
    HapticService.swipe();
    setState(() {
      _scannedItem = null;
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
