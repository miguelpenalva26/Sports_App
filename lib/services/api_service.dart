import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _base = 'http://localhost:8000';

  static Map<String, String> _authHeaders(String token) => {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_base/api/token/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access'] as String;
    }
    return null;
  }

  static Future<List> fetchBookings(String token) async {
    final response = await http.get(
      Uri.parse('$_base/api/bookings/'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    return [];
  }

  static Future<bool> deleteBooking(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$_base/api/bookings/$id/'),
      headers: _authHeaders(token),
    );
    return response.statusCode == 204;
  }

  static Future<List> fetchFacilities(String token) async {
    final response = await http.get(
      Uri.parse('$_base/api/facilities/'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<List> fetchBookingsForDay(
      String token, int facilityId, String date) async {
    final response = await http.get(
      Uri.parse('$_base/api/bookings/?facility=$facilityId&date=$date'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<String> fetchRecommendation(String date, String hour) async {
    final response = await http.get(
      Uri.parse('$_base/api/recommendation/?date=$date&hour=$hour'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["advice"].contains("Rain")) {
        return "⚠ Rain expected → Book INDOOR";
      }
      return "✅ Good weather → Outdoor is fine";
    }
    return "";
  }

  static Future<bool> createBooking(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_base/api/bookings/'),
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }
}
