import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
 
import 'puzzle_list_page.dart';
 
void main() {
  runApp(const MyApp());
}
 
// ─── Palette de couleurs globale ─────────────────────────────────────────────
class AppColors {
  static const Color bg         = Color(0xFFF5F0E8);
  static const Color brownDark  = Color(0xFF2C1A0E);
  static const Color gold       = Color(0xFFC8922A);
  static const Color fieldColor = Color(0xFFEEE8DC);
  static const Color divider    = Color(0xFFD9D0C0);
}
 
// ─── Application ─────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoodyCraft Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.light(
          primary: AppColors.brownDark,
          secondary: AppColors.gold,
          surface: AppColors.bg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.brownDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brownDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: AppColors.brownDark, fontSize: 13),
        ),
        scaffoldBackgroundColor: AppColors.bg,
      ),
      // Seul point d'entrée : le login
      home: const LoginScreen(),
      routes: {
        '/admin/dashboard': (context) => const AppShell(),
      },
    );
  }
}
 
// ─── AppShell — navigation principale via IndexedStack ───────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});
 
  @override
  State<AppShell> createState() => _AppShellState();
}
 
class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
 
  // Pages indexées — ajouter ici les nouvelles sections
  static const List<Widget> _pages = [
    _DashboardPlaceholder(),
    PuzzleListPage(),
    _CommandesPlaceholder(),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack garde chaque page en mémoire (pas de rebuild au changement d'onglet)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.brownDark.withOpacity(0.5),
        backgroundColor: AppColors.bg,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
        ],
      ),
    );
  }
}
 
// ─── Placeholders (à remplacer par les vraies pages) ─────────────────────────
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();
 
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Dashboard — à implémenter',
            style: TextStyle(color: AppColors.brownDark)),
      ),
    );
  }
}
 
class _CommandesPlaceholder extends StatelessWidget {
  const _CommandesPlaceholder();
 
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Commandes — à implémenter',
            style: TextStyle(color: AppColors.brownDark)),
      ),
    );
  }
}
 
// ─── Écran de connexion ───────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage            = const FlutterSecureStorage();
 
  bool _isLoading   = false;
  bool _obscurePass = true;
  String? _errorMessage;
 
  static const String _baseUrl = 'http://groupe2.lycee.local/api';
 
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });
 
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email':    _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
 
      final data = jsonDecode(response.body);
 
      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'user_role',    value: data['user']['role']);
 
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
 
      } else if (response.statusCode == 403) {
        setState(() => _errorMessage = 'Accès refusé. Réservé aux administrateurs.');
      } else {
        setState(() => _errorMessage = 'Identifiants incorrects.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de joindre le serveur.');
    }
 
    setState(() => _isLoading = false);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 64),
                const SizedBox(height: 16),
                const Text(
                  'WoodyCraft',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brownDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ESPACE ADMINISTRATEUR',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                _buildLabel('Email professionnel'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: 'admin@woodycraft.fr',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildLabel('Mot de passe'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _passwordController,
                  hint: '••••••••',
                  obscure: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 12),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Identifiants oubliés ?',
                    style: TextStyle(color: AppColors.gold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.brownDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
 
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.brownDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.brownDark.withOpacity(0.4),
          fontSize: 14,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
 
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
 
