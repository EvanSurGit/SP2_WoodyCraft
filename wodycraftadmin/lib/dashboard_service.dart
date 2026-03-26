import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {

  final String apiUrl = "http://groupe2.lycee.local/api/admin/dashboard";

  Future<Map<String, dynamic>> fetchDashboard() async {

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur API dashboard");
    }
  }
}