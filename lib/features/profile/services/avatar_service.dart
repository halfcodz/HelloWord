import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

/// 사진 파일을 골라 작은 정사각 JPEG(base64)로 변환한다.
/// (웹에서 안정적인 file_picker 사용)
class AvatarService {
  /// 사진을 고르고 200x200 JPEG base64로 반환. 취소하면 null.
  static Future<String?> pickAndEncode() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    if (bytes == null) return null;

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
