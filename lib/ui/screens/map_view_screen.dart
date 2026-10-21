// ============================================================
// Jakdrain — Map View Screen
// Peta interaktif digital twin drainase Jakarta berbasis OpenStreetMap (Free API).
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/drainage_provider.dart';
import 'package:jakdrain/ui/widgets/drainage_status_badge.dart';
import 'package:jakdrain/ui/screens/report_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  DrainageStatus? _activeFilter;
  DrainageReport? _selectedReport;
  double _currentZoom = 14.2;

  // Titik koordinat pusat Jakarta (Bundaran HI / Tanah Abang)
  static const LatLng _jakartaCenter = LatLng(-6.1950, 106.8200);

  List<DrainageReport> _getFilteredReports(List<DrainageReport> reports) {
    if (_activeFilter == null) return reports;
    return reports.where((r) => r.status == _activeFilter).toList();
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    final newZoom = (_currentZoom + 1).clamp(10.0, 18.5);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    final newZoom = (_currentZoom - 1).clamp(10.0, 18.5);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _recenterJakarta() {
    HapticFeedback.mediumImpact();
    _mapController.move(_jakartaCenter, 14.2);
    setState(() {
      _currentZoom = 14.2;
      _selectedReport = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final drainageProvider = Provider.of<DrainageProvider>(context);
    final filteredReports = _getFilteredReports(drainageProvider.reports);

    return Scaffold(
      backgroundColor: JakdrainColors.surface,
      body: Stack(
        children: [
          // ─── Real Interactive Map (OpenStreetMap Free API) ─────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _jakartaCenter,
              initialZoom: 14.2,
              minZoom: 10.0,
              maxZoom: 18.5,
              onTap: (_, __) {
                if (_selectedReport != null) {
                  setState(() => _selectedReport = null);
                }
              },
              onPositionChanged: (pos, _) {
                _currentZoom = pos.zoom;
              },
            ),
            children: [
              // OpenStreetMap Standard Tiles (100% Free, No Credit Card, No Paid API Keys)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jakartasmartcity.jakdrain',
                maxZoom: 19,
              ),

              // Interactive Drainage Markers
              MarkerLayer(
                markers: filteredReports.map((report) {
                  final isSelected = _selectedReport?.id == report.id;
                  return Marker(
                    point: LatLng(report.latitude, report.longitude),
                    width: isSelected ? 56 : 46,
                    height: isSelected ? 66 : 56,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _mapController.move(
                          LatLng(report.latitude, report.longitude),
                          15.5,
                        );
                        setState(() => _selectedReport = report);
                      },
                      child: _MapPin(
                        status: report.status,
                        isSelected: isSelected,
                        sedimentPercentage: report.sedimentPercentage,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ─── Top Filter Bar ────────────────────────────────────────
          _buildTopBar(drainageProvider, filteredReports.length),

          // ─── Floating Zoom & Recenter Controls ─────────────────────
          _buildFloatingMapControls(),

          // ─── Legend ────────────────────────────────────────────────
          if (_selectedReport == null) _buildLegend(),

          // ─── Selected Report Sheet ─────────────────────────────────
          if (_selectedReport != null)
            _buildReportSheet(_selectedReport!),
        ],
      ),
    );
  }

  Widget _buildTopBar(DrainageProvider provider, int count) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: JakdrainColors.cardGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
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
                        'Peta Drainase DKI Jakarta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: JakdrainColors.deepNavy,
                        ),
                      ),
                      Text(
                        '$count saluran air terpantau (OSM Live)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: JakdrainColors.subtleGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge Free API
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: JakdrainColors.safe.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Free Map API',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: JakdrainColors.safe,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips (Menggunakan data riil Provider yang sinkron dengan titik peta)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Semua',
                  isActive: _activeFilter == null,
                  count: provider.reports.length,
                  onTap: () => setState(() => _activeFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Kritis',
                  isActive: _activeFilter == DrainageStatus.kritis,
                  color: JakdrainColors.critical,
                  count: provider.kritisReports.length,
                  onTap: () =>
                      setState(() => _activeFilter = DrainageStatus.kritis),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Waspada',
                  isActive: _activeFilter == DrainageStatus.waspada,
                  color: JakdrainColors.warning,
                  count: provider.waspadaReports.length,
                  onTap: () =>
                      setState(() => _activeFilter = DrainageStatus.waspada),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Aman',
                  isActive: _activeFilter == DrainageStatus.aman,
                  color: JakdrainColors.safe,
                  count: provider.amanReports.length,
                  onTap: () =>
                      setState(() => _activeFilter = DrainageStatus.aman),
                ),
              ],
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 350.ms)
          .slideY(begin: -0.05, end: 0, duration: 350.ms),
    );
  }

  Widget _buildFloatingMapControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 120,
      child: Column(
        children: [
          _buildMapButton(
            icon: Icons.add_rounded,
            tooltip: 'Perbesar',
            onTap: _zoomIn,
          ),
          const SizedBox(height: 8),
          _buildMapButton(
            icon: Icons.remove_rounded,
            tooltip: 'Perkecil',
            onTap: _zoomOut,
          ),
          const SizedBox(height: 8),
          _buildMapButton(
            icon: Icons.my_location_rounded,
            tooltip: 'Pusatkan Jakarta',
            color: JakdrainColors.electricBlue,
            iconColor: Colors.white,
            onTap: _recenterJakarta,
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor ?? JakdrainColors.deepNavy,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      left: 16,
      bottom: 24 + MediaQuery.of(context).padding.bottom,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legenda Saluran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: JakdrainColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            _LegendItem(color: JakdrainColors.critical, label: 'Kritis (>65%)'),
            _LegendItem(color: JakdrainColors.warning, label: 'Waspada (40-65%)'),
            _LegendItem(color: JakdrainColors.safe, label: 'Aman (<40%)'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSheet(DrainageReport report) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20 + MediaQuery.of(context).padding.bottom,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(report: report),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.address,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: JakdrainColors.deepNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${report.kelurahan}, ${report.kecamatan}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: JakdrainColors.subtleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DrainageStatusBadge(status: report.status),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedReport = null),
                    child: const Icon(Icons.close_rounded, size: 18, color: JakdrainColors.subtleGray),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniMetric(
                    icon: Icons.layers_rounded,
                    label: 'Sedimen',
                    value: '${report.sedimentPercentage.toInt()}%',
                    color: _getStatusColor(report.status),
                  ),
                  const SizedBox(width: 16),
                  _MiniMetric(
                    icon: Icons.straighten_rounded,
                    label: 'Sisa Kapasitas',
                    value: '${report.remainingCapacityCm} cm',
                    color: JakdrainColors.electricBlue,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(report: report),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 16),
                      label: Text(
                        'Detail AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JakdrainColors.electricBlue,
                        side: const BorderSide(color: JakdrainColors.electricBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final provider = Provider.of<DrainageProvider>(context, listen: false);
                        await provider.updateTaskStatus(report.id, TaskStatus.dalamPengerukan);
                        if (mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Pengerukan saluran ${report.id} ditugaskan ke Tim PPSU!',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: JakdrainColors.safe,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                        setState(() => _selectedReport = null);
                      },
                      icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                      label: Text(
                        'Pengerukan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 250.ms)
            .slideY(begin: 0.1, end: 0, duration: 250.ms),
      ),
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

/// Pin marker interaktif di peta OSM.
class _MapPin extends StatelessWidget {
  final DrainageStatus status;
  final bool isSelected;
  final double sedimentPercentage;

  const _MapPin({
    required this.status,
    this.isSelected = false,
    required this.sedimentPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DrainageStatus.kritis => JakdrainColors.critical,
      DrainageStatus.waspada => JakdrainColors.warning,
      DrainageStatus.aman => JakdrainColors.safe,
    };

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${sedimentPercentage.toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.location_on_rounded,
              color: color,
              size: isSelected ? 32 : 26,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip untuk status drainase.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? JakdrainColors.electricBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? chipColor : JakdrainColors.divider,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : JakdrainColors.darkText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : JakdrainColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : JakdrainColors.subtleGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item legenda peta.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: JakdrainColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini metric untuk report sheet.
class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: JakdrainColors.subtleGray,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
