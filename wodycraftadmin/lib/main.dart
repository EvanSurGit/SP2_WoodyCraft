import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
 
import 'dashboardadmin.dart'; // <-- 1. ON IMPORTE TON VRAI DASHBOARD ICI !
 
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
        colorScheme: const ColorScheme.light(
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
      // Point d'entrée : le login
      home: const LoginScreen(),
      routes: {
        // --- 2. MAGIE : ICI ON REDIRIGE VERS TON VRAI DASHBOARD ! ---
        '/admin/dashboard': (context) => AdminDashboard(),
      },
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
 
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
 
    try {
      final response = await http.post(
        Uri.parse('http://groupe2.lycee.local/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
          if (!mounted) return;
          // --- 3. REDIRECTION VERS LA ROUTE QU'ON A CORRIGÉE ---
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = 'Identifiants incorrects ou accès refusé.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou Icône
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brownDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.admin_panel_settings, size: 64, color: AppColors.gold),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'WoodyCraft',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brownDark,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Espace Administrateur',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
 
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
 
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.brownDark),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.brownDark),
                ),
              ),
              const SizedBox(height: 32),
 
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                        )
                      : const Text(
                          'SE CONNECTER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}