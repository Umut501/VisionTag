import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:visiontag/screens/wardrobe_screen.dart';
import 'package:visiontag/screens/qr_scanner_screen.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/services/haptic_service.dart';
import '../providers/clothing_provider.dart';
import 'dart:io';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/clothing_item.dart';
import '../models/clothing_item_details.dart';

class HomeModeScreen extends StatefulWidget {
  const HomeModeScreen({Key? key}) : super(key: key);

  @override
  State<HomeModeScreen> createState() => _HomeModeScreenState();
}

class _HomeModeScreenState extends State<HomeModeScreen> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService();
  int _selectedIndex = 0; // 0: Wardrobe, 1: Scan Item
  Offset? _startFocalPoint;
  bool _announcementMade = false;
  ClothingItem? _scannedItem;
  double _initialScale = 1.0;
  StreamSubscription? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  final double _shakeThreshold = 15.0;
  bool _hasReturnedFromSubScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceCurrentSelection());
    _initShakeDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _hasReturnedFromSubScreen) {
      // We've returned from a sub-screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceReturnToHomeMode();
        _hasReturnedFromSubScreen = false;
      });
    }
  }

  void _initShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      // enableShakeToRepeat kontrolü
      // Eğer GestureProvider kullanıyorsan:
      // final provider = Provider.of<GestureProvider>(context, listen: false);
      // if (!provider.enableShakeToRepeat) return;

      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.81; // Normalize to remove gravity effect
      if (acceleration > _shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!).inMilliseconds > 1200) {
          _lastShakeTime = now;
          HapticService.medium(); // Haptic feedback for shake detection
          _showHelp();
        }
      }
    });
  }

  void _announceCurrentSelection() {
    if (_hasReturnedFromSubScreen) {
      _announceReturnToHomeMode();
      _hasReturnedFromSubScreen = false;
      return;
    }
    
    String announcement = "Home Mode. ";
    if (_selectedIndex == 0) {
      announcement += "Wardrobe selected. Swipe down to select Scan Item. ";
    } else {
      announcement += "Scan Item selected. Swipe up to select Wardrobe. ";
    }
    announcement += "Double tap anywhere to enter. Single finger swipe left to return to main screen. Pinch to exit application. Shake the device for help.";
    
    _ttsService.speak(announcement, priority: SpeechPriority.high);
  }

  void _announceReturnToHomeMode() async {
    await Future.delayed(const Duration(milliseconds: 700));
    String announcement = "You are back in Home Mode. ";
    if (_selectedIndex == 0) {
      announcement += "Wardrobe selected. Swipe down to select Scan Item. ";
    } else {
      announcement += "Scan Item selected. Swipe up to select Wardrobe. ";
    }
    announcement += "Double tap anywhere to enter. Single finger swipe left to return to main screen. Pinch to exit application.";
    
    _ttsService.speak(announcement, priority: SpeechPriority.high);
  }

  void _handlePinch(double scale) {
    if (scale < 0.7) {
      HapticService.heavy(); // Strong haptic feedback for app exit
      _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
      Future.delayed(const Duration(milliseconds: 1000), () {
        exit(0);
      });
    }
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
    _scanQrCode();
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

  void _enterSelected() async {
    _hasReturnedFromSubScreen = true;
    
    if (_selectedIndex == 0) {
      HapticService.medium(); // Haptic feedback for entering wardrobe
      _ttsService.speak("Opening wardrobe", priority: SpeechPriority.high);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WardrobeScreen()),
      );
    } else {
      HapticService.medium(); // Haptic feedback for entering scanner
      _ttsService.speak("Opening scanner", priority: SpeechPriority.high);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerScreen(
            onScan: (data) {
              _processScannedItem(data);
              //_ttsService.speak("Item scanned successfully");
            },
          ),
        ),
      );
    }
    
    // When we return, announce that we're back in home mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceReturnToHomeMode();
      _hasReturnedFromSubScreen = false;
    });
  }

  void _showHelp() {
    _ttsService.speak(
      "Home Mode Help. Swipe up to select Wardrobe or swipe down to select Scan Item. Double tap anywhere to enter selected option. Single finger swipe left to return to main screen. Pinch to exit application.",
      priority: SpeechPriority.high,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Mode'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ), //_scannedItem == null ? _buildSelectionInterface() : _buildItemDetails()
      body: _scannedItem == null ? GestureDetector(
        onScaleStart: (details) {
          _initialScale = 1.0;
          _startFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          // Pinch to exit
          if (details.scale < 0.7) {
            _handlePinch(details.scale);
          }
          // Swipe detection
          if (_startFocalPoint != null) {
            final dx = details.focalPoint.dx - _startFocalPoint!.dx;
            final dy = details.focalPoint.dy - _startFocalPoint!.dy;
            
            // Single finger horizontal swipe left - return to main screen
            if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
              HapticService.swipe(); // Haptic feedback for navigation
              _ttsService.speak("Returning to main screen.", priority: SpeechPriority.high);
              Future.delayed(const Duration(milliseconds: 1200), () {
              Navigator.of(context).maybePop();
              });
              _startFocalPoint = null;
            }
            // Vertical swipe detection
            else if (dy.abs() > dx.abs()) {
              if (dy < -80) {
                // Swipe up: Wardrobe seçili olsun
                if (_selectedIndex != 0) {
                  HapticService.selection(); // Haptic feedback for selection change
                  setState(() => _selectedIndex = 0);
                  _announceCurrentSelection();
                }
                _startFocalPoint = null;
              } else if (dy > 80) {
                // Swipe down: Scan Item seçili olsun
                if (_selectedIndex != 1) {
                  HapticService.selection(); // Haptic feedback for selection change
                  setState(() => _selectedIndex = 1);
                  _announceCurrentSelection();
                }
                _startFocalPoint = null;
              }
            }
          }
        },
        onDoubleTap: _enterSelected,
        child: Column(
          children: [
            // Wardrobe Section
            Expanded(
              child: Semantics(
                label: 'Wardrobe. Swipe up or down to select. Double tap anywhere to enter.',
                button: true,
                selected: _selectedIndex == 0,
                child: GestureDetector(
                  onTap: () {
                    HapticService.selection(); // Haptic feedback for tap selection
                    setState(() => _selectedIndex = 0);
                    _announceCurrentSelection();
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _selectedIndex == 0 ? [
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
                          Icons.checkroom,
                          size: _selectedIndex == 0 ? 110 : 90,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Wardrobe',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_selectedIndex == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Double tap anywhere to enter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 16),
                          const Icon(
                            Icons.swipe_up_rounded,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ],
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

            // Scan Section
            Expanded(
              child: Semantics(
                label: 'Scan Item. Swipe up or down to select. Double tap anywhere to enter.',
                button: true,
                selected: _selectedIndex == 1,
                child: GestureDetector(
                  onTap: () {
                    HapticService.selection(); // Haptic feedback for tap selection
                    setState(() => _selectedIndex = 1);
                    _announceCurrentSelection();
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _selectedIndex == 1 ? [
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.primary,
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
                          size: _selectedIndex == 1 ? 110 : 90,
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
                        if (_selectedIndex == 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Double tap anywhere to enter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 16),
                          const Icon(
                            Icons.swipe_down_rounded,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ) : _buildItemDetails()
    );
  }
}