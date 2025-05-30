import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app/movie/movie.dart'; // Pastikan ini diimpor
import 'package:app/screens/auth_page.dart';
import 'package:app/screens/movie_list_page.dart';
import 'package:app/screens/favorites_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan ini ditambahkan
  await Hive.initFlutter();
  Hive.registerAdapter(MovieAdapter()); // Daftarkan adapter Movie
  runApp(const MovieApp());
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthPage(),
      routes: {
        '/home': (context) => const MovieListPage(),
        '/favorites': (context) => const FavoritesPage(),
      },
    );
  }
}