import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../movie/movie.dart';
import 'movie_detail_page.dart';

// Definisi Warna dari Palet yang Diberikan
const Color primaryColor = Color(0xFF8D6B94); // Ungu tua/abu-abu
const Color secondaryColor = Color(0xFFB15A7B); // Merah muda/ungu gelap
const Color accentColor = Color(0xFFC3A29E); // Coklat muda/salmon
const Color lightBackgroundColor = Color(0xFFE8DBC5); // Krem muda
const Color lightestBackgroundColor = Color(0xFFF4E9CE); // Hampir putih

class MovieListPage extends StatefulWidget {
  const MovieListPage({super.key});

  @override
  State<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  final List<Movie> _movies = [];
  final List<Movie> _allMovies = []; // Menyimpan semua data movie
  bool _isLoading = true;
  String _username = 'User';
  String _errorMessage = '';
  bool _hasError = false;

  // Filter variables
  String _selectedGenre = 'Semua';
  Set<String> _availableGenres = {'Semua'};
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUsername(), _loadMovies()]);
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? 'User';
      });
    } catch (e) {
      print('Error loading username: $e');
    }
  }

  Future<void> _loadMovies() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasError = false;
      });
    }

    try {
      final data = await ApiService.getMovies(); // Pastikan method ini ada di ApiService
      if (mounted) {
        setState(() {
          _allMovies.clear();
          _allMovies.addAll(data);
          _movies.clear();
          _movies.addAll(data);
          _hasError = false;
          _extractGenres();
        });
      }
    } catch (e) {
      print('Error loading Movies: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat data: ${e.toString()}";
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _extractGenres() {
    Set<String> genres = {'Semua'};
    
    // Extract genres from all movies
    for (Movie movie in _allMovies) {
      if (movie.genres != null) {
        for (String genre in movie.genres!) {
          genres.add(genre.trim());
        }
      }
    }

    setState(() {
      _availableGenres = genres;
    });
  }

  Future<void> _searchMoviesByGenre(String genre) async {
    if (genre == 'Semua') {
      setState(() {
        _movies.clear();
        _movies.addAll(_allMovies);
        _selectedGenre = genre;
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedGenre = genre;
      _searchQuery = genre;
    });

    try {
      // Jika ada endpoint search, gunakan ini
      // final searchResults = await ApiService.searchMovies(genre);
      
      // Untuk sementara, gunakan filter lokal
      final filteredResults = _allMovies.where((movie) {
        if (movie.genres != null) {
          return movie.genres!.any((g) => 
            g.toLowerCase().contains(genre.toLowerCase()));
        }
        return false;
      }).toList();

      if (mounted) {
        setState(() {
          _movies.clear();
          _movies.addAll(filteredResults);
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error searching movies: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal mencari film: ${e.toString()}";
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightestBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Halo, $_username!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 244, 233),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Temukan film favoritmu di sini.',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 255, 244, 233)
                          .withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: const Color.fromARGB(255, 255, 244, 233),
            ),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: const Color.fromARGB(255, 255, 244, 233),
            ),
            onPressed: _loadMovies,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: const Color.fromARGB(255, 255, 244, 233),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(color: primaryColor)),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                lightBackgroundColor.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            children: [
              _buildGenreFilter(),
              Expanded(child: _buildBody()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter berdasarkan genre:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableGenres.length,
              itemBuilder: (context, index) {
                final genre = _availableGenres.elementAt(index);
                final isSelected = _selectedGenre == genre;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      genre,
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _searchMoviesByGenre(genre);
                      }
                    },
                    backgroundColor: lightBackgroundColor,
                    selectedColor: secondaryColor,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 4 : 2,
                    pressElevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? secondaryColor
                            : primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_searchQuery.isNotEmpty && _selectedGenre != 'Semua')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text(
                    'Menampilkan hasil untuk: "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_movies.length} film)',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Memuat data film...',
              style: TextStyle(color: primaryColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Mencari Film Genre $_selectedGenre...',
              style: TextStyle(color: primaryColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
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
                _errorMessage.contains("SocketException")
                    ? 'Pastikan Anda terhubung ke internet.'
                    : _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              onPressed: () {
                if (_selectedGenre == 'Semua') {
                  _loadMovies();
                } else {
                  _searchMoviesByGenre(_selectedGenre);
                }
              },
              label: 'Coba Lagi',
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      );
    }

    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 60, color: accentColor),
            const SizedBox(height: 20),
            Text(
              _selectedGenre == 'Semua'
                  ? 'Belum ada film ditemukan.'
                  : 'Tidak ada film dengan genre "$_selectedGenre".',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedGenre == 'Semua'
                  ? 'Coba muat ulang atau periksa koneksi Anda.'
                  : 'Coba pilih genre lain atau muat ulang data.',
              style: TextStyle(
                color: primaryColor.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              onPressed: () {
                if (_selectedGenre == 'Semua') {
                  _loadMovies();
                } else {
                  _searchMoviesByGenre('Semua');
                }
              },
              label: _selectedGenre == 'Semua'
                  ? 'Muat Ulang'
                  : 'Tampilkan Semua',
              backgroundColor: accentColor,
              foregroundColor: primaryColor,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedGenre == 'Semua') {
          await _loadMovies();
        } else {
          await _searchMoviesByGenre(_selectedGenre);
        }
      },
      color: secondaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color.fromARGB(255, 255, 244, 233),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailPage(movieId: movie.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Hero(
                tag: 'movieImage_${movie.id}',
                child: Image.network(
                  ApiService.getImageUrl(movie.imgUrl, size: 'medium'),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      color: lightBackgroundColor,
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
                      color: lightBackgroundColor,
                      child: Icon(
                        Icons.image_not_supported_outlined,
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
                  // Tampilkan genre
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
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