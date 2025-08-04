import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AssistantChatViewModel extends ChangeNotifier {
  String _response = '';
  bool _isLoading = false;

  String get response => _response;
  bool get isLoading => _isLoading;

  set response(String value) {
    _response = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String> createAssistant(
      String vectorStoreId, List<String> fileIds) async {
    try {
      final apiKey = dotenv.env['API_KEY'];
      final url = Uri.parse('https://api.openai.com/v1/assistants');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'OpenAI-Beta': 'assistants=v2',
        },
        body: jsonEncode({
          "name": "Assistant with File Search by sweta",
          "instructions":
              "You are a helpful assistant providing concise responses.",
          "model": "gpt-4-turbo",
          "tools": [
            {"type": "file_search"},
            {"type": "code_interpreter"}
          ],
          "tool_resources": {
            "file_search": {
              "vector_store_ids": [vectorStoreId]
            },
            "code_interpreter": {"file_ids": fileIds}
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? "";
      } else {
        throw Exception("Assistant creation failed: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createThread() async {
    final apiKey = dotenv.env['API_KEY'];
    final url = Uri.parse('https://api.openai.com/v1/threads');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    } else {
      throw Exception("Failed to create thread: ${response.body}");
    }
  }

  Future<String> createVectorStore(List<String> fileIds) async {
    try {
      final apiKey = dotenv.env['API_KEY'];
      final url = Uri.parse('https://api.openai.com/v1/vector_stores');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'OpenAI-Beta': 'assistants=v2',
        },
        body: jsonEncode({
          "name": "Vector Store",
          "file_ids": fileIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? "";
      } else {
        throw Exception("Vector store creation failed: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadFileToVectorStore(
      String vectorStoreId, String fileId) async {
    final apiKey = dotenv.env['API_KEY'];
    final url = Uri.parse(
        'https://api.openai.com/v1/vector_stores/$vectorStoreId/files');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        "file_id": fileId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
          "Failed to upload file to vector store: ${response.body}");
    }
  }

  Future<void> addMessageToThread(String threadId, String message) async {
    final apiKey = dotenv.env['API_KEY'];
    final url =
        Uri.parse('https://api.openai.com/v1/threads/$threadId/messages');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        "role": "user",
        "content": message,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception("Failed to add message: ${response.body}");
    }
  }

  Future<Map<String, String>> fetchAllFileMetadata() async {
    try {
      final apiKey = dotenv.env['API_KEY'];
      final url = Uri.parse('https://api.openai.com/v1/files');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final fileList = responseData['data'] as List<dynamic>;

        return {
          for (var file in fileList)
            file['id'] as String: file['filename'] as String
        };
      } else {
        throw Exception("Failed to fetch file metadata: ${response.body}");
      }
    } catch (e) {
      print("Error fetching file metadata: $e");
      return {};
    }
  }

Future<void> createAndStreamRun(String assistantId, String threadId) async {
  _response = '';
  isLoading = true;
  final fileMetadata = await fetchAllFileMetadata(); 
  print("File Metadata: $fileMetadata"); 

  try {
    final apiKey = dotenv.env['API_KEY'];
    final createRunUrl = Uri.parse('https://api.openai.com/v1/threads/$threadId/runs');
    final createRunResponse = await http.post(
      createRunUrl,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        'assistant_id': assistantId,
        'stream': true,
      }),
    );

    if (createRunResponse.statusCode != 200) {
      throw Exception("Failed to create run: ${createRunResponse.body}");
    }

    final responseBody = createRunResponse.body;
    final lines = responseBody.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('data:')) {
        final jsonData = line.substring(5).trim();
        try {
          final parsedData = json.decode(jsonData);
          if (parsedData is Map<String, dynamic> &&
              parsedData.containsKey('content')) {
            final contentArray = parsedData['content'];
            if (contentArray is List) {
              for (var item in contentArray) {
                if (item is Map<String, dynamic> &&
                    item['type'] == 'text' &&
                    item.containsKey('text')) {
                  var textValue = item['text']?['value'] ?? "";

                  // Replace file citations with the filename
                  textValue = textValue.replaceAllMapped(
                    RegExp(r"【(\d+:\d+)†source】"),
                    (match) {
                      final fileId = match.group(1)?.split(':')?.first ?? "";
                      print("Matching fileId: $fileId");
                      final fileName = fileMetadata[fileId];
                      if (fileName == null) {
                        print("File ID not found in metadata: $fileId"); 
                      }
                      return fileName != null ? "from $fileName documents" : "from Unknown File documents";
                    },
                  );

                  _response += "$textValue\n";
                  notifyListeners();
                }
              }
            }
          }
        } catch (e) {
          print("Skipping invalid JSON: $line, Error: $e");
        }
      }
    }
  } catch (e) {
    _response = 'An error occurred while processing the request.';
    notifyListeners();
    print("Error: $e");
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

  Future<void> handleUserQuery(String userQuery) async {
    isLoading = true;
    try {
      final fileMetadata = await fetchAllFileMetadata();
      if (fileMetadata.isEmpty) {
        throw Exception("No file metadata available");
      }
      final vectorStoreId = await createVectorStore(fileMetadata.keys.toList());
      final assistantId =
          await createAssistant(vectorStoreId, fileMetadata.keys.toList());
      final threadId = await createThread();
      await addMessageToThread(threadId, userQuery);
      await createAndStreamRun(assistantId, threadId);
    } catch (e) {
      response = "Error: $e";
    } finally {
      isLoading = false;
    }
  }
}
