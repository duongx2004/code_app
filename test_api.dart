import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.delete(
      Uri.parse('http://127.0.0.1:8081/api/admin/clear-progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'type': 'exercises'}),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}