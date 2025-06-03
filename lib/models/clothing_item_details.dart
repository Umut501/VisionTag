import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/tts_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClothingItemDetails extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback? onAddToWardrobe;
  final VoidCallback? onScanAnother;
  final VoidCallback? onShare;

  const ClothingItemDetails({
    Key? key,
    required this.item,
    this.onAddToWardrobe,
    this.onScanAnother,
    this.onShare,
  }) : super(key: key);

  String _formatPrice() {
    if (item.discount > 0) {
      final originalPrice = item.price;
      final discountAmount = originalPrice * (item.discount / 100);
      final finalPrice = originalPrice - discountAmount;
      return '\$${finalPrice.toStringAsFixed(2)} (${item.discount.toInt()}% off)';
    } else {
      return '\$${item.price.toStringAsFixed(2)}';
    }
  }

  String _getItemIconSvg(ClothingItem item) {
    if (item.name.toLowerCase().contains('shirt')) return "shirt";
    if (item.name.toLowerCase().contains('shorts')) return "shorts";
    if (item.name.toLowerCase().contains('pants')) return "pants";
    if (item.name.toLowerCase().contains('shoes')) return "shoes";
    if (item.name.toLowerCase().contains('sweater')) return "sweater";
    if (item.name.toLowerCase().contains('hoodie')) return "sweater";
    return "tie";
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = TtsService();

    return Card(
  key: ValueKey(true),
  elevation: 8,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  clipBehavior: Clip.antiAlias,
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withOpacity(0.85),
        ],
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  "assets/images/${_getItemIconSvg(item)}.svg",
                  width: 60,
                  height: 60,
                  color: Colors.white,
                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Basic Info Section
          _buildSection(
            context,
            title: 'Temel Bilgiler',
            children: [
              _buildDetailRow('Renk', item.color),
              _buildDetailRow('Beden', item.size),
              _buildDetailRow('Doku', item.texture),
              _buildDetailRow('Fiyat', _formatPrice()),
            ],
          ),

          const SizedBox(height: 16),

          // Material and Care
          _buildSection(
            context,
            title: 'Malzeme ve Bakım',
            children: [
              _buildDetailRow('Malzeme', item.material),
              _buildDetailRow('Geri Dönüşüm', item.recyclable ? 'Evet' : 'Hayır'),
              ...item.laundryInstructions.entries.map(
                (entry) => _buildDetailRow(entry.key, entry.value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Brand Info
          _buildSection(
            context,
            title: 'Marka Bilgileri',
            children: [
              _buildDetailRow('Üretici', item.manufacturer),
              _buildDetailRow('Koleksiyon', item.collection),
            ],
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onAddToWardrobe != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    onAddToWardrobe!();
                    ttsService.speak('Adding item to wardrobe');
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Add'),
                ),
              if (onScanAnother != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    onScanAnother!();
                    ttsService.speak('Scanning another item');
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Rescan'),
                ),
            ],
          ),
        ],
      ),
    ),
  ),
);

  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}