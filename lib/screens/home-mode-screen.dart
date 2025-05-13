import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:visiontag/screens/qr-scanner-screen.dart';
import 'package:visiontag/screens/wardrobe-screen.dart';
import 'package:visiontag/services/tts_service.dart';

class HomeModeScreen extends StatefulWidget {
  const HomeModeScreen({Key? key}) : super(key: key);

  @override
  State<HomeModeScreen> createState() => _HomeModeScreenState();
}

class _HomeModeScreenState extends State<HomeModeScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    _ttsService
        .speak("Home Mode. Tap to scan clothing or manage your wardrobe.");
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
        title: const Text('Home Mode'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // Scan QR Code
          _buildMenuTile(
            context: context,
            title: 'Scan Item',
            icon: Icons.qr_code_scanner,
            onTap: () {
              _ttsService.speak("Scan item QR code");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRScannerScreen(
                    onScan: (data) async {
                      await _processScannedItem(context, data);
                    },
                  ),
                ),
              );
            },
          ),

          // View Wardrobe
          _buildMenuTile(
            context: context,
            title: 'My Wardrobe',
            icon: Icons.checkroom,
            onTap: () {
              _ttsService.speak("Opening wardrobe");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WardrobeScreen(),
                ),
              );
            },
          ),

          // Mark as Clean/Dirty
          _buildMenuTile(
            context: context,
            title: 'Update Status',
            icon: Icons.wash,
            onTap: () {
              _ttsService.speak("Select an item to update its clean status");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WardrobeScreen(
                    mode: WardrobeMode.updateStatus,
                  ),
                ),
              );
            },
          ),

          // Remove Item
          _buildMenuTile(
            context: context,
            title: 'Remove Item',
            icon: Icons.delete_outline,
            onTap: () {
              _ttsService.speak("Select an item to remove from wardrobe");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WardrobeScreen(
                    mode: WardrobeMode.delete,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
// In home_mode_screen.dart, update the _buildMenuTile method
Widget _buildMenuTile({
  required BuildContext context,
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 4,
    child: GestureDetector(
      onTap: () {
        _ttsService.speak("$title. Double tap to select.");
      },
      onDoubleTap: () {
        _ttsService.speak("Opening $title");
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
  Future<void> _processScannedItem(BuildContext context, String data) async {
    try {
      final clothingItem = ClothingItem.fromJson(
        Map<String, dynamic>.from(
          json.decode(data),
        ),
      );

      final provider = Provider.of<ClothingProvider>(context, listen: false);

      if (provider.getItemById(clothingItem.id) != null) {
        // Item already exists
        _ttsService.speak("This item is already in your wardrobe");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('This item is already in your wardrobe')),
          );
        }
      } else {
        // Add new item
        await provider.addItem(clothingItem);

        final description =
            "Added to wardrobe: ${clothingItem.name}, Color: ${clothingItem.color}, Size: ${clothingItem.size}";
        _ttsService.speak(description);

        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added item to your wardrobe')),
          );
        }
      }
    } catch (e) {
      _ttsService.speak("Invalid QR code. Please try again");
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code format')),
        );
      }
    }
  }
}
