import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/services/haptic_service.dart';

import 'dart:math';
import 'dart:io';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({Key? key}) : super(key: key);

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final TtsService _ttsService = TtsService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _focusedIndex = 0;
  int? _flippedIndex;
  int _autoDetailToken = 0;
  bool _announcementMade = false;
  int get _itemsPerPage => 2;
  String? _deleteCandidateId;
  Offset? _startFocalPoint;
  
  // For tracking multi-finger gestures
  Set<int> _activePointers = {};
  bool _isMultiTouch = false;
  bool _firstEntry = true;
  
  // Delete confirmation state
  bool _isDeleteConfirmation = false;
  String? _pendingDeleteId;
  bool _zoomProcessed = false; // Prevent multiple zoom triggers
  DateTime? _lastZoomTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ClothingProvider>(context, listen: false);
      _announceCurrentSelection();
    });
  }

void _announceCurrentSelection() {
  final provider = Provider.of<ClothingProvider>(context, listen: false);
  final items = provider.items;
  final totalPages = (items.length / _itemsPerPage).ceil();
  final currentPageItems = _getCurrentPageItems(_currentPage);

  if (items.isEmpty) {
    _ttsService.speak("Your wardrobe is empty. Scan clothing items to add them.");
    return;
  }

  if (currentPageItems.isNotEmpty) {
    final currentItem = currentPageItems[_focusedIndex];

    // Kısa location info
    String pageStr = "${_ordinal(_currentPage + 1)} page";
    String itemStr = "${_ordinal(_focusedIndex + 1)} item";
    String announcement = "Wardrobe, $pageStr, $itemStr. ";

    // Current item info
    announcement += "Selected item is: ${currentItem.name}. ";
    announcement += "Double tap to listen details. The item ";
    announcement += currentItem.isClean ? "is clean. " : "needs washing. ";
    if (currentItem.isClean) {
      announcement += "Hold to mark dirty. ";
    } else {
      announcement += "Hold to mark clean. ";
    }

    // Delete action
    announcement += "Zoom in to delete item. ";

    // Possible actions
    if (_focusedIndex == 0 && currentPageItems.length > 1) {
      announcement += "Swipe down with one finger to go to the next item ${currentPageItems[1].name}. ";
    } else if (_focusedIndex == currentPageItems.length - 1 && currentPageItems.length > 1) {
      announcement += "Swipe up with one finger to go to the previous item ${currentPageItems[0].name}. ";
    } else if (currentPageItems.length > 1) {
      announcement += "Swipe up with one finger to go to the previous item ${currentPageItems[_focusedIndex - 1].name}, swipe down with one finger to go to the next item ${currentPageItems[_focusedIndex + 1].name}. ";
    }

    if (totalPages > 1) {
      if (_currentPage == 0) {
        announcement += "Swipe right with two fingers for next page. ";
      } else if (_currentPage == totalPages - 1) {
        announcement += "Swipe left with two fingers for previous page. ";
      } else {
        announcement += "Swipe left with two fingers for previous page, swipe right with two fingers for next page. ";
      }
    }
    announcement += "Swipe left with one finger to return home. Pinch to exit.";

    _ttsService.speak(announcement, priority: SpeechPriority.high);
  }
}

void _announceItemChange() {
  final currentPageItems = _getCurrentPageItems(_currentPage);
  final provider = Provider.of<ClothingProvider>(context, listen: false);
  final items = provider.items;
  final totalPages = (items.length / _itemsPerPage).ceil();

  if (currentPageItems.isNotEmpty) {
    final currentItem = currentPageItems[_focusedIndex];

    // Kısa location info
    String pageStr = "${_ordinal(_currentPage + 1)} page";
    String itemStr = "${_ordinal(_focusedIndex + 1)} item";
    String announcement = "Wardrobe, $pageStr, $itemStr. ";

    // Current item info
    announcement += "Selected item is: ${currentItem.name}. ";
    announcement += "Double tap to listen details. The item ";
    announcement += currentItem.isClean ? "is clean. " : "needs washing. ";
    if (currentItem.isClean) {
      announcement += "Hold to mark dirty. ";
    } else {
      announcement += "Hold to mark clean. ";
    }

    // Delete action
    announcement += "Zoom in to delete item. ";

    // Possible actions
    if (_focusedIndex == 0 && currentPageItems.length > 1) {
      announcement += "Swipe down with one finger to go to the next item ${currentPageItems[1].name}. ";
    } else if (_focusedIndex == currentPageItems.length - 1 && currentPageItems.length > 1) {
      announcement += "Swipe up with one finger to go to the previous item ${currentPageItems[0].name}. ";
    } else if (currentPageItems.length > 1) {
      announcement += "Swipe up with one finger to go to the previous item ${currentPageItems[_focusedIndex - 1].name}, swipe down with one finger to go to the next item ${currentPageItems[_focusedIndex + 1].name}. ";
    }

    if (totalPages > 1) {
      if (_currentPage == 0) {
        announcement += "Swipe right with two fingers for next page. ";
      } else if (_currentPage == totalPages - 1) {
        announcement += "Swipe left with two fingers for previous page. ";
      } else {
        announcement += "Swipe left with two fingers for previous page, swipe right with two fingers for next page. ";
      }
    }
    announcement += "Swipe left with one finger to return home. Pinch to exit.";

    _ttsService.speak(announcement, priority: SpeechPriority.high);
  }
}

