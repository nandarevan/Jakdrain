// ============================================================
// Jakdrain — User Provider
// Manajemen sesi petugas PPSU (Akun Terdaftar vs Akun Demo)
// Dilengkapi persistensi sesi SharedPreferences dan proteksi timeout 2 menit.
// ============================================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String name;
  final String nipOrNik;
  final String region;
  final String phoneNumber;
  final bool isDemoMode;
  final String joinedDate;
  int totalInspections;
  int resolvedCount;

  UserModel({
    required this.name,
    required this.nipOrNik,
    required this.region,
    required this.phoneNumber,
    this.isDemoMode = false,
    required this.joinedDate,
    this.totalInspections = 0,
    this.resolvedCount = 0,
  });

  /// Akun Demo default
  factory UserModel.demo() {
    return UserModel(
      name: 'Ahmad Fauzi (Demo)',
      nipOrNik: 'PPSU-3174-DEMO',
      region: 'Suku Dinas SDA Jakarta Pusat',
      phoneNumber: '0812-3456-7890',
      isDemoMode: true,
      joinedDate: 'Oktober 2024',
      totalInspections: 142,
      resolvedCount: 128,
    );
  }
}

class UserProvider extends ChangeNotifier {
  static const int sessionTimeoutSeconds = 120; // Wajib: tepat 2 menit tidak aktif

  static const String _kLoggedIn = 'jakdrain_session_logged_in';
  static const String _kNip = 'jakdrain_session_nip';
  static const String _kName = 'jakdrain_session_name';
  static const String _kRegion = 'jakdrain_session_region';
  static const String _kPhone = 'jakdrain_session_phone';
  static const String _kJoined = 'jakdrain_session_joined';
  static const String _kIsDemo = 'jakdrain_session_is_demo';
  static const String _kInspections = 'jakdrain_session_inspections';
  static const String _kResolved = 'jakdrain_session_resolved';
  static const String _kLastActiveEpoch = 'jakdrain_session_last_active_epoch';

  UserModel _currentUser = UserModel.demo();
  bool _isLoggedIn = false;
  bool _sessionInitialized = false;
  bool _sessionExpiredNotice = false;
  int _lastActiveEpoch = 0;
  Timer? _inactivityCheckerTimer;

  /// Database Petugas Terdaftar (Disinkronkan dengan Firestore)
  final Map<String, UserModel> _registeredOfficers = {
    '312020292': UserModel(
      name: 'Ahmad Budi Santoso',
      nipOrNik: '312020292',
      region: 'Suku Dinas SDA Jakarta Pusat',
      phoneNumber: '0812-9988-7766',
      isDemoMode: false,
      joinedDate: 'Januari 2024',
      totalInspections: 24,
      resolvedCount: 21,
    ),
  };

  UserModel get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isDemoMode => _currentUser.isDemoMode;
  bool get sessionInitialized => _sessionInitialized;
  bool get sessionExpiredNotice => _sessionExpiredNotice;
  Map<String, UserModel> get registeredOfficers => Map.unmodifiable(_registeredOfficers);

  void dismissExpiredNotice() {
    _sessionExpiredNotice = false;
    notifyListeners();
  }

  /// Inisialisasi sesi saat startup aplikasi
  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool(_kLoggedIn) ?? false;

      if (wasLoggedIn) {
        final lastActive = prefs.getInt(_kLastActiveEpoch) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSeconds = (now - lastActive) / 1000.0;

        // Jika jeda waktu BELUM LEBIH dari 2 menit (120 detik), pertahankan login!
        if (elapsedSeconds < sessionTimeoutSeconds) {
          final isDemo = prefs.getBool(_kIsDemo) ?? false;
          if (isDemo) {
            _currentUser = UserModel.demo();
          } else {
            final nip = prefs.getString(_kNip) ?? '';
            final name = prefs.getString(_kName) ?? 'Petugas PPSU';
            final region = prefs.getString(_kRegion) ?? 'Suku Dinas SDA DKI Jakarta';
            final phone = prefs.getString(_kPhone) ?? '0812-XXXX-XXXX';
            final joined = prefs.getString(_kJoined) ?? 'Aktif 2026';
            final inspections = prefs.getInt(_kInspections) ?? 0;
            final resolved = prefs.getInt(_kResolved) ?? 0;

            final restoredUser = UserModel(
              name: name,
              nipOrNik: nip,
              region: region,
              phoneNumber: phone,
              isDemoMode: false,
              joinedDate: joined,
              totalInspections: inspections,
              resolvedCount: resolved,
            );
            if (nip.isNotEmpty) {
              _registeredOfficers[nip] = restoredUser;
            }
            _currentUser = restoredUser;
          }
          _isLoggedIn = true;
          _lastActiveEpoch = now;
          await prefs.setInt(_kLastActiveEpoch, now);
          _startInactivityChecker();
        } else {
          // Lebih dari 2 menit: Sesi harus login ulang
          _isLoggedIn = false;
          _sessionExpiredNotice = true;
          await _clearStoredSession(prefs);
        }
      }
    } catch (e) {
      debugPrint('Error initSession: $e');
    } finally {
      _sessionInitialized = true;
      notifyListeners();
    }
  }

  /// Mulai timer berkala pengecekan ketidakaktifan (setiap 5 detik)
  void _startInactivityChecker() {
    _inactivityCheckerTimer?.cancel();
    _inactivityCheckerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkSessionValidity();
    });
  }

  /// Periksa apakah sudah tidak aktif LEBIH DARI 2 MENIT
  void checkSessionValidity() {
    if (!_isLoggedIn) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastActiveEpoch > 0) {
      final elapsedSeconds = (now - _lastActiveEpoch) / 1000.0;
      // Lebih dari 2 menit: logout otomatis
      if (elapsedSeconds >= sessionTimeoutSeconds) {
        logout(dueToTimeout: true);
      }
    }
  }

  int _lastPersistedEpoch = 0;

  /// Perbarui waktu aktivitas terakhir (setiap ada interaksi / sentuhan layar)
  void updateActiveTimestamp({bool forcePersist = false}) {
    if (!_isLoggedIn) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastActiveEpoch = now;

    // Optimasi disk I/O: Simpan ke SharedPreferences maksimal hanya tiap 15 detik
    if (forcePersist || (now - _lastPersistedEpoch > 15000)) {
      _lastPersistedEpoch = now;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_kLastActiveEpoch, now);
      }).catchError((_) {});
    }
  }

  /// Simpan data sesi ke SharedPreferences
  Future<void> _persistSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastActiveEpoch = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(_kLoggedIn, true);
      await prefs.setString(_kNip, user.nipOrNik);
      await prefs.setString(_kName, user.name);
      await prefs.setString(_kRegion, user.region);
      await prefs.setString(_kPhone, user.phoneNumber);
      await prefs.setString(_kJoined, user.joinedDate);
      await prefs.setBool(_kIsDemo, user.isDemoMode);
      await prefs.setInt(_kInspections, user.totalInspections);
      await prefs.setInt(_kResolved, user.resolvedCount);
      await prefs.setInt(_kLastActiveEpoch, _lastActiveEpoch);
      _sessionExpiredNotice = false;
      _startInactivityChecker();
    } catch (e) {
      debugPrint('Error persistSession: $e');
    }
  }

  /// Bersihkan data sesi
  Future<void> _clearStoredSession(SharedPreferences prefs) async {
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kNip);
    await prefs.remove(_kName);
    await prefs.remove(_kRegion);
    await prefs.remove(_kPhone);
    await prefs.remove(_kJoined);
    await prefs.remove(_kIsDemo);
    await prefs.remove(_kInspections);
    await prefs.remove(_kResolved);
    await prefs.remove(_kLastActiveEpoch);
  }

  /// Registrasi akun baru petugas PPSU
  void registerUser({
    required String name,
    required String nipOrNik,
    required String region,
    required String phoneNumber,
  }) {
    final newUser = UserModel(
      name: name.trim(),
      nipOrNik: nipOrNik.trim(),
      region: region.trim(),
      phoneNumber: phoneNumber.trim(),
      isDemoMode: false,
      joinedDate: 'Hari Ini (Baru Terdaftar)',
      totalInspections: 0,
      resolvedCount: 0,
    );
    _registeredOfficers[nipOrNik.trim()] = newUser;
    _currentUser = newUser;
    _isLoggedIn = true;
    _persistSession(newUser);
    notifyListeners();
  }

  /// Set user aktif setelah verifikasi database berhasil
  void setCurrentUser(UserModel user) {
    _registeredOfficers[user.nipOrNik.trim()] = user;
    _currentUser = user;
    _isLoggedIn = true;
    _persistSession(user);
    notifyListeners();
  }

  /// Ambil profil petugas terdaftar berdasarkan NIP
  UserModel? getOfficerByNip(String nip) {
    return _registeredOfficers[nip.trim()];
  }

  /// Cari petugas terdaftar berdasarkan Nama (case-insensitive)
  UserModel? getOfficerByName(String name) {
    final search = name.trim().toLowerCase();
    for (final officer in _registeredOfficers.values) {
      if (officer.name.trim().toLowerCase() == search) {
        return officer;
      }
    }
    return null;
  }

  /// Login dengan NIP / NIK yang sudah ada
  void loginWithId(String nipOrNik, {String? name}) {
    final cleanNip = nipOrNik.trim();
    if (cleanNip.isEmpty || cleanNip.toLowerCase().contains('demo')) {
      _currentUser = UserModel.demo();
    } else if (_registeredOfficers.containsKey(cleanNip)) {
      _currentUser = _registeredOfficers[cleanNip]!;
    } else {
      String resolvedName = name != null && name.trim().isNotEmpty
          ? name.trim()
          : 'Petugas PPSU ($cleanNip)';
      final user = UserModel(
        name: resolvedName,
        nipOrNik: cleanNip,
        region: 'Suku Dinas SDA DKI Jakarta',
        phoneNumber: '0812-XXXX-XXXX',
        isDemoMode: false,
        joinedDate: 'Aktif 2026',
        totalInspections: 0,
        resolvedCount: 0,
      );
      _registeredOfficers[cleanNip] = user;
      _currentUser = user;
    }
    _isLoggedIn = true;
    _persistSession(_currentUser);
    notifyListeners();
  }

  /// Masuk dengan mode demo cepat
  void loginDemo() {
    _currentUser = UserModel.demo();
    _isLoggedIn = true;
    _persistSession(_currentUser);
    notifyListeners();
  }

  /// Logout (bisa manual atau karena timeout 2 menit)
  void logout({bool dueToTimeout = false}) {
    _inactivityCheckerTimer?.cancel();
    _currentUser = UserModel.demo();
    _isLoggedIn = false;
    _sessionExpiredNotice = dueToTimeout;
    SharedPreferences.getInstance().then((prefs) => _clearStoredSession(prefs)).catchError((_) {});
    notifyListeners();
  }

  /// Menambah riwayat inspeksi
  void incrementInspection() {
    _currentUser.totalInspections++;
    updateActiveTimestamp();
    notifyListeners();
  }
}
