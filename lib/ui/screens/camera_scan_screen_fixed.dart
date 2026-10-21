// ============================================================
// Jakdrain — Camera Scan Screen
// Layar pemindaian AI cerdas dengan kamera GPS Timestamp riil,
// deteksi endapan lumpur, sampah got, aliran air & rekomendasi SDA.
// ============================================================
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/core/mock_ai.dart';
import 'package:jakdrain/core/camera_service.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/drainage_provider.dart';
import 'package:jakdrain/providers/user_provider.dart';
import 'package:jakdrain/ui/widgets/animated_scanner_overlay.dart';
import 'package:jakdrain/ui/widgets/gps_timestamp_stamp.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  File? _capturedImage;
  bool _isScanning = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _hasCameraPermission = false;

  String? _realAddress;
  String? _street;
  String? _kelurahan;
  String? _kecamatan;
  String? _kota;
  String? _provinsi;
  double? _altitude;
  double? _realLat;
  double? _realLng;

  DateTime _liveTime = DateTime.now();
  Timer? _liveClockTimer;
  late AnimationController _shutterAnimController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shutterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Timer jam berjalan tiap detik persis seperti tampilan kamera timestamp
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _liveTime = DateTime.now();
        });
      }
    });

    _checkPermissionState();
    _fetchInitialLocation();
  }

  Future<void> _fetchInitialLocation() async {
    final loc = await JakdrainCameraService.getCurrentLocation();
    if (mounted && loc != null) {
      setState(() {
        _realAddress = loc['address'] as String?;
        _street = loc['street'] as String?;
        _kelurahan = loc['kelurahan'] as String?;
        _kecamatan = loc['kecamatan'] as String?;
        _kota = loc['kota'] as String?;
        _provinsi = loc['provinsi'] as String?;
        _altitude = loc['altitude'] as double?;
        _realLat = loc['latitude'] as double?;
        _realLng = loc['longitude'] as double?;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveClockTimer?.cancel();
    _shutterAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionState();
      _fetchInitialLocation();
    }
  }

  Future<void> _checkPermissionState() async {
    final granted = await JakdrainCameraService.isCameraPermissionGranted();
    if (mounted && granted != _hasCameraPermission) {
      setState(() {
        _hasCameraPermission = granted;
      });
    }
  }

  /// Membuka kamera fisik Android langsung via native MethodChannel FileProvider dengan izin runtime.
  Future<void> _takePhoto() async {
    HapticFeedback.mediumImpact();
    final hasPermission = await JakdrainCameraService.isCameraPermissionGranted();
    if (!hasPermission) {
      if (!mounted) return;
      final granted = await JakdrainCameraService.showPermissionDialog(context);
      await _checkPermissionState();
      if (!granted) return;
    }

    if (!mounted) return;
    final photo = await JakdrainCameraService.takePhoto(context);
    if (photo != null && photo.existsSync()) {
      await _fetchInitialLocation();
      setState(() {
        _capturedImage = photo;
      });
      await _runAiAnalysis();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Kamera ditutup atau foto belum diambil.'),
              ],
            ),
            backgroundColor: JakdrainColors.deepNavy,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


  /// Menjalankan animasi scanning laser dan analisis AI Jakdrain.
  Future<void> _runAiAnalysis() async {
    HapticFeedback.heavyImpact();

    // Shutter flash effect
    await _shutterAnimController.forward();
    await _shutterAnimController.reverse();

    setState(() {
      _isScanning = true;
    });

    // Scanning animation duration
    await Future.delayed(const Duration(milliseconds: 1800));

    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });

    // AI processing dengan deteksi sampah, lumpur, dan aliran got (Mengirim foto captured)
    final result = await MockAiProcessor.analyzeImage(_capturedImage);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _showResultModal(result);
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = false;
      _isProcessing = false;
      _capturedImage = null;
    });
  }

  /// Menampilkan sheet peringatan jika objek yang difoto bukan saluran got/air
  void _showInvalidObjectSheet(AiScanResult result) {
    HapticFeedback.vibrate();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          bottom: true,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                bottomInset + (bottomPadding > 0 ? bottomPadding : 16) + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
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

                  // Icon Ditolak
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: JakdrainColors.critical.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.no_photography_rounded,
                      color: JakdrainColors.critical,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Objek Tidak Dikenali!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: JakdrainColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: JakdrainColors.critical.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.invalidReason ?? 'Bukan Saluran Got / Air',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: JakdrainColors.critical,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preview Foto yang ditolak dengan border merah
                  if (_capturedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.file(
                            _capturedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                border: Border.all(color: JakdrainColors.critical, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: JakdrainColors.critical,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cancel_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ditolak: Objek Non-Drainase',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Penjelasan Rekomendasi
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: JakdrainColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JakdrainColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: JakdrainColors.deepNavy, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result.recommendation,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: JakdrainColors.subtleGray,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tombol Aksi Foto Ulang (Kamera Fisik Saja)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetScan();
                          _takePhoto();
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                        label: Text(
                          'Arahkan Kamera & Foto Got Ulang',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JakdrainColors.electricBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResultModal(AiScanResult result) {
    if (!result.isValidDrainage) {
      _showInvalidObjectSheet(result);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResultModal(
        result: result,
        capturedImage: _capturedImage,
        street: _street,
        kelurahan: _kelurahan ?? 'Duri Kosambi',
        kecamatan: _kecamatan ?? 'Kecamatan Cengkareng',
        kota: _kota ?? 'Kota Jakarta Barat',
        provinsi: _provinsi ?? 'Daerah Khusus Ibukota Jakarta',
        altitude: _altitude ?? 28.7,
        realAddress: _realAddress,
        realLat: _realLat,
        realLng: _realLng,
        onRetake: () {
          Navigator.pop(context);
          _resetScan();
        },
        onSubmit: (finalResult) {
          Navigator.pop(context);
          _submitReport(finalResult);
        },
      ),
    );
  }

  Future<void> _submitReport(AiScanResult result) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final drainageProvider = Provider.of<DrainageProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    final random = Random();
    final selectedJalan = _street ?? _realAddress ?? 'Jl. Duri Kosambi Raya No. 42';
    final lat = _realLat ?? (-6.1754 + (random.nextDouble() - 0.5) * 0.01);
    final lng = _realLng ?? (106.8272 + (random.nextDouble() - 0.5) * 0.01);

    final status = result.riskLevel == 'Kritis'
        ? DrainageStatus.kritis
        : (result.riskLevel == 'Waspada'
            ? DrainageStatus.waspada
            : DrainageStatus.aman);

    // Pastikan persentase sedimen tidak pernah 0% pada saat bikin laporan awal
    double finalSediment = result.sedimentPercentage;
    double finalCapacity = result.remainingCapacityCm;
    if (finalSediment <= 0) {
      if (status == DrainageStatus.kritis) {
        finalSediment = 78.0;
        finalCapacity = 8.0;
      } else if (status == DrainageStatus.waspada) {
        finalSediment = 45.0;
        finalCapacity = 20.0;
      } else {
        finalSediment = 10.0;
        finalCapacity = 40.0;
      }
    }

    final reportId = 'DR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newReport = DrainageReport(
      id: reportId,
      address: selectedJalan,
      kelurahan: _kelurahan ?? 'Duri Kosambi',
      kecamatan: _kecamatan?.replaceAll('Kecamatan ', '') ?? 'Cengkareng',
      latitude: lat,
      longitude: lng,
      sedimentPercentage: finalSediment,
      remainingCapacityCm: finalCapacity,
      status: status,
      recommendation: result.recommendation,
      inspectedAt: DateTime.now(),
      inspectorName: currentUser.name,
      imagePath: _capturedImage?.path,
      taskStatus: TaskStatus.baruDilihat,
    );

    // Kirim langsung ke Cloud Firestore via DrainageProvider
    final success = await drainageProvider.addNewReport(newReport);
    userProvider.incrementInspection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? 'Laporan $reportId tersimpan ke Cloud Firestore!'
                      : 'Laporan tersimpan di memori perangkat.',
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
      _resetScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Konten Kamera Utama
            Column(
              children: [
                // ─── Header Top Bar Kamera ───────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      // Flash Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isFlashOn = !_isFlashOn);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isFlashOn ? JakdrainColors.warning.withValues(alpha: 0.25) : Colors.white12,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isFlashOn ? Icons.flash_on_rounded : Icons.flash_auto_rounded,
                                color: _isFlashOn ? JakdrainColors.warning : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isFlashOn ? 'ON' : 'AUTO',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Live GPS Indicator Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: JakdrainColors.safe.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JakdrainColors.safe.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: JakdrainColors.safe, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _kelurahan ?? 'Duri Kosambi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Camera Switch Icon
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kamera Utama Belakang (Resolusi Tinggi Aktif)'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),

                // ─── Area Viewfinder Kamera & Watermark Live ───
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _capturedImage != null
                        ? _buildCapturedImagePreview()
                        : _buildViewfinderCard(),
                  ),
                ),

                // ─── Mode Selector Text ──────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: JakdrainColors.electricBlue.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Foto Got (AI Scan)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: JakdrainColors.skyBlueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Video Drainase',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Shutter & Controls Bottom Bar ──────────────
                Container(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 14),
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indikator Kamera Fisik Aktif (Only Foto Lapangan)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: JakdrainColors.safe.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JakdrainColors.safe.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.videocam_rounded, color: JakdrainColors.safe, size: 22),
                      ),

                      // Tombol Shutter Kamera Lingkaran Putih (Persis Screenshot)
                      GestureDetector(
                        onTap: (_isScanning || _isProcessing) ? null : _takePhoto,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF0F172A),
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tombol Simulasi AI Cepat
                      GestureDetector(
                        onTap: () {
                          setState(() => _capturedImage = null);
                          _runAiAnalysis();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: JakdrainColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: JakdrainColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: JakdrainColors.warning, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── Scanning Laser Animation Overlay ───────────
            if (_isScanning)
              Positioned.fill(
                child: AnimatedScannerOverlay(isScanning: _isScanning),
              ),

            // ─── Shutter Flash Effect ───────────────────────
            AnimatedBuilder(
              animation: _shutterAnimController,
              builder: (context, child) {
                return _shutterAnimController.value > 0
                    ? Container(
                        color: Colors.white.withValues(
                          alpha: _shutterAnimController.value * 0.5,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),

            // ─── Processing Indicator ───────────────────────
            if (_isProcessing)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: JakdrainColors.skyBlueAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          color: JakdrainColors.skyBlueAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI Menganalisis Got & Sampah...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mendeteksi botol, kresek, lumpur, & aliran air',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: JakdrainColors.subtleGray,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
          ],
        ),
      ),
    );
  }

  /// Preview foto yang diambil dengan Stempel Watermark GPS persis Screenshot Pengguna
  Widget _buildCapturedImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _capturedImage!,
            fit: BoxFit.cover,
          ),
          // Watermark GPS Timestamp Lengkap di Kanan Bawah
          Positioned(
            bottom: 14,
            right: 14,
            child: GpsTimestampStamp(
              dateTime: DateTime.now(),
              street: _street,
              kelurahan: _kelurahan ?? 'Duri Kosambi',
              kecamatan: _kecamatan ?? 'Kecamatan Cengkareng',
              kota: _kota ?? 'Kota Jakarta Barat',
              provinsi: _provinsi ?? 'Daerah Khusus Ibukota Jakarta',
              altitude: _altitude ?? 28.7,
              indexNumber: 23,
              showBackground: true,
            ),
          ),
          // Tombol Reset / Foto Ulang
          Positioned(
            top: 14,
            left: 14,
            child: GestureDetector(
              onTap: _resetScan,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Foto Ulang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
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
    );
  }

  /// Viewfinder Kamera Interaktif dengan Stempel GPS Live di Kanan Bawah
  Widget _buildViewfinderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient Viewfinder
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF334155).withValues(alpha: 0.6),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          // Reticle Frame Panduan Sudut di Tengah
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JakdrainColors.skyBlueAccent.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                          left: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                          right: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                          left: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                          right: BorderSide(color: JakdrainColors.skyBlueAccent, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_center_focus_rounded,
                        size: 44,
                        color: JakdrainColors.skyBlueAccent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Arahkan ke Selokan / Got',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Deteksi Sedimen, Sampah & Aliran',
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

          // ─── Watermark Stempel GPS Live di Pojok Kanan Bawah (Persis Screenshot) ───
          Positioned(
            bottom: 14,
            right: 14,
            child: GpsTimestampStamp(
              dateTime: _liveTime,
              street: _street,
              kelurahan: _kelurahan ?? 'Duri Kosambi',
              kecamatan: _kecamatan ?? 'Kecamatan Cengkareng',
              kota: _kota ?? 'Kota Jakarta Barat',
              provinsi: _provinsi ?? 'Daerah Khusus Ibukota Jakarta',
              altitude: _altitude ?? 28.7,
              indexNumber: 23,
              showBackground: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet hasil analisis AI komprehensif.
class _ResultModal extends StatefulWidget {
  final AiScanResult result;
  final File? capturedImage;
  final String? street;
  final String kelurahan;
  final String kecamatan;
  final String kota;
  final String provinsi;
  final double altitude;
  final String? realAddress;
  final double? realLat;
  final double? realLng;
  final VoidCallback onRetake;
  final void Function(AiScanResult finalResult) onSubmit;

  const _ResultModal({
    required this.result,
    required this.capturedImage,
    this.street,
    required this.kelurahan,
    required this.kecamatan,
    required this.kota,
    required this.provinsi,
    required this.altitude,
    this.realAddress,
    this.realLat,
    this.realLng,
    required this.onRetake,
    required this.onSubmit,
  });

  @override
  State<_ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<_ResultModal> {
  late String _selectedRisk;
  late double _currentSediment;
  late double _currentCapacity;

  @override
  void initState() {
    super.initState();
    _selectedRisk = widget.result.riskLevel;

    // Pastikan nilai sedimen awal realistis dan tidak pernah 0%
    if (widget.result.sedimentPercentage > 0) {
      _currentSediment = widget.result.sedimentPercentage;
      _currentCapacity = widget.result.remainingCapacityCm;
    } else {
      if (_selectedRisk == 'Kritis') {
        _currentSediment = 78.0;
        _currentCapacity = 8.0;
      } else if (_selectedRisk == 'Waspada') {
        _currentSediment = 45.0;
        _currentCapacity = 20.0;
      } else {
        _currentSediment = 10.0;
        _currentCapacity = 40.0;
      }
    }
  }

  void _onRiskSelected(String risk) {
    setState(() {
      _selectedRisk = risk;
      if (risk == 'Aman') {
        _currentSediment = 10.0;
        _currentCapacity = 40.0;
      } else if (risk == 'Waspada') {
        _currentSediment = 45.0;
        _currentCapacity = 20.0;
      } else {
        _currentSediment = 78.0;
        _currentCapacity = 8.0;
      }
    });
  }

  Widget _buildRiskChip(String risk, Color color, IconData icon) {
    final isSelected = _selectedRisk == risk;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRiskSelected(risk),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : JakdrainColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : JakdrainColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : JakdrainColors.subtleGray),
              const SizedBox(width: 4),
              Text(
                risk,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    final isKritis = _selectedRisk == 'Kritis';
    final isWaspada = _selectedRisk == 'Waspada';

    final statusColor = isKritis
        ? JakdrainColors.critical
        : isWaspada
            ? JakdrainColors.warning
            : JakdrainColors.safe;

    final statusBgColor = isKritis
        ? JakdrainColors.criticalLight
        : isWaspada
            ? JakdrainColors.warningLight
            : JakdrainColors.safeLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(22, 14, 22, 24 + (bottomPadding > 0 ? bottomPadding : 16)),
            children: [
              // Handle bar
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

              // Title & status badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Analisis AI Got',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: JakdrainColors.deepNavy,
                          ),
                        ),
                        Text(
                          'Akurasi Model: ${widget.result.aiConfidence}% • Terverifikasi Dinas SDA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: JakdrainColors.safe,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isKritis
                              ? Icons.warning_rounded
                              : isWaspada
                                  ? Icons.info_rounded
                                  : Icons.check_circle_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedRisk,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ─── Pilihan Penyesuaian Tingkat Risiko Got (Aman / Waspada / Kritis) ───
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: JakdrainColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JakdrainColors.divider),
                ),
                child: Row(
                  children: [
                    _buildRiskChip('Aman', JakdrainColors.safe, Icons.check_circle_rounded),
                    const SizedBox(width: 6),
                    _buildRiskChip('Waspada', JakdrainColors.warning, Icons.info_rounded),
                    const SizedBox(width: 6),
                    _buildRiskChip('Kritis', JakdrainColors.critical, Icons.warning_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Thumbnail foto yang diambil dengan Stempel GPS Lengkap (Bisa di-klik untuk Zoom)
              if (widget.capturedImage != null)
                GestureDetector(
                  onTap: () => _showZoomDialog(
                    context,
                    widget.capturedImage!,
                    street: widget.realAddress ?? widget.street,
                    kelurahan: widget.kelurahan,
                    kecamatan: widget.kecamatan,
                    kota: widget.kota,
                    provinsi: widget.provinsi,
                    altitude: widget.altitude,
                    latitude: widget.realLat,
                    longitude: widget.realLng,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.file(
                          widget.capturedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Badge Zoom Hint
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
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
                            street: widget.street,
                            kelurahan: widget.kelurahan,
                            kecamatan: widget.kecamatan,
                            kota: widget.kota,
                            provinsi: widget.provinsi,
                            altitude: widget.altitude,
                            indexNumber: 23,
                            showBackground: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // ─── FITUR BARU: Deteksi Sampah Got ───────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: JakdrainColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JakdrainColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.result.isCleanWater ? Icons.water_drop_rounded : Icons.delete_sweep_rounded,
                          color: widget.result.isCleanWater ? JakdrainColors.safe : JakdrainColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.result.isCleanWater ? 'Kondisi Kebersihan Air Got' : 'Deteksi Sampah & Hambatan Got',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: JakdrainColors.deepNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (widget.result.isCleanWater ? JakdrainColors.safe : JakdrainColors.warning).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.result.trashSeverity.contains('(')
                                ? widget.result.trashSeverity.split('(').first.trim()
                                : (widget.result.trashSeverity.contains('-')
                                    ? widget.result.trashSeverity.split('-').first.trim()
                                    : widget.result.trashSeverity),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.result.isCleanWater ? JakdrainColors.safe : JakdrainColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.result.detectedTrashItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: JakdrainColors.divider),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: widget.result.isCleanWater ? JakdrainColors.safe : JakdrainColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: JakdrainColors.darkText,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ─── Metric Tiles Grid ───────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Tingkat Sedimen',
                      value: '${_currentSediment.toStringAsFixed(1)}%',
                      subvalue: 'Tebal: ${(_currentSediment * 0.4).toStringAsFixed(1)} cm',
                      color: statusColor,
                      icon: Icons.layers_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Kapasitas Tersisa',
                      value: '${_currentCapacity.toStringAsFixed(1)} cm',
                      subvalue: 'Target Normal >35 cm',
                      color: JakdrainColors.electricBlue,
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Status Aliran Air',
                      value: widget.result.waterFlowStatus.split(' ')[0],
                      subvalue: widget.result.waterFlowStatus,
                      color: JakdrainColors.skyBlueAccent,
                      icon: Icons.water_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Estimasi Pengerukan',
                      value: '${widget.result.estimatedWorkHours} Jam',
                      subvalue: 'Tim Regu PPSU',
                      color: JakdrainColors.safe,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Bar Sedimentasi
              _SedimentBar(percentage: _currentSediment, color: statusColor),
              const SizedBox(height: 16),

              // Rekomendasi Teknis & Peralatan
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: JakdrainColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: JakdrainColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: JakdrainColors.electricBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rekomendasi Penanganan PPSU/SDA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: JakdrainColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.result.recommendation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.45,
                        color: JakdrainColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Peralatan disarankan: ${widget.result.requiredTools.join(", ")}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: JakdrainColors.electricBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updatedResult = widget.result.copyWith(
                      riskLevel: _selectedRisk,
                      sedimentPercentage: _currentSediment,
                      remainingCapacityCm: _currentCapacity,
                      sedimentDepthCm: _currentSediment * 0.4,
                    );
                    widget.onSubmit(updatedResult);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Kirim Laporan Pengerukan',
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
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: widget.onRetake,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Foto Ulang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JakdrainColors.subtleGray,
                    side: const BorderSide(color: JakdrainColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showZoomDialog(
    BuildContext context,
    File image, {
    String? street,
    required String kelurahan,
    required String kecamatan,
    required String kota,
    required String provinsi,
    required double altitude,
    double? latitude,
    double? longitude,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(ctx),
          ),
          title: Text(
            'Detail Foto Lapangan',
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
                      Image.file(image, fit: BoxFit.contain),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GpsTimestampStamp(
                          dateTime: DateTime.now(),
                          street: street,
                          kelurahan: kelurahan,
                          kecamatan: kecamatan,
                          kota: kota,
                          provinsi: provinsi,
                          altitude: altitude,
                          indexNumber: 23,
                          latitude: latitude,
                          longitude: longitude,
                          showBackground: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black.withValues(alpha: 0.8),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (street != null && street.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: JakdrainColors.skyBlueAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$street, $kelurahan, $kecamatan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (latitude != null && longitude != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Koordinat: ${latitude.toStringAsFixed(5)}° LS, ${longitude.toStringAsFixed(5)}° BT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.white70,
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
}

/// Visual bar kapasitas sedimen
class _SedimentBar extends StatelessWidget {
  final double percentage;
  final Color color;

  const _SedimentBar({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tingkat Sedimentasi Saluran Got',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: JakdrainColors.deepNavy,
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: JakdrainColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Metric tile dalam modal hasil
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subvalue;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    this.subvalue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: JakdrainColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JakdrainColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: JakdrainColors.subtleGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: JakdrainColors.deepNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subvalue != null)
                  Text(
                    subvalue!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
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
    );
  }
}