void _handleDeleteItem() {
  final currentPageItems = _getCurrentPageItems(_currentPage);
  if (currentPageItems.isNotEmpty && _pendingDeleteId != null) {
    final provider = Provider.of<ClothingProvider>(context, listen: false);
    
    // Find the specific item to delete
    final itemToDelete = currentPageItems.firstWhere(
      (item) => item.id == _pendingDeleteId,
      orElse: () => currentPageItems[_focusedIndex]
    );
    
    final itemName = itemToDelete.name;
    
    // Delete only the specific item
    provider.removeItem(_pendingDeleteId!);
    HapticService.success(); // Haptic feedback for successful deletion
    _ttsService.speak("$itemName has been deleted from your wardrobe.");
    
    setState(() {
      _isDeleteConfirmation = false;
      _pendingDeleteId = null;
      _flippedIndex = null;
      _zoomProcessed = false; // Reset zoom flag
      
      // Update page structure after deletion
      final allItems = provider.items;
      final newTotalPages = (allItems.length / _itemsPerPage).ceil();
      
      // If current page is now empty but not the last page, stay on current page
      // If current page is empty and is the last page, go to previous page
      if (allItems.isEmpty) {
        // All items deleted
        _currentPage = 0;
        _focusedIndex = 0;
      } else {
        final newCurrentPageItems = _getCurrentPageItems(_currentPage);
        
        if (newCurrentPageItems.isEmpty && _currentPage > 0) {
          // Current page is empty, go to previous page
          _currentPage--;
          _focusedIndex = 0;
        } else if (newCurrentPageItems.isNotEmpty) {
          // Adjust focused index if it's out of bounds
          if (_focusedIndex >= newCurrentPageItems.length) {
            _focusedIndex = newCurrentPageItems.length - 1;
          }
        }
      }
    });
    
    // Announce new selection if items still exist
    final provider2 = Provider.of<ClothingProvider>(context, listen: false);
    if (provider2.items.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _announceCurrentSelection();
      });
    }
  }
}

void _cancelDelete() {
  setState(() {
    _isDeleteConfirmation = false;
    _pendingDeleteId = null;
    _zoomProcessed = false; // Reset zoom flag
  });
  _ttsService.speak("Delete cancelled.");
}

