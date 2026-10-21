import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/core/firebase_service.dart';
import 'package:jakdrain/providers/user_provider.dart';
import 'package:jakdrain/ui/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;

        return Scaffold(
          backgroundColor: JakdrainColors.surface,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ─── Header Profile ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 20,
                    20,
                    28,
                  ),
                  decoration: const BoxDecoration(
                    gradient: JakdrainColors.headerGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: user.isDemoMode
                              ? Colors.white.withValues(alpha: 0.15)
                              : JakdrainColors.safe.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: user.isDemoMode
                                ? Colors.white.withValues(alpha: 0.3)
                                : JakdrainColors.safe,
                          ),
                        ),
                        child: Text(
                          user.isDemoMode
                              ? 'Mode Demo • NIP: ${user.nipOrNik}'
                              : '✓ Petugas Terdaftar • NIP: ${user.nipOrNik}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(
                            value: '${user.totalInspections}',
                            label: 'Total Inspeksi',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          _ProfileStat(
                            value: user.isDemoMode ? '28' : '1',
                            label: 'Bulan Ini',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const _ProfileStat(value: '5.0', label: 'Rating Petugas'),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.05, end: 0),

            const SizedBox(height: 20),

            // ─── Menu Items ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JakdrainColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profil',
                    subtitle: 'Ubah informasi pribadi',
                    delayMs: 200,
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Wilayah Tugas',
                    subtitle: user.region,
                    delayMs: 300,
                  ),
                  _MenuItem(
                    icon: Icons.phone_android_rounded,
                    label: 'Nomor Kontak Petugas',
                    subtitle: user.phoneNumber,
                    delayMs: 350,
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifikasi',
                    subtitle: 'Atur pemberitahuan',
                    delayMs: 400,
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan & FAQ',
                    subtitle: 'Pusat bantuan petugas',
                    delayMs: 500,
                  ),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang Aplikasi',
                    subtitle: 'Jakdrain v1.0.0 (DKI Jakarta)',
                    delayMs: 600,
                  ),
                  const SizedBox(height: 20),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseService.signOut();
                        userProvider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Keluar / Ganti Akun',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JakdrainColors.critical,
                        side: BorderSide(
                          color: JakdrainColors.critical.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 700.ms),

                  const SizedBox(height: 24),
                  // Footer
                  Center(
                    child: Text(
                      '© 2026 Pemprov DKI Jakarta — Jakarta Smart City',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: JakdrainColors.subtleGray.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

/// Statistik profil di header.
class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Item menu profil.
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int delayMs;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JakdrainColors.electricBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: JakdrainColors.electricBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: JakdrainColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: JakdrainColors.subtleGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: JakdrainColors.subtleGray,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delayMs))
        .slideX(begin: 0.05, end: 0, duration: 400.ms,
            delay: Duration(milliseconds: delayMs));
  }
}
