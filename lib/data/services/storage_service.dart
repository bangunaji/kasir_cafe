import 'dart:io';
import 'package:dio/dio.dart';

class StorageService {
  final Dio _dio = Dio();
  final String _apiKey = 'fc29833618c280bea1eb6898d7b45488';
  final String _apiUrl = 'https://api.imgbb.com/1/upload';

  Future<String?> uploadProductImage(File imageFile) async {
    try {
      // Create FormData with API key and Image file
      FormData formData = FormData.fromMap({
        'key': _apiKey,
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      // Send POST request to ImgBB
      Response response = await _dio.post(_apiUrl, data: formData);

      if (response.statusCode == 200) {
        // Return the display URL from ImgBB response
        return response.data['data']['url'];
      } else {
        // ImgBB Upload failed: ${response.statusMessage}
        return null;
      }
    } catch (e) {
      // Error uploading to ImgBB: $e
      return null;
    }
  }

  // ImgBB free API doesn't easily support deletion via API key 
  // (usually requires dynamic session or different endpoint)
  // For the sake of simplicity in this POS app, we'll just skip deletion for now
  Future<void> deleteImage(String imageUrl) async {
    // Optional: Implement if needed, but ImgBB free tier is mainly for hosting
    print('Deletion on ImgBB not implemented for free tier API');
  }
}
