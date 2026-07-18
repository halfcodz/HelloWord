import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// 갤러리 사진을 골라 작은 정사각 JPEG(base64)로 변환한다.
class AvatarService {
  /// 사진을 고르고 200x200 JPEG base64로 반환. 취소하면 null.
  static Future<String?> pickAndEncode() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final square = img.copyResizeCropSquare(decoded, size: 200);
    final jpg = img.encodeJpg(square, quality: 75);
    return base64Encode(jpg);
  }

  /// base64 문자열을 이미지 바이트로 디코딩. 실패 시 null.
  static Uint8List? decode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }
}
