import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:visiontag/screens/qr-scanner-screen.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/screens/retail_qr_generator_screen.dart';

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
    _ttsService.speak(
        "Retail Mode. Tap the screen to scan a clothing item in the store.");
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
      ),
      body: _scannedItem == null ? _buildScanPrompt() : _buildItemDetails(),
    );
  }

// In RetailModeScreen's _buildScanPrompt method, add buttons for both scanning and creating
  Widget _buildScanPrompt() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Retail Mode',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Scan existing QR codes or create new ones for clothing items',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _scanQrCode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _ttsService.speak("Create new QR code for a clothing item");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RetailQRGeneratorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Create QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetails() {
    final item = _scannedItem!;
    final discountedPrice = item.discountedPrice;
    final hasDiscount = item.discount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addToWardrobe,
                icon: const Icon(Icons.add),
                label: const Text('Add to Wardrobe'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Color sample and info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      Color(int.parse(item.colorHex.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color: ${item.color}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Hex: ${item.colorHex}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Price information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Original Price: \$${item.price.toStringAsFixed(2)}',
                        style: hasDiscount
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              )
                            : Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  if (hasDiscount) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Discount: ${item.discount.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Final Price: \$${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Material and details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Size', item.size),
                  _buildDetailRow('Material', item.material),
                  _buildDetailRow('Texture', item.texture),
                  _buildDetailRow('Manufacturer', item.manufacturer),
                  _buildDetailRow('Collection', item.collection),
                  _buildDetailRow('Recyclable', item.recyclable ? 'Yes' : 'No'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Laundry instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laundry Care Instructions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...item.laundryInstructions.entries.map(
                    (entry) => _buildDetailRow(entry.key, entry.value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _speakItemDetails,
                icon: const Icon(Icons.volume_up),
                label: const Text('Read Aloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _scanQrCode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQrCode() async {
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

  void _processScannedItem(String data) {
    try {
      final itemData = json.decode(data);
      setState(() {
        _scannedItem = ClothingItem.fromJson(
          Map<String, dynamic>.from(itemData),
        );
      });
      _speakItemDetails();
    } catch (e) {
      _ttsService.speak("Invalid QR code. Please try again");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code format')),
      );
    }
  }

  void _speakItemDetails() {
    if (_scannedItem == null) return;

    final item = _scannedItem!;
    final hasDiscount = item.discount > 0;
    final priceText = hasDiscount
        ? "Original price: ${item.price} dollars, with ${item.discount}% discount. Final price: ${item.discountedPrice.toStringAsFixed(2)} dollars"
        : "Price: ${item.price} dollars";

    final description = """
      Item: ${item.name}.
      Color: ${item.color}.
      Size: ${item.size}.
      Material: ${item.material}.
      Texture: ${item.texture}.
      $priceText.
      Manufacturer: ${item.manufacturer}.
      Collection: ${item.collection}.
      ${item.recyclable ? 'This item is recyclable.' : ''}
      Laundry instructions: ${item.laundryInstructions.entries.map((e) => "${e.key}: ${e.value}").join('. ')}.
    """;

    _ttsService.speak(description);
  }

  void _addToWardrobe() {
    if (_scannedItem == null) return;

    final provider = Provider.of<ClothingProvider>(context, listen: false);

    if (provider.getItemById(_scannedItem!.id) != null) {
      // Item already exists
      _ttsService.speak("This item is already in your wardrobe");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is already in your wardrobe')),
      );
    } else {
      // Add new item
      provider.addItem(_scannedItem!);

      final description = "Added to wardrobe: ${_scannedItem!.name}";
      _ttsService.speak(description);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added item to your wardrobe')),
      );
    }
  }
}
