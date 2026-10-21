// ============================================================
// Jakdrain — Dashboard Screen
// Beranda interaktif dengan metrik, cuaca BMKG, aksi cepat,
// telemetri pintu air Jakarta, dan aktivitas inspeksi drainase.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/navigation_provider.dart';
import 'package:jakdrain/providers/user_provider.dart';
import 'package:jakdrain/providers/drainage_provider.dart';
import 'package:jakdrain/ui/widgets/stat_card.dart';
import 'package:jakdrain/ui/widgets/drainage_status_badge.dart';
import 'package:jakdrain/ui/screens/report_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final drainageProvider = Provider.of<DrainageProvider>(context);
    final reports = drainageProvider.reports;
    final weather = MockData.currentWeather;
    final kritisReports = drainageProvider.kritisReports;
    final dalamPengerukanCount = drainageProvider.pengerukanCount;

    return Scaffold(
      backgroundColor: JakdrainColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header Card ────────────────────────────────────
          SliverToBoxAdapter(child: _HeaderCard(weather: weather)),

          // ─── Quick Metric Cards ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ringkasan Hari Ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: JakdrainColors.deepNavy,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: JakdrainColors.safe.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: JakdrainColors.safe,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sistem Aktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: JakdrainColors.safe,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 168,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                children: [
                  AnimatedStatCard(
                    title: 'Total Got Terpantau',
                    value: '${reports.length * 20 + 2}',
                    icon: Icons.visibility_rounded,
                    delayMs: 100,
                    onTap: () {
                      Provider.of<NavigationProvider>(context, listen: false).setIndex(3);
                    },
                  ),
                  const SizedBox(width: 12),
                  AnimatedStatCard(
                    title: 'Sedimen Kritis (>50%)',
                    value: '${kritisReports.length}',
                    icon: Icons.warning_amber_rounded,
                    accentColor: JakdrainColors.critical,
                    isHighlighted: true,
                    delayMs: 200,
                    onTap: () {
                      Provider.of<NavigationProvider>(context, listen: false).setIndex(1);
                    },
                  ),
                  const SizedBox(width: 12),
                  AnimatedStatCard(
                    title: 'Pengerukan Hari Ini',
                    value: '$dalamPengerukanCount',
                    icon: Icons.construction_rounded,
                    accentColor: JakdrainColors.warning,
                    delayMs: 300,
                    onTap: () {
                      Provider.of<NavigationProvider>(context, listen: false).setIndex(3);
                    },
                  ),
                  const SizedBox(width: 12),
                  AnimatedStatCard(
                    title: 'Laporan Selesai',
                    value: '${reports.where((r) => r.taskStatus == TaskStatus.selesai).length}',
                    icon: Icons.check_circle_rounded,
                    accentColor: JakdrainColors.safe,
                    delayMs: 400,
                    onTap: () {
                      Provider.of<NavigationProvider>(context, listen: false).setIndex(3);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ─── Aksi Cepat Petugas (DI BAWAH RINGKASAN HARI INI) ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _QuickActionStation(),
            ),
          ),

          // ─── Status Pintu Air & TMA Jakarta (Live Telemetri) ───
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _FloodGateTmaWidget(),
            ),
          ),

          // ─── Prioritas Pengerukan Got Kritis ─────────────────
          if (kritisReports.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: _PriorityDrainageSection(reports: kritisReports),
              ),
            ),

          // ─── Aktivitas Terkini ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas Inspeksi Terkini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: JakdrainColors.deepNavy,
                    ),
                  ),
                  Text(
                    '${reports.length} Got',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JakdrainColors.subtleGray,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final report = reports[index];
                  return _ActivityCard(
                    report: report,
                    delayMs: 300 + (index * 80),
                  );
                },
                childCount: reports.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu header bergradien biru dengan info profil user dinamis & cuaca BMKG.
class _HeaderCard extends StatelessWidget {
  final WeatherAlert weather;

