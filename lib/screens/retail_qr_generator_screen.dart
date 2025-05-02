import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:visiontag/models/clothing_item.dart';
import 'package:visiontag/services/tts_service.dart';
import 'package:visiontag/utils/qr-generator.dart';

class RetailQRGeneratorScreen extends StatefulWidget {
  const RetailQRGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<RetailQRGeneratorScreen> createState() =>
      _RetailQRGeneratorScreenState();
}

class _RetailQRGeneratorScreenState extends State<RetailQRGeneratorScreen> {
  final TtsService _ttsService = TtsService();
  final _formKey = GlobalKey<FormState>();
  final uuid = const Uuid();

  // Form data
  String _name = '';
  String _color = '';
  String _colorHex = '#000000';
  String _size = 'M';
  String _texture = 'Smooth';
  double _price = 0.0;
  double _discount = 0.0;
  String _material = '';
  bool _recyclable = false;
  final Map<String, String> _laundryInstructions = {
    'Washing': 'Machine wash cold',
    'Drying': 'Tumble dry low',
    'Ironing': 'Iron on low',
  };
  String _manufacturer = '';
  String _collection = '';

  String? _qrData;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initTts();
    _ttsService.speak("Create a QR code for a clothing item");
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
        title: const Text('Create Retail QR Code'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_qrData != null) _buildQRCodeDisplay() else _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeDisplay() {
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'QR Code Generated',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Attach this QR code to the clothing item',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _qrData = null;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Information'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Save or share the QR code
                      final fileName = '${_name.replaceAll(' ', '_')}_qr_code';
                      QrGenerator.shareQrCode(_qrData!, fileName);

                      _ttsService.speak("Sharing QR code for $_name");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing QR code')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Name
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Item Name',
              border: OutlineInputBorder(),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an item name';
              }
              return null;
            },
            onSaved: (value) {
              _name = value!;
            },
          ),
          const SizedBox(height: 16),

          // Color
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Color Name',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a color';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _color = value!;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Color Hex',
                    hintText: '#RRGGBB',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a hex color';
                    }
                    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                      return 'Invalid hex color';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _colorHex = value!;
                  },
                  initialValue: '#000000',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Size and Texture
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  value: _size,
                  items: ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                      .map((size) => DropdownMenuItem(
                            value: size,
                            child: Text(size),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _size = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a size';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _size = value!;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Texture',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  initialValue: 'Smooth',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a texture';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _texture = value!;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price and Discount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _price = double.parse(value!);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Discount',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: '0',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a discount';
                    }
                    final discount = double.tryParse(value);
                    if (discount == null) {
                      return 'Invalid discount';
                    }
                    if (discount < 0 || discount > 100) {
                      return 'Discount must be 0-100%';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _discount = double.parse(value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Material Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Material and Recyclable
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a material';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _material = value!;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormField<bool>(
                  initialValue: _recyclable,
                  builder: (FormFieldState<bool> field) {
                    return CheckboxListTile(
                      title: const Text('Recyclable'),
                      value: _recyclable,
                      onChanged: (value) {
                        setState(() {
                          _recyclable = value!;
                        });
                        field.didChange(value);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                  onSaved: (value) {
                    _recyclable = value!;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Washing instructions
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Washing Instructions',
              border: OutlineInputBorder(),
              filled: true,
            ),
            initialValue: _laundryInstructions['Washing'],
            onSaved: (value) {
              _laundryInstructions['Washing'] = value!;
            },
          ),
          const SizedBox(height: 16),

          // Drying instructions
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Drying Instructions',
              border: OutlineInputBorder(),
              filled: true,
            ),
            initialValue: _laundryInstructions['Drying'],
            onSaved: (value) {
              _laundryInstructions['Drying'] = value!;
            },
          ),
          const SizedBox(height: 16),

          // Ironing instructions
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Ironing Instructions',
              border: OutlineInputBorder(),
              filled: true,
            ),
            initialValue: _laundryInstructions['Ironing'],
            onSaved: (value) {
              _laundryInstructions['Ironing'] = value!;
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Brand Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Manufacturer
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Manufacturer',
              border: OutlineInputBorder(),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a manufacturer';
              }
              return null;
            },
            onSaved: (value) {
              _manufacturer = value!;
            },
          ),
          const SizedBox(height: 16),

          // Collection
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Collection',
              border: OutlineInputBorder(),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a collection';
              }
              return null;
            },
            onSaved: (value) {
              _collection = value!;
            },
          ),
          const SizedBox(height: 32),

          // Generate button
          Center(
            child: ElevatedButton.icon(
              onPressed: _generateQRCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _generateQRCode() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final clothingItem = ClothingItem(
        id: uuid.v4(),
        name: _name,
        color: _color,
        colorHex: _colorHex,
        size: _size,
        texture: _texture,
        price: _price,
        discount: _discount,
        material: _material,
        recyclable: _recyclable,
        laundryInstructions: _laundryInstructions,
        manufacturer: _manufacturer,
        collection: _collection,
      );

      final qrData = jsonEncode(clothingItem.toJson());

      setState(() {
        _qrData = qrData;
      });

      _ttsService.speak("QR code generated successfully");
    }
  }
}
