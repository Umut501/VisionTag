// ignore: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:visiontag/services/tts_service.dart';

enum WardrobeMode {
  view,
  updateStatus,
  delete,
}

class WardrobeScreen extends StatefulWidget {
  final WardrobeMode mode;

  const WardrobeScreen({
    Key? key,
    this.mode = WardrobeMode.view,
  }) : super(key: key);

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();

    switch (widget.mode) {
      case WardrobeMode.view:
        _ttsService.speak("Your wardrobe. Tap an item to hear details.");
        break;
      case WardrobeMode.updateStatus:
        _ttsService.speak("Select an item to update its clean status.");
        break;
      case WardrobeMode.delete:
        _ttsService.speak("Select an item to remove from your wardrobe.");
        break;
    }
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
        title: Text(_getAppBarTitle()),
        centerTitle: true,
      ),
      body: Consumer<ClothingProvider>(
        builder: (context, provider, child) {
          final items = provider.items;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.checkroom_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your wardrobe is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan clothing items to add them to your wardrobe',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildClothingItem(context, item, provider);
            },
          );
        },
      ),
    );
  }

  String _getAppBarTitle() {
    switch (widget.mode) {
      case WardrobeMode.view:
        return 'My Wardrobe';
      case WardrobeMode.updateStatus:
        return 'Update Status';
      case WardrobeMode.delete:
        return 'Remove Item';
    }
  }

  Widget _buildClothingItem(
    BuildContext context,
    ClothingItem item,
    ClothingProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _handleItemTap(item, provider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Color preview
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      Color(int.parse(item.colorHex.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),

              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.color} • ${item.size} • ${item.material}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          item.isClean ? Icons.check_circle : Icons.wash,
                          size: 16,
                          color: item.isClean ? Colors.green : Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isClean ? 'Clean' : 'Needs washing',
                          style: TextStyle(
                            color: item.isClean ? Colors.green : Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action icon based on mode
              _buildActionIcon(widget.mode, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(WardrobeMode mode, ClothingItem item) {
    switch (mode) {
      case WardrobeMode.view:
        return const Icon(Icons.arrow_forward_ios, size: 16);
      case WardrobeMode.updateStatus:
        return Icon(
          item.isClean ? Icons.wash : Icons.check_circle,
          color: item.isClean ? Colors.amber : Colors.green,
        );
      case WardrobeMode.delete:
        return const Icon(Icons.delete, color: Colors.red);
    }
  }

  void _handleItemTap(ClothingItem item, ClothingProvider provider) {
    switch (widget.mode) {
      case WardrobeMode.view:
        _speakItemDetails(item);
        break;
      case WardrobeMode.updateStatus:
        _updateItemStatus(item, provider);
        break;
      case WardrobeMode.delete:
        _confirmDelete(item, provider);
        break;
    }
  }

  void _speakItemDetails(ClothingItem item) {
    final description = """
      Item: ${item.name}.
      Color: ${item.color}.
      Size: ${item.size}.
      Material: ${item.material}.
      Texture: ${item.texture}.
      Manufacturer: ${item.manufacturer}.
      Collection: ${item.collection}.
      Status: ${item.isClean ? 'Clean' : 'Needs washing'}.
      ${item.recyclable ? 'This item is recyclable.' : ''}
      Laundry instructions: ${item.laundryInstructions.entries.map((e) => "${e.key}: ${e.value}").join('. ')}.
    """;

    _ttsService.speak(description);
  }

  void _updateItemStatus(ClothingItem item, ClothingProvider provider) {
    provider.toggleCleanStatus(item.id);

    final newStatus = !item.isClean;
    final statusMessage =
        newStatus ? "Item marked as clean" : "Item marked as needs washing";

    _ttsService.speak(statusMessage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(statusMessage)),
    );
  }

  void _confirmDelete(ClothingItem item, ClothingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text(
            'Are you sure you want to remove ${item.name} from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeItem(item.id);

              final message = "${item.name} removed from wardrobe";
              _ttsService.speak(message);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
