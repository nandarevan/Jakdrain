// ============================================================
// Jakdrain — Login Screen
// Halaman autentikasi dengan mode demo & fitur pendaftaran petugas PPSU.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/core/firebase_service.dart';
import 'package:jakdrain/providers/user_provider.dart';
import 'package:jakdrain/ui/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _login([String? registeredName]) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Kasus 1: Mode Demo Petugas
    if (registeredName == 'Petugas Demo PPSU') {
      userProvider.loginDemo();
      try {
        await FirebaseService.saveOfficerProfile(userProvider.currentUser, userProvider.currentUser.nipOrNik);
        await FirebaseService.recordLoginLog(officer: userProvider.currentUser, loginMethod: 'Mode Demo Petugas');
      } catch (_) {}
      if (mounted) {
        _showLoginSuccessSnackBar(userProvider.currentUser);
        _navigateToHome();
      }
      return;
    }

    // Kasus 2: Langsung setelah registrasi berhasil
    if (registeredName != null) {
      final user = userProvider.currentUser;
      if (mounted) {
        _showLoginSuccessSnackBar(user);
        _navigateToHome();
      }
      return;
    }

    // Kasus 3: Login Manual (Verifikasi Ketat Nama & NIP terhadap Database)
    final nameInput = _nameController.text.trim();
    final nipInput = _idController.text.trim();

    if (nameInput.isEmpty || nipInput.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nameInput.isEmpty
                      ? 'Harap masukkan Nama Lengkap Petugas!'
                      : 'Harap masukkan ID Petugas / NIK / NIP yang terdaftar!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: JakdrainColors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final verification = await FirebaseService.verifyOfficerCredentials(
      enteredName: nameInput,
      enteredNip: nipInput,
      localRegistry: userProvider.registeredOfficers,
    );

    if (!verification.success) {
      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Peringatan Merah Tengah
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: JakdrainColors.critical.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gpp_bad_rounded,
                      color: JakdrainColors.critical,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul Tengah
                  Text(
                    'Verifikasi Login Ditolak',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: JakdrainColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pesan Verifikasi Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: JakdrainColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JakdrainColors.divider),
                    ),
                    child: Text(
                      verification.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: JakdrainColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Aksi Interaktif Ditengah
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Periksa Kembali NIP & Nama',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JakdrainColors.electricBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        _showRegisterSheet();
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: JakdrainColors.electricBlue),
                      label: Text(
                        'Belum Terdaftar? Buat Akun Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: JakdrainColors.electricBlue,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: JakdrainColors.electricBlue, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    // Berhasil Terverifikasi! Set user aktif
    final verifiedUser = verification.user!;
    userProvider.setCurrentUser(verifiedUser);

    try {
      await FirebaseService.saveOfficerProfile(verifiedUser, verifiedUser.nipOrNik);
      await FirebaseService.recordLoginLog(
        officer: verifiedUser,
        loginMethod: 'NIP: ${verifiedUser.nipOrNik} (${verifiedUser.name})',
      );
    } catch (e) {
      debugPrint('Firebase logging error: $e');
    }

    if (mounted) {
      _showLoginSuccessSnackBar(verifiedUser);
      _navigateToHome();
    }
  }

  void _showLoginSuccessSnackBar(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                user.isDemoMode
                    ? 'Masuk sebagai ${user.name} • Sesi Tamu'
                    : 'Terverifikasi Database! Selamat bertugas, ${user.name} (${user.nipOrNik})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: user.isDemoMode ? JakdrainColors.electricBlue : JakdrainColors.safe,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRegisterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RegisterBottomSheet(
        onSuccess: (name, nip, wilayah, phone) async {
          Navigator.pop(context);
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.registerUser(
            name: name,
            nipOrNik: nip,
            region: 'Suku Dinas SDA $wilayah',
            phoneNumber: phone,
          );
          final registeredUser = userProvider.currentUser;

          // Isi kolom login agar user tahu datanya
          _nameController.text = name;
          _idController.text = nip;

          try {
            await FirebaseService.saveOfficerProfile(registeredUser, nip);
            await FirebaseService.recordLoginLog(
              officer: registeredUser,
              loginMethod: 'Pendaftaran Akun Baru Petugas SDA',
            );
          } catch (e) {
            debugPrint('Error register Firestore: $e');
          }
          _login(name);
        },
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final user = await FirebaseService.signInWithGoogle();
      if (user != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.registerUser(
          name: user.name,
          nipOrNik: user.nipOrNik,
          region: user.region,
          phoneNumber: user.phoneNumber,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil masuk dengan Google: ${user.name}'),
            backgroundColor: JakdrainColors.safe,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Google: $e'),
            backgroundColor: JakdrainColors.critical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: JakdrainColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── Logo & Branding ──────────────────────────────
                _buildLogo(),
                if (userProvider.sessionExpiredNotice) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: JakdrainColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: JakdrainColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: JakdrainColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sesi Anda telah berakhir karena tidak aktif lebih dari 2 menit. Silakan login kembali.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9A6B00),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => userProvider.dismissExpiredNotice(),
                          child: const Icon(Icons.close_rounded, size: 18, color: JakdrainColors.subtleGray),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 36),

                // ─── Input Field ──────────────────────────────────
                _buildInputSection(),
                const SizedBox(height: 20),

                // ─── Login Button ─────────────────────────────────
                _buildLoginButton(),
                const SizedBox(height: 12),

                // ─── Register Button ──────────────────────────────
                _buildRegisterButton(),
                const SizedBox(height: 20),

                // ─── Divider ──────────────────────────────────────
                _buildDivider(),
                const SizedBox(height: 16),

                // ─── Google Sign-In Button ────────────────────────
                _buildGoogleSignInButton(),
                const SizedBox(height: 10),

                // ─── Demo Mode Button ─────────────────────────────
                _buildDemoButton(),
                const SizedBox(height: 28),

                // ─── Footer ───────────────────────────────────────
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: JakdrainColors.headerGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: JakdrainColors.electricBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 38,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 16),
        Text(
          'Jakdrain',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: JakdrainColors.deepNavy,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 150.ms),
        const SizedBox(height: 6),
        Text(
          'Sistem Monitoring Drainase Mikro\nPemprov DKI Jakarta',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: JakdrainColors.subtleGray,
            height: 1.4,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 250.ms),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Nama Lengkap Petugas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: JakdrainColors.darkText,
            ),
          ),
        ),
        TextField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: JakdrainColors.deepNavy,
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Ahmad Budi Santoso',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: JakdrainColors.subtleGray.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'ID Petugas / NIK / NIP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: JakdrainColors.darkText,
            ),
          ),
        ),
        TextField(
          controller: _idController,
          keyboardType: TextInputType.text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: JakdrainColors.deepNavy,
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: 312020292 / PPSU-Jakpus',
            prefixIcon: Icon(
              Icons.badge_outlined,
              color: JakdrainColors.subtleGray.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _login(),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Masuk',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 350.ms);
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _showRegisterSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: Text(
          'Daftar Akun Petugas Baru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: JakdrainColors.electricBlue,
          side: const BorderSide(color: JakdrainColors.electricBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: JakdrainColors.divider.withValues(alpha: 0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau gunakan akses cepat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: JakdrainColors.subtleGray,
            ),
          ),
        ),
        Expanded(child: Divider(color: JakdrainColors.divider.withValues(alpha: 0.5))),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 450.ms);
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: BorderSide(color: Colors.grey.shade300, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.g_mobiledata_rounded,
                size: 26,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Masuk dengan Akun Google',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 480.ms);
  }

  Widget _buildDemoButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: _isLoading ? null : () => _login('Petugas Demo PPSU'),
        icon: const Icon(Icons.play_circle_fill_rounded, color: JakdrainColors.skyBlueAccent),
        label: Text(
          'Masuk Langsung (Mode Demo Petugas)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: JakdrainColors.electricBlue,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: JakdrainColors.electricBlue.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms);
  }

  Widget _buildFooter() {
    return Text(
      '© 2026 Pemprov DKI Jakarta — Jakarta Smart City',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        color: JakdrainColors.subtleGray.withValues(alpha: 0.6),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 600.ms);
  }
}

