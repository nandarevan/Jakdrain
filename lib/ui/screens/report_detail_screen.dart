// ============================================================
// Jakdrain — Report Detail Screen
// Detail lengkap laporan inspeksi drainase, bukti foto pengerukan PPSU
// dengan watermark timestamp & lokasi, serta pengaturan tingkat risiko.
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/core/mock_ai.dart';
import 'package:jakdrain/core/camera_service.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/drainage_provider.dart';
import 'package:jakdrain/providers/user_provider.dart';
import 'package:jakdrain/ui/widgets/drainage_status_badge.dart';
import 'package:jakdrain/ui/widgets/gps_timestamp_stamp.dart';

class ReportDetailScreen extends StatelessWidget {
  final DrainageReport report;

  const ReportDetailScreen({super.key, required this.report});

  String _safeFormatDate(DateTime dt) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }
  }

  void _showCompleteTaskSheet(BuildContext context, DrainageReport currentReport) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CompleteTaskSheet(report: currentReport),
    );
  }

  void _showAdjustRiskSheet(BuildContext context, DrainageReport currentReport) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdjustRiskSheet(report: currentReport),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drainageProvider = Provider.of<DrainageProvider>(context);
    final currentReport = drainageProvider.reports.firstWhere(
      (r) => r.id == report.id,
      orElse: () => report,
    );
    final isCompleted = currentReport.taskStatus == TaskStatus.selesai;

    return Scaffold(
      backgroundColor: JakdrainColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Collapsing App Bar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: JakdrainColors.electricBlue,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: JakdrainColors.headerGradient,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPatternPainter()),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              DrainageStatusBadge(
                                status: currentReport.status,
                                fontSize: 12,
                              ),
                              const SizedBox(width: 8),
                              _TaskStatusChip(taskStatus: currentReport.taskStatus),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentReport.address,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentReport.kelurahan}, ${currentReport.kecamatan}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Content ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Banner Status Selesai (Jika Sudah Selesai) ───
                if (isCompleted) ...[
                  _CompletionSuccessCard(
                    report: currentReport,
                    onEdit: () => _showAdjustRiskSheet(context, currentReport),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.05, end: 0),
                  const SizedBox(height: 18),
                ],

                // ─── ID & Timestamp ───────────────────────────
                _InfoRow(
                  label: 'ID Laporan',
                  value: currentReport.id,
                  icon: Icons.tag_rounded,
                ),
                _InfoRow(
                  label: 'Waktu Inspeksi',
                  value: _safeFormatDate(currentReport.inspectedAt),
                  icon: Icons.access_time_rounded,
                ),
                _InfoRow(
                  label: 'Petugas Inspeksi',
                  value: currentReport.inspectorName,
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),

                // ─── Sediment Gauge & Metrics ─────────────────
                _SedimentGauge(
                  percentage: currentReport.sedimentPercentage,
                  status: currentReport.status,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms),
                const SizedBox(height: 16),

                // ─── Metrics Grid ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _DetailMetricCard(
                        label: 'Sedimen',
                        value: '${currentReport.sedimentPercentage.toInt()}%',
                        icon: Icons.layers_rounded,
                        color: _getStatusColor(currentReport.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailMetricCard(
                        label: 'Sisa Kapasitas',
                        value: '${currentReport.remainingCapacityCm.toInt()} cm',
                        icon: Icons.straighten_rounded,
                        color: JakdrainColors.electricBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _DetailMetricCard(
                        label: 'Garis Lintang (Latitude)',
                        value:
                            '${currentReport.latitude.toStringAsFixed(4)}° ${currentReport.latitude < 0 ? "LS" : "LU"}',
                        icon: Icons.explore_rounded,
                        color: JakdrainColors.skyBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailMetricCard(
                        label: 'Garis Bujur (Longitude)',
                        value:
                            '${currentReport.longitude.toStringAsFixed(4)}° ${currentReport.longitude >= 0 ? "BT" : "BB"}',
                        icon: Icons.my_location_rounded,
                        color: JakdrainColors.electricBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _DetailMetricCard(
                  label: 'Tingkat Risiko Drainase',
                  value: currentReport.status == DrainageStatus.kritis
                      ? 'Kritis (Bahaya Tersumbat)'
                      : (currentReport.status == DrainageStatus.waspada
                          ? 'Waspada (Perlu Penanganan)'
                          : 'Aman (Normal Terawat)'),
                  icon: Icons.shield_rounded,
                  color: _getStatusColor(currentReport.status),
                ),
                const SizedBox(height: 18),

                // ─── Recommendation Card ──────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: JakdrainColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: JakdrainColors.electricBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rekomendasi Sistem',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: JakdrainColors.deepNavy,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _showAdjustRiskSheet(context, currentReport),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 14, color: JakdrainColors.electricBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'Atur Risiko',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: JakdrainColors.electricBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentReport.recommendation,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.6,
                          color: JakdrainColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Interactive Action Section ─────────────────
                _buildActionButtons(context, currentReport),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DrainageReport currentReport) {
    final drainageProvider = Provider.of<DrainageProvider>(context, listen: false);

    if (currentReport.taskStatus == TaskStatus.baruDilihat) {
      return Column(
        children: [
          // Tombol 1: Terima Tugas (Accept)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                }
                await drainageProvider.updateTaskStatus(
                  currentReport.id,
                  TaskStatus.dalamPengerukan,
                );
              },
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
              label: Text(
                'Terima Tugas Pengerukan (Accept)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JakdrainColors.electricBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol 2: Selesaikan Langsung dengan Foto Bukti
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                _showCompleteTaskSheet(context, currentReport);
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 18, color: JakdrainColors.safe),
              label: Text(
                'Selesaikan Langsung & Kirim Foto Bukti',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JakdrainColors.safe,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: JakdrainColors.safe, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    } else if (currentReport.taskStatus == TaskStatus.dalamPengerukan) {
      return Column(
        children: [
          // Banner Status Berjalan (Inline & Tidak Menghalangi Tombol Foto)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JakdrainColors.safe.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: JakdrainColors.safe.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: JakdrainColors.safe.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: JakdrainColors.safe, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tugas Diterima! Status: Sedang Dikerjakan PPSU',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: JakdrainColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pengerukan saluran sedang berlangsung. Siapkan kamera HP untuk mengambil foto bukti fisik saluran drainase setelah selesai.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: JakdrainColors.darkText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                _showCompleteTaskSheet(context, currentReport);
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: Text(
                'Selesaikan Tugas & Kirim Foto Bukti',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JakdrainColors.safe,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      );
    } else {
      // Selesai
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showAdjustRiskSheet(context, currentReport),
              icon: const Icon(Icons.edit_note_rounded, size: 20, color: JakdrainColors.electricBlue),
              label: Text(
                'Atur Ulang Tingkat Risiko / Perbarui Bukti',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JakdrainColors.electricBlue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: JakdrainColors.electricBlue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await drainageProvider.updateTaskStatus(currentReport.id, TaskStatus.baruDilihat);
            },
            child: Text(
              'Reset Status ke "Baru Dilihat"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: JakdrainColors.subtleGray,
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _getStatusColor(DrainageStatus status) {
    return switch (status) {
      DrainageStatus.kritis => JakdrainColors.critical,
      DrainageStatus.waspada => JakdrainColors.warning,
      DrainageStatus.aman => JakdrainColors.safe,
    };
  }
}

/// Kartu status keberhasilan tugas selesai (CEKLIS) dengan foto bukti, timestamp, dan catatan
class _CompletionSuccessCard extends StatelessWidget {
  final DrainageReport report;
  final VoidCallback onEdit;

  const _CompletionSuccessCard({required this.report, required this.onEdit});

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Baru Saja';
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProofImage = report.proofImagePath != null &&
        report.proofImagePath!.isNotEmpty &&
        File(report.proofImagePath!).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JakdrainColors.safe.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: JakdrainColors.safe.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Ceklis Hijau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: JakdrainColors.safe.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: JakdrainColors.safe,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUGAS PENGERUKAN SELESAI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: JakdrainColors.safe,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Diverifikasi ${report.completedBy ?? report.inspectorName} • ${_formatDate(report.completedAt)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: JakdrainColors.subtleGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18, color: JakdrainColors.safe),
                  tooltip: 'Edit Bukti & Risiko',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto Bukti dengan Watermark Overlay (Bisa diklik untuk perbesar & inspeksi foto jelas)
                if (hasProofImage) ...[
                  GestureDetector(
                    onTap: () => _showFullScreenImage(
                      context,
                      report.proofImagePath!,
                      title: 'Bukti Pengerukan: ${report.address}',
                      inspector: report.completedBy ?? report.inspectorName,
                      timestamp: report.completedAt ?? report.inspectedAt,
                      lat: report.latitude,
                      lng: report.longitude,
                      notes: report.officerNotes,
                      street: report.address,
                      kelurahan: report.kelurahan,
                      kecamatan: report.kecamatan,
                      kota: 'Kota Jakarta Barat',
                      provinsi: 'Daerah Khusus Ibukota Jakarta',
                      altitude: 28.7,
                      indexNumber: report.id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0'),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Image.file(
                            File(report.proofImagePath!),
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                          ),
                          // Badge Petunjuk Klik untuk Zoom
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Perbesar Foto',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Watermark Stamp Badge
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, color: JakdrainColors.safe, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'BUKTI FISIK PENGERUKAN SALURAN',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '📅 ${_formatDate(report.completedAt)} WIB\n📍 ${report.address} (${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Catatan / Pesan Petugas
                if (report.officerNotes != null && report.officerNotes!.isNotEmpty) ...[
                  Text(
                    'Pesan & Catatan Petugas Lapangan:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: JakdrainColors.subtleGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JakdrainColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: JakdrainColors.divider),
                    ),
                    child: Text(
                      '"${report.officerNotes}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: JakdrainColors.deepNavy,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Tingkat Risiko Terkini
                Row(
                  children: [
                    Text(
                      'Tingkat Risiko Terkini: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: JakdrainColors.deepNavy,
                      ),
                    ),
                    DrainageStatusBadge(status: report.status, fontSize: 11),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showFullScreenImage(
    BuildContext context,
    String imagePath, {
    required String title,
    String? inspector,
    DateTime? timestamp,
    double? lat,
    double? lng,
    String? notes,
    String? street,
    String? kelurahan,
    String? kecamatan,
    String? kota,
    String? provinsi,
    double? altitude,
    dynamic indexNumber,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (dialogCtx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Cubit untuk Zoom',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 6.0,
                clipBehavior: Clip.none,
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GpsTimestampStamp(
                          dateTime: timestamp ?? DateTime.now(),
                          street: street,
                          kelurahan: kelurahan ?? 'Duri Kosambi',
                          kecamatan: kecamatan ?? 'Kecamatan Cengkareng',
                          kota: kota ?? 'Kota Jakarta Barat',
                          provinsi: provinsi ?? 'Daerah Khusus Ibukota Jakarta',
                          altitude: altitude ?? 28.7,
                          indexNumber: indexNumber ?? 23,
                          latitude: lat,
                          longitude: lng,
                          showBackground: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.black.withValues(alpha: 0.85),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (inspector != null)
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: JakdrainColors.safe, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Petugas Inspeksi: $inspector',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              _formatDateStatic(timestamp),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    if (street != null && street.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: JakdrainColors.skyBlueAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$street, ${kelurahan ?? ""}, ${kecamatan ?? ""}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (lat != null && lng != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Koordinat: Garis Lintang (Latitude): ${lat.toStringAsFixed(5)}° ${lat < 0 ? "LS" : "LU"}, Garis Bujur (Longitude): ${lng.toStringAsFixed(5)}° ${lng >= 0 ? "BT" : "BB"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Catatan: "$notes"',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateStatic(DateTime? dt) {
    if (dt == null) return 'Baru Saja';
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }
  }
}

/// Modal Form Selesai Tugas & Ambil Bukti Foto
class _CompleteTaskSheet extends StatefulWidget {
  final DrainageReport report;

  const _CompleteTaskSheet({required this.report});

  @override
  State<_CompleteTaskSheet> createState() => _CompleteTaskSheetState();
}

class _CompleteTaskSheetState extends State<_CompleteTaskSheet> {
  File? _proofPhoto;
  late DrainageStatus _selectedRisk;
  late TextEditingController _notesController;
  bool _isSubmitting = false;
  String? _realAddress;
  double? _realLat;
  double? _realLng;

  // Nilai realistis awal (tidak pernah 0%!)
  double _currentSediment = 10.0;
  double _currentCapacity = 40.0;

  @override
  void initState() {
    super.initState();
    _selectedRisk = DrainageStatus.aman; // Default pengerukan selesai adalah aman
    _currentSediment = 10.0;
    _currentCapacity = 40.0;
    _notesController = TextEditingController(
      text: widget.report.officerNotes ??
          'Endapan sedimen dan sampah telah dikeruk tuntas oleh tim PPSU. Aliran drainase kini normal dan lancar.',
    );
    if (widget.report.proofImagePath != null &&
        widget.report.proofImagePath!.isNotEmpty &&
        File(widget.report.proofImagePath!).existsSync()) {
      _proofPhoto = File(widget.report.proofImagePath!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    HapticFeedback.mediumImpact();
    final photo = await JakdrainCameraService.takePhoto(context);
    if (photo != null && photo.existsSync()) {
      final loc = await JakdrainCameraService.getCurrentLocation();
      setState(() {
        _proofPhoto = photo;
        if (loc != null) {
          _realAddress = loc['address'] as String?;
          _realLat = loc['latitude'] as double?;
          _realLng = loc['longitude'] as double?;
        }
      });

      // Analisis foto bukti untuk menyesuaikan persentase secara akurat
      try {
        final aiRes = await MockAiProcessor.analyzeImage(photo);
        if (aiRes.isValidDrainage && aiRes.sedimentPercentage > 0) {
          setState(() {
            _currentSediment = aiRes.sedimentPercentage;
            _currentCapacity = aiRes.remainingCapacityCm;
            if (aiRes.riskLevel == 'Kritis') {
              _selectedRisk = DrainageStatus.kritis;
            } else if (aiRes.riskLevel == 'Waspada') {
              _selectedRisk = DrainageStatus.waspada;
            } else {
              _selectedRisk = DrainageStatus.aman;
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final drainageProvider = Provider.of<DrainageProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Pastikan persentase sedimen realistis sesuai pilihan risiko (TIDAK PERNAH 0%)
    double finalSediment = _currentSediment;
    double finalCapacity = _currentCapacity;

    if (finalSediment <= 0) {
      if (_selectedRisk == DrainageStatus.kritis) {
        finalSediment = 78.0;
        finalCapacity = 8.0;
      } else if (_selectedRisk == DrainageStatus.waspada) {
        finalSediment = 42.0;
        finalCapacity = 22.0;
      } else {
        finalSediment = 10.0;
        finalCapacity = 40.0;
      }
    }

    await drainageProvider.completeTaskWithProof(
      reportId: widget.report.id,
      newStatus: _selectedRisk,
      newSedimentPercentage: finalSediment,
      newRemainingCapacityCm: finalCapacity,
      proofImagePath: _proofPhoto?.path,
      officerNotes: _notesController.text.trim(),
      completedBy: userProvider.currentUser.name,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tugas ${widget.report.id} Selesai! Bukti & pembaruan risiko tersimpan.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: JakdrainColors.safe,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomInset + (bottomPadding > 0 ? bottomPadding : 24) + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Modal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JakdrainColors.safe.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.task_alt_rounded, color: JakdrainColors.safe, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selesaikan Tugas & Kirim Bukti',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: JakdrainColors.deepNavy,
                        ),
                      ),
                      Text(
                        widget.report.address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: JakdrainColors.subtleGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── 1. Foto Bukti Pekerjaan (Hanya Kamera HP Langsung) ───
            Text(
              '1. Foto Bukti Hasil Pengerukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JakdrainColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),

            if (_proofPhoto == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: JakdrainColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JakdrainColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: JakdrainColors.electricBlue.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ambil foto bukti fisik saluran yang telah dikeruk',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: JakdrainColors.subtleGray,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Buka Kamera HP (Wajib Foto Langsung)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JakdrainColors.electricBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Preview Foto dengan Watermark Stamp (Bisa diklik untuk perbesar)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _CompletionSuccessCard._showFullScreenImage(
                        context,
                        _proofPhoto!.path,
                        title: 'Pratinjau Bukti: ${widget.report.address}',
                        inspector: 'Petugas Lapangan',
                        timestamp: DateTime.now(),
                        lat: _realLat ?? widget.report.latitude,
                        lng: _realLng ?? widget.report.longitude,
                        notes: _notesController.text.trim(),
                        street: _realAddress ?? widget.report.address,
                        kelurahan: widget.report.kelurahan,
                        kecamatan: widget.report.kecamatan,
                        kota: 'Kota Jakarta Barat',
                        provinsi: 'Daerah Khusus Ibukota Jakarta',
                        altitude: 28.7,
                        indexNumber: widget.report.id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0'),
                      ),
                      child: Image.file(
                        _proofPhoto!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Badge Zoom Hint
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Ketuk untuk Zoom',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GpsTimestampStamp(
                        dateTime: DateTime.now(),
                        kelurahan: _realAddress ?? widget.report.kelurahan,
                        kecamatan: widget.report.kecamatan,
                        kota: 'Kota Jakarta Barat',
                        provinsi: 'Daerah Khusus Ibukota Jakarta',
                        altitude: 28.7,
                        indexNumber: widget.report.id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0'),
                        showBackground: true,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Foto Ulang',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // ─── 2. Atur Ulang Tingkat Risiko Saluran ───
            Text(
              '2. Tingkat Risiko Setelah Pengerukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JakdrainColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRiskOption(
                  status: DrainageStatus.aman,
                  label: 'Aman (Normal)',
                  color: JakdrainColors.safe,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(width: 8),
                _buildRiskOption(
                  status: DrainageStatus.waspada,
                  label: 'Waspada',
                  color: JakdrainColors.warning,
                  icon: Icons.warning_amber_rounded,
                ),
                const SizedBox(width: 8),
                _buildRiskOption(
                  status: DrainageStatus.kritis,
                  label: 'Kritis',
                  color: JakdrainColors.critical,
                  icon: Icons.dangerous_rounded,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Indikator Persentase Sedimen Realistis (Langsung terlihat saat diklik, tidak pernah 0%!)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (_selectedRisk == DrainageStatus.kritis
                        ? JakdrainColors.critical
                        : (_selectedRisk == DrainageStatus.waspada
                            ? JakdrainColors.warning
                            : JakdrainColors.safe))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_selectedRisk == DrainageStatus.kritis
                          ? JakdrainColors.critical
                          : (_selectedRisk == DrainageStatus.waspada
                              ? JakdrainColors.warning
                              : JakdrainColors.safe))
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedRisk == DrainageStatus.kritis
                        ? Icons.warning_rounded
                        : (_selectedRisk == DrainageStatus.waspada
                            ? Icons.info_rounded
                            : Icons.check_circle_rounded),
                    size: 18,
                    color: _selectedRisk == DrainageStatus.kritis
                        ? JakdrainColors.critical
                        : (_selectedRisk == DrainageStatus.waspada
                            ? JakdrainColors.warning
                            : JakdrainColors.safe),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tingkat Sedimen: ${_currentSediment.toInt()}% • Sisa Kapasitas: ${_currentCapacity.toInt()} cm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedRisk == DrainageStatus.kritis
                            ? JakdrainColors.critical
                            : (_selectedRisk == DrainageStatus.waspada
                                ? JakdrainColors.warning
                                : JakdrainColors.safe),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── 3. Pesan / Catatan Petugas ───
            Text(
              '3. Pesan / Catatan Petugas Lapangan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JakdrainColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: JakdrainColors.deepNavy),
              decoration: InputDecoration(
                hintText: 'Tuliskan rincian hasil pengerukan, kedalaman sedimen yang diangkat, dll...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 22),

            // Tombol Kirim & Selesai
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  'Kirim Bukti & Tandai Selesai',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JakdrainColors.safe,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildRiskOption({
    required DrainageStatus status,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedRisk == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRisk = status;
            if (status == DrainageStatus.aman) {
              _currentSediment = 10.0;
              _currentCapacity = 40.0;
            } else if (status == DrainageStatus.waspada) {
              _currentSediment = 42.0;
              _currentCapacity = 22.0;
            } else {
              _currentSediment = 78.0;
              _currentCapacity = 8.0;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : JakdrainColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : JakdrainColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : JakdrainColors.subtleGray, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : JakdrainColors.subtleGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Pengaturan Ulang Tingkat Risiko
class _AdjustRiskSheet extends StatefulWidget {
  final DrainageReport report;

  const _AdjustRiskSheet({required this.report});

  @override
  State<_AdjustRiskSheet> createState() => _AdjustRiskSheetState();
}

class _AdjustRiskSheetState extends State<_AdjustRiskSheet> {
  late DrainageStatus _currentRisk;
  File? _proofPhoto;
  final _notesController = TextEditingController();
  bool _isSaving = false;
  String? _realAddress;
  String? _kelurahan;
  String? _kecamatan;
  String? _kota;
  String? _provinsi;
  double? _altitude;

  @override
  void initState() {
    super.initState();
    _currentRisk = widget.report.status;
    _fetchLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final loc = await JakdrainCameraService.getCurrentLocation();
    if (mounted && loc != null) {
      setState(() {
        _realAddress = loc['address'] as String?;
        _kelurahan = loc['kelurahan'] as String?;
        _kecamatan = loc['kecamatan'] as String?;
        _kota = loc['kota'] as String?;
        _provinsi = loc['provinsi'] as String?;
        _altitude = loc['altitude'] as double?;
      });
    }
  }

  Future<void> _takePhoto() async {
    HapticFeedback.mediumImpact();
    final photo = await JakdrainCameraService.takePhoto(context);
    if (photo != null && photo.existsSync()) {
      setState(() => _proofPhoto = photo);
      await _fetchLocation();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final drainageProvider = Provider.of<DrainageProvider>(context, listen: false);

    double sediment = _currentRisk == DrainageStatus.aman
        ? 15.0
        : (_currentRisk == DrainageStatus.waspada ? 45.0 : 78.0);
    double capacity = _currentRisk == DrainageStatus.aman
        ? 36.0
        : (_currentRisk == DrainageStatus.waspada ? 20.0 : 8.0);

    await drainageProvider.updateReportRiskAndStatus(
      reportId: widget.report.id,
      newRiskStatus: _currentRisk,
      sedimentPercentage: sediment,
      remainingCapacityCm: capacity,
      proofImagePath: _proofPhoto?.path,
      officerNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _proofPhoto != null
                      ? 'Kondisi diperbarui ke ${_currentRisk.name.toUpperCase()} beserta bukti foto!'
                      : 'Kondisi diperbarui ke ${_currentRisk.name.toUpperCase()}!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: JakdrainColors.safe,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          bottomInset + (bottomPadding > 0 ? bottomPadding : 24),
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
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: JakdrainColors.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: JakdrainColors.electricBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atur Ulang Kondisi Drainase',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: JakdrainColors.deepNavy,
                          ),
                        ),
                        Text(
                          'Bisa klik langsung simpan atau lampirkan foto bukti GPS',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: JakdrainColors.subtleGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ─── 1. Pilihan Status Baru ───
              Text(
                '1. Pilih Tingkat Risiko Baru',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: JakdrainColors.deepNavy),
              ),
              const SizedBox(height: 8),
              _buildSelectTile(
                status: DrainageStatus.aman,
                title: 'Aman (Normal)',
                subtitle: 'Aliran lancar, sedimen terkontrol, risiko genangan rendah.',
                color: JakdrainColors.safe,
              ),
              const SizedBox(height: 8),
              _buildSelectTile(
                status: DrainageStatus.waspada,
                title: 'Waspada (Sedang)',
                subtitle: 'Sedimen 25-50%, aliran melambat, butuh pembersihan berkala.',
                color: JakdrainColors.warning,
              ),
              const SizedBox(height: 8),
              _buildSelectTile(
                status: DrainageStatus.kritis,
                title: 'Kritis (Tinggi)',
                subtitle: 'Sedimen >50%, aliran tersumbat, potensi banjir tinggi.',
                color: JakdrainColors.critical,
              ),
              const SizedBox(height: 10),

              // Indikator Persentase Sedimen Realistis Sesuai Pilihan (Langsung berubah saat diklik, tidak pernah 0%!)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (_currentRisk == DrainageStatus.kritis
                          ? JakdrainColors.critical
                          : (_currentRisk == DrainageStatus.waspada
                              ? JakdrainColors.warning
                              : JakdrainColors.safe))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_currentRisk == DrainageStatus.kritis
                            ? JakdrainColors.critical
                            : (_currentRisk == DrainageStatus.waspada
                                ? JakdrainColors.warning
                                : JakdrainColors.safe))
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentRisk == DrainageStatus.kritis
                          ? Icons.warning_rounded
                          : (_currentRisk == DrainageStatus.waspada
                              ? Icons.info_rounded
                              : Icons.check_circle_rounded),
                      size: 18,
                      color: _currentRisk == DrainageStatus.kritis
                          ? JakdrainColors.critical
                          : (_currentRisk == DrainageStatus.waspada
                              ? JakdrainColors.warning
                              : JakdrainColors.safe),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Estimasi Sedimen: ${_currentRisk == DrainageStatus.kritis ? 78 : (_currentRisk == DrainageStatus.waspada ? 45 : 15)}% • Sisa Kapasitas: ${_currentRisk == DrainageStatus.kritis ? 8 : (_currentRisk == DrainageStatus.waspada ? 20 : 36)} cm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _currentRisk == DrainageStatus.kritis
                              ? JakdrainColors.critical
                              : (_currentRisk == DrainageStatus.waspada
                                  ? JakdrainColors.warning
                                  : JakdrainColors.safe),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ─── 2. Foto Bukti (Bisa dikirim atau dilewati) ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2. Foto Bukti Lapangan (Opsional)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: JakdrainColors.deepNavy),
                  ),
                  Text(
                    'Bisa dilewati',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: JakdrainColors.subtleGray),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_proofPhoto == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: JakdrainColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: JakdrainColors.divider),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Buka Kamera HP (Wajib Foto Langsung)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.file(
                        _proofPhoto!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                      // Watermark GpsTimestampStamp di Kanan Bawah
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GpsTimestampStamp(
                          dateTime: DateTime.now(),
                          street: _realAddress ?? widget.report.address,
                          kelurahan: _kelurahan ?? widget.report.kelurahan,
                          kecamatan: _kecamatan ?? widget.report.kecamatan,
                          kota: _kota ?? 'Kota Jakarta Barat',
                          provinsi: _provinsi ?? 'Daerah Khusus Ibukota Jakarta',
                          altitude: _altitude ?? 28.7,
                          indexNumber: widget.report.id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0'),
                          showBackground: true,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _proofPhoto = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ─── 3. Catatan Ringkas (Opsional) ───
              Text(
                '3. Catatan Tambahan (Opsional)',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: JakdrainColors.deepNavy),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: JakdrainColors.deepNavy),
                decoration: InputDecoration(
                  hintText: 'Contoh: Sedimen dikeruk sebagian, aliran mulai normal...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: JakdrainColors.subtleGray),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Tombol Simpan (Cuma Klik Langsung Jadi!) ───
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'Simpan Perubahan Kondisi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JakdrainColors.electricBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectTile({
    required DrainageStatus status,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _currentRisk == status;
    return GestureDetector(
      onTap: () => setState(() => _currentRisk = status),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : JakdrainColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : JakdrainColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: JakdrainColors.deepNavy,
                    ),
                  ),
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
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Chip status tugas
class _TaskStatusChip extends StatelessWidget {
  final TaskStatus taskStatus;

  const _TaskStatusChip({required this.taskStatus});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (taskStatus) {
      TaskStatus.baruDilihat => ('Baru Dilihat', JakdrainColors.electricBlue, Icons.visibility_rounded),
      TaskStatus.dalamPengerukan => ('Dalam Pengerukan', JakdrainColors.warning, Icons.construction_rounded),
      TaskStatus.selesai => ('Selesai ✓', JakdrainColors.safe, Icons.check_circle_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row info label-value.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: JakdrainColors.subtleGray),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: JakdrainColors.subtleGray,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: JakdrainColors.deepNavy,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gauge visual sedimen berbentuk arc.
class _SedimentGauge extends StatelessWidget {
  final double percentage;
  final DrainageStatus status;

  const _SedimentGauge({required this.percentage, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DrainageStatus.kritis => JakdrainColors.critical,
      DrainageStatus.waspada => JakdrainColors.warning,
      DrainageStatus.aman => JakdrainColors.safe,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tingkat Sedimentasi Saluran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: JakdrainColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: JakdrainColors.divider.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    DrainageStatusBadge(
                      status: status,
                      showIcon: false,
                      fontSize: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: JakdrainColors.divider.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu metrik detail.
class _DetailMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: JakdrainColors.subtleGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Pattern painter untuk background app bar.
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
