// ============================================================
// Jakdrain — Map Filter Provider
// Mengelola filter pin pada peta berdasarkan status drainase.
// ============================================================
import 'package:flutter/material.dart';
import 'package:jakdrain/data/models.dart';

class MapFilterProvider extends ChangeNotifier {
  DrainageStatus? _activeFilter;

  DrainageStatus? get activeFilter => _activeFilter;

  /// Set filter status aktif. `null` menampilkan semua.
  void setFilter(DrainageStatus? status) {
    _activeFilter = status;
    notifyListeners();
  }

  /// Cek apakah filter tertentu aktif.
  bool isActive(DrainageStatus? status) => _activeFilter == status;

  /// Filter daftar laporan berdasarkan status aktif.
  List<DrainageReport> filterReports(List<DrainageReport> reports) {
    if (_activeFilter == null) return reports;
    return reports.where((r) => r.status == _activeFilter).toList();
  }
}