/// Modal formulir pendaftaran akun petugas SDA/PPSU baru.
class _RegisterBottomSheet extends StatefulWidget {
  final void Function(String name, String nip, String wilayah, String phone) onSuccess;

  const _RegisterBottomSheet({required this.onSuccess});

  @override
  State<_RegisterBottomSheet> createState() => _RegisterBottomSheetState();
}

class _RegisterBottomSheetState extends State<_RegisterBottomSheet> {
  final _nameController = TextEditingController();
  final _nipController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedWilayah = 'Jakarta Pusat';
  bool _isRegistering = false;

  final List<String> _wilayahList = const [
    'Jakarta Pusat',
    'Jakarta Barat',
    'Jakarta Selatan',
    'Jakarta Timur',
    'Jakarta Utara',
    'Kepulauan Seribu',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final name = _nameController.text.trim();
    final nip = _nipController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan nama lengkap Petugas'),
          backgroundColor: JakdrainColors.critical,
        ),
      );
      return;
    }

    if (nip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan NIP / NIK Petugas'),
          backgroundColor: JakdrainColors.critical,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);
    
    // Cek apakah NIP sudah terdaftar di Firestore
    try {
      final existing = await FirebaseService.getOfficerProfile(nip);
      if (existing != null && mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NIP $nip sudah terdaftar atas nama "${existing['name']}". Silakan langsung login!'),
            backgroundColor: JakdrainColors.warning,
          ),
        );
        return;
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      widget.onSuccess(
        name,
        nip,
        _selectedWilayah,
        phone.isNotEmpty ? phone : '0812-3456-7890',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: JakdrainColors.electricBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: JakdrainColors.electricBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Petugas Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: JakdrainColors.deepNavy,
                        ),
                      ),
                      Text(
                        'Inspeksi Drainase & SDA DKI Jakarta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: JakdrainColors.subtleGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(
              label: 'Nama Lengkap',
              hint: 'Contoh: Ahmad Fauzi',
              icon: Icons.person_outline,
              controller: _nameController,
            ),
            const SizedBox(height: 14),
            _buildField(
              label: 'NIP / NIK Petugas PPSU',
              hint: 'Contoh: 3171012345670001',
              icon: Icons.badge_outlined,
              controller: _nipController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            Text(
              'Wilayah Penugasan Suku Dinas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: JakdrainColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: JakdrainColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JakdrainColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWilayah,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: _wilayahList.map((w) {
                    return DropdownMenuItem(
                      value: w,
                      child: Text(
                        w,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: JakdrainColors.deepNavy,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWilayah = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildField(
              label: 'No. Handphone / WhatsApp',
              hint: 'Contoh: 081234567890',
              icon: Icons.phone_android_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _submitRegister,
                child: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Daftar Sekarang & Mulai Bertugas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: JakdrainColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: JakdrainColors.deepNavy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: JakdrainColors.subtleGray),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
