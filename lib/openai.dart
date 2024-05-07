import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiKey = 'api-key';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

Future<String> getResponse(String prompt) async {
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/engines/davinci-codex/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'prompt': prompt,
      'max_tokens': 60,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['choices'][0]['text'].trim();
  } else {
    throw Exception('Failed to get response from OpenAI');
  }
}
