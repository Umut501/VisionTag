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
  final bool isClean;

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

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      colorHex: json['colorHex'],
      size: json['size'],
      texture: json['texture'],
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      material: json['material'],
      recyclable: json['recyclable'] ?? false,
      laundryInstructions:
          Map<String, String>.from(json['laundryInstructions']),
      manufacturer: json['manufacturer'],
      collection: json['collection'],
      isClean: json['isClean'] ?? true,
    );
  }

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

  double get discountedPrice => price - (price * discount / 100);

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

  /// TTS için detaylı açıklama
  String get accessibilityDescription {
    final buffer = StringBuffer();

    buffer.write("Color $color , size $size. ");
    buffer.write("Made of $material with a $texture texture. ");
    buffer.write(isClean ? "It is clean. " : "It needs to be washed. ");
    if (discount > 0) {
      buffer.write(
          "Price: ${discountedPrice.toStringAsFixed(2)} dollars after a ${discount.toInt()} percent discount. ");
    } else {
      buffer.write("Price: ${price.toStringAsFixed(2)} dollars. ");
    }
    if (recyclable) {
      buffer.write("This item is recyclable. ");
    }
    buffer.write("From the $collection collection by $manufacturer. End of description.");

    return buffer.toString();
  }

  /// Kısa açıklama - TTS veya liste gösterimi için ideal
  String get briefDescription {
    String base = "$name, size $size, color $color";
    if (base.length > 50) {
      return "${base.substring(0, 47)}...";
    }
    return base;
  }
}
