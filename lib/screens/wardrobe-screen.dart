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

// Modify _WardrobeScreenState in wardrobe-screen.dart

class _WardrobeScreenState extends State<WardrobeScreen> {
  final TtsService _ttsService = TtsService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _itemsPerPage = 4; // Show 4 items per page

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

// In wardrobe_screen.dart, modify the _initializeTts method
  Future<void> _initializeTts() async {
    await _ttsService.initTts();

    // Get item count using Provider
    final itemCount =
        Provider.of<ClothingProvider>(context, listen: false).items.length;

    switch (widget.mode) {
      case WardrobeMode.view:
        _ttsService.speak(
            "Your wardrobe has $itemCount items. Tap an item to hear basic details. Double tap to view full details.");
        break;
      case WardrobeMode.updateStatus:
        _ttsService.speak(
            "Update status. $itemCount items in your wardrobe. Tap to hear details, double tap to change status.");
        break;
      case WardrobeMode.delete:
        _ttsService.speak(
            "Remove item. $itemCount items in your wardrobe. Tap to hear details, double tap to remove.");
        break;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            _ttsService.speak(
                "Your wardrobe is empty. Scan clothing items to add them.");
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

          // Announce item count when the screen is displayed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ttsService.speak(
                "${items.length} items in your wardrobe. Showing 4 items per page.");
          });

          // Calculate total pages
          final totalPages = (items.length / _itemsPerPage).ceil();

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                    _ttsService.speak("Page ${page + 1} of $totalPages");
                  },
                  itemCount: totalPages,
                  itemBuilder: (context, pageIndex) {
                    // Get items for this page
                    final startIndex = pageIndex * _itemsPerPage;
                    final endIndex = (startIndex + _itemsPerPage) < items.length
                        ? startIndex + _itemsPerPage
                        : items.length;
                    final pageItems = items.sublist(startIndex, endIndex);

                    // Create a grid layout with 4 items (2x2)
                    return GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: pageItems
                          .map((item) =>
                              _buildClothingItemCard(context, item, provider))
                          .toList(),
                    );
                  },
                ),
              ),

              // Pagination indicator
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _currentPage > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $totalPages',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _currentPage < totalPages - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClothingItemCard(
    BuildContext context,
    ClothingItem item,
    ClothingProvider provider,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _speakBasicDetails(item),
        onDoubleTap: () => _handleItemDoubleTap(item, provider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 12),

              // Item name
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Clean/Dirty status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.isClean ? Icons.check_circle : Icons.wash,
                    size: 20,
                    color: item.isClean ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.isClean ? 'Clean' : 'Needs washing',
                    style: TextStyle(
                      color: item.isClean ? Colors.green : Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Action indicator based on mode
              if (widget.mode != WardrobeMode.view)
                Text(
                  widget.mode == WardrobeMode.updateStatus
                      ? 'Double tap to change status'
                      : 'Double tap to remove',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _speakBasicDetails(ClothingItem item) {
    final basicDescription = """
      ${item.name}. 
      Color: ${item.color}. 
      Size: ${item.size}. 
      Status: ${item.isClean ? 'Clean' : 'Needs washing'}.
      Double tap for more details.
    """;

    _ttsService.speak(basicDescription);
  }

  void _handleItemDoubleTap(ClothingItem item, ClothingProvider provider) {
    switch (widget.mode) {
      case WardrobeMode.view:
        _showItemDetails(item);
        break;
      case WardrobeMode.updateStatus:
        _updateItemStatus(item, provider);
        break;
      case WardrobeMode.delete:
        _confirmDelete(item, provider);
        break;
    }
  }

  void _showItemDetails(ClothingItem item) {
    _speakItemDetails(item);

    // Show a detailed modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(int.parse(
                                item.colorHex.replaceAll('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Basic details
                  _buildDetailSection(
                    title: 'Basic Details',
                    details: [
                      {'label': 'Color', 'value': item.color},
                      {'label': 'Size', 'value': item.size},
                      {'label': 'Material', 'value': item.material},
                      {'label': 'Texture', 'value': item.texture},
                      {
                        'label': 'Status',
                        'value': item.isClean ? 'Clean' : 'Needs washing'
                      },
                    ],
                  ),

                  // Brand information
                  _buildDetailSection(
                    title: 'Brand Information',
                    details: [
                      {'label': 'Manufacturer', 'value': item.manufacturer},
                      {'label': 'Collection', 'value': item.collection},
                      {
                        'label': 'Recyclable',
                        'value': item.recyclable ? 'Yes' : 'No'
                      },
                    ],
                  ),

                  // Laundry instructions
                  _buildDetailSection(
                    title: 'Laundry Instructions',
                    details: item.laundryInstructions.entries
                        .map((e) => {'label': e.key, 'value': e.value})
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // Read aloud button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _speakItemDetails(item),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Read Aloud'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Map<String, String>> details,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${detail['label']}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(detail['value']!),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
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

  // [Existing methods for _updateItemStatus and _confirmDelete]

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
