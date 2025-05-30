import 'package:app/movie/movie.dart';
import 'package:hive/hive.dart';

class MovieDatabase {
  static const String boxName = 'moviesBox';

  Future<void> addMovie(Movie movie, String username) async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.put(
      '${username}_${movie.id}',
      movie,
    ); // Gunakan username sebagai bagian dari kunci
  }

  Future<List<Movie>> getMovies(String username) async {
    final box = await Hive.openBox<Movie>(boxName);
    final userMovies = box.keys
        .where((key) => key.startsWith('${username}_'))
        .map((key) => box.get(key))
        .whereType<Movie>()
        .toList();
    return userMovies;
  }

  Future<void> deleteMovie(String id, String username) async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.delete('${username}_$id');
  }

  Future<void> clearMovies() async {
    final box = await Hive.openBox<Movie>(boxName);
    await box.clear();
  }
}
