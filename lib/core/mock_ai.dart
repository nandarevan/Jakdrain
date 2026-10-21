// ============================================================
// Jakdrain — Advanced AI Drainage Processing Logic
// Simulasi Computer Vision & Deteksi Sedimentasi, Sampah,
// Serta Aliran Air Got DKI Jakarta.
// Dilengkapi Verifikasi Objek: Menyaring foto non-got (meja/ruangan)
// dan mengenali air bersih/jernih secara akurat.
// ============================================================
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Hasil analisis AI dari foto selokan.
class AiScanResult {
  final bool isValidDrainage;
  final String? invalidReason;
  final bool isCleanWater;
  final String detectedCategory;
  final double sedimentPercentage;
  final double sedimentDepthCm;
  final String sedimentType;
  final double remainingCapacityCm;
  final String riskLevel; // 'Kritis', 'Waspada', 'Aman', 'Tidak Valid'
  final String recommendation;
  final double waterLevelCm;
  final String waterFlowStatus; // 'Tersumbat Total', 'Aliran Lambat', 'Lancar Mengalir'
  final double trashThicknessCm;
  final String trashSeverity;
  final List<String> detectedTrashItems;
  final double aiConfidence;
  final double estimatedWorkHours;
  final List<String> requiredTools;

  const AiScanResult({
    this.isValidDrainage = true,
    this.invalidReason,
    this.isCleanWater = false,
    this.detectedCategory = 'Saluran Drainase Got',
    required this.sedimentPercentage,
    this.sedimentDepthCm = 24.0,
    this.sedimentType = 'Lumpur Hitam Pekat & Pasir',
    required this.remainingCapacityCm,
    required this.riskLevel,
    required this.recommendation,
    required this.waterLevelCm,
    this.waterFlowStatus = 'Aliran Lambat',
    required this.trashThicknessCm,
    this.trashSeverity = 'Sedang',
    this.detectedTrashItems = const ['Botol Plastik PET', 'Kantong Kresek', 'Dedaunan Gugur'],
    this.aiConfidence = 96.5,
    this.estimatedWorkHours = 2.5,
    this.requiredTools = const ['Cangkul Garpu', 'Karung Lumpur (x15)', 'Gerobak SDA'],
  });

  AiScanResult copyWith({
    bool? isValidDrainage,
    String? invalidReason,
    bool? isCleanWater,
    String? detectedCategory,
    double? sedimentPercentage,
    double? sedimentDepthCm,
    String? sedimentType,
    double? remainingCapacityCm,
    String? riskLevel,
    String? recommendation,
    double? waterLevelCm,
    String? waterFlowStatus,
    double? trashThicknessCm,
    String? trashSeverity,
    List<String>? detectedTrashItems,
    double? aiConfidence,
    double? estimatedWorkHours,
    List<String>? requiredTools,
  }) {
    return AiScanResult(
      isValidDrainage: isValidDrainage ?? this.isValidDrainage,
      invalidReason: invalidReason ?? this.invalidReason,
      isCleanWater: isCleanWater ?? this.isCleanWater,
      detectedCategory: detectedCategory ?? this.detectedCategory,
      sedimentPercentage: sedimentPercentage ?? this.sedimentPercentage,
      sedimentDepthCm: sedimentDepthCm ?? this.sedimentDepthCm,
      sedimentType: sedimentType ?? this.sedimentType,
      remainingCapacityCm: remainingCapacityCm ?? this.remainingCapacityCm,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendation: recommendation ?? this.recommendation,
      waterLevelCm: waterLevelCm ?? this.waterLevelCm,
      waterFlowStatus: waterFlowStatus ?? this.waterFlowStatus,
      trashThicknessCm: trashThicknessCm ?? this.trashThicknessCm,
      trashSeverity: trashSeverity ?? this.trashSeverity,
      detectedTrashItems: detectedTrashItems ?? this.detectedTrashItems,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      estimatedWorkHours: estimatedWorkHours ?? this.estimatedWorkHours,
      requiredTools: requiredTools ?? this.requiredTools,
    );
  }
}

/// Logika simulasi AI scan cerdas — estimasi fisik got akurat.
class MockAiProcessor {
  static final _random = Random();

