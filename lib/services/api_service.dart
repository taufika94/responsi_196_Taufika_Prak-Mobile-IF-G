import 'dart:convert';
import 'package:http/http.dart' as http;
import '../movie/movie.dart';

class ApiService {
  static const String _baseUrl = 'https://681388b3129f6313e2119693.mockapi.io';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Get all movies
  static Future<List<Movie>> getMovies() async {
    try {
      print('Fetching movies from: $_baseUrl/api/v1/movie');
      
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/movie'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        // Check if response is directly an array or wrapped in an object
        List<dynamic> moviesJson;
        if (data is List) {
          moviesJson = data;
        } else if (data is Map && data['movies'] != null) {
          moviesJson = data['movies'];
        } else if (data is Map && data['data'] != null) {
          moviesJson = data['data'];
        } else {
          throw Exception('Unexpected response format');
        }

        return moviesJson
            .map((json) => Movie.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in getMovies: $e');
      throw _handleNetworkError(e);
    }
  }

  // Search movies
  static Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/movie?search=$query'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      print('Search API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        List<dynamic> moviesJson;
        if (data is List) {
          moviesJson = data;
        } else if (data is Map && data['movies'] != null) {
          moviesJson = data['movies'];
        } else {
          return [];
        }

        // Filter locally if API doesn't support search
        final allMovies = moviesJson
            .map((json) => Movie.fromJson(json as Map<String, dynamic>))
            .toList();
            
        return allMovies
            .where((movie) =>
                movie.title.toLowerCase().contains(query.toLowerCase()) ||
                movie.description.toLowerCase().contains(query.toLowerCase()) ||
                (movie.genres?.any((genre) => 
                    genre.toLowerCase().contains(query.toLowerCase())) ?? false))
            .toList();
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in searchMovies: $e');
      throw _handleNetworkError(e);
    }
  }

  // Get movie by ID
  static Future<Movie> getMovieDetail(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/movie/$id'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Handle different response formats
        if (data['movie'] != null) {
          return Movie.fromJson(data['movie']);
        } else if (data['data'] != null) {
          return Movie.fromJson(data['data']);
        } else {
          return Movie.fromJson(data);
        }
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in getMovieDetail: $e');
      throw _handleNetworkError(e);
    }
  }

  // Add new movie (if API supports it)
  static Future<Movie> addMovie(Movie movie) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/movie'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(movie.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Movie.fromJson(data);
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in addMovie: $e');
      throw _handleNetworkError(e);
    }
  }

  // Update movie (if API supports it)
  static Future<Movie> updateMovie(String id, Movie movie) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/v1/movie/$id'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(movie.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Movie.fromJson(data);
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in updateMovie: $e');
      throw _handleNetworkError(e);
    }
  }

  // Delete movie (if API supports it)
  static Future<bool> deleteMovie(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/v1/movie/$id'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error in deleteMovie: $e');
      return false;
    }
  }

  // Get image URL helper
  static String getImageUrl(String imageUrl, {required String size}) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    return '$_baseUrl/images/$imageUrl';
  }

  // Error handling
  static Exception _handleError(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return Exception('Bad request: $responseBody');
      case 401:
        return Exception('Unauthorized access');
      case 403:
        return Exception('Forbidden access');
      case 404:
        return Exception('Resource not found');
      case 500:
        return Exception('Internal server error');
      case 502:
        return Exception('Bad gateway');
      case 503:
        return Exception('Service unavailable');
      default:
        return Exception('HTTP Error $statusCode: $responseBody');
    }
  }

  static Exception _handleNetworkError(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return Exception('Request timeout. Please check your internet connection.');
    } else if (error.toString().contains('SocketException')) {
      return Exception('No internet connection available.');
    } else if (error.toString().contains('FormatException')) {
      return Exception('Invalid data format received from server.');
    } else if (error is Exception) {
      return error;
    } else {
      return Exception('Unknown network error: ${error.toString()}');
    }
  }
}
