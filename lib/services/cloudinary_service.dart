import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'yblkxzs4';
  static const String uploadPreset = 'ik4g4hpq';

  // Cloudinary's generic "auto" endpoint accepts images, pdfs, etc.
  static final Uri _uploadUrl = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
  );

  /// Uploads file bytes to Cloudinary and returns the secure URL.
  /// [fileName] should include the extension (e.g. "sheet.pdf").
  static Future<CloudinaryUploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uploadUrl)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return CloudinaryUploadResult(
      url: data['secure_url'] as String,
      resourceType: data['resource_type'] as String, // "image" | "raw" | "video"
      format: data['format'] as String?, // e.g. "pdf", "png"
      originalFileName: fileName,
    );
  }
}

class CloudinaryUploadResult {
  final String url;
  final String resourceType;
  final String? format;
  final String originalFileName;

  CloudinaryUploadResult({
    required this.url,
    required this.resourceType,
    required this.format,
    required this.originalFileName,
  });

  /// Simple classification for UI rendering: "image" or "file"
  /// Note: Cloudinary classifies PDFs as resource_type "image" (since it can
  /// render PDF pages as images), so we must exclude pdf/raw formats here
  /// explicitly rather than trusting resourceType alone.
  String get displayType {
    final f = format?.toLowerCase();
    if (resourceType == 'image' && f != 'pdf') return 'image';
    return 'file';
  }
}