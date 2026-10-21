// ============================================================
// Jakdrain — Data Models
// Model data untuk laporan drainase, cuaca, dan tugas PPSU.
// ============================================================

/// Status kondisi drainase.
enum DrainageStatus { kritis, waspada, aman }

/// Model laporan inspeksi drainase.
class DrainageReport {
  final String id;
  final String address;
  final String kelurahan;
  final String kecamatan;
  final double latitude;
  final double longitude;
  final double sedimentPercentage;
  final double remainingCapacityCm;
  final DrainageStatus status;
  final String recommendation;
  final DateTime inspectedAt;
  final String inspectorName;
  final String? imagePath;
  final TaskStatus taskStatus;
  final String? proofImagePath;
  final String? officerNotes;
  final DateTime? completedAt;
  final String? completedBy;

  const DrainageReport({
    required this.id,
    required this.address,
    required this.kelurahan,
    required this.kecamatan,
    required this.latitude,
    required this.longitude,
    required this.sedimentPercentage,
    required this.remainingCapacityCm,
    required this.status,
    required this.recommendation,
    required this.inspectedAt,
    required this.inspectorName,
    this.imagePath,
    this.taskStatus = TaskStatus.baruDilihat,
    this.proofImagePath,
    this.officerNotes,
    this.completedAt,
    this.completedBy,
  });

  DrainageReport copyWith({
    String? id,
    String? address,
    String? kelurahan,
    String? kecamatan,
    double? latitude,
    double? longitude,
    double? sedimentPercentage,
    double? remainingCapacityCm,
    DrainageStatus? status,
    String? recommendation,
    DateTime? inspectedAt,
    String? inspectorName,
    String? imagePath,
    TaskStatus? taskStatus,
    String? proofImagePath,
    String? officerNotes,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return DrainageReport(
      id: id ?? this.id,
      address: address ?? this.address,
      kelurahan: kelurahan ?? this.kelurahan,
      kecamatan: kecamatan ?? this.kecamatan,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sedimentPercentage: sedimentPercentage ?? this.sedimentPercentage,
      remainingCapacityCm: remainingCapacityCm ?? this.remainingCapacityCm,
      status: status ?? this.status,
      recommendation: recommendation ?? this.recommendation,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      inspectorName: inspectorName ?? this.inspectorName,
      imagePath: imagePath ?? this.imagePath,
      taskStatus: taskStatus ?? this.taskStatus,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      officerNotes: officerNotes ?? this.officerNotes,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'latitude': latitude,
      'longitude': longitude,
      'sedimentPercentage': sedimentPercentage,
      'remainingCapacityCm': remainingCapacityCm,
      'status': status.name,
      'recommendation': recommendation,
      'inspectedAt': inspectedAt.toIso8601String(),
      'inspectorName': inspectorName,
      'imagePath': imagePath ?? '',
      'taskStatus': taskStatus.name,
      'proofImagePath': proofImagePath ?? '',
      'officerNotes': officerNotes ?? '',
      'completedAt': completedAt?.toIso8601String() ?? '',
      'completedBy': completedBy ?? '',
    };
  }

  factory DrainageReport.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    final inspectedRaw = map['inspectedAt'];
    if (inspectedRaw is String) {
      parsedDate = DateTime.tryParse(inspectedRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCompletedAt;
    final completedRaw = map['completedAt'];
    if (completedRaw is String && completedRaw.isNotEmpty) {
      parsedCompletedAt = DateTime.tryParse(completedRaw);
    }

    return DrainageReport(
      id: docId ?? map['id'] ?? 'DR-${DateTime.now().millisecondsSinceEpoch}',
      address: map['address'] as String? ?? 'DKI Jakarta',
      kelurahan: map['kelurahan'] as String? ?? 'Jakarta',
      kecamatan: map['kecamatan'] as String? ?? 'Jakarta',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.2088,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 106.8456,
      sedimentPercentage: (map['sedimentPercentage'] as num?)?.toDouble() ?? 50.0,
      remainingCapacityCm: (map['remainingCapacityCm'] as num?)?.toDouble() ?? 20.0,
      status: parseStatus(map['status'] as String?),
      recommendation: map['recommendation'] as String? ?? 'Pemeriksaan rutin.',
      inspectedAt: parsedDate,
      inspectorName: map['inspectorName'] as String? ?? 'Petugas PPSU',
      imagePath: (map['imagePath'] as String?)?.isNotEmpty == true ? map['imagePath'] as String : null,
      taskStatus: parseTaskStatus(map['taskStatus'] as String?),
      proofImagePath: (map['proofImagePath'] as String?)?.isNotEmpty == true ? map['proofImagePath'] as String : null,
      officerNotes: (map['officerNotes'] as String?)?.isNotEmpty == true ? map['officerNotes'] as String : null,
      completedAt: parsedCompletedAt,
      completedBy: (map['completedBy'] as String?)?.isNotEmpty == true ? map['completedBy'] as String : null,
    );
  }

  static DrainageStatus parseStatus(String? val) {
    if (val == null) return DrainageStatus.aman;
    return DrainageStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DrainageStatus.aman,
    );
  }

  static TaskStatus parseTaskStatus(String? val) {
    if (val == null) return TaskStatus.baruDilihat;
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskStatus.baruDilihat,
    );
  }
}

/// Peringatan cuaca dari BMKG.
class WeatherAlert {
  final String condition;
  final String description;
  final double rainProbability;
  final String alertTime;

