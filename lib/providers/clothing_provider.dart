import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visiontag/models/clothing_item.dart';

class ClothingProvider with ChangeNotifier {
  List<ClothingItem> _items = [];

  List<ClothingItem> get items => [..._items];

  // Constructor - Load items from storage
  ClothingProvider() {
    loadItems();
  }

  // Load items from shared preferences
  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList('clothingItems') ?? [];
    
    _items = itemsJson
        .map((item) => ClothingItem.fromJson(jsonDecode(item)))
        .toList();
    
    notifyListeners();
  }

  // Save items to shared preferences
  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _items
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList('clothingItems', itemsJson);
  }

  // Add new item
  Future<void> addItem(ClothingItem item) async {
    _items.add(item);
    notifyListeners();
    await saveItems();
  }

  // Remove item
  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await saveItems();
  }

  // Update item
  Future<void> updateItem(ClothingItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index >= 0) {
      _items[index] = updatedItem;
      notifyListeners();
      await saveItems();
    }
  }

  // Toggle clean status
  Future<void> toggleCleanStatus(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final updatedItem = _items[index].toggleCleanStatus();
      _items[index] = updatedItem;
      notifyListeners();
      await saveItems();
    }
  }

  // Get item by ID
  ClothingItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}