// Yardımcı fonksiyon: 1 -> first, 2 -> second, 3 -> third, ...
String _ordinal(int n) {
  if (n == 1) return "first";
  if (n == 2) return "second";
  if (n == 3) return "third";
  if (n == 4) return "fourth";
  if (n == 5) return "fifth";
  return "$n" + "th";
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

  String _formatPrice(ClothingItem item) {
    try {
      if (item.discount > 0) {
        final originalPrice = item.price;
        final discountAmount = originalPrice * (item.discount / 100);
        final finalPrice = originalPrice - discountAmount;
        return '\$${finalPrice.toStringAsFixed(2)} (${item.discount.toInt()}% off)';
      } else {
        return '\$${item.price.toStringAsFixed(2)}';
      }
    } catch (e) {
      // Fallback eğer hesaplama hatası olursa
      return '\$${item.price.toStringAsFixed(2)}';
    }
  }

  Widget _buildCompactDetailRow(String label, String value, {bool showRecyclable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showRecyclable) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.recycling,
                  size: 20,
                  color: Colors.green[200],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildTwoColumnDetails(ClothingItem item) {
    final leftColumnData = [
      {'label': 'Color', 'value': item.color, 'recyclable': false},
      {'label': 'Size', 'value': item.size, 'recyclable': false},
      {'label': 'Material', 'value': item.material, 'recyclable': item.recyclable},
      {'label': 'Brand', 'value': item.manufacturer, 'recyclable': false},
    ];
    
    final rightColumnData = [
      {'label': 'Texture', 'value': item.texture, 'recyclable': false},
      {'label': 'Status', 'value': item.isClean ? "Clean" : "Needs washing", 'recyclable': false},
      {'label': 'Collection', 'value': item.collection, 'recyclable': false},
      {'label': 'Price', 'value': _formatPrice(item), 'recyclable': false},
    ];

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftColumnData.map((data) => 
                _buildCompactDetailRow(
                  data['label'] as String, 
                  data['value'] as String,
                  showRecyclable: data['recyclable'] as bool,
                )
              ).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: rightColumnData.map((data) => 
                _buildCompactDetailRow(
                  data['label'] as String, 
                  data['value'] as String,
                  showRecyclable: data['recyclable'] as bool,
                )
              ).toList(),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _ttsService.speak("Returning to Home Mode", priority: SpeechPriority.high);
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          },
        ),
      ),
      body: Consumer<ClothingProvider>(
        builder: (context, provider, child) {
          final items = provider.items;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (items.isNotEmpty && !_announcementMade) {
              _announcementMade = true;
              _announceCurrentSelection();
            }
          });

          if (items.isEmpty) {
            return _buildEmptyWardrobe();
          }

          final totalPages = (items.length / _itemsPerPage).ceil();
          final currentPageItems = _getCurrentPageItems(_currentPage);

          if (_focusedIndex >= currentPageItems.length) {
            _focusedIndex = 0;
          }

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
                _zoomProcessed = false; // Reset zoom processing flag
              },
              onScaleUpdate: (details) async {
                // Exit app with pinch
                if (details.scale < 0.7) {
                  _ttsService.speak("Exiting application, bye!", priority: SpeechPriority.high);
                  await Future.delayed(const Duration(milliseconds: 1000));
                  exit(0);
                  return;
                }
                
                // Zoom in for delete - more conservative thresholds with debouncing
                if (details.scale > 1.8 && !_zoomProcessed) {
                  final now = DateTime.now();
                  
                  // Prevent rapid zoom triggers (minimum 1 second between actions)
                  if (_lastZoomTime != null && now.difference(_lastZoomTime!).inMilliseconds < 1000) {
                    return;
                  }
                  
                  if (!_isDeleteConfirmation) {
                    final currentPageItems = _getCurrentPageItems(_currentPage);
                    if (currentPageItems.isNotEmpty) {
                      final itemToDelete = currentPageItems[_focusedIndex];
                      setState(() {
                        _isDeleteConfirmation = true;
                        _pendingDeleteId = itemToDelete.id;
                        _zoomProcessed = true;
                      });
                      _lastZoomTime = now;
                      HapticService.warning(); // Haptic feedback for delete warning
                      _ttsService.speak("Are you sure you want to delete ${itemToDelete.name}? Zoom in again to confirm, or swipe left to cancel.");
                      return;
                    }
                  } else if (details.scale > 2.2) {
                    setState(() {
                      _zoomProcessed = true;
                    });
                    _lastZoomTime = now;
                    HapticService.heavy(); // Strong haptic feedback for delete confirmation
                    _handleDeleteItem();
                    return;
                  }
                }
                
                // Only do swipe detection if scale is near 1.0 (no zoom)
                if (_startFocalPoint != null && details.scale > 0.8 && details.scale < 1.2) {
                  final dx = details.focalPoint.dx - _startFocalPoint!.dx;
                  final dy = details.focalPoint.dy - _startFocalPoint!.dy;
                  
                  // Two finger swipes for page navigation
                  if (_isMultiTouch && dx.abs() > dy.abs() && dx.abs() > 50) {
                    if (dx < 0) {
                      if (_currentPage < totalPages - 1) {
                        setState(() {
                          _currentPage++;
                          _focusedIndex = 0;
                          _flippedIndex = null;
                          _deleteCandidateId = null;
                          _isDeleteConfirmation = false;
                          _pendingDeleteId = null;
                          _zoomProcessed = false;
                          _zoomProcessed = false;
                        });
                        _pageController.animateToPage(
                          _currentPage,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _announceCurrentSelection();
                        _startFocalPoint = null;
                      }
                    } else {
                      if (_currentPage > 0) {
                        setState(() {
                          _currentPage--;
                          _focusedIndex = 0;
                          _flippedIndex = null;
                          _deleteCandidateId = null;
                          _isDeleteConfirmation = false;
                          _pendingDeleteId = null;
                        });
                        _pageController.animateToPage(
                          _currentPage,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _announceCurrentSelection();
                        _startFocalPoint = null;
                      }
                    }
                  }
                  // Single finger swipes for item navigation and back
                  else if (!_isMultiTouch) {
                    if (dy.abs() > dx.abs() && dy.abs() > 50) {
                      if (dy > 0) {
                        if (_focusedIndex < currentPageItems.length - 1) {
                          setState(() {
                            _focusedIndex++;
                            _flippedIndex = null;
                            _deleteCandidateId = null;
                            _isDeleteConfirmation = false;
                            _pendingDeleteId = null;
                            _zoomProcessed = false;
                            _zoomProcessed = false;
                          });
                          HapticService.selection(); // Haptic feedback for item navigation
                          _announceItemChange();
                          _startFocalPoint = null;
                        }
                      } else {
                        if (_focusedIndex > 0) {
                          setState(() {
                            _focusedIndex--;
                            _flippedIndex = null;
                            _deleteCandidateId = null;
                            _isDeleteConfirmation = false;
                            _pendingDeleteId = null;
                          });
                          HapticService.selection(); // Haptic feedback for item navigation
                          _announceItemChange();
                          _startFocalPoint = null;
                        }
                      }
                    }
                    else if (dx.abs() > dy.abs() && dx.abs() > 80 && dx < 0) {
                      if (_isDeleteConfirmation) {
                        HapticService.light(); // Light haptic for cancel
                        _cancelDelete();
                        _startFocalPoint = null;
                      } else {
                        HapticService.swipe(); // Haptic feedback for navigation
                        _ttsService.speak("Returning to Home Mode", priority: SpeechPriority.high);
                        Future.delayed(const Duration(milliseconds: 2500), () {
                          if (mounted) {
                            Navigator.of(context).maybePop();
                          }
                        });
                        _startFocalPoint = null;
                      }
                    }
                  }
                }
              },
              onScaleEnd: (details) {
                _startFocalPoint = null;
                // Reset zoom processing after gesture ends
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _zoomProcessed = false;
                    });
                  }
                });
              },
              onDoubleTap: () async {
                HapticService.medium(); // Haptic feedback for double tap
                final currentPageItems = _getCurrentPageItems(_currentPage);
                if (currentPageItems.isNotEmpty) {
                  final focusedItem = currentPageItems[_focusedIndex];
                  setState(() {
                    _flippedIndex = _focusedIndex;
                    _deleteCandidateId = null;
                    _isDeleteConfirmation = false;
                    _pendingDeleteId = null;
                    _zoomProcessed = false;
                  });
                  await _ttsService.stop();
                  _ttsService.speak("Reading full details for ${focusedItem.name} item.", priority: SpeechPriority.high);
                  await Future.delayed(const Duration(milliseconds: 4000));
                  _ttsService.speak(focusedItem.accessibilityDescription);
                }
              },
              onLongPress: () async {
                HapticService.medium(); // Haptic feedback for long press
                final currentPageItems = _getCurrentPageItems(_currentPage);
                if (currentPageItems.isNotEmpty) {
                  final focusedItem = currentPageItems[_focusedIndex];
                  Provider.of<ClothingProvider>(context, listen: false).toggleCleanStatus(focusedItem.id);
                  final newStatus = !focusedItem.isClean;
                  final message = newStatus
                      ? "${focusedItem.name} marked as clean"
                      : "${focusedItem.name} marked as needs washing";
                  HapticService.success(); // Haptic feedback for successful status change
                  _ttsService.speak(message);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  setState(() {
                    _flippedIndex = null;
                    _deleteCandidateId = null;
                    _isDeleteConfirmation = false;
                    _pendingDeleteId = null;
                  });
                }
              },
              child: Column(
                children: [
                  // Delete confirmation banner
                  if (_isDeleteConfirmation) 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.red.withOpacity(0.8),
                      child: Text(
                        'Delete confirmation: Zoom in again to confirm, swipe left to cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalPages,
                      itemBuilder: (context, pageIndex) {
                        final pageItems = _getCurrentPageItems(pageIndex);
                        return _buildTwoItemLayout(pageItems, currentPageItems);
                      },
                    ),
                  ),
                  if (totalPages > 1) _buildPageIndicator(totalPages),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWardrobe() {
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

  Widget _buildTwoItemLayout(List<ClothingItem> items, List<ClothingItem> currentPageItems) {
    return Column(
      children: List.generate(2, (index) {
        if (index < items.length) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildClothingItemCard(
                items[index],
                isFocused: index == _focusedIndex,
                index: index,
                currentPageItems: currentPageItems,
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
    ClothingItem item, {
    bool isFocused = false,
    required int index,
    required List<ClothingItem> currentPageItems,
  }) {
    final isFlipped = _flippedIndex == index;
    final isDeleteCandidate = _isDeleteConfirmation && _pendingDeleteId == item.id;

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
          ? Card(
              key: ValueKey(true),
              elevation: 8,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset("assets/images/${_getItemIconSvg(item)}.svg", 
                            width: 80, 
                            height: 80, 
                            color: Colors.white,
                            placeholderBuilder: (context) => CircularProgressIndicator(),),
                          /*Icon(
                            _getItemIconSvg(item),
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16)*/
                          
                          Text(
                            item.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32.0,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          
                          ..._buildTwoColumnDetails(item),
                          
                          const SizedBox(height: 16),
                          
                          // Status indicator - sola yaslanmış
                          Row(
                            children: [
                              Icon(
                                item.isClean ? Icons.check_circle : Icons.wash,
                                size: 26,
                                color: item.isClean ? Colors.green[200] : Colors.amber[200],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.isClean ? "Ready to wear" : "Needs washing",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Expanded(child: Card(
              key: ValueKey(false),
              elevation: isFocused ? 8 : 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDeleteCandidate ? [
                      Colors.red.withOpacity(0.8),
                      Colors.red.withOpacity(0.6),
                    ] : isFocused ? [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ] : [
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDeleteCandidate) ...[
                        Icon(
                          Icons.delete_forever,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'DELETE?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ] else ...[
                        SvgPicture.asset("assets/images/${_getItemIconSvg(item)}.svg", 
                            width: 80, 
                            height: 80, 
                            color: Colors.white,
                            placeholderBuilder: (context) => CircularProgressIndicator(),),
                        const SizedBox(height: 20),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isFocused ? 28 : 24,
                            color: isFocused ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Size ${item.size}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isFocused ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              item.isClean ? Icons.check_circle : Icons.wash,
                              size: 36,
                              color: isFocused 
                                ? (item.isClean ? Colors.green[200] : Colors.amber[200])
                                : (item.isClean ? Colors.green[100] : Colors.amber[100]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${item.material} • ${item.texture}',
                          style: TextStyle(
                            fontSize: 20,
                            color: isFocused ? Colors.white70 : Colors.white54,
                          ),
                        ),
                        /*if (!isFocused) ...[    removed because it overflows on small screens
                          const SizedBox(height: 20),
                          if (index < _focusedIndex) ...[
                            Icon(
                              Icons.swipe_up_rounded,
                              size: 40,
                              color: Colors.white70,
                            ),
                          ] else ...[
                            Icon(
                              Icons.swipe_down_rounded,
                              size: 40,
                              color: Colors.white70,
                            ),
                          ],
                        ],*/
                      ],
                    ],
                  ),
                ),
              ),
            ),),
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentPage > 0) ...[
                  Icon(
                    Icons.swipe_right_rounded,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Previous page',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (_currentPage > 0 && _currentPage < totalPages - 1)
                  Text(
                    ' • ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                if (_currentPage < totalPages - 1) ...[
                  Text(
                    'Next page',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.swipe_left_rounded,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          const SizedBox(height: 8),
          Row(
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
        ],
      ),
    );
  }

  IconData _getItemIcon(ClothingItem item) {
    if (item.name.toLowerCase().contains('shirt')) return Icons.checkroom;
    if (item.name.toLowerCase().contains('pants')) return Icons.shopping_bag;
    if (item.name.toLowerCase().contains('shoe')) return Icons.directions_run;
    return Icons.checkroom;
  }

  String _getItemIconSvg(ClothingItem item) {
    if (item.name.toLowerCase().contains('shirt')) return "shirt";
    if (item.name.toLowerCase().contains('shorts')) return "shorts";
    if (item.name.toLowerCase().contains('pants')) return "pants";
    if (item.name.toLowerCase().contains('shoes')) return "shoes";
    if (item.name.toLowerCase().contains('sweater')) return "sweater";
    if (item.name.toLowerCase().contains('hoodie')) return "hoodie";
    if (item.name.toLowerCase().contains('jacket')) return "jacket";
    if (item.name.toLowerCase().contains('socks')) return "socks_2";
    if (item.name.toLowerCase().contains('vest')) return "vest";
    return "hanger";
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    _ttsService.dispose();
    _autoDetailToken++;
    super.dispose();
  }
}