// ============================================================
// Jakdrain — Firebase Service
// Autentikasi Firebase (Google, Email/Password, Tamu) & Cloud Firestore.
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:jakdrain/data/models.dart';
import 'package:jakdrain/providers/user_provider.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentFirebaseUser => _auth.currentUser;

  /// 1. Login dengan Akun Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Dibatalkan pengguna

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userModel = UserModel(
          name: user.displayName ?? 'Petugas Google',
          nipOrNik: 'GGL-${user.uid.substring(0, 8).toUpperCase()}',
          region: 'Suku Dinas SDA DKI Jakarta',
          phoneNumber: user.phoneNumber ?? 'Terhubung Google',
          isDemoMode: false,
          joinedDate: 'Terdaftar Google',
          totalInspections: 0,
          resolvedCount: 0,
        );

        // Simpan / update ke Firestore
        await saveOfficerProfile(userModel, user.uid);
        await recordLoginLog(officer: userModel, loginMethod: 'Google Sign-In');
        return userModel;
      }
    } catch (e) {
      debugPrint('Error signInWithGoogle: $e');
      rethrow;
    }
    return null;
  }

  /// 2. Daftar Akun Petugas dengan Email & Password
  static Future<UserModel> registerOfficer({
    required String email,
    required String password,
    required String name,
    required String nip,
    required String region,
    required String phone,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user!;
    await user.updateDisplayName(name);

    final userModel = UserModel(
      name: name,
      nipOrNik: nip,
      region: region,
      phoneNumber: phone,
      isDemoMode: false,
      joinedDate: 'Aktif 2026',
      totalInspections: 0,
      resolvedCount: 0,
    );

    await saveOfficerProfile(userModel, user.uid);
    return userModel;
  }

  /// 3. Login Petugas dengan Email & Password
  static Future<UserModel?> loginOfficer({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user != null) {
      // Ambil data petugas dari Firestore
      try {
        final doc =
            await _firestore.collection('officers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          return UserModel(
            name: data['name'] ?? user.displayName ?? 'Petugas PPSU',
            nipOrNik: data['nip'] ?? 'PPSU-RESMI',
            region: data['region'] ?? 'Suku Dinas SDA DKI',
            phoneNumber: data['phone'] ?? '-',
            isDemoMode: false,
            joinedDate: data['joinedDate'] ?? '2026',
            totalInspections: data['totalInspections'] ?? 0,
            resolvedCount: data['resolvedCount'] ?? 0,
          );
        }
      } catch (_) {}

      return UserModel(
        name: user.displayName ?? 'Petugas PPSU',
        nipOrNik: 'PPSU-${user.uid.substring(0, 6)}',
        region: 'Suku Dinas SDA DKI',
        phoneNumber: '-',
        isDemoMode: false,
        joinedDate: '2026',
      );
    }
    return null;
  }

  /// 4. Login Mode Tamu / Demo Cepat (Anonymous)
  static Future<UserModel> signInAnonymous() async {
    final UserCredential credential = await _auth.signInAnonymously();
    final user = credential.user!;

    return UserModel(
      name: 'Petugas Demo (${user.uid.substring(0, 5)})',
      nipOrNik: 'DEMO-${user.uid.substring(0, 5).toUpperCase()}',
      region: 'Suku Dinas SDA Jakarta Pusat (Demo)',
      phoneNumber: '0812-DEMO-0000',
      isDemoMode: true,
      joinedDate: 'Mode Tamu Firebase',
      totalInspections: 142,
      resolvedCount: 128,
    );
  }

  /// 5. Simpan / Perbarui Profil Petugas ke Firestore
  static Future<void> saveOfficerProfile(UserModel officer, [String? customDocId]) async {
    try {
      final docId = customDocId ?? officer.nipOrNik.replaceAll('/', '-').trim();
      await _firestore.collection('officers').doc(docId).set({
        'name': officer.name,
        'nip': officer.nipOrNik,
        'region': officer.region,
        'phone': officer.phoneNumber,
        'isDemo': officer.isDemoMode,
        'joinedDate': officer.joinedDate,
        'totalInspections': officer.totalInspections,
        'resolvedCount': officer.resolvedCount,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Profil petugas berhasil disimpan ke Firestore: $docId');
    } catch (e) {
      debugPrint('Error saveOfficerProfile: $e');
    }
  }

  /// Ambil data profil petugas dari Firestore berdasarkan NIP
  static Future<Map<String, dynamic>?> getOfficerProfile(String nipOrNik) async {
    try {
      final docId = nipOrNik.replaceAll('/', '-').trim();
      final doc = await _firestore.collection('officers').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  /// Verifikasi Login Petugas secara ketat: Nama & NIP wajib cocok dengan Database
  static Future<({bool success, UserModel? user, String message})> verifyOfficerCredentials({
    required String enteredName,
    required String enteredNip,
    Map<String, UserModel>? localRegistry,
  }) async {
    final cleanName = enteredName.trim();
    final cleanNip = enteredNip.trim();

    if (cleanName.isEmpty || cleanNip.isEmpty) {
      return (
        success: false,
        user: null,
        message: 'Nama Lengkap dan NIP wajib diisi!',
      );
    }

    try {
      // 1. Cek Firestore berdasarkan NIP (Doc ID atau field 'nip')
      Map<String, dynamic>? dataByNip = await getOfficerProfile(cleanNip);
      if (dataByNip == null) {
        final querySnap = await _firestore
            .collection('officers')
            .where('nip', isEqualTo: cleanNip)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          dataByNip = querySnap.docs.first.data();
        }
      }

      // 2. Cek Firestore apakah nama terdaftar dengan NIP berbeda
      Map<String, dynamic>? dataByName;
      try {
        final queryNameSnap = await _firestore
            .collection('officers')
            .where('name', isEqualTo: cleanName)
            .limit(1)
            .get();
        if (queryNameSnap.docs.isNotEmpty) {
          dataByName = queryNameSnap.docs.first.data();
        }
      } catch (_) {}

      // Evaluasi data Firestore
      if (dataByNip != null) {
        final registeredName = (dataByNip['name'] ?? '').toString().trim();
        // Cek kecocokan nama (case-insensitive)
        if (registeredName.toLowerCase() == cleanName.toLowerCase()) {
          final user = UserModel(
            name: registeredName,
            nipOrNik: (dataByNip['nip'] ?? cleanNip).toString().trim(),
            region: dataByNip['region'] ?? 'Suku Dinas SDA DKI Jakarta',
            phoneNumber: dataByNip['phone'] ?? '-',
            isDemoMode: false,
            joinedDate: dataByNip['joinedDate'] ?? 'Terdaftar Resmi',
            totalInspections: (dataByNip['totalInspections'] as num?)?.toInt() ?? 0,
            resolvedCount: (dataByNip['resolvedCount'] as num?)?.toInt() ?? 0,
          );
          return (success: true, user: user, message: 'Verifikasi Database Berhasil');
        } else {
          return (
            success: false,
            user: null,
            message: 'NIP $cleanNip terdaftar atas nama "$registeredName", bukan "$cleanName". Pastikan Nama & NIP sesuai!',
          );
        }
      }

      if (dataByName != null) {
        return (
          success: false,
          user: null,
          message: 'Petugas "$cleanName" terdaftar di database, tetapi NIP yang Anda masukkan salah. Pastikan NIP sesuai dengan saat pendaftaran!',
        );
      }
    } catch (e) {
      debugPrint('Firestore verification note: $e');
    }

    // 3. Fallback ke Local Registry (jika offline atau Firestore belum sinkron)
    if (localRegistry != null) {
      if (localRegistry.containsKey(cleanNip)) {
        final localUser = localRegistry[cleanNip]!;
        if (localUser.name.toLowerCase() == cleanName.toLowerCase()) {
          return (success: true, user: localUser, message: 'Login Berhasil (Database Lokal)');
        } else {
          return (
            success: false,
            user: null,
            message: 'NIP $cleanNip terdaftar atas nama "${localUser.name}", bukan "$cleanName". Data tidak cocok!',
          );
        }
      }

      for (final localUser in localRegistry.values) {
        if (localUser.name.toLowerCase() == cleanName.toLowerCase()) {
          return (
            success: false,
            user: null,
            message: 'Petugas "$cleanName" terdaftar dengan NIP "${localUser.nipOrNik}", bukan "$cleanNip". Mohon periksa kembali NIP Anda!',
          );
        }
      }
    }

    return (
      success: false,
      user: null,
      message: 'Akun "$cleanName" dengan NIP "$cleanNip" belum terdaftar di database. Silakan klik "Daftar Petugas Baru" terlebih dahulu!',
    );
  }

  /// Catat Setiap Sesi Login Petugas ke Koleksi 'login_activity' Firestore
  static Future<void> recordLoginLog({
    required UserModel officer,
    required String loginMethod,
  }) async {
    try {
      await _firestore.collection('login_activity').add({
        'officerName': officer.name,
        'nip': officer.nipOrNik,
        'region': officer.region,
        'phone': officer.phoneNumber,
        'isDemo': officer.isDemoMode,
        'loginMethod': loginMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'clientDevice': 'Aplikasi Mobile Jakdrain (Android)',
        'status': 'Berhasil Masuk',
      });
      debugPrint('Log aktivitas login berhasil disimpan ke Firestore untuk ${officer.name}');
    } catch (e) {
      debugPrint('Error recordLoginLog: $e');
    }
  }

  /// 6. Simpan Laporan Hasil Scan Got ke Firestore
  static Future<void> saveDrainageReport(DrainageReport report) async {
    try {
      final docRef = _firestore.collection('drainage_reports').doc(report.id);
      await docRef.set({
        ...report.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Laporan berhasil disimpan ke Firestore: ${report.id}');
    } catch (e) {
      debugPrint('Error saveDrainageReport: $e');
      rethrow;
    }
  }

  /// 7. Stream Realtime Seluruh Laporan Drainase dari Firestore
  static Stream<List<DrainageReport>> streamDrainageReports() {
    return _firestore
        .collection('drainage_reports')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DrainageReport.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// 8. Update Status Tugas PPSU di Firestore
  static Future<void> updateReportTaskStatus({
    required String reportId,
    required TaskStatus newStatus,
  }) async {
    try {
      await _firestore
          .collection('drainage_reports')
          .doc(reportId)
          .update({'taskStatus': newStatus.name});
    } catch (e) {
      debugPrint('Error updateReportTaskStatus: $e');
    }
  }

  /// 9. Sinkronisasi Data Awal (Seed) ke Firestore
  /// Berguna untuk mengisi database kosong agar langsung muncul di Firebase Console!
  static Future<int> seedSampleReportsToFirestore(List<DrainageReport> reports) async {
    try {
      final batch = _firestore.batch();
      for (final report in reports) {
        final docRef = _firestore.collection('drainage_reports').doc(report.id);
        batch.set(docRef, {
          ...report.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Berhasil seed ${reports.length} laporan ke Firestore');
      return reports.length;
    } catch (e) {
      debugPrint('Error seeding sample reports to Firestore: $e');
      rethrow;
    }
  }

  /// 7. Logout Firebase & Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
