// ignore: file_names
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QrGenerator {
  // Generate QR code as image
  static Future<Uint8List?> generateQrImage(String data,
      {double size = 300}) async {
    try {
      final QrPainter painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
      );

      final ui.Image image = await painter.toImage(size);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating QR code: $e');
      }
      return null;
    }
  }

  // Save QR code to temporary file and share
  static Future<void> shareQrCode(String data, String fileName) async {
    try {
      final qrImage = await generateQrImage(data);

      if (qrImage != null) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName.png';

        final file = File(filePath);
        await file.writeAsBytes(qrImage);

        final XFile xFile = XFile(filePath, mimeType: 'image/png');
        await Share.shareXFiles([xFile], text: 'VisionTag QR Code');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing QR code: $e');
      }
    }
  }
}
