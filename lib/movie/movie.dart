import 'package:hive/hive.dart';
part 'movie.g.dart'; // Ini akan dihasilkan oleh Hive

@HiveType(typeId: 0)
class Movie extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String releaseDate;
  
  @HiveField(3)
  final String imgUrl;
  
  @HiveField(4)
  final String rating;
  
  @HiveField(5)
  final String language;
  
  @HiveField(6)
  final String? createdAt;
  
  @HiveField(7)
  final String description;
  
  @HiveField(8)
  final String? director;
  
  @HiveField(9)
  final List<String>? cast;
  
  @HiveField(10)
  final String duration;
  
  @HiveField(11)
  final List<String>? genres;

  Movie({
    required this.id,
    required this.title,
    required this.releaseDate,
    required this.imgUrl,
    required this.description,
    required this.language,
    required this.rating,
    required this.duration,
    this.createdAt,
    this.director,
    this.cast,
    this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      releaseDate: json['release_date'] ?? '',
      imgUrl: json['imgUrl'] ?? '',
      rating: json['rating']?.toString() ?? '0.0',
      createdAt: json['created_at'],
      description: json['description'] ?? '',
      director: json['director'],
      cast: json['cast'] != null
          ? (json['cast'] is List
              ? List<String>.from(json['cast'])
              : [json['cast'].toString()])
          : null,
      language: json['language'] ?? '',
      duration: json['duration']?.toString() ?? '0 min',
      genres: json['genre'] != null
          ? (json['genre'] is List
              ? List<String>.from(json['genre'])
              : [json['genre'].toString()])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'release_date': releaseDate,
      'imgUrl': imgUrl,
      'description': description,
      'rating': rating,
      'duration': duration,
      'created_at': createdAt,
      'director': director,
      'cast': cast,
      'language': language,
      'genre': genres,
    };
  }
}