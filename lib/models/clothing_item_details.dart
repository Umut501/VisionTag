import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/tts_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final ttsService = TtsService();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve renk önizlemesi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(int.parse(item.colorHex.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Temel bilgiler
          _buildSection(
            context,
            title: 'Temel Bilgiler',
            children: [
              _buildDetailRow('Renk', item.color),
              _buildDetailRow('Beden', item.size),
              _buildDetailRow('Doku', item.texture),
              _buildDetailRow('Fiyat', _formatPrice()), // DÜZELTME: price formatı
            ],
          ),

          // Malzeme ve bakım
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

          // Marka bilgileri
          _buildSection(
            context,
            title: 'Marka Bilgileri',
            children: [
              _buildDetailRow('Üretici', item.manufacturer),
              _buildDetailRow('Koleksiyon', item.collection),
            ],
          ),

          // Eylem düğmeleri
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onAddToWardrobe != null)
                  ElevatedButton(
                    onPressed: () {
                      onAddToWardrobe!();
                      ttsService.speak('Gardıroba ekleniyor');
                    },
                    child: const Text('Gardıroba Ekle', style: TextStyle(fontSize: 18)),
                  ),
                if (onScanAnother != null)
                  ElevatedButton(
                    onPressed: () {
                      onScanAnother!();
                      ttsService.speak('Başka bir öğe tara');
                    },
                    child: const Text('Başka Tara', style: TextStyle(fontSize: 18)),
                  ),
                if (onShare != null)
                  ElevatedButton(
                    onPressed: () {
                      onScanAnother!();
                      ttsService.speak('Öğe detayları paylaşılıyor');
                    },
                    child: const Text('Paylaş', style: TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
        ],
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