import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'services/database_service.dart';
import 'utils/initial_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService.instance;
  final wordCount = await dbService.getWordCount();

  if (wordCount == 0) {
    await dbService.initializeWithWords(InitialData.words);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Voca',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