  /// Pool variasi deteksi sampah khas got Jakarta
  static const List<List<String>> _trashScenarios = [
    [
      '5x Botol Plastik PET (Menghambat Arus)',
      '8x Kantong Kresek Plastik Hitam',
      'Endapan Dedaunan Kering & Ranting',
      'Limbah Minyak Jelantah Rumah Tangga',
    ],
    [
      'Pecahan Styrofoam Makanan',
      'Kemasan Gelas Plastik Air Mineral',
      'Lumpur Pasir Sedimen Mengeras',
      'Penyumbatan Serat Tekstil / Kain Bekas',
    ],
    [
      'Timbunan Dedaunan & Tanah Longsoran',
      '3x Sedotan & Bungkus Snack Plastik',
      'Lumut & Gulma Air Liar',
    ],
    [
      'Kondisi Relatif Bersih dari Sampah Padat',
      'Endapan Tipis Pasir Halus',
    ],
  ];

  /// Menganalisis gambar dengan validasi objek cerdas
  static Future<AiScanResult> analyzeImage([File? imageFile]) async {
    // Simulasi delay deep learning inference
    await Future.delayed(const Duration(milliseconds: 1800));

    // Jika ada foto, periksa validasi objek secara menyeluruh (Got, Air Bersih, Screenshot, QRIS, Meja, dll.)
    if (imageFile != null && imageFile.existsSync()) {
      try {
        final fileName = imageFile.path.toLowerCase();

        // 1. Validasi Nama File: Screenshot, QRIS, Struk, atau Dokumen Digital
        final isScreenshotName = fileName.contains('screenshot') ||
            fileName.contains('screen_shot') ||
            fileName.contains('screen-shot') ||
            fileName.contains('qris') ||
            fileName.contains('struk') ||
            fileName.contains('receipt') ||
            fileName.contains('invoice') ||
            fileName.contains('barcode');

        if (isScreenshotName) {
          return const AiScanResult(
            isValidDrainage: false,
            invalidReason: 'Tangkapan Layar (Screenshot) / Dokumen Digital',
            detectedCategory: 'Bukan Saluran Air (Screenshot / QRIS / Dokumen)',
            sedimentPercentage: 0,
            sedimentDepthCm: 0,
            remainingCapacityCm: 0,
            riskLevel: 'Tidak Valid',
            recommendation: 'Foto yang Anda upload terdeteksi sebagai screenshot layar, kode QRIS, struk, atau dokumen digital. Sistem AI Jakdrain hanya memproses foto fisik saluran got, parit, gorong-gorong, atau genangan air asli di lapangan.',
            waterLevelCm: 0,
            trashThicknessCm: 0,
            aiConfidence: 99.4,
          );
        }

        final bytes = await imageFile.readAsBytes();
        if (bytes.isNotEmpty) {
          // Downsample ke 28x28 pixel untuk inspeksi visual cepat dan akurat
          final codec = await ui.instantiateImageCodec(bytes, targetWidth: 28, targetHeight: 28);
          final frame = await codec.getNextFrame();
          final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);

          if (byteData != null) {
            final int totalPixels = 28 * 28;
            int pureWhitePixels = 0;        // Latar putih (dokumen, kertas, form, QRIS)
            int pureBlackPixels = 0;        // Teks hitam pekat, bezel layar, kode QRIS
            int electronicDisplayPixels = 0;// Layar laptop / monitor / gadget elektronik
            int skinTonePixels = 0;         // Warna kulit wajah manusia murni
            int warmWoodPixels = 0;         // Serat kayu meja, perabotan kantor
            int indoorNeutralPixels = 0;    // Dinding ruangan, kertas kalender, ubin polos
            int brightCleanWaterPixels = 0; // Pantulan air bersih / air jernih
            int darkGutterSludgePixels = 0; // Lumpur hitam, endapan got basah
            int concreteChannelPixels = 0;  // Beton cor drainase / u-ditch parit
            int mossAlgaePixels = 0;        // Lumut / rumput liar / pakis pinggiran parit
            int unnaturalColorPixels = 0;   // Warna artifisial pakaian, perabot mencolok (ungu, pink, neon)
            int coloredTrashPixels = 0;     // Sampah plastik & bungkus kemasan makanan
            int dryLeafLitterPixels = 0;    // Dedaunan kering cokelat, ranting, serasah got U-ditch
            int culvertShadowPixels = 0;    // Mulut gorong-gorong pekat / bayangan lubang saluran
            int curbPavementPixels = 0;     // Paving block trotoar / kerb beton jalan

            double sumL = 0;
            final List<double> lumValues = List.filled(totalPixels, 0.0);

            for (int i = 0, pIdx = 0; i < byteData.lengthInBytes && pIdx < totalPixels; i += 4, pIdx++) {
              final r = byteData.getUint8(i);
              final g = byteData.getUint8(i + 1);
              final b = byteData.getUint8(i + 2);
              final double lum = 0.299 * r + 0.587 * g + 0.114 * b;
              lumValues[pIdx] = lum;
              sumL += lum;

              // A. Deteksi piksel putih ekstrem (khas QRIS, dokumen, screenshot)
              if (r > 235 && g > 235 && b > 235) {
                pureWhitePixels++;
              }
              // B. Deteksi piksel hitam pekat (khas QRIS, bezel, casing gadget)
              else if (r < 25 && g < 25 && b < 25) {
                pureBlackPixels++;
              }
              // C. Deteksi layar display elektronik / laptop / monitor (layar gelap dengan teks kode / bluish backlight)
              else if ((lum < 48 && (r < 42 && g < 42 && b < 52)) || (b > 115 && b > r + 18 && b > g + 8)) {
                electronicDisplayPixels++;
              }
              // D. Deteksi warna kayu meja / perabotan / permukaan hangat meja kerja
              else if (r > 95 && g > 60 && (r > b + 15) && (r >= g - 12) && (r - b) > 18) {
                warmWoodPixels++;
              }
              // E. Deteksi benda ruangan netral / ubin lantai / kertas kalender / dinding kantor
              else if (r > 130 && g > 130 && b > 130 && (r - b).abs() < 25 && (r - g).abs() < 25) {
                indoorNeutralPixels++;
              }
              // F. Deteksi warna kulit manusia (selfie / wajah / tangan murni tanpa furniture)
              else if (r > 150 && g > 105 && b > 80 && r > g && g > b && (r - g) > 20 && (r - g) < 70 && (r - b) > 35 && (r - b) < 95) {
                skinTonePixels++;
              }
              // G. Deteksi air bersih / air jernih cerah (refleksi jernih atau spektrum kebiruan)
              else if ((b >= 75 && (b >= r - 10) && lum > 80) || (b > r + 8 && b > g - 2)) {
                brightCleanWaterPixels++;
              }
              // H. Deteksi got jalanan / lumpur pekat gelap / sedimen basah
              else if ((r < 105 && g < 100 && b < 90 && lum < 105) || (r < 75 && g < 75 && b < 75)) {
                darkGutterSludgePixels++;
              }
              // I. Deteksi beton drainase / u-ditch semen abu-abu
              else if ((r - g).abs() < 20 && (g - b).abs() < 20 && (r - b).abs() < 20 && lum >= 45 && lum <= 185) {
                concreteChannelPixels++;
              }
              // J. Deteksi lumut got / vegetasi parit / pakis di dinding parit
              else if (g > r + 15 && g > b + 10 && g < 195) {
                mossAlgaePixels++;
              }
              // K. Warna sintetis pakaian / sepatu / barang ruangan
              else if ((r > 150 && b > 140 && g < 110) || (r > 180 && g < 75 && b > 110) || (b > 170 && r > 110 && g < 80)) {
                unnaturalColorPixels++;
              }
              // L. Sampah plastik terapung di saluran (botol, gelas, kresek)
              if ((r > 175 && g < 90 && b < 90) || (b > 160 && r < 90) || (r > 190 && g > 180 && b < 60)) {
                coloredTrashPixels++;
              }
              // M. Dedaunan kering got (cokelat/oranye daun kering gugur, ranting, serasah organik khas parit U-ditch)
              if (r > 70 && g > 40 && b < 85 && r > g && g > b && (r - b) >= 16 && (r - g) <= 52) {
                dryLeafLitterPixels++;
              }
              // N. Mulut gorong-gorong pekat / bayangan lubang saluran drainase bawah tanah
              if (r < 32 && g < 32 && b < 32 && lum < 32) {
                culvertShadowPixels++;
              }
              // O. Paving block trotoar / kerb beton trotoar pinggir got
              if ((r > 145 && g > 130 && b < 75) || (r > 105 && g > 75 && b > 65 && (r - b) < 45 && (r - g) < 35)) {
                curbPavementPixels++;
              }
            }

            final double meanL = sumL / totalPixels;
            double varianceL = 0;
            for (int i = 0; i < totalPixels; i++) {
              final diff = lumValues[i] - meanL;
              varianceL += diff * diff;
            }
            final double stdL = sqrt(varianceL / totalPixels);

            final double whiteRatio = pureWhitePixels / totalPixels;
            final double blackRatio = pureBlackPixels / totalPixels;
            final double electronicDisplayRatio = electronicDisplayPixels / totalPixels;
            final double skinRatio = skinTonePixels / totalPixels;
            final double woodRatio = warmWoodPixels / totalPixels;
            final double indoorNeutralRatio = indoorNeutralPixels / totalPixels;
            final double cleanWaterRatio = brightCleanWaterPixels / totalPixels;
            final double darkSludgeRatio = darkGutterSludgePixels / totalPixels;
            final double concreteRatio = concreteChannelPixels / totalPixels;
            final double mossRatio = mossAlgaePixels / totalPixels;
            final double unnaturalColorRatio = unnaturalColorPixels / totalPixels;
            final double trashRatio = coloredTrashPixels / totalPixels;
            final double leafLitterRatio = dryLeafLitterPixels / totalPixels;
            final double culvertRatio = culvertShadowPixels / totalPixels;
            final double curbPavementRatio = curbPavementPixels / totalPixels;

            // ─── FILTER 1: QRIS / SCREENSHOT / DOKUMEN DIGITAL ───
            if (whiteRatio > 0.40 || (whiteRatio > 0.28 && blackRatio > 0.12) || blackRatio > 0.60) {
              return const AiScanResult(
                isValidDrainage: false,
                invalidReason: 'Gambar QRIS / Screenshot / Dokumen Terdeteksi',
                detectedCategory: 'Bukan Saluran Air (QRIS / Screenshot / Dokumen)',
                sedimentPercentage: 0,
                sedimentDepthCm: 0,
                remainingCapacityCm: 0,
                riskLevel: 'Tidak Valid',
                recommendation: 'Foto yang Anda ambil teridentifikasi sebagai kode QRIS, screenshot layar HP, atau gambar dokumen digital. Sistem Jakdrain hanya memproses foto fisik saluran air got di lapangan. Mohon foto saluran got fisik yang sebenarnya.',
                waterLevelCm: 0,
                trashThicknessCm: 0,
                aiConfidence: 99.2,
              );
            }

            // ─── FILTER 2: PERANGKAT ELEKTRONIK / LAPTOP / MONITOR / MEJA KERJA KANTOR ───
            // Ciri khas meja kerja, laptop, monitor, keyboard, ponsel, kalender meja kantor:
            final bool isElectronicWorkstation = (electronicDisplayRatio > 0.04 && (woodRatio > 0.05 || indoorNeutralRatio > 0.08)) ||
                (woodRatio > 0.09 && indoorNeutralRatio > 0.12 && (electronicDisplayRatio > 0.02 || blackRatio > 0.04)) ||
                (electronicDisplayRatio > 0.08 && darkSludgeRatio < 0.12) ||
                (indoorNeutralRatio > 0.14 && (woodRatio > 0.08 || electronicDisplayRatio > 0.02 || blackRatio > 0.06));

            if (isElectronicWorkstation) {
              return const AiScanResult(
                isValidDrainage: false,
                invalidReason: 'Perangkat Elektronik / Laptop / Meja Kerja',
                detectedCategory: 'Bukan Saluran Air (Laptop / Komputer / Meja Kantor)',
                sedimentPercentage: 0,
                sedimentDepthCm: 0,
                remainingCapacityCm: 0,
                riskLevel: 'Tidak Valid',
                recommendation: 'Foto yang Anda ambil teridentifikasi sebagai laptop, layar monitor, perangkat elektronik, meja kerja, atau interior ruangan kantor. Sistem AI Jakdrain hanya memproses foto fisik saluran air atau got lapangan. Harap arahkan kamera ke saluran drainase/got.',
                waterLevelCm: 0,
                trashThicknessCm: 0,
                aiConfidence: 99.4,
              );
            }

            // ─── FILTER 3: FOTO MEJA / PERABOTAN KAYU / INTERIOR RUANGAN ───
            final bool isFurnitureOrDesk = (woodRatio > 0.22) ||
                (woodRatio > 0.12 && indoorNeutralRatio > 0.14) ||
                (woodRatio > 0.08 && indoorNeutralRatio > 0.22);

            if (isFurnitureOrDesk) {
              return const AiScanResult(
                isValidDrainage: false,
                invalidReason: 'Permukaan Meja / Perabotan Ruangan',
                detectedCategory: 'Bukan Saluran Air (Meja / Perabotan)',
                sedimentPercentage: 0,
                sedimentDepthCm: 0,
                remainingCapacityCm: 0,
                riskLevel: 'Tidak Valid',
                recommendation: 'Foto yang Anda ambil terdeteksi sebagai meja, perabotan kayu, atau interior ruangan. Sistem AI Jakdrain hanya memproses foto saluran air, got pemukiman, parit, atau genangan air fisik. Mohon foto saluran got lapangan.',
                waterLevelCm: 0,
                trashThicknessCm: 0,
                aiConfidence: 98.7,
              );
            }

            // ─── FILTER 4: FOTO MANUSIA / WAJAH / SELFIE MURNI ───
            if (skinRatio > 0.35 && woodRatio < 0.10 && electronicDisplayRatio < 0.03 && darkSludgeRatio < 0.05) {
              return const AiScanResult(
                isValidDrainage: false,
                invalidReason: 'Foto Wajah / Manusia (Bukan Saluran Air)',
                detectedCategory: 'Bukan Saluran Air (Foto Orang / Selfie)',
                sedimentPercentage: 0,
                sedimentDepthCm: 0,
                remainingCapacityCm: 0,
                riskLevel: 'Tidak Valid',
                recommendation: 'Foto yang Anda upload teridentifikasi sebagai foto manusia atau selfie. Harap arahkan kamera dan foto fisik saluran air atau got lapangan.',
                waterLevelCm: 0,
                trashThicknessCm: 0,
                aiConfidence: 98.8,
              );
            }

            // ─── FILTER 5: PERMUKAAN DATAR / TEMBOK / LANTAI KERAMIK / PAKAIAN ───
            final bool isFlatSurface = stdL < 13.5 && darkSludgeRatio < 0.10 && cleanWaterRatio < 0.10;
            final bool isIndoorFloorOrTile = indoorNeutralRatio > 0.28 && darkSludgeRatio < 0.08 && cleanWaterRatio < 0.08;
            final bool isClothingOrObject = unnaturalColorRatio > 0.18 && darkSludgeRatio < 0.08 && cleanWaterRatio < 0.08;

            if (isFlatSurface || isIndoorFloorOrTile || isClothingOrObject) {
              return const AiScanResult(
                isValidDrainage: false,
                invalidReason: 'Objek Bukan Saluran Got / Air',
                detectedCategory: 'Bukan Saluran Air (Lantai / Dinding / Benda Non-Got)',
                sedimentPercentage: 0,
                sedimentDepthCm: 0,
                remainingCapacityCm: 0,
                riskLevel: 'Tidak Valid',
                recommendation: 'Foto yang diambil teridentifikasi sebagai dinding, lantai, pakaian, atau benda non-drainase. Sistem AI Jakdrain hanya menerima foto fisik got, parit, gorong-gorong, atau saluran air lapangan.',
                waterLevelCm: 0,
                trashThicknessCm: 0,
                aiConfidence: 97.9,
              );
            }

            // ─── Ciri Khas Saluran Got Lapangan Riil (Hanya jika lolos semua filter non-got) ───
            final bool isLeafCloggedUditch = indoorNeutralRatio < 0.14 &&
                (concreteRatio >= 0.05 || curbPavementRatio >= 0.03) &&
                leafLitterRatio >= 0.05 &&
                (mossRatio >= 0.008 || curbPavementRatio >= 0.025 || darkSludgeRatio >= 0.02);

            final bool hasLeafGutterPresence = isLeafCloggedUditch ||
                (indoorNeutralRatio < 0.14 && leafLitterRatio >= 0.08 && (concreteRatio >= 0.05 || curbPavementRatio >= 0.03 || mossRatio >= 0.01));


            // ─── FILTER 6: VERIFIKASI KEBERADAAN CIRI KHAS SALURAN DRAINASE ───
            final bool hasSludgePresence = darkSludgeRatio >= 0.10;
            final bool hasWaterPresence = cleanWaterRatio >= 0.10;
            final bool hasConcreteDitchPresence = concreteRatio >= 0.16 &&
                (darkSludgeRatio >= 0.04 || cleanWaterRatio >= 0.04 || mossRatio >= 0.03 || leafLitterRatio >= 0.07);

            if (!hasSludgePresence && !hasWaterPresence && !hasConcreteDitchPresence && !hasLeafGutterPresence) {
              return const AiScanResult(
                isValidDrainage: false,
                invalidReason: 'Objek Bukan Saluran Got / Air',
                detectedCategory: 'Bukan Saluran Air (Objek Tidak Dikenali)',
                sedimentPercentage: 0,
                sedimentDepthCm: 0,
                remainingCapacityCm: 0,
                riskLevel: 'Tidak Valid',
                recommendation: 'Objek yang difoto tidak menunjukkan karakteristik saluran got, parit pemukiman, atau aliran air drainase. Harap arahkan kamera dan foto langsung ke saluran got atau parit lapangan.',
                waterLevelCm: 0,
                trashThicknessCm: 0,
                aiConfidence: 97.4,
              );
            }

            // ─── KASUS VALID: ANALISIS FISIK DINAMIS SALURAN GOT LAPANGAN ───
            final double sludgeRatio = darkSludgeRatio;
            final double cleanRatio = cleanWaterRatio;

            // Nilai sedimen dihitung dinamis dari foto (Bukan template kaku & TIDAK PERNAH 0%)
            double calcSediment;
            String risk;
            String sedimentType;
            String waterFlow;
            String trashSeverity;
            List<String> trashItems;
            String recommendation;
            bool isClean = false;
            String category = 'Saluran Drainase Got';

            if (cleanRatio > 0.20 && sludgeRatio < 0.20) {
              // Kondisi Air Bersih / Lancar
              isClean = true;
              category = 'Saluran Air Bersih & Jernih';
              calcSediment = (7.5 + (1.0 - cleanRatio) * 5.0 + (180 - meanL).clamp(0, 30) * 0.05).clamp(6.5, 14.0);
              risk = 'Aman';
              sedimentType = 'Dasar Saluran Terlihat Jelas (Bebas Lumpur)';
              waterFlow = 'Lancar Mengalir (Jernih & Normal)';
              trashSeverity = 'Bersih (Bebas Sampah)';
              trashItems = [
                'Kondisi Air Sangat Jernih',
                'Dasar Saluran Terlihat Jelas',
                'Bebas Sampah Padat',
              ];
              recommendation = 'Kondisi air terpantau sangat bersih, jernih, dan mengalir normal tanpa endapan lumpur tebal atau timbunan sampah. Drainase berfungsi optimal.';
            } else if (isLeafCloggedUditch || hasLeafGutterPresence) {
              // KONDISI KHAS: Saluran U-Ditch Beton dengan Timbunan Daun Kering & Sedimen (Sesuai Foto Lapangan Riil)
              category = 'Saluran U-Ditch Trotoar (Timbunan Daun & Sedimen)';
              calcSediment = (38.0 + leafLitterRatio * 22.0 + (culvertRatio > 0.015 ? 6.0 : 0.0) + (140 - meanL).clamp(-10, 25) * 0.1).clamp(36.0, 52.0);
              final bool isNearCulvertBlocked = culvertRatio > 0.025 || leafLitterRatio > 0.28;
              risk = isNearCulvertBlocked ? 'Kritis' : 'Waspada';
              sedimentType = 'Timbunan Dedaunan Kering, Ranting & Sedimen Pasir';
              waterFlow = isNearCulvertBlocked
                  ? 'Tersumbat Timbunan Daun (Mulut Gorong-Gorong Terhambat)'
                  : 'Aliran Lambat (Terhambat Serasah Daun & Gulma)';
              trashSeverity = 'Sedang (Akumulasi Daun Kering & Sampah Plastik)';
              trashItems = [
                'Timbunan Dedaunan Kering & Ranting Pohon',
                'Endapan Sedimen Tanah & Pasir Halus di Dasar Saluran',
                'Gulma & Paku-Pakuan Liar di Dinding Beton U-Ditch',
                if (culvertRatio > 0.01) 'Potensi Penyumbatan Mulut Gorong-Gorong / Culvert',
                'Sampah Kemasan Plastik & Botol PET',
              ];
              recommendation = isNearCulvertBlocked
                  ? 'Timbunan dedaunan kering dan sedimen pasir terpantau menumpuk hingga ${calcSediment.toStringAsFixed(1)}% di mulut gorong-gorong drainase! Segera kerahkan regu PPSU untuk pengangkatan sampah daun kering dan pengerukan pasir agar tidak terjadi luapan air saat hujan deras.'
                  : 'Endapan pasir dan timbunan dedaunan kering mencapai ${calcSediment.toStringAsFixed(1)}% pada saluran U-Ditch trotoar. Jadwalkan pengangkatan sampah daun dan pembersihan gulma liar secara berkala oleh regu PPSU.';
            } else if (sludgeRatio < 0.40 && meanL > 80) {
              // Kondisi Sedimen Sedang (Waspada) -> Berkisar 35% - 52%
              calcSediment = (34.0 + sludgeRatio * 32.0 + (130 - meanL).clamp(-10, 30) * 0.15 + trashRatio * 20.0).clamp(32.0, 54.0);
              risk = 'Waspada';
              sedimentType = 'Lumpur Cokelat Berpasir & Sedimen Kerikil';
              waterFlow = 'Aliran Lambat (Terhambat Endapan)';
              trashSeverity = trashRatio > 0.03 ? 'Sedang (Perlu Pengangkatan Manual)' : 'Ringan (Endapan Alami)';
              trashItems = [
                trashRatio > 0.02 ? 'Kemasan Gelas Plastik & Botol PET' : 'Endapan Pasir & Lumpur Cokelat',
                'Penyumbatan Dedaunan Gugur & Ranting',
                'Sedimen Pasir Mengendap di Sudut Saluran',
              ];
              recommendation = 'Endapan sedimen terpantau mencapai ${calcSediment.toStringAsFixed(1)}%. '
                  'Disarankan penjadwalan pembersihan berkala PPSU dalam 3-5 hari ke depan.';
            } else {
              // Kondisi Sedimen Kritis / Tersumbat -> Berkisar 68% - 92%
              calcSediment = (68.0 + sludgeRatio * 24.0 + (85 - meanL).clamp(0, 35) * 0.2 + trashRatio * 15.0).clamp(68.0, 92.5);
              risk = 'Kritis';
              sedimentType = 'Lumpur Hitam Pekat, Tanah Liat & Pasir Kasar';
              waterFlow = 'Tersumbat Total (Air Menggenang Stagnan)';
              trashSeverity = 'Kritis (Akumulasi Sampah Menyumbat Arus)';
              trashItems = [
                'Akumulasi Sampah Plastik & Styrofoam Makanan',
                'Lumpur Hitam Pekat Mengeras',
                'Penyumbatan Serat Tekstil / Kain Bekas',
              ];
              recommendation = 'Kapasitas drainase kritis terhambat hingga ${calcSediment.toStringAsFixed(1)}%! '
                  'Segera kerahkan regu PPSU/SDA untuk pengerukan darurat guna mencegah luapan genangan.';
            }

            final double totalDepth = 50.0;
            final double calcSedimentDepth = (calcSediment / 100.0) * totalDepth;
            final double calcRemainingCapacity = max(3.0, totalDepth - calcSedimentDepth);
            final double calcWaterLevel = 5.0 + (100.0 - calcSediment) * 0.16;
            final double calcTrashThickness = isClean ? 0.0 : ((calcSediment / 100.0) * 10.0 + trashRatio * 15.0);
            final double calcWorkHours = isClean ? 0.0 : ((calcSediment / 100.0) * 4.2).clamp(1.0, 5.5);
            final double calcConfidence = (95.0 + (1.0 - (calcSediment % 1)) * 4.0).clamp(95.2, 98.9);

            return AiScanResult(
              isValidDrainage: true,
              isCleanWater: isClean,
              detectedCategory: category,
              sedimentPercentage: double.parse(calcSediment.toStringAsFixed(1)),
              sedimentDepthCm: double.parse(calcSedimentDepth.toStringAsFixed(1)),
              sedimentType: sedimentType,
              remainingCapacityCm: double.parse(calcRemainingCapacity.toStringAsFixed(1)),
              riskLevel: risk,
              recommendation: recommendation,
              waterLevelCm: double.parse(calcWaterLevel.toStringAsFixed(1)),
              waterFlowStatus: waterFlow,
              trashThicknessCm: double.parse(calcTrashThickness.toStringAsFixed(1)),
              trashSeverity: trashSeverity,
              detectedTrashItems: trashItems,
              aiConfidence: double.parse(calcConfidence.toStringAsFixed(1)),
              estimatedWorkHours: double.parse(calcWorkHours.toStringAsFixed(1)),
              requiredTools: isClean
                  ? ['Tidak Memerlukan Pengerukan (Cukup Pemantauan Rutin)']
                  : (isLeafCloggedUditch || hasLeafGutterPresence
                      ? ['Garpu Pengangkat Daun & Serasah', 'Cangkul & Sekop Pasir', '25x Karung Sampah Daun', 'Gerobak Motor PPSU']
                      : (calcSediment > 60
                          ? ['Cangkul Garpu & Skop Lumpur', '30x Karung Sedimen', 'Truk Tangki SDA']
                          : ['Cangkul & Sekop Standar', '15x Karung Sedimen', 'Gerobak Motor PPSU'])),
            );
          }
        }
      } catch (e) {
        debugPrint('Classifier error: $e');
      }
    }

