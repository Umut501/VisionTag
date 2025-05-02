class ClothingItem {
  final String id;
  final String name;
  final String color;
  final String colorHex;
  final String size;
  final String texture;
  final double price;
  final double discount;
  final String material;
  final bool recyclable;
  final Map<String, String> laundryInstructions;
  final String manufacturer;
  final String collection;
  bool isClean;

  ClothingItem({
    required this.id,
    required this.name,
    required this.color,
    required this.colorHex,
    required this.size,
    required this.texture,
    required this.price,
    this.discount = 0.0,
    required this.material,
    this.recyclable = false,
    required this.laundryInstructions,
    required this.manufacturer,
    required this.collection,
    this.isClean = true,
  });

  // Create item from QR code data (JSON)
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      colorHex: json['colorHex'],
      size: json['size'],
      texture: json['texture'],
      price: json['price'].toDouble(),
      discount: json['discount']?.toDouble() ?? 0.0,
      material: json['material'],
      recyclable: json['recyclable'] ?? false,
      laundryInstructions: Map<String, String>.from(json['laundryInstructions']),
      manufacturer: json['manufacturer'],
      collection: json['collection'],
      isClean: json['isClean'] ?? true,
    );
  }

  // Convert to JSON for QR code generation and storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'colorHex': colorHex,
      'size': size,
      'texture': texture,
      'price': price,
      'discount': discount,
      'material': material,
      'recyclable': recyclable,
      'laundryInstructions': laundryInstructions,
      'manufacturer': manufacturer,
      'collection': collection,
      'isClean': isClean,
    };
  }

  // Get discounted price
  double get discountedPrice {
    return price - (price * discount / 100);
  }

  // Toggle clean status
  ClothingItem toggleCleanStatus() {
    return ClothingItem(
      id: id,
      name: name,
      color: color,
      colorHex: colorHex,
      size: size,
      texture: texture,
      price: price,
      discount: discount,
      material: material,
      recyclable: recyclable,
      laundryInstructions: laundryInstructions,
      manufacturer: manufacturer,
      collection: collection,
      isClean: !isClean,
    );
  }
}