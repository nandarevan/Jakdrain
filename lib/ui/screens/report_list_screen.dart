// ============================================================
// Jakdrain — Report List Screen
// Daftar seluruh laporan inspeksi drainase.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/drainage_provider.dart';
import 'package:jakdrain/ui/widgets/drainage_status_badge.dart';
import 'package:jakdrain/ui/screens/report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  String _searchQuery = '';
  DrainageStatus? _filterStatus;

  List<DrainageReport> _getFilteredReports(List<DrainageReport> reports) {
    var result = reports;

    if (_filterStatus != null) {
      result = result.where((r) => r.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((r) =>
              r.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.kelurahan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return result;
  }

  Future<void> _handleCloudSync(DrainageProvider provider) async {
    try {
      final count = await provider.seedInitialDataToFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berhasil sinkron $count data drainase ke Cloud Firestore!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: JakdrainColors.safe,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi: $e'),
            backgroundColor: JakdrainColors.critical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drainageProvider = Provider.of<DrainageProvider>(context);
    final filteredReports = _getFilteredReports(drainageProvider.reports);

    return Scaffold(
      backgroundColor: JakdrainColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: JakdrainColors.cardGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan Inspeksi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: JakdrainColors.deepNavy,
                          ),
                        ),
                        Text(
                          '${filteredReports.length} laporan terpantau',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: JakdrainColors.subtleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Sinkron Cloud Firestore
                  InkWell(
                    onTap: drainageProvider.isSeeding
                        ? null
                        : () => _handleCloudSync(drainageProvider),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: drainageProvider.isFirestoreConnected
                            ? JakdrainColors.electricBlue.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: drainageProvider.isFirestoreConnected
                              ? JakdrainColors.electricBlue.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (drainageProvider.isSeeding)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: JakdrainColors.electricBlue,
                              ),
                            )
                          else
                            Icon(
                              Icons.cloud_sync_rounded,
                              size: 16,
                              color: drainageProvider.isFirestoreConnected
                                  ? JakdrainColors.electricBlue
                                  : Colors.orange,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            drainageProvider.isSeeding
                                ? 'Sinkron...'
                                : 'Sinkron Cloud',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: drainageProvider.isFirestoreConnected
                                  ? JakdrainColors.electricBlue
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Search Bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan alamat atau ID...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: JakdrainColors.subtleGray,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Filter Chips ─────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip('Semua', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Kritis', DrainageStatus.kritis),
                  const SizedBox(width: 8),
                  _buildFilterChip('Waspada', DrainageStatus.waspada),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aman', DrainageStatus.aman),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Report List ──────────────────────────────────
            Expanded(
              child: filteredReports.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        // Realtime stream already updates, but trigger manual notify
                      },
                      color: JakdrainColors.electricBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return _ReportCard(
                            report: report,
                            index: index,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, DrainageStatus? status) {
    final isActive = _filterStatus == status;
    final color = switch (status) {
      DrainageStatus.kritis => JakdrainColors.critical,
      DrainageStatus.waspada => JakdrainColors.warning,
      DrainageStatus.aman => JakdrainColors.safe,
      null => JakdrainColors.electricBlue,
    };

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : JakdrainColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : JakdrainColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: JakdrainColors.subtleGray.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada laporan ditemukan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: JakdrainColors.subtleGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu laporan individual.
class _ReportCard extends StatelessWidget {
  final DrainageReport report;
  final int index;

  const _ReportCard({required this.report, required this.index});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: JakdrainColors.electricBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.id,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: JakdrainColors.electricBlue,
                        ),
                      ),
                    ),
                    const Spacer(),
                    DrainageStatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 10),

                // Address
                Text(
                  report.address,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: JakdrainColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.kelurahan}, ${report.kecamatan}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: JakdrainColors.subtleGray,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom metrics
                Row(
                  children: [
                    _MetricChip(
                      icon: Icons.layers_rounded,
                      value: '${report.sedimentPercentage.toInt()}%',
                      color: _getStatusColor(report.status),
                    ),
                    const SizedBox(width: 12),
                    _MetricChip(
                      icon: Icons.straighten_rounded,
                      value: '${report.remainingCapacityCm} cm',
                      color: JakdrainColors.electricBlue,
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM HH:mm').format(report.inspectedAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: JakdrainColors.subtleGray,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: JakdrainColors.subtleGray,
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
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: 100 + index * 80),
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: 100 + index * 80),
        );
  }

  Color _getStatusColor(DrainageStatus status) {
    return switch (status) {
      DrainageStatus.kritis => JakdrainColors.critical,
      DrainageStatus.waspada => JakdrainColors.warning,
      DrainageStatus.aman => JakdrainColors.safe,
    };
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
