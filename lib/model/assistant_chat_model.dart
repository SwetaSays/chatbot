//----------------------Backup code----------------------

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       title: 'Assistant OpenAI with File Search',
//       home: AssistantScreen(),
//     );
//   }
// }

// class AssistantScreen extends StatefulWidget {
//   const AssistantScreen({super.key});

//   @override
//   _AssistantScreenState createState() => _AssistantScreenState();
// }

// class _AssistantScreenState extends State<AssistantScreen> {
//   final _controller = TextEditingController();
//   String _response = '';
//   final String apiKey =String.fromEnvironment('OPENAI_API_KEY'); 
//   bool isLoading = false;

//   Future<String> createAssistant(
//       String vectorStoreId, List<String> fileIds) async {
//     try {
//       final url = Uri.parse('https://api.openai.com/v1/assistants');
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//           'OpenAI-Beta': 'assistants=v2',
//         },
//         body: jsonEncode({
//           "name": "Assistant with File Search by sweta",
//           "instructions":
//           "You are a helpful assistant providing concise responses.",
//           "model": "gpt-4-turbo",
//           "tools": [
//             {"type": "file_search"},
//             {"type": "code_interpreter"}
//           ],
//           "tool_resources": {
//             "file_search": {
//               "vector_store_ids": [vectorStoreId]
//             },
//             "code_interpreter": {"file_ids": fileIds}
//           },
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['id'] ?? ""; // Assistant ID
//       } else {
//         throw Exception("Assistant creation failed: ${response.body}");
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<String> createVectorStore(List<String> fileIds) async {
//     try {
//       final url = Uri.parse('https://api.openai.com/v1/vector_stores');
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//           'OpenAI-Beta': 'assistants=v2',
//         },
//         body: jsonEncode({
//           "name": "Vector Store",
//           "file_ids": fileIds,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['id'] ?? "";
//       } else {
//         throw Exception("Vector store creation failed: ${response.body}");
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> handleUserQuery(String userQuery) async {
//     setState(() => isLoading = true);
//     try {
//       final fileIds = [
//         "file-BsGz5DdwzYZEoaXZoJbbeC",
//         "file-N6xHgXdHputpCuwnCTB91G",
//         "file-CAT2WE5qpaMuEnfU2zpRfH"
//       ];
//       final vectorStoreId = await createVectorStore(fileIds);
//       final assistantId = await createAssistant(vectorStoreId, fileIds);
//       final threadId = await createThread();
//       await addMessageToThread(threadId, userQuery);
//       await createAndStreamRun(assistantId, threadId);
//     } catch (e) {
//       setState(() => _response = "Error: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> uploadFileToVectorStore(
//       String vectorStoreId, String fileId) async {
//     final url = Uri.parse(
//         'https://api.openai.com/v1/vector_stores/$vectorStoreId/files');
//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $apiKey',
//         'Content-Type': 'application/json',
//         'OpenAI-Beta': 'assistants=v2',
//       },
//       body: jsonEncode({
//         "file_id": fileId,
//       }),
//     );
//     if (response.statusCode != 200) {
//       throw Exception(
//           "Failed to upload file to vector store: ${response.body}");
//     }
//   }

//   Future<String> createThread() async {
//     final url = Uri.parse('https://api.openai.com/v1/threads');
//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $apiKey',
//         'Content-Type': 'application/json',
//         'OpenAI-Beta': 'assistants=v2',
//       },
//       body: jsonEncode({}),
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['id'] as String;
//     } else {
//       throw Exception("Failed to create thread: ${response.body}");
//     }
//   }

//   Future<void> addMessageToThread(String threadId, String message) async {
//     final url =
//     Uri.parse('https://api.openai.com/v1/threads/$threadId/messages');
//     final response = await http.post(
//       url,
//       headers: {
//         'Authorization': 'Bearer $apiKey',
//         'Content-Type': 'application/json',
//         'OpenAI-Beta': 'assistants=v2',
//       },
//       body: jsonEncode({
//         "role": "user",
//         "content": message,
//       }),
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['id'];
//     } else {
//       throw Exception("Failed to add message: ${response.body}");
//     }
//   }

//   Future<void> createAndStreamRun(String assistantId, String threadId) async {
//     try {
//       setState(() {
//         _response = '';
//         isLoading = true;
//       });

//       // Step 1: Create a new run
//       final createRunUrl =
//       Uri.parse('https://api.openai.com/v1/threads/$threadId/runs');
//       final createRunResponse = await http.post(
//         createRunUrl,
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//           'OpenAI-Beta': 'assistants=v2',
//         },
//         body: jsonEncode({
//           'assistant_id': assistantId,
//           'stream': true,
//         }),
//       );

//       if (createRunResponse.statusCode != 200) {
//         throw Exception("Failed to create run: ${createRunResponse.body}");
//       }

//       // Step 2: Parse the initial response to get the relevant content
//       final responseBody = createRunResponse.body;
//       final lines = responseBody.split('\n');
//       print("lines:$lines");

//       for (var line in lines) {
//         line = line.trim();
//         if (line.isEmpty) continue;

//         if (line.startsWith('data:')) {
//           final jsonData = line.substring(5).trim(); // Remove 'data:' prefix
//           try {
//             final parsedData = json.decode(jsonData);
//             print("parsedData:$parsedData");

//             if (parsedData is Map<String, dynamic> &&
//                 parsedData.containsKey('content')) {
//               final contentArray = parsedData['content'];
//               if (contentArray is List) {
//                 for (var item in contentArray) {
//                   if (item is Map<String, dynamic> &&
//                       item['type'] == 'text' &&
//                       item.containsKey('text')) {
//                     final textData = item['text'];
//                     if (textData is Map<String, dynamic> &&
//                         textData.containsKey('value')) {
//                       setState(() {
//                         _response += "${textData['value']}\n";
//                       });
//                     }
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             // Skip lines that are not JSON
//             print("Skipping invalid JSON: $line, Error: $e");
//           }
//         }
//       }
//     } catch (e) {
//       print("Error: $e");
//       setState(() {
//         _response = 'An error occurred while processing the request.';
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchFileDetails(String fileId) async {
//     final url = Uri.parse('https://api.openai.com/v1/files/$fileId');
//     final response = await http.get(
//       url,
//       headers: {
//         'Authorization': 'Bearer $apiKey',
//         'Content-Type': 'application/json',
//       },
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final filename = data['filename'];
//       print("Cited File: $filename");
//     } else {
//       print("Failed to fetch file details: ${response.body}");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Assistant with File Search')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               TextField(
//                 controller: _controller,
//                 decoration: const InputDecoration(
//                   labelText: 'Ask a question',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () {
//                   handleUserQuery(_controller.text);
//                   _controller.clear();
//                 },
//                 child: isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text('Send'),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Response:-',
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold, color: Colors.blueAccent),
//               ),
//               const SizedBox(height: 10),
//               SingleChildScrollView(
//                 child: Text(
//                   _response,
//                   style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


/////////////////////////////////////////////////////////////////
 // Future<List<String>> fetchAllFileIds() async {
  //   try {
  //     final apiKey = dotenv.env['API_KEY'];
  //     final url = Uri.parse('https://api.openai.com/v1/files');
  //     final response = await http.get(
  //       url,
  //       headers: {'Authorization': 'Bearer $apiKey'},
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body) as Map<String, dynamic>;
  //       final fileList = responseData['data'] as List<dynamic>;
  //       return fileList.map((file) => file['id'] as String).toList();
  //     } else {
  //       throw Exception("Failed to fetch file IDs: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Error fetching file IDs: $e");
  //     return [];
  //   }
  // }

  // Future<void> createAndStreamRun(String assistantId, String threadId) async {
  //   _response = '';
  //   isLoading = true;

  //   try {
  //     // Step 1: Create a new run
  //     final apiKey = dotenv.env['API_KEY'];
  //     final createRunUrl =
  //         Uri.parse('https://api.openai.com/v1/threads/$threadId/runs');
  //     final createRunResponse = await http.post(
  //       createRunUrl,
  //       headers: {
  //         'Authorization': 'Bearer $apiKey',
  //         'Content-Type': 'application/json',
  //         'OpenAI-Beta': 'assistants=v2',
  //       },
  //       body: jsonEncode({
  //         'assistant_id': assistantId,
  //         'stream': true,
  //       }),
  //     );

  //     if (createRunResponse.statusCode != 200) {
  //       throw Exception("Failed to create run: ${createRunResponse.body}");
  //     }

  //     // Step 2: Parse the initial response to get the relevant content
  //     final responseBody = createRunResponse.body;
  //     final lines = responseBody.split('\n');

  //     for (var line in lines) {
  //       line = line.trim();
  //       if (line.isEmpty) continue;

  //       if (line.startsWith('data:')) {
  //         final jsonData = line.substring(5).trim();
  //         try {
  //           final parsedData = json.decode(jsonData);

  //           if (parsedData is Map<String, dynamic> &&
  //               parsedData.containsKey('content')) {
  //             final contentArray = parsedData['content'];
  //             if (contentArray is List) {
  //               for (var item in contentArray) {
  //                 if (item is Map<String, dynamic> &&
  //                     item['type'] == 'text' &&
  //                     item.containsKey('text')) {
  //                   final textData = item['text'];
  //                   if (textData is Map<String, dynamic> &&
  //                       textData.containsKey('value')) {
  //                     _response += "${textData['value']}\n";
  //                     notifyListeners();
  //                   }
  //                 }
  //               }
  //             }
  //           }
  //         } catch (e) {
  //           print("Skipping invalid JSON: $line, Error: $e");
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     _response = 'An error occurred while processing the request.';
  //     notifyListeners();
  //     print("Error: $e");
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> handleUserQuery(String userQuery) async {
  //   isLoading = true;
  //   try {
  //     final fileIds = await fetchAllFileIds();
  //     print("fileIds$fileIds");

  //     if (fileIds.isEmpty) {
  //       throw Exception("No file IDs available");
  //     }
  //     final vectorStoreId = await createVectorStore(fileIds);
  //     final assistantId = await createAssistant(vectorStoreId, fileIds);
  //     final threadId = await createThread();
  //     await addMessageToThread(threadId, userQuery);
  //     await createAndStreamRun(assistantId, threadId);
  //   } catch (e) {
  //     response = "Error: $e";
  //   } finally {
  //     isLoading = false;
  //   }
  // }