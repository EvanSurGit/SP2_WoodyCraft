import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'catalogue_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // --- C'EST ICI LA CORRECTION 👇 ---
  runApp(const WoodyCraftAdmin()); 
}

class WoodyCraftAdmin extends StatelessWidget {
  const WoodyCraftAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PuzzleVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2EDE6),
        primaryColor: const Color(0xFFC17D2E),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFC17D2E),
          secondary: Color(0xFFC17D2E),
          surface: Colors.white,
          background: Color(0xFFF2EDE6),
        ),
        useMaterial3: true,
      ),
      home: const CataloguePage(),
    );
  }
}