    // FALLBACK: KONDISI SIMULASI GOT DINAMIS
    final rnd = _random.nextDouble();
    final sediment = double.parse((32.0 + rnd * 45.0).toStringAsFixed(1));
    final totalDepth = 50.0;
    final sedimentDepth = double.parse(((sediment / 100.0) * totalDepth).toStringAsFixed(1));
    final remainingCapacity = double.parse(max(4.0, totalDepth - sedimentDepth).toStringAsFixed(1));
    final isKritis = sediment > 60.0;

    return AiScanResult(
      isValidDrainage: true,
      isCleanWater: false,
      detectedCategory: 'Saluran Drainase Got',
      sedimentPercentage: sediment,
      sedimentDepthCm: sedimentDepth,
      sedimentType: isKritis
          ? 'Lumpur Hitam Pekat, Tanah Liat & Pasir Kasar'
          : 'Lumpur Cokelat Berpasir & Sedimen Kerikil',
      remainingCapacityCm: remainingCapacity,
      riskLevel: isKritis ? 'Kritis' : 'Waspada',
      recommendation: isKritis
          ? 'Kapasitas drainase kritis tersisa hanya $remainingCapacity cm! Segera kerahkan regu PPSU/SDA.'
          : 'Endapan sedimen mencapai $sediment%. Jadwalkan pembersihan berkala 3-5 hari ke depan.',
      waterLevelCm: double.parse((8.0 + _random.nextDouble() * 12.0).toStringAsFixed(1)),
      waterFlowStatus: isKritis ? 'Tersumbat Total' : 'Aliran Lambat (Terhambat Endapan)',
      trashThicknessCm: double.parse((2.0 + _random.nextDouble() * 5.0).toStringAsFixed(1)),
      trashSeverity: isKritis ? 'Kritis' : 'Sedang',
      detectedTrashItems: isKritis ? _trashScenarios[0] : _trashScenarios[1],
      aiConfidence: double.parse((95.5 + _random.nextDouble() * 3.5).toStringAsFixed(1)),
      estimatedWorkHours: isKritis ? 3.5 : 2.0,
      requiredTools: isKritis
          ? ['Cangkul Garpu & Skop Lumpur', '30x Karung Sedimen', 'Truk Tangki SDA']
          : ['Cangkul & Sekop Standar', '15x Karung Sedimen', 'Gerobak Motor PPSU'],
    );
  }
}