  const WeatherAlert({
    required this.condition,
    required this.description,
    required this.rainProbability,
    required this.alertTime,
  });
}

/// Status tugas pengerukan PPSU.
enum TaskStatus { baruDilihat, dalamPengerukan, selesai }

/// Model tugas PPSU.
class PPSUTask {
  final String id;
  final String assignedTo;
  final String drainageReportId;
  final TaskStatus status;
  final DateTime assignedAt;
  final DateTime? completedAt;

  const PPSUTask({
    required this.id,
    required this.assignedTo,
    required this.drainageReportId,
    required this.status,
    required this.assignedAt,
    this.completedAt,
  });
}

/// Data mock untuk demo mode.
class MockData {
  MockData._();

  static final WeatherAlert currentWeather = WeatherAlert(
    condition: 'Cerah Berawan',
    description: 'Potensi hujan ringan malam hari',
    rainProbability: 0.35,
    alertTime: '20:00',
  );

  static final List<DrainageReport> sampleReports = [
    DrainageReport(
      id: 'DR-001',
      address: 'Jl. Kebon Kacang Raya No. 12',
      kelurahan: 'Kebon Melati',
      kecamatan: 'Tanah Abang',
      latitude: -6.1934,
      longitude: 106.8198,
      sedimentPercentage: 72.5,
      remainingCapacityCm: 11.0,
      status: DrainageStatus.kritis,
      recommendation: 'Segera jadwalkan pengerukan sebelum hujan deras.',
      inspectedAt: DateTime.now().subtract(const Duration(hours: 2)),
      inspectorName: 'Ahmad Fauzi',
      taskStatus: TaskStatus.dalamPengerukan,
    ),
    DrainageReport(
      id: 'DR-002',
      address: 'Jl. Petamburan III No. 5',
      kelurahan: 'Petamburan',
      kecamatan: 'Tanah Abang',
      latitude: -6.1880,
      longitude: 106.8120,
      sedimentPercentage: 45.0,
      remainingCapacityCm: 22.5,
      status: DrainageStatus.waspada,
      recommendation: 'Pengerukan disarankan dalam 3-5 hari ke depan.',
      inspectedAt: DateTime.now().subtract(const Duration(hours: 5)),
      inspectorName: 'Budi Santoso',
      taskStatus: TaskStatus.baruDilihat,
    ),
    DrainageReport(
      id: 'DR-003',
      address: 'Jl. Bendungan Hilir Raya No. 8',
      kelurahan: 'Bendungan Hilir',
      kecamatan: 'Tanah Abang',
      latitude: -6.2050,
      longitude: 106.8170,
      sedimentPercentage: 25.0,
      remainingCapacityCm: 35.0,
      status: DrainageStatus.aman,
      recommendation: 'Kondisi drainase baik. Lakukan pemantauan rutin.',
      inspectedAt: DateTime.now().subtract(const Duration(days: 1)),
      inspectorName: 'Siti Rahayu',
      taskStatus: TaskStatus.selesai,
    ),
    DrainageReport(
      id: 'DR-004',
      address: 'Jl. Karet Pasar Baru Barat V',
      kelurahan: 'Karet Tengsin',
      kecamatan: 'Tanah Abang',
      latitude: -6.2010,
      longitude: 106.8130,
      sedimentPercentage: 81.0,
      remainingCapacityCm: 8.5,
      status: DrainageStatus.kritis,
      recommendation: 'Segera lakukan pengerukan. Risiko banjir sangat tinggi.',
      inspectedAt: DateTime.now().subtract(const Duration(hours: 1)),
      inspectorName: 'Ahmad Fauzi',
      taskStatus: TaskStatus.baruDilihat,
    ),
    DrainageReport(
      id: 'DR-005',
      address: 'Jl. Teluk Betung No. 15',
      kelurahan: 'Kebon Melati',
      kecamatan: 'Tanah Abang',
      latitude: -6.1960,
      longitude: 106.8210,
      sedimentPercentage: 55.0,
      remainingCapacityCm: 18.0,
      status: DrainageStatus.waspada,
      recommendation: 'Pengerukan disarankan segera.',
      inspectedAt: DateTime.now().subtract(const Duration(hours: 8)),
      inspectorName: 'Dedi Kurniawan',
      taskStatus: TaskStatus.dalamPengerukan,
    ),
    DrainageReport(
      id: 'DR-006',
      address: 'Jl. Wahid Hasyim No. 22',
      kelurahan: 'Kebon Sirih',
      kecamatan: 'Menteng',
      latitude: -6.1870,
      longitude: 106.8290,
      sedimentPercentage: 18.0,
      remainingCapacityCm: 38.0,
      status: DrainageStatus.aman,
      recommendation: 'Kondisi baik. Pemantauan rutin.',
      inspectedAt: DateTime.now().subtract(const Duration(days: 2)),
      inspectorName: 'Siti Rahayu',
      taskStatus: TaskStatus.selesai,
    ),
    DrainageReport(
      id: 'DR-007',
      address: 'Jl. Cikini Raya No. 30',
      kelurahan: 'Cikini',
      kecamatan: 'Menteng',
      latitude: -6.1910,
      longitude: 106.8380,
      sedimentPercentage: 68.0,
      remainingCapacityCm: 12.5,
      status: DrainageStatus.kritis,
      recommendation: 'Segera jadwalkan pengerukan.',
      inspectedAt: DateTime.now().subtract(const Duration(hours: 3)),
      inspectorName: 'Budi Santoso',
      taskStatus: TaskStatus.baruDilihat,
    ),
  ];
}
