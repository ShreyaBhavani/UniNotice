import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/remote_notice.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Example: Fetch posts
  Future<List<dynamic>> fetchPosts() async {
    return await get('/posts');
  }

  // Example: Fetch users
  Future<List<dynamic>> fetchUsers() async {
    return await get('/users');
  }

  /// Typed helper to fetch notices and map to [Notice] models.
  Future<List<Notice>> fetchNotices() async {
    // Example of a more meaningful English news API.
    // This uses the Spaceflight News API which returns articles like:
    // { id, title, summary, url, ... }
    final uri = Uri.parse('https://api.spaceflightnewsapi.net/v4/articles/?limit=20');

    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final results = decoded['results'];
        if (results is List) {
          return results
              .map((item) => Notice.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Unexpected response format for notices');
        }
      } else {
        throw Exception('Failed to load notices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notices: $e');
    }
  }
}
