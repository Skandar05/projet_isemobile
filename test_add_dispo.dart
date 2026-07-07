import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://apiserv.ise-college-lycee.com:8415';
  final idTeacher = 155;
  final url = Uri.parse('$baseUrl/api/enseignant/disponibilites/$idTeacher');

  final payload = {
    "idenseignant": idTeacher,
    "jour": "Mardi",
    "heuredebut": "14:00",
    "heurefin": "16:00"
  };

  print('Sending POST request to: $url');
  print('Payload: $payload');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
