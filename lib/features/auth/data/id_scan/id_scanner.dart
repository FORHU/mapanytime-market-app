import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';

/// Reads an ID photo on the device with ML Kit text recognition — the photo
/// isn't sent anywhere to be read.
class IdScanner {
  const IdScanner();

  Future<ScannedId> scan(String imagePath) async {
    final recognizer = TextRecognizer();
    try {
      final text = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      // Reading order top to bottom (then left to right within a row), so a
      // printed label is followed by the value beneath it.
      final lines = [for (final block in text.blocks) ...block.lines]
        ..sort((a, b) {
          final dy = a.boundingBox.top - b.boundingBox.top;
          if (dy.abs() > a.boundingBox.height / 2) return dy.sign.toInt();
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        });
      final texts = [for (final line in lines) line.text];
      // Debug builds only (it's ID data): what OCR actually returned, for
      // diagnosing a misread and for turning real cards into parser tests.
      if (kDebugMode) debugPrint('[IdScanner] lines:\n${texts.join('\n')}');
      return IdTextParser.parse(texts);
    } finally {
      await recognizer.close();
    }
  }
}

/// Takes or picks the ID photo. Throws a `PlatformException` with code
/// `camera_access_denied` / `photo_access_denied` when permission is refused.
class IdPhotoPicker {
  const IdPhotoPicker();

  /// Local path of the photo, or null if the buyer cancelled.
  Future<String?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      // Plenty for OCR and for an admin to read, at a few hundred KB.
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    return file?.path;
  }
}

final idScannerProvider = Provider<IdScanner>((ref) => const IdScanner());

final idPhotoPickerProvider = Provider<IdPhotoPicker>(
  (ref) => const IdPhotoPicker(),
);
