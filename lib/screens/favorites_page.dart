import 'package:app/movie/MovieDatabase.dart';
import 'package:app/screens/movie_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../movie/movie.dart';
import '../services/api_service.dart';// Import MovieDatabase

const Color primaryColor = Color(0xFF8D6B94);
const Color secondaryColor = Color(0xFFB15A7B);
const Color accentColor = Color(0xFFC3A29E);
const Color lightBackgroundColor = Color(0xFFE8DBC5);
const Color lightestBackgroundColor = Color(0xFFF4E9CE);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MovieDatabase _movieDatabase = MovieDatabase();
  List<Movie> _favoriteMovies = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedMovies = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';

    try {
      _favoriteMovies = await _movieDatabase.getMovies(username); // Ambil berdasarkan username
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat favorit: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';
    await _movieDatabase.deleteMovie(movieId, username); // Hapus berdasarkan username
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dihapus dari favorit!'),
          backgroundColor: const Color.fromARGB(255, 209, 47, 47),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  Future<void> _removeSelectedFavorites() async {
    if (_selectedMovies.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';

    for (final id in _selectedMovies) {
      await _movieDatabase.deleteMovie(id, username); // Hapus berdasarkan username
    }

    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedMovies.length} Movie dihapus dari favorit!'),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMovies.clear();
      }
    });
  }

  void _toggleMovieSelection(String movieId) {
    setState(() {
      if (_selectedMovies.contains(movieId)) {
        _selectedMovies.remove(movieId);
      } else {
        _selectedMovies.add(movieId);
      }

      if (_selectedMovies.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightestBackgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                lightBackgroundColor.withOpacity(0.5),
              ),
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      foregroundColor: lightestBackgroundColor,
      elevation: 0,
      title: _isSelectionMode
          ? Text('${_selectedMovies.length} dipilih',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ))
          : const Text(
              'Movie Favorit',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
      centerTitle: true,
      actions: [
        if (_favoriteMovies.isNotEmpty && !_isLoading && _errorMessage.isEmpty)
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Batal' : 'Pilih',
          ),
        if (_isSelectionMode && _selectedMovies.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _removeSelectedFavorites,
            tooltip: 'Hapus yang dipilih',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: secondaryColor));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: secondaryColor, size: 60),
            const SizedBox(height: 20),
            Text(
              'Oops! Terjadi kesalahan.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }

    if (_favoriteMovies.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: secondaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _favoriteMovies.length,
        itemBuilder: (context, index) {
          final movie = _favoriteMovies[index];
          final isSelected = _selectedMovies.contains(movie.id);
          return _isSelectionMode
              ? _buildSelectableMovieCard(movie, isSelected)
              : _buildDismissibleMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildSelectableMovieCard(Movie movie, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleMovieSelection(movie.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? secondaryColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            _buildMovieCardContent(movie),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: accentColor),
          const SizedBox(height: 24),
          Text(
            'Belum ada Movie favorit.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tambahkan beberapa dari daftar Movie utama Anda!',
            style: TextStyle(
              fontSize: 16,
              color: primaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Jelajahi Movie', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleMovieCard(Movie movie) {
    return Dismissible(
      key: Key(movie.id),
      background: Container(
        decoration: BoxDecoration(
          color: secondaryColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 20),
        child: Icon(Icons.delete, color: lightestBackgroundColor, size: 30),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: lightestBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Hapus dari Favorit?',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Anda yakin ingin menghapus ${movie.title} dari daftar favorit?',
              style: TextStyle(color: primaryColor.withOpacity(0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: lightestBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _removeFavorite(movie.id),
      child: _buildMovieCardContent(movie),
    );
  }

  Widget _buildMovieCardContent(Movie movie) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: lightBackgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isSelectionMode
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailPage(movieId: movie.id),
                  ),
                ).then((_) => _loadFavorites());
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'movieImage_${movie.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  ApiService.getImageUrl(movie.imgUrl, size: 'medium'),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      color: lightestBackgroundColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: secondaryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: lightestBackgroundColor,
                      child: Icon(
                        Icons.movie_outlined,
                        size: 80,
                        color: primaryColor.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: secondaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          movie.releaseDate,
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        movie.duration,
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.language, size: 16, color: secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        movie.language,
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (movie.genres != null && movie.genres!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: movie.genres!.map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGenreColor(genre).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getGenreColor(genre).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getGenreColor(genre),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'action':
        return Colors.red.shade700;
      case 'comedy':
        return Colors.orange.shade700;
      case 'drama':
        return Colors.blue.shade700;
      case 'horror':
        return Colors.purple.shade700;
      case 'romance':
        return Colors.pink.shade700;
      case 'thriller':
        return Colors.grey.shade700;
      case 'sci-fi':
      case 'science fiction':
        return Colors.cyan.shade700;
      case 'fantasy':
        return Colors.indigo.shade700;
      case 'adventure':
        return Colors.green.shade700;
      case 'mystery':
        return Colors.brown.shade700;
      default:
        return primaryColor;
    }
  }
}

// Custom Painter untuk pola latar belakang
class _BackgroundPatternPainter extends CustomPainter {
  final Color patternColor;

  _BackgroundPatternPainter(this.patternColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = patternColor;

    final double baseSize = size.width * 0.08;
    final double spacing = size.width * 0.15;

    for (double x = -baseSize; x < size.width + baseSize; x += spacing) {
      for (double y = -baseSize; y < size.height + baseSize; y += spacing) {
        canvas.drawCircle(
          Offset(x + size.width * 0.03, y + size.height * 0.05),
          baseSize * 0.6,
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x, y + baseSize, baseSize * 0.8, baseSize * 0.8),
          paint,
        );
        canvas.drawOval(
          Rect.fromLTWH(
            x + baseSize * 0.5,
            y + baseSize * 1.5,
            baseSize,
            baseSize * 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}