// ============================================================
// Jakdrain — Camera & Permission Service
// Layanan Kamera Native Android, Izin Runtime, dan Buka Pengaturan HP.
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jakdrain/core/theme.dart';

class JakdrainCameraService {
  static const MethodChannel _channel = MethodChannel('jakdrain/camera');

  /// Memeriksa apakah izin kamera sudah diberikan
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>('checkCameraPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Meminta izin kamera via prompt runtime OS
  static Future<bool> requestCameraPermission() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestCameraPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka langsung halaman App Info / Perizinan Aplikasi di Pengaturan HP
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  /// Mengambil lokasi GPS riil dari perangkat HP
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final Map<dynamic, dynamic>? loc =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation');
      if (loc != null) {
        return {
          'latitude': (loc['latitude'] as num?)?.toDouble() ?? -6.1754,
          'longitude': (loc['longitude'] as num?)?.toDouble() ?? 106.8272,
          'altitude': (loc['altitude'] as num?)?.toDouble() ?? 28.7,
          'street': loc['street'] as String? ?? 'Duri Kosambi',
          'kelurahan': loc['kelurahan'] as String? ?? 'Duri Kosambi',
          'kecamatan': loc['kecamatan'] as String? ?? 'Kecamatan Cengkareng',
          'kota': loc['kota'] as String? ?? 'Kota Jakarta Barat',
          'provinsi': loc['provinsi'] as String? ?? 'Daerah Khusus Ibukota Jakarta',
          'address': loc['address'] as String? ?? 'Duri Kosambi, Cengkareng',
          'isReal': loc['isReal'] as bool? ?? false,
        };
      }
    } catch (_) {}
    return {
      'latitude': -6.1754,
      'longitude': 106.8272,
      'altitude': 28.7,
      'street': 'Duri Kosambi',
      'kelurahan': 'Duri Kosambi',
      'kecamatan': 'Kecamatan Cengkareng',
      'kota': 'Kota Jakarta Barat',
      'provinsi': 'Daerah Khusus Ibukota Jakarta',
      'address': 'Duri Kosambi, Cengkareng',
      'isReal': false,
    };
  }

  /// Mengambil foto fisik via Kamera HP dengan pengecekan izin otomatis
  static Future<File?> takePhoto(BuildContext context) async {
    final hasPermission = await isCameraPermissionGranted();
    if (!hasPermission) {
      if (!context.mounted) return null;
      final granted = await showPermissionDialog(context);
      if (!granted) return null;
    }

    try {
      final String? photoPath = await _channel.invokeMethod<String>('takePhoto');
      if (photoPath != null && File(photoPath).existsSync()) {
        return File(photoPath);
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        if (context.mounted) {
          await showPermissionDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error takePhoto: $e');
    }
    return null;
  }

  /// Memilih foto dari Galeri
  static Future<File?> pickFromGallery() async {
    try {
      final String? photoPath = await _channel.invokeMethod<String>('pickGallery');
      if (photoPath != null && File(photoPath).existsSync()) {
        return File(photoPath);
      }
    } catch (e) {
      debugPrint('Error pickGallery: $e');
    }
    return null;
  }

  /// Dialog Persetujuan Izin Kamera & Arahkan ke Pengaturan HP
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionSheet(),
    ) ?? false;
  }
}

class _PermissionSheet extends StatefulWidget {
  @override
  State<_PermissionSheet> createState() => _PermissionSheetState();
}

class _PermissionSheetState extends State<_PermissionSheet> with WidgetsBindingObserver {
  bool _hasOpenedSettings = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusAndAutoProceed();
    }
  }

  Future<void> _checkStatusAndAutoProceed() async {
    setState(() => _isChecking = true);
    final granted = await JakdrainCameraService.isCameraPermissionGranted();
    if (mounted) {
      setState(() => _isChecking = false);
      if (granted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
          const SizedBox(height: 20),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JakdrainColors.electricBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 28,
                  color: JakdrainColors.electricBlue,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JakdrainColors.safe.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 28,
                  color: JakdrainColors.safe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Aktivasi Izin Kamera & Lokasi GPS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: JakdrainColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Untuk mengambil foto bukti fisik dan mencatat titik koordinat GPS riil HP saat pemotretan (mencegah manipulasi lokasi), mohon aktifkan izin Kamera & Lokasi perangkat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: JakdrainColors.subtleGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),

          // Langkah Aktivasi Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: JakdrainColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JakdrainColors.divider),
            ),
            child: Column(
              children: [
                _buildStepRow(
                  number: '1',
                  text: 'Ketuk tombol "Minta Izin Sistem Langsung" atau "Buka Pengaturan HP".',
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  number: '2',
                  text: 'Pilih "Izinkan" untuk akses Kamera dan Lokasi (Saat Aplikasi Digunakan).',
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  number: '3',
                  text: 'Kamera langsung terbuka dengan cap stempel lokasi GPS riil di foto!',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Tombol 1: Buka Pengaturan HP
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                setState(() => _hasOpenedSettings = true);
                await JakdrainCameraService.openAppSettings();
              },
              icon: const Icon(Icons.settings_outlined, size: 20),
              label: Text(
                'Buka Pengaturan Izin HP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JakdrainColors.electricBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol 2: Cek Izin / Minta Izin OS Langsung
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isChecking
                  ? null
                  : () async {
                      if (_hasOpenedSettings) {
                        await _checkStatusAndAutoProceed();
                        final granted = await JakdrainCameraService.isCameraPermissionGranted();
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Izin kamera belum aktif di pengaturan HP. Silakan aktifkan izin kamera terlebih dahulu.'),
                              backgroundColor: JakdrainColors.critical,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        final granted = await JakdrainCameraService.requestCameraPermission();
                        if (context.mounted) {
                          if (granted) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() => _hasOpenedSettings = true);
                            await JakdrainCameraService.openAppSettings();
                          }
                        }
                      }
                    },
              icon: Icon(
                _hasOpenedSettings ? Icons.check_circle_outline_rounded : Icons.lock_open_rounded,
                size: 18,
                color: _hasOpenedSettings ? JakdrainColors.safe : JakdrainColors.electricBlue,
              ),
              label: Text(
                _hasOpenedSettings ? 'Saya Sudah Aktifkan, Cek & Buka Kamera' : 'Minta Izin Sistem Langsung',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hasOpenedSettings ? JakdrainColors.safe : JakdrainColors.electricBlue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _hasOpenedSettings ? JakdrainColors.safe : JakdrainColors.electricBlue,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JakdrainColors.electricBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: JakdrainColors.electricBlue,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: JakdrainColors.darkText,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