  const _HeaderCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String dateStr;
    try {
      dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    } catch (_) {
      dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;

        return Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            gradient: JakdrainColors.headerGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Halo, ${user.name}! 👋',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.isDemoMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : JakdrainColors.safe.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.isDemoMode ? 'Demo' : 'PPSU Resmi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.nipOrNik} • $dateStr',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Lokasi wilayah penugasan
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.region,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_queue_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${weather.condition} • Potensi Hujan ${weather.alertTime}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

/// Stasiun Aksi Cepat Petugas (Quick Action Station).
class _QuickActionStation extends StatelessWidget {
  const _QuickActionStation();

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat Petugas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: JakdrainColors.deepNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Tombol Scan Kamera
            Expanded(
              child: _ActionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Scan Got AI',
                subtitle: 'Foto & Prediksi',
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                onTap: () => navProvider.setIndex(2),
              ),
            ),
            const SizedBox(width: 10),
            // Tombol Peta
            Expanded(
              child: _ActionTile(
                icon: Icons.map_rounded,
                title: 'Peta Drainase',
                subtitle: 'OpenStreetMap',
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
                onTap: () => navProvider.setIndex(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Lapor Got Mampet
            Expanded(
              child: _ActionTile(
                icon: Icons.warning_rounded,
                title: 'Lapor Darurat',
                subtitle: 'Got Mampet / Meluap',
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Silakan potret got darurat di menu Scan Kamera.'),
                      backgroundColor: JakdrainColors.critical,
                      action: SnackBarAction(
                        label: 'Buka Scan',
                        textColor: Colors.white,
                        onPressed: () => navProvider.setIndex(2),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Status Sensor
            Expanded(
              child: _ActionTile(
                icon: Icons.sensors_rounded,
                title: 'Sensor IoT',
                subtitle: 'Debit Air DKI Aktif',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sensor IoT Debit Air DKI Jakarta: 100% Online.'),
                      backgroundColor: Color(0xFF4F46E5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget Telemetri Tinggi Muka Air (TMA) Pintu Air Jakarta.
class _FloodGateTmaWidget extends StatelessWidget {
  const _FloodGateTmaWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JakdrainColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: JakdrainColors.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: JakdrainColors.electricBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Telemetri Pintu Air & TMA DKI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: JakdrainColors.deepNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: JakdrainColors.safe.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: JakdrainColors.safe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TmaItem(
                  location: 'Manggarai',
                  tma: '650 cm',
                  status: 'Siaga 4 (Normal)',
                  statusColor: JakdrainColors.safe,
                ),
              ),
              Container(width: 1, height: 42, color: JakdrainColors.divider),
              Expanded(
                child: _TmaItem(
                  location: 'P.A. Karet',
                  tma: '410 cm',
                  status: 'Siaga 4 (Normal)',
                  statusColor: JakdrainColors.safe,
                ),
              ),
              Container(width: 1, height: 42, color: JakdrainColors.divider),
              Expanded(
                child: _TmaItem(
                  location: 'Pompa Pluit',
                  tma: '3/3 Unit',
                  status: 'Beroperasi',
                  statusColor: JakdrainColors.safe,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }
}

class _TmaItem extends StatelessWidget {
  final String location;
  final String tma;
  final String status;
  final Color statusColor;

  const _TmaItem({
    required this.location,
    required this.tma,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            location,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JakdrainColors.deepNavy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tma,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: JakdrainColors.electricBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bagian Prioritas Pengerukan Got Sedimen Kritis.
class _PriorityDrainageSection extends StatelessWidget {
  final List<DrainageReport> reports;

  const _PriorityDrainageSection({required this.reports});

  @override
  Widget build(BuildContext context) {
    final topCritical = reports.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JakdrainColors.critical.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: JakdrainColors.critical.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: JakdrainColors.critical,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prioritas Pengerukan Got',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: JakdrainColors.critical,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: JakdrainColors.critical,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${topCritical.sedimentPercentage.toInt()}% Penuh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            topCritical.address,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: JakdrainColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${topCritical.kelurahan} • Gorong-gorong tersumbat lumpur & botol plastik',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: JakdrainColors.subtleGray,
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar sedimen
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: topCritical.sedimentPercentage / 100,
              backgroundColor: Colors.white,
              color: JakdrainColors.critical,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(report: topCritical),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                'Lihat Rincian & Mulai Pengerukan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JakdrainColors.critical,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 280.ms);
  }
}

/// Kartu aktivitas inspeksi terkini.
class _ActivityCard extends StatelessWidget {
  final DrainageReport report;
  final int delayMs;

  const _ActivityCard({required this.report, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(report.inspectedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(report: report),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: JakdrainColors.divider.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Status icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(report.status),
                    color: _getStatusColor(report.status),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: JakdrainColors.deepNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${report.kelurahan} • Sedimen ${report.sedimentPercentage.toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: JakdrainColors.subtleGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status & time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TaskStatusBadge(status: report.taskStatus),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: JakdrainColors.subtleGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delayMs))
        .slideX(begin: 0.03, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Color _getStatusColor(DrainageStatus status) {
    switch (status) {
      case DrainageStatus.aman:
        return JakdrainColors.safe;
      case DrainageStatus.waspada:
        return JakdrainColors.warning;
      case DrainageStatus.kritis:
        return JakdrainColors.critical;
    }
  }

  IconData _getStatusIcon(DrainageStatus status) {
    switch (status) {
      case DrainageStatus.aman:
        return Icons.check_circle_outline_rounded;
      case DrainageStatus.waspada:
        return Icons.warning_amber_rounded;
      case DrainageStatus.kritis:
        return Icons.error_outline_rounded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }
}
