// home_mode_screen.dart - CORRECTED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visiontag/providers/clothing_provider.dart';
import 'package:visiontag/screens/wardrobe_screen.dart';
import 'package:visiontag/screens/qr_scanner_screen.dart';
import 'package:visiontag/screens/generate_qr_screen.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/widgets/gesture_detector_widget.dart';

class HomeModeScreen extends StatefulWidget {
  const HomeModeScreen({Key? key}) : super(key: key);

  @override
  State<HomeModeScreen> createState() => _HomeModeScreenState();
}

class _HomeModeScreenState extends State<HomeModeScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();

    final provider = context.read<ClothingProvider>();
    final itemCount = provider.totalItems;
    final cleanCount = provider.cleanItemsCount;
    final dirtyCount = provider.dirtyItemsCount;

    _ttsService.speak(
      "Home Mode. You have $itemCount items in your wardrobe. "
      "$cleanCount clean items and $dirtyCount items need washing. "
      "Swipe up to view wardrobe, swipe down to scan item, swipe left to update status, "
      "swipe right to remove items, or double tap to generate QR code.",
      priority: SpeechPriority.high,
    );
  }

  void _navigateToWardrobe() {
    _ttsService.speak("Opening wardrobe", priority: SpeechPriority.high);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WardrobeScreen(mode: WardrobeMode.view),
      ),
    );
  }

  void _navigateToScanner() {
    _ttsService.speak("Opening scanner", priority: SpeechPriority.high);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScan: (data) {
            // Handle scanned data - you might want to process and add to wardrobe
            Navigator.pop(context);
            _ttsService.speak("Item scanned successfully");
          },
        ),
      ),
    );
  }

  void _navigateToUpdateStatus() {
    _ttsService.speak("Opening status update", priority: SpeechPriority.high);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const WardrobeScreen(mode: WardrobeMode.updateStatus),
      ),
    );
  }

  void _navigateToRemoveItems() {
    _ttsService.speak("Opening item removal", priority: SpeechPriority.high);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WardrobeScreen(mode: WardrobeMode.delete),
      ),
    );
  }

  void _navigateToQRGenerator() {
    _ttsService.speak("Opening QR code generator",
        priority: SpeechPriority.high);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GenerateQRScreen(),
      ),
    );
  }

  void _speakWardrobeStats() {
    final provider = context.read<ClothingProvider>();
    final itemCount = provider.totalItems;
    final cleanCount = provider.cleanItemsCount;
    final dirtyCount = provider.dirtyItemsCount;

    _ttsService.speak(
      "Wardrobe summary: $itemCount total items. $cleanCount clean, $dirtyCount need washing.",
      priority: SpeechPriority.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Mode'),
        centerTitle: true,
      ),
      body: GestureDetectorWidget(
        onSwipeUp: _navigateToWardrobe,
        onSwipeDown: _navigateToScanner,
        onSwipeLeft: _navigateToUpdateStatus,
        onSwipeRight: _navigateToRemoveItems,
        onDoubleTap: _navigateToQRGenerator,
        onLongPress: _speakWardrobeStats,
        onShake: () => _ttsService.repeatLastSpoken(),
        helpText: "Home Mode. Swipe up for wardrobe, down to scan, "
            "left to update status, right to remove items. Double tap to generate QR codes.",
        child: Consumer<ClothingProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wardrobe Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            context,
                            'Total Items',
                            provider.totalItems.toString(),
                            Icons.checkroom,
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            'Clean Items',
                            provider.cleanItemsCount.toString(),
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            'Need Washing',
                            provider.dirtyItemsCount.toString(),
                            Icons.wash,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        'View Wardrobe',
                        'See all your items',
                        Icons.visibility,
                        _navigateToWardrobe,
                        "Swipe up gesture",
                      ),
                      _buildActionCard(
                        context,
                        'Scan Item',
                        'Add new clothing item',
                        Icons.qr_code_scanner,
                        _navigateToScanner,
                        "Swipe down gesture",
                      ),
                      _buildActionCard(
                        context,
                        'Update Status',
                        'Mark items clean or dirty',
                        Icons.update,
                        _navigateToUpdateStatus,
                        "Swipe left gesture",
                      ),
                      _buildActionCard(
                        context,
                        'Remove Items',
                        'Delete items from wardrobe',
                        Icons.delete,
                        _navigateToRemoveItems,
                        "Swipe right gesture",
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Generate QR Code Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToQRGenerator,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generate QR Code'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      'Use gestures to navigate quickly:\n'
                      '• Swipe up: View wardrobe\n'
                      '• Swipe down: Scan item\n'
                      '• Swipe left: Update status\n'
                      '• Swipe right: Remove items\n'
                      '• Double tap: Generate QR code\n'
                      '• Long press: Hear statistics',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    String gestureHint,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _ttsService.speak("$title selected");
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                gestureHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
