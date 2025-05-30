import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Definisi Warna dari Palet
// Menggunakan nilai heksadesimal dari gambar yang Anda berikan
const Color primaryColor = Color(0xFF8D6B94); // Ungu tua/abu-abu
const Color secondaryColor = Color(0xFFB15A7B); // Merah muda/ungu gelap
const Color accentColor = Color(0xFFC3A29E); // Coklat muda/salmon
const Color lightBackgroundColor = Color(0xFFE8DBC5); // Krem muda
const Color lightestBackgroundColor = Color(0xFFFFF4E9); // Hampir putih

// Halaman otentikasi yang menggunakan StatefulWidget
class AuthPage extends StatefulWidget {  // Menyimpan state (login/register mode), Menangani input form, Menampilkan loading state, bukan stateless karena Karena tidak ada perubahan state yang perlu dihandle.
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

// State untuk AuthPage
class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk form validasi
  bool _isLogin = true; // Menentukan mode login atau registrasi
  bool _isLoading = false; // Menentukan status loading

  // Kontroler untuk input teks
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Memeriksa status login saat halaman diinisialisasi
  }

  @override
  void dispose() {
    // Membersihkan kontroler saat widget dihapus
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Memeriksa apakah pengguna sudah login sebelumnya
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null && mounted) {
      // Delay sedikit untuk animasi lebih smooth sebelum navigasi
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home'); // Navigasi ke halaman utama
      }
    }
  }

  // Menangani otentikasi (login/registrasi)
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return; // Validasi form

    setState(() => _isLoading = true); // Mengubah status loading

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_isLogin) {
        await _handleLogin(prefs); // Menangani login
      } else {
        await _handleRegistration(prefs); // Menangani registrasi
      }

      if (mounted) {
        // Delay sedikit untuk animasi lebih smooth sebelum navigasi
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home'); // Navigasi ke halaman utama
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin
                ? 'Login gagal: ${e.toString().replaceFirst("Exception: ", "")}'
                : 'Pendaftaran gagal: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: secondaryColor, // Menggunakan secondaryColor untuk error
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Mengubah status loading kembali
      }
    }
  }

  // Menangani proses login
  Future<void> _handleLogin(SharedPreferences prefs) async {
    final savedPassword = prefs.getString('password_${_usernameController.text}');
    if (savedPassword == _passwordController.text) {
      await prefs.setString('username', _usernameController.text); // Menyimpan username
    } else {
      throw Exception('Nama pengguna atau kata sandi tidak valid.'); // Menangani kesalahan
    }
  }

  // Menangani proses registrasi
  Future<void> _handleRegistration(SharedPreferences prefs) async {
    final existingPassword = prefs.getString('password_${_usernameController.text}');
    if (existingPassword != null) {
      throw Exception('Nama pengguna sudah ada. Silakan gunakan nama lain atau masuk.'); // Menangani kesalahan
    }
    await prefs.setString('password_${_usernameController.text}', _passwordController.text); // Menyimpan password
    await prefs.setString('username', _usernameController.text); // Menyimpan username
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Mencegah keyboard menggeser layout
      body: Stack(
        children: [
          // Latar Belakang Gradien dengan Pola
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightBackgroundColor, lightestBackgroundColor],
              ),
            ),
          ),
          // Pola untuk membuat 'rame'
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(accentColor.withOpacity(0.3)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.6 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 15, // Bayangan lebih menonjol
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Lebih membulat
                  ),
                  color: lightestBackgroundColor, // Warna card yang terang
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.movie, // Ikon terkait makanan
                            size: 90,
                            color: primaryColor, // Warna ikon
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _isLogin ? 'Selamat Datang!' : 'Ayo Mulai Petualangan!',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: primaryColor, // Warna teks utama
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isLogin
                                ? 'Nikmati film seru dan pengalaman tak terlupakan.'
                                : 'Daftar sekarang dan temukan favorit barumu.',
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryColor.withOpacity(0.8), // Warna teks sekunder
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 36),
                          _buildTextFormField(
                            controller: _usernameController,
                            labelText: 'Nama Pengguna',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mohon masukkan nama pengguna'; // Validasi input
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          _buildTextFormField(
                            controller: _passwordController,
                            labelText: 'Kata Sandi',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mohon masukkan kata sandi'; // Validasi input
                              }
                              if (value.length < 6) {
                                return 'Kata sandi minimal 6 karakter'; // Validasi panjang kata sandi
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 36),
                          _buildAuthButton(context), // Tombol untuk login/daftar
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() => _isLogin = !_isLogin), // Mengubah mode
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor, // Warna teks tombol switch
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            child: Text(
                              _isLogin
                                  ? 'Belum punya akun? Daftar Sekarang!'
                                  : 'Sudah punya akun? Masuk di sini',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membangun field input teks
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: primaryColor.withOpacity(0.9)), // Warna teks input
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: primaryColor), // Warna ikon input
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), // Sudut lebih membulat
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: lightBackgroundColor.withOpacity(0.6), // Warna isian input field
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accentColor.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: secondaryColor, width: 2.5), // Border aktif
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.red, width: 2.5),
        ),
      ),
      validator: validator, // Validasi input
    );
  }

  // Fungsi untuk membangun tombol otentikasi
  Widget _buildAuthButton(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _handleAuth, // Menangani klik jika tidak loading
      borderRadius: BorderRadius.circular(18), // Match text field border radius
      child: Container(
        height: 60, // Sedikit lebih tinggi
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [secondaryColor, primaryColor], // Gradien dari palet
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 6), // Bayangan lebih dalam
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white) // Menampilkan indikator loading
            : Text(
                _isLogin ? 'MASUK' : 'DAFTAR',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5, // Spasi antar huruf
                ),
              ),
      ),
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

    // Contoh pola: lingkaran dan garis acak
    // Anda bisa mengganti ini dengan pola lain yang Anda inginkan
    final double radius = size.width * 0.05;
    final double spacing = size.width * 0.15;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Lingkaran
        canvas.drawCircle(Offset(x, y), radius, paint);
        // Lingkaran kecil
        canvas.drawCircle(Offset(x + spacing / 2, y + spacing / 2), radius * 0.5, paint);
      }
    }

    // Tambahan beberapa bentuk acak lainnya
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.7, size.width * 0.2, size.height * 0.1), paint);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.7, size.height * 0.2, size.width * 0.15, size.height * 0.08), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Tidak perlu repaint
  }
}