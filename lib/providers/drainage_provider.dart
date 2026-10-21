// ============================================================
// Jakdrain — Drainage Provider
// Sinkronisasi Data Laporan Drainase & Cloud Firestore Realtime.
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jakdrain/core/firebase_service.dart';
import 'package:jakdrain/data/models.dart';

class DrainageProvider extends ChangeNotifier {
  List<DrainageReport> _reports = MockData.sampleReports;
  bool _isLoading = false;
  bool _isSeeding = false;
  bool _isFirestoreConnected = false;
  String? _errorMessage;
  StreamSubscription<List<DrainageReport>>? _firestoreSubscription;

  DrainageProvider() {
    _initFirestoreListener();
  }

  List<DrainageReport> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isSeeding => _isSeeding;
  bool get isFirestoreConnected => _isFirestoreConnected;
  String? get errorMessage => _errorMessage;

  List<DrainageReport> get kritisReports =>
      _reports.where((r) => r.status == DrainageStatus.kritis).toList();

  List<DrainageReport> get waspadaReports =>
      _reports.where((r) => r.status == DrainageStatus.waspada).toList();

  List<DrainageReport> get amanReports =>
      _reports.where((r) => r.status == DrainageStatus.aman).toList();

  int get pengerukanCount =>
      _reports.where((r) => r.taskStatus == TaskStatus.dalamPengerukan).length;

  int get selesaiCount =>
      _reports.where((r) => r.taskStatus == TaskStatus.selesai).length;

  double get averageSediment {
    if (_reports.isEmpty) return 0.0;
    final total = _reports.fold<double>(0.0, (acc, r) => acc + r.sedimentPercentage);
    return (total / _reports.length);
  }

  /// Listen to Cloud Firestore real-time updates
  void _initFirestoreListener() {
    try {
      _firestoreSubscription = FirebaseService.streamDrainageReports().listen(
        (firestoreReports) {
          _isFirestoreConnected = true;
          _errorMessage = null;

          // Gabungkan data Cloud Firestore dengan 7 titik pantau standar DKI Jakarta
          // Laporan dari Firestore diutamakan jika ID-nya sama
          final Map<String, DrainageReport> mergedMap = {};
          for (final report in MockData.sampleReports) {
            mergedMap[report.id] = report;
          }
          for (final report in firestoreReports) {
            mergedMap[report.id] = report;
          }

          _reports = mergedMap.values.toList();
          // Urutkan: laporan yang baru diinspeksi/diupdate tampil teratas
          _reports.sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore stream error: $err');
          _isFirestoreConnected = false;
          _errorMessage = err.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Firestore initialization error: $e');
      _isFirestoreConnected = false;
    }
  }

  /// Menambah laporan baru ke Firestore & memicu notifikasi
  Future<bool> addNewReport(DrainageReport newReport) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simpan langsung ke Cloud Firestore
      await FirebaseService.saveDrainageReport(newReport);

      // Update data lokal jika belum otomatis ter-stream
      final existingIndex = _reports.indexWhere((r) => r.id == newReport.id);
      if (existingIndex >= 0) {
        _reports[existingIndex] = newReport;
      } else {
        _reports = [newReport, ..._reports];
      }
      _isFirestoreConnected = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Gagal simpan ke Firestore: $e. Menyimpan ke cache lokal.');
      // Tetap simpan secara lokal agar operasional petugas tidak terganggu
      _reports = [newReport, ..._reports];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mengubah status tugas PPSU (contoh: dari baruDilihat -> dalamPengerukan -> selesai)
  Future<void> updateTaskStatus(String reportId, TaskStatus newStatus) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final updated = _reports[index].copyWith(taskStatus: newStatus);
      _reports[index] = updated;
      notifyListeners();

      try {
        await FirebaseService.updateReportTaskStatus(
          reportId: reportId,
          newStatus: newStatus,
        );
      } catch (e) {
        debugPrint('Error updating status in Firestore: $e');
      }
    }
  }

  /// Menyelesaikan tugas PPSU dengan foto bukti, catatan pesan, dan pembaruan tingkat risiko
  Future<void> completeTaskWithProof({
    required String reportId,
    required DrainageStatus newStatus,
    required double newSedimentPercentage,
    required double newRemainingCapacityCm,
    String? proofImagePath,
    String? officerNotes,
    required String completedBy,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final updated = _reports[index].copyWith(
        taskStatus: TaskStatus.selesai,
        status: newStatus,
        sedimentPercentage: newSedimentPercentage,
        remainingCapacityCm: newRemainingCapacityCm,
        proofImagePath: proofImagePath,
        officerNotes: officerNotes,
        completedAt: DateTime.now(),
        completedBy: completedBy,
      );
      _reports[index] = updated;
      notifyListeners();

      try {
        await FirebaseService.saveDrainageReport(updated);
      } catch (e) {
        debugPrint('Error saving completed report to Firestore: $e');
      }
    }
  }

  /// Memperbarui tingkat risiko dan status laporan secara fleksibel
  Future<void> updateReportRiskAndStatus({
    required String reportId,
    required DrainageStatus newRiskStatus,
    TaskStatus? taskStatus,
    double? sedimentPercentage,
    double? remainingCapacityCm,
    String? proofImagePath,
    String? officerNotes,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final updated = _reports[index].copyWith(
        status: newRiskStatus,
        taskStatus: taskStatus ?? _reports[index].taskStatus,
        sedimentPercentage: sedimentPercentage ?? _reports[index].sedimentPercentage,
        remainingCapacityCm: remainingCapacityCm ?? _reports[index].remainingCapacityCm,
        proofImagePath: proofImagePath ?? _reports[index].proofImagePath,
        officerNotes: officerNotes ?? _reports[index].officerNotes,
      );
      _reports[index] = updated;
      notifyListeners();

      try {
        await FirebaseService.saveDrainageReport(updated);
      } catch (e) {
        debugPrint('Error updating report in Firestore: $e');
      }
    }
  }

  /// Sinkronkan data contoh Jakarta ke Firestore koleksi 'drainage_reports'
  /// Ini akan langsung membuat dokumen muncul di Google Cloud Firestore Console!
  Future<int> seedInitialDataToFirestore() async {
    _isSeeding = true;
    notifyListeners();

    try {
      final count = await FirebaseService.seedSampleReportsToFirestore(MockData.sampleReports);
      _isSeeding = false;
      _isFirestoreConnected = true;
      notifyListeners();
      return count;
    } catch (e) {
      _isSeeding = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
