import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:id_checker/features/home/data/models/image_model.dart';
import 'dart:convert';

class ApiDataSource {
  final String baseUrl = 'https://bilgy-malena-lazulitic.ngrok-free.dev';

  Future<ImageModel?> extractData(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/extract'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 API Status: ${response.statusCode}');
      print('📄 API Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ImageModel.fromJson(json);
      }

      return null;
    } catch (e) {
      print('❌ API Error: $e');
      return null;
    }
  }
}
