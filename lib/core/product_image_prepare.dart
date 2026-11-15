import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
import 'i18n.dart';

/// Result of staff product image pick → crop/rotate → 1024 WebP compress.
class PreparedProductImage {
  const PreparedProductImage({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;
}

/// Client-side product catalog image pipeline.
///
/// 1. Pick from camera/gallery
/// 2. Square crop UI with rotate controls ([image_cropper])
/// 3. Compress to ~1024×1024 WebP ([flutter_image_compress])
abstract final class ProductImagePrepare {
  static const int edgePx = 1024;
  static const int webpQuality = 80;
  static const int jpegFallbackQuality = 85;

  static final ImagePicker _picker = ImagePicker();
  static final ImageCropper _cropper = ImageCropper();

  /// Returns null if the user cancels pick or crop.
  static Future<PreparedProductImage?> pickCropAndCompress({
    required BuildContext context,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      // Keep enough detail for crop; final size comes from compress.
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 95,
    );
    if (picked == null) return null;

    if (!context.mounted) return null;
    final cropped = await _cropper.cropImage(
      sourcePath: picked.path,
      maxWidth: edgePx,
      maxHeight: edgePx,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: _uiSettings(context),
    );
    if (cropped == null) return null;

    return _compressToCatalogImage(cropped.path);
  }

  static List<PlatformUiSettings> _uiSettings(BuildContext context) {
    final title = t('STORE_FORM.PRODUCT_IMAGE_CROP_TITLE');
    final settings = <PlatformUiSettings>[
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: Brand.themeColor,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: Brand.themeColor,
        backgroundColor: Brand.themeBackground,
        statusBarLight: false,
        navBarLight: true,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
        hideBottomControls: false,
        aspectRatioPresets: const <CropAspectRatioPresetData>[
          CropAspectRatioPreset.square,
        ],
      ),
      IOSUiSettings(
        title: title,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
        rotateClockwiseButtonHidden: false,
        rotateButtonsHidden: false,
        aspectRatioPresets: const <CropAspectRatioPresetData>[
          CropAspectRatioPreset.square,
        ],
      ),
    ];

    if (kIsWeb) {
      settings.add(
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 520, height: 520),
          rotatable: true,
          scalable: true,
          zoomable: true,
          guides: true,
          center: true,
        ),
      );
    }
    return settings;
  }

  static Future<PreparedProductImage> _compressToCatalogImage(
    String path,
  ) async {
    try {
      final webp = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: edgePx,
        minHeight: edgePx,
        quality: webpQuality,
        format: CompressFormat.webp,
        keepExif: false,
      );
      if (webp != null && webp.isNotEmpty) {
        return PreparedProductImage(
          bytes: Uint8List.fromList(webp),
          filename: 'product.webp',
        );
      }
    } catch (_) {
      // Fall through to JPEG when WebP encode is unavailable.
    }

    final jpeg = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: edgePx,
      minHeight: edgePx,
      quality: jpegFallbackQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (jpeg != null && jpeg.isNotEmpty) {
      return PreparedProductImage(
        bytes: Uint8List.fromList(jpeg),
        filename: 'product.jpg',
      );
    }

    // Last resort: raw cropped JPEG bytes from the cropper.
    return PreparedProductImage(
      bytes: Uint8List.fromList(await XFile(path).readAsBytes()),
      filename: 'product.jpg',
    );
  }
}
