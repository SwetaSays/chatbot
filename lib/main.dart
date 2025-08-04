import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:table_ai/view/assistant_chat_view.dart';
import 'package:table_ai/viewModel/assistant_chat_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssistantChatViewModel(),
      child: const MaterialApp(
        title: 'Chat Assistant',
        home: AssistantChatView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
