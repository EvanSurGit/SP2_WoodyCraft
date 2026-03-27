import 'package:crudapi/puzzle_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WoodyCraftAdmin());
}

class WoodyCraftAdmin extends StatelessWidget {
  const WoodyCraftAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoodyCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'DM Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C3D2E)),
        scaffoldBackgroundColor: const Color(0xFFF5F0EB),
      ),
      home: const PuzzleListPage(),
    );
  }
}

// ======================
// Page Dashboard (placeholder)
// ======================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Dashboard",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}

// ======================
// Page Stocks (placeholder)
// ======================
class StocksPage extends StatelessWidget {
  const StocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          "Stocks",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Stocks",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}