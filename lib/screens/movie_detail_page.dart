import 'package:app/movie/MovieDatabase.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Tambahkan import untuk format tanggal
import '../services/api_service.dart';
import '../movie/movie.dart';

// Definisi Warna dari Palet yang Diberikan
const Color primaryColor = Color(0xFF8D6B94); // Ungu tua/abu-abu
const Color secondaryColor = Color(0xFFB15A7B); // Merah muda/ungu gelap
const Color accentColor = Color(0xFFC3A29E); // Coklat muda/salmon
const Color lightBackgroundColor = Color(0xFFE8DBC5); // Krem muda
const Color lightestBackgroundColor = Color(0xFFF4E9CE); // Hampir putih

/*
PENJELASAN STATEFUL vs STATELESS:
- StatefulWidget digunakan ketika widget perlu:
  1. Menyimpan data yang bisa berubah (state)
  2. Memiliki logika bisnis yang kompleks
  3. Berubah tampilannya berdasarkan interaksi/user input
  4. Mengelola lifecycle (initState, dispose, dll)

- StatelessWidget digunakan ketika widget:
  1. Hanya menampilkan data (tidak berubah)
  2. Tidak perlu mengelola state
  3. Bersifat statis/tidak berinteraksi

Dalam halaman ini kita menggunakan StatefulWidget karena:
1. Perlu menyimpan data movie yang di-load dari API
2. Perlu mengelola status loading/error
3. Perlu mengubah tampilan saat movie di-favoritkan
4. Perlu menyimpan state favorit ke SharedPreferences
*/

// Komponen halaman detail movie
class MovieDetailPage extends StatefulWidget {
  final String movieId; // ID movie yang akan ditampilkan, berasal dari navigasi sebelumnya

  const MovieDetailPage({super.key, required this.movieId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late Movie _movie;
  bool _isLoading = true;
  bool _isFavorite = false;
  String _errorMessage = '';
  final MovieDatabase _movieDatabase = MovieDatabase(); // Instance MovieDatabase

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
    _checkFavoriteStatus(); // Mengecek apakah movie ini telah difavoritkan sebelumnya oleh user
  }

  // Mengambil detail movie dari API
  Future<void> _loadMovieDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await ApiService.getMovieDetail(widget.movieId); // Fetch detail dari API
      setState(() => _movie = data); // Simpan hasil ke state
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", "")); // Tangani error
    } finally {
      setState(() => _isLoading = false); // Sembunyikan loading spinner
    }
  }

  // Mengecek apakah movie ini sudah ada dalam daftar favorit di SharedPreferences
  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';
    final favoriteMovies = await _movieDatabase.getMovies(username);

    setState(() {
      _isFavorite = favoriteMovies.any((movie) => movie.id == widget.movieId); // Cek apakah movie ada di daftar
    });
  }

  // Menambahkan atau menghapus movie dari daftar favorit user
  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'default_user';

    setState(() => _isFavorite = !_isFavorite); // Toggle status favorit

    if (_isFavorite) {
      // Jika ditambahkan ke favorit
      await _movieDatabase.addMovie(_movie, username); // Simpan film ke Hive
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Film ditambahkan ke favorit!'),
            backgroundColor: Color.fromARGB(255, 67, 102, 70),
          ),
        );
      }
    } else {
      // Jika dihapus dari favorit
      await _movieDatabase.deleteMovie(_movie.id, username); // Hapus film dari Hive
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Film dihapus dari favorit!'),
            backgroundColor: Color.fromARGB(255, 209, 47, 47),
          ),
        );
      }
    }
  }


  // Helper method untuk format tanggal createdAt
  String _formatCreatedAt(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return 'Tidak diketahui';
    }
    
    try {
      final DateTime dateTime = DateTime.parse(createdAt);
      final DateFormat formatter = DateFormat('dd MMM yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return createdAt; // Return original string jika parsing gagal
    }
  }

  // Membangun UI utama halaman
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightestBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: secondaryColor)) // Tampilkan loading saat memuat data
          : _errorMessage.isNotEmpty
              ? _buildErrorState() // Jika error, tampilkan pesan error
              : _buildDetailBody(), // Jika sukses, tampilkan detail movie
    );
  }

  // UI ketika terjadi kesalahan dalam mengambil data
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: secondaryColor, size: 60),
          const SizedBox(height: 20),
          Text(
            'Oops! Terjadi kesalahan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage.contains("SocketException")
                  ? 'Pastikan Anda terhubung ke internet dan coba lagi.'
                  : _errorMessage,
              style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMovieDetail,
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

  // UI utama yang menampilkan detail movie setelah data berhasil dimuat
  Widget _buildDetailBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320, // Tinggi maksimum saat dibuka penuh
          pinned: true, // Tetap terlihat saat di-scroll
          backgroundColor: primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _movie.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Color.fromARGB(49, 255, 255, 255),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'movieImage_${_movie.id}',
                  child: Image.network(
                    ApiService.getImageUrl(_movie.imgUrl, size: 'large'),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: lightBackgroundColor,
                        child: Icon(
                          Icons.movie,
                          size: 80,
                          color: primaryColor.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                ),
                // Gradient overlay untuk readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
                size: 28,
              ),
              onPressed: _toggleFavorite, // Aksi ketika ikon favorit ditekan
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoCard(),
                const SizedBox(height: 20),
                _buildSectionHeader('Deskripsi'),
                _buildDescriptionCard(),
                const SizedBox(height: 20),
                if (_movie.genres != null && _movie.genres!.isNotEmpty) ...[
                  _buildSectionHeader('Genre'),
                  _buildGenresCard(),
                  const SizedBox(height: 20),
                ],
                if (_movie.cast != null && _movie.cast!.isNotEmpty) ...[
                  _buildSectionHeader('Pemeran'),
                  _buildCastCard(),
                  const SizedBox(height: 20),
                ],
                if (_movie.director != null && _movie.director!.isNotEmpty) ...[
                  _buildSectionHeader('Sutradara'),
                  _buildDirectorCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Membuat teks judul bagian
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  // Menampilkan informasi dasar movie dalam kartu - DIMODIFIKASI untuk include createdAt
  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Rating dan Tahun Rilis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber.shade600,
                  label: 'Rating',
                  value: '${_movie.rating}/10',
                ),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  iconColor: secondaryColor,
                  label: 'Rilis',
                  value: _movie.releaseDate,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),
            // Durasi dan Bahasa
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.access_time,
                  iconColor: primaryColor,
                  label: 'Durasi',
                  value: _movie.duration,
                ),
                _buildInfoItem(
                  icon: Icons.language,
                  iconColor: accentColor,
                  label: 'Bahasa',
                  value: _movie.language,
                ),
              ],
            ),
            // Tambahkan divider dan createdAt jika data tersedia
            if (_movie.createdAt != null && _movie.createdAt!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE0E0E0)),
              const SizedBox(height: 16),
              // CreatedAt - centered karena hanya satu item
              _buildInfoItem(
                icon: Icons.schedule,
                iconColor: Colors.green.shade600,
                label: 'Ditambahkan',
                value: _formatCreatedAt(_movie.createdAt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: primaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Menampilkan deskripsi movie dalam kartu
  Widget _buildDescriptionCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _movie.description,
          style: TextStyle(
            fontSize: 16,
            color: primaryColor,
            height: 1.6,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  // Menampilkan daftar genre movie sebagai chip
  Widget _buildGenresCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _movie.genres!.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getGenreColor(genre).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getGenreColor(genre).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: _getGenreColor(genre),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Menampilkan daftar pemeran
  Widget _buildCastCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _movie.cast!.map((actor) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.person, color: secondaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      actor,
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Menampilkan sutradara
  Widget _buildDirectorCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.movie_creation, color: primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _movie.director!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi helper untuk mendapatkan warna berdasarkan genre
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