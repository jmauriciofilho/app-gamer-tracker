import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // O ProviderScope armazena o estado de todos os providers do aplicativo
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreador de Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true), // Suporte a Dark Mode ativado
      home: const Scaffold(
        body: Center(child: Text('Ambiente Riverpod + Isar Configurado!')),
      ),
    );
  }
}
