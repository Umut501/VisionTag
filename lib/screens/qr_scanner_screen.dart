import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/services/haptic_service.dart';
import 'dart:io';
import 'dart:async';

class QRScannerScreen extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerScreen({
    Key? key,
    required this.onScan,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService();
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  bool _torchEnabled = false;
  bool _isAnnouncing = false;
  Timer? _scanInstructionTimer;
  Offset? _startFocalPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanInstructionTimer?.cancel();
    _controller.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_hasScanned) {
      _announceInstructions();
    }
  }

  Future<void> _initializeScanner() async {
    await _ttsService.initTts();
    _announceInstructions();
    
    // Periodic reminders every 10 seconds
    _scanInstructionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_hasScanned && !_isAnnouncing) {
        _ttsService.speak("Still scanning. Point camera at QR code. Double tap to toggle flashlight. Swipe left to go back.");
      }
    });
  }

  void _announceInstructions() {
    _isAnnouncing = true;
    _ttsService.speak(
      "QR Code Scanner. Point your camera at a clothing QR code. "
      "Double tap anywhere to toggle flashlight. "
      "Swipe left to return. "
      "Hold the device steady when you find the QR code.",
      priority: SpeechPriority.high,
    ).then((_) {
      _isAnnouncing = false;
    });
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _controller.toggleTorch();
    HapticService.medium();
    _ttsService.speak(_torchEnabled ? "Flashlight on" : "Flashlight off");
  }

  void _handleScanDetected(String qrData) {
    if (_hasScanned) return;
    
    setState(() {
      _hasScanned = true;
    });
    
    _scanInstructionTimer?.cancel();
    HapticService.success();
    _ttsService.speak("QR code detected successfully! Processing item information.");
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onScan(qrData);
      Navigator.pop(context);
    });
  }

  void _handleBack() {
    HapticService.swipe();
    _ttsService.speak("Returning to previous screen");
    Future.delayed(const Duration(milliseconds: 1000), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
          tooltip: 'Go back',
        ),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: 'Toggle flashlight',
          ),
        ],
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _startFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          // Exit app with pinch
          if (details.scale < 0.7) {
            HapticService.heavy();
            _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
            Future.delayed(const Duration(milliseconds: 1000), () {
              exit(0);
            });
            return;
          }
          
          // Swipe left to go back
          if (_startFocalPoint != null && details.scale > 0.8 && details.scale < 1.2) {
            final dx = details.focalPoint.dx - _startFocalPoint!.dx;
            final dy = details.focalPoint.dy - _startFocalPoint!.dy;
            
            if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
              _handleBack();
              _startFocalPoint = null;
            }
          }
        },
        onDoubleTap: _toggleTorch,
        onLongPress: _announceInstructions,
        child: Column(
          children: [
            // Camera preview with overlay
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _handleScanDetected(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                  // Scanning overlay
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hasScanned ? Colors.green : Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _hasScanned ? Colors.green : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _hasScanned
                            ? const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 80,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Status indicator
                  if (_hasScanned)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'QR Code Detected!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Instructions panel
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasScanned ? Icons.check_circle : Icons.qr_code_scanner,
                      size: 48,
                      color: _hasScanned 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasScanned 
                          ? 'QR Code Detected Successfully!'
                          : 'Scan QR Code on Clothing Item',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _hasScanned ? Colors.green : null,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (!_hasScanned) ...[
                      Text(
                        'Point camera at QR code and hold steady',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Double tap for flashlight',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.swipe_left,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Swipe left to go back',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Processing item information...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}