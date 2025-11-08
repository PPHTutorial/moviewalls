import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../core/utils/logger.dart';
import '../iap/subscription_manager.dart';

/// Watermark service for adding watermarks to images
class WatermarkService {
  static WatermarkService? _instance;

  WatermarkService._();

  static WatermarkService get instance {
    _instance ??= WatermarkService._();
    return _instance!;
  }

  /// Process image with watermark based on user subscription status
  Future<Uint8List> processImage({
    required Uint8List imageBytes,
    required bool isPro,
    String quality = 'HD',
  }) async {
    try {
      // Check actual Pro status
      final actualProStatus = SubscriptionManager.instance.isProUser || isPro;

      // If user is Pro, return original image without watermark
      if (actualProStatus) {
        AppLogger.i('Pro user - returning original image without watermark');
        return imageBytes;
      }

      // For free users, add watermark
      AppLogger.i('Free user - adding watermark to image');
      return await _addWatermark(imageBytes);
    } catch (e, stackTrace) {
      AppLogger.e('Error processing image', e, stackTrace);
      // On error, return original image (this should rarely happen)
      // Log the error so we can debug watermark issues
      return imageBytes;
    }
  }

  /// Add watermark to image using moviewalls.png
  Future<Uint8List> _addWatermark(Uint8List imageBytes) async {
    try {
      // Decode main image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Load watermark image
      final watermarkBytes =
          await rootBundle.load('assets/images/moviewalls.png');
      final watermarkImage =
          img.decodeImage(watermarkBytes.buffer.asUint8List());
      if (watermarkImage == null) {
        throw Exception('Failed to decode watermark image');
      }

      // Calculate watermark size - use smaller size for downloads
      // Use 5% of image width/height, but ensure minimum visibility
      final targetSize =
          (image.width < image.height ? image.width : image.height) * 0.05;
      final watermarkWidth = targetSize.round().clamp(80, 150);
      final watermarkHeight =
          (watermarkImage.height * (watermarkWidth / watermarkImage.width))
              .round();

      // Resize watermark
      final resizedWatermark = img.copyResize(
        watermarkImage,
        width: watermarkWidth,
        height: watermarkHeight,
      );

      // Calculate centered position
      final x = ((image.width - watermarkWidth) / 2).round();
      final y = ((image.height - watermarkHeight) / 2).round();

      // Apply opacity (0.4 = 40% opacity) to watermark pixels
      final opacity = 0.2;

      // Apply opacity to watermark image
      for (int py = 0; py < resizedWatermark.height; py++) {
        for (int px = 0; px < resizedWatermark.width; px++) {
          final pixel = resizedWatermark.getPixel(px, py);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final a = pixel.a.toInt();
          final newAlpha = ((a * opacity).round()).clamp(0, 255);
          resizedWatermark.setPixel(
            px,
            py,
            img.ColorRgba8(r, g, b, newAlpha),
          );
        }
      }

      // Composite watermark onto image
      img.compositeImage(
        image,
        resizedWatermark,
        dstX: x,
        dstY: y,
      );

      // Encode back to bytes (preserve original format)
      Uint8List processedBytes;
      if (imageBytes.length > 0 &&
          imageBytes[0] == 0xFF &&
          imageBytes[1] == 0xD8) {
        // JPEG format
        processedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
      } else {
        // PNG or other format
        processedBytes = Uint8List.fromList(img.encodePng(image));
      }

      AppLogger.i(
          'Watermark added successfully (centered, 40% size, 40% opacity)');
      return processedBytes;
    } catch (e, stackTrace) {
      AppLogger.e('Error adding watermark', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user has Pro subscription
  Future<bool> checkProStatus() async {
    return SubscriptionManager.instance.isProUser;
  }

  /// Preview watermark on UI (for showing to users)
  Widget buildWatermarkPreview({double? size, double? opacity}) {
    final watermarkSize = size ?? 0.2; // 40% of screen size
    final watermarkOpacity = opacity ?? 0.2; // 20% opacity

    return Center(
      child: IgnorePointer(
        child: Opacity(
          opacity: watermarkOpacity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use 40% of the smaller dimension (width or height)
              final maxSize = constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight;
              final watermarkDimension = maxSize * watermarkSize;

              return Image.asset(
                'assets/images/moviewalls.png',
                width: watermarkDimension,
                height: watermarkDimension,
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      ),
    );
  }
}
