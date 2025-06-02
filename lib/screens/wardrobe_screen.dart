import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/services/haptic_service.dart';
import 'dart:math';

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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _focusedIndex = 0;
  int? _flippedIndex; // <-- Eklendi
  String? _selectedItemId;
  bool _deleteInitiated = false;
  bool _announcementMade = false;
  Future? _pendingDetailFuture;
  int _pendingDetailToken = 0;
  int _autoDetailToken = 0; // State değişkenlerine ekleyin

  int get _itemsPerPage => 2;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ClothingProvider>(context, listen: false);
      final currentPageItems = _getCurrentPageItems(_currentPage);
      _announceWardrobeInfoAndFocusItem(currentPageItems, isFirstOpen: true);
    });
    _announcementMade = true;
  }

  void _announceWardrobeInfo() {
    if (_announcementMade) return; // Prevent duplicate on rebuild
    final provider = Provider.of<ClothingProvider>(context, listen: false);
    final items = provider.items;
    final totalPages = (items.length / _itemsPerPage).ceil();
    final currentPageItems = _getCurrentPageItems(_currentPage);

    String announcement = "";
    switch (widget.mode) {
      case WardrobeMode.view:
        announcement = "Wardrobe view. ";
        break;
      case WardrobeMode.updateStatus:
        announcement = "Update status mode. ";
        break;
      case WardrobeMode.delete:
        announcement = "Remove items mode. ";
        break;
    }

    announcement += "Page ${_currentPage + 1} of $totalPages. "
        "${currentPageItems.length} items on this page. "
        "${items.length} total items in wardrobe. "
        "Swipe up or down to move between items. "
        "Single tap to hear item details. ";

    if (widget.mode == WardrobeMode.view) {
      announcement += "Double tap to view full details.";
    } else if (widget.mode == WardrobeMode.updateStatus) {
      announcement += "Double tap to change clean status.";
    } else {
      announcement += "Double tap to select for removal. Double tap again to confirm.";
    }

    _ttsService.speak(announcement);
  }

  void _announceWardrobeInfoAndFocusItem(List<ClothingItem> currentPageItems, {bool isFirstOpen = false}) async {
    await _ttsService.stop();

    final provider = Provider.of<ClothingProvider>(context, listen: false);
    final items = provider.items;
    final totalPages = (items.length / _itemsPerPage).ceil();

    String announcement;
    if (isFirstOpen) {
      announcement = "You opened your wardrobe. You have ${items.length} items in your wardrobe. "
          "Each page shows 2 items. "
          "You are on page ${_currentPage + 1} of $totalPages. ";
    } else {
      announcement = "Page ${_currentPage + 1} of $totalPages. ";
    }

    if (currentPageItems.isNotEmpty) {
      announcement += "The first item is ${currentPageItems[0].name}. ";
      announcement += "Swipe up or down to move between items. Double tap anywhere for listening details of selected item.";
      announcement += " You are currently focused on ${currentPageItems[_focusedIndex].name}.";
      announcement += "Reading details for ${currentPageItems[_focusedIndex].name}.";
    } else {
      announcement += "There are no items on this page.";
    }

    await _ttsService.speak(announcement);

    final myToken = ++_autoDetailToken;

    if (currentPageItems.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 25000));
      if (myToken == _autoDetailToken) {
        _speakItemDetails(currentPageItems[_focusedIndex]);
      }
    }
  }

  List<ClothingItem> _getCurrentPageItems(int pageIndex) {
    final provider = Provider.of<ClothingProvider>(context, listen: false);
    final items = provider.items;
    final startIndex = pageIndex * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage) < items.length
        ? startIndex + _itemsPerPage
        : items.length;
    return items.sublist(startIndex, endIndex);
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
            if (!_announcementMade) {
              _ttsService.speak("Your wardrobe is empty. Scan clothing items to add them.");
              _announcementMade = true;
            }
            return _buildEmptyWardrobe();
          }

          final totalPages = (items.length / _itemsPerPage).ceil();
          final currentPageItems = _getCurrentPageItems(_currentPage);

          if (_focusedIndex >= currentPageItems.length) {
            _focusedIndex = 0;
          }

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -200 && _currentPage < totalPages - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else if (details.primaryVelocity! > 200) {
                if (_deleteInitiated && widget.mode == WardrobeMode.delete) {
                  setState(() {
                    _deleteInitiated = false;
                    _selectedItemId = null;
                  });
                  HapticService.light();
                  _ttsService.speak("Delete cancelled");
                } else if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            onVerticalDragEnd: (details) async {
              if (currentPageItems.length < 2) return;
              if (details.primaryVelocity == null) return;
              setState(() {
                _flippedIndex = null; // Her swipe'ta kartı ön yüze döndür
              });
              if (details.primaryVelocity! > 200 && _focusedIndex < currentPageItems.length - 1) {
                setState(() {
                  _focusedIndex++;
                });
                await _ttsService.stop();
                _speakItemDetails(currentPageItems[_focusedIndex]);
              } else if (details.primaryVelocity! < -200 && _focusedIndex > 0) {
                setState(() {
                  _focusedIndex--;
                });
                await _ttsService.stop();
                _speakItemDetails(currentPageItems[_focusedIndex]);
              }
            },
            onDoubleTap: () async {
              if (currentPageItems.isNotEmpty) {
                if (widget.mode == WardrobeMode.view) {
                  setState(() {
                    _flippedIndex = _focusedIndex;
                  });
                  await _ttsService.stop();
                  _autoDetailToken++; // Otomatik detay okuma işlemini iptal et
                  _ttsService.speak("Reading full details for ${currentPageItems[_focusedIndex].name} item.", priority: SpeechPriority.high);
                  await Future.delayed(const Duration(milliseconds: 2800));
                  _ttsService.speak(currentPageItems[_focusedIndex].accessibilityDescription);
                } else if (widget.mode == WardrobeMode.updateStatus) {
                  _updateItemStatus(currentPageItems[_focusedIndex], provider);
                } else if (widget.mode == WardrobeMode.delete) {
                  _handleDeleteDoubleTap(currentPageItems[_focusedIndex], provider);
                }
              }
            },
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                        _selectedItemId = null;
                        _deleteInitiated = false;
                        _focusedIndex = 0;
                        _pendingDetailToken++;
                        _flippedIndex = null; // Sayfa değişince kartı ön yüze döndür
                      });
                      _announcementMade = false;
                      final currentPageItems = _getCurrentPageItems(page);
                      _announceWardrobeInfoAndFocusItem(currentPageItems, isFirstOpen: false);
                    },
                    itemCount: totalPages,
                    itemBuilder: (context, pageIndex) {
                      final pageItems = _getCurrentPageItems(pageIndex);
                      return _buildTwoItemLayout(pageItems, provider);
                    },
                  ),
                ),
                if (totalPages > 1) _buildPageIndicator(totalPages),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWardrobe() {
    _ttsService.speak("Your wardrobe is empty. Scan clothing items to add them.");
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checkroom_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Your wardrobe is empty',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Scan clothing items to add them to your wardrobe',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTwoItemLayout(List<ClothingItem> items, ClothingProvider provider) {
    return Column(
      children: List.generate(2, (index) {
        if (index < items.length) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildClothingItemCard(
                items[index],
                provider,
                isGridView: false,
                isFocused: index == _focusedIndex,
                index: index, // <-- index'i iletin
              ),
            ),
          );
        } else {
          return const Expanded(child: SizedBox.shrink());
        }
      }),
    );
  }

  Widget _buildClothingItemCard(
    ClothingItem item,
    ClothingProvider provider, {
    required bool isGridView,
    bool isFocused = false,
    required int index,
  }) {
    final isSelected = _selectedItemId == item.id;
    final isDeleteMode = widget.mode == WardrobeMode.delete;
    final isFlipped = _flippedIndex == index;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final rotate = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isUnder = (ValueKey(isFlipped) != child!.key);
            var tilt = (animation.value - 0.5).abs() - 0.5;
            tilt *= isUnder ? -0.003 : 0.003;
            final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: isFlipped
          ? _buildItemDetailsSheet(item, ScrollController(), key: ValueKey(true))
          : Card(
              key: ValueKey(false),
              elevation: isSelected ? 8 : 4,
              color: isFocused
                  ? Colors.blue.shade100
                  : isSelected
                      ? (isDeleteMode && _deleteInitiated
                          ? Colors.red.shade100
                          : Theme.of(context).colorScheme.primaryContainer)
                      : null,
              child: Padding(
                padding: EdgeInsets.all(isGridView ? 16 : 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getItemIcon(item),
                      size: isGridView ? 48 : 64,
                      color: Color(int.parse(item.colorHex.replaceAll('#', '0xFF'))),
                    ),
                    SizedBox(height: isGridView ? 12 : 16),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: isGridView ? null : 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isGridView ? 8 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Size ${item.size}',
                          style: TextStyle(
                            fontSize: isGridView ? 12 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          item.isClean ? Icons.check_circle : Icons.wash,
                          size: isGridView ? 20 : 24,
                          color: item.isClean ? Colors.green : Colors.amber,
                        ),
                      ],
                    ),
                    if (!isGridView) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${item.material} • ${item.texture}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                    if (widget.mode != WardrobeMode.view) ...[
                      const SizedBox(height: 12),
                      Text(
                        _getModeActionText(isSelected),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: isSelected ? Colors.red : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildItemDetailsSheet(ClothingItem item, ScrollController controller, {Key? key}) {
    return Card(
      key: key,
      elevation: 8,
      color: Colors.white,
      child: SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      _getItemIcon(item),
                      size: 80,
                      color: Color(int.parse(item.colorHex.replaceAll('#', '0xFF'))),
                    ),
                    const SizedBox(height: 16),
                    Text(item.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailSection('Basic Information', [
                'Color: ${item.color}',
                'Size: ${item.size}',
                'Material: ${item.material}',
                'Texture: ${item.texture}',
                'Status: ${item.isClean ? "Clean" : "Needs washing"}',
              ]),
              _buildDetailSection('Brand Information', [
                'Manufacturer: ${item.manufacturer}',
                'Collection: ${item.collection}',
                'Recyclable: ${item.recyclable ? "Yes" : "No"}',
              ]),
              _buildDetailSection('Care Instructions',
                item.laundryInstructions.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .toList(),
              ),
              if (item.price > 0) ...[
                _buildDetailSection('Pricing', [
                  'Price: \$${item.price.toStringAsFixed(2)}',
                  if (item.discount > 0)
                    'Discount: ${item.discount}% off',
                  if (item.discount > 0)
                    'Final Price: \$${item.discountedPrice.toStringAsFixed(2)}',
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(detail, style: Theme.of(context).textTheme.bodyLarge),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  void _updateItemStatus(ClothingItem item, ClothingProvider provider) {
    provider.toggleCleanStatus(item.id);
    final newStatus = !item.isClean;
    final message = newStatus
        ? "${item.name} marked as clean"
        : "${item.name} marked as needs washing";

    _ttsService.speak(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPageIndicator(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalPages,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentPage
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ),
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
        return 'Remove Items';
    }
  }

  void _speakItemDetails(ClothingItem item) {
    String details = "${item.name} selected. Color: ${item.color}. Size: ${item.size}. ";
    details += "Material: ${item.material}. ";
    details += item.isClean ? "Status: Clean. " : "Status: Needs washing. ";

    if (widget.mode == WardrobeMode.view) {
      details += "Double tap for full details.";
    } else if (widget.mode == WardrobeMode.updateStatus) {
      details += "Double tap to change clean status.";
    } else if (widget.mode == WardrobeMode.delete && _selectedItemId == item.id && _deleteInitiated) {
      details += "Selected for removal. Double tap again to confirm.";
    }

    _ttsService.speak(details);
  }

  void _handleDeleteDoubleTap(ClothingItem item, ClothingProvider provider) {
    if (_selectedItemId == item.id && _deleteInitiated) {
      provider.removeItem(item.id);
      _ttsService.speak("${item.name} removed from wardrobe.");
      setState(() {
        _selectedItemId = null;
        _deleteInitiated = false;
        _flippedIndex = null;
      });
    } else {
      setState(() {
        _selectedItemId = item.id;
        _deleteInitiated = true;
      });
      _ttsService.speak("Double tap again to confirm removal of ${item.name}.");
    }
  }

  IconData _getItemIcon(ClothingItem item) {
    // Basit örnek: türüne göre ikon seçimi
    // Gerçek uygulamada item.type gibi bir alan varsa ona göre genişletin
    if (item.name.toLowerCase().contains('shirt')) return Icons.checkroom;
    if (item.name.toLowerCase().contains('pants')) return Icons.shopping_bag;
    if (item.name.toLowerCase().contains('shoe')) return Icons.directions_run;
    return Icons.checkroom;
  }

  String _getModeActionText(bool isSelected) {
    switch (widget.mode) {
      case WardrobeMode.updateStatus:
        return "Double tap to change clean status";
      case WardrobeMode.delete:
        return isSelected ? "Double tap again to confirm removal" : "Double tap to select for removal";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop(); // TTS'i durdur
    _ttsService.dispose();
    _pendingDetailToken++;
    _autoDetailToken++; // Bekleyen otomatik detay okuma işlemlerini iptal et
    super.dispose();
  }
}