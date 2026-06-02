import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';

Future<void> sendData(ImageEntity document) async {
  final url = Uri.parse(
    "https://script.google.com/macros/s/AKfycbz3WX7ckrJThZqbgADl8zB9FbvvbapRHNNI5OKeNrv6pgJIkfGiwyY3t_KkWWvxXs3r/exec",
  );

  final typeString = document.type == ImageType.nationalId
      ? "National ID"
      : "Driver License";

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "id": document.nid ?? "30103120400493",
      "name": document.name ?? "No Name",
      "type": typeString,
    }),
  );

  if (response.statusCode == 200) {
    print("Success");
  } else {
    print("Error: ${response.body}");
  }
}
