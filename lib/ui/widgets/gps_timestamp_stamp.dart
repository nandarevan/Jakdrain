// ============================================================
// Jakdrain — GPS Timestamp Stamp Widget
// Stempel Watermark Lokasi & Waktu Riil sesuai standar foto lapangan
// Format: Waktu, Kelurahan/Jalan, Kecamatan, Kota, Provinsi, Altitude, Index
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GpsTimestampStamp extends StatelessWidget {
  final DateTime? dateTime;
  final String? street;
  final String? kelurahan;
  final String? kecamatan;
  final String? kota;
  final String? provinsi;
  final double? altitude;
  final dynamic indexNumber;
  final double? latitude;
  final double? longitude;
  final bool showBackground;

  const GpsTimestampStamp({
    super.key,
    this.dateTime,
    this.street,
    this.kelurahan,
    this.kecamatan,
    this.kota,
    this.provinsi,
    this.altitude,
    this.indexNumber,
    this.latitude,
    this.longitude,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = dateTime ?? DateTime.now();
    // Format tanggal persis screenshot: "14 Okt 2026 07.55.28"
    final formattedTime = DateFormat('dd MMM yyyy HH.mm.ss', 'id_ID').format(now);

    final lineKelurahan = (kelurahan != null && kelurahan!.isNotEmpty)
        ? kelurahan!
        : (street != null && street!.isNotEmpty ? street! : 'Duri Kosambi');

    final lineKecamatan = (kecamatan != null && kecamatan!.isNotEmpty)
        ? (kecamatan!.startsWith('Kecamatan') ? kecamatan! : 'Kecamatan $kecamatan')
        : 'Kecamatan Cengkareng';

    final lineKota = (kota != null && kota!.isNotEmpty)
        ? (kota!.startsWith('Kota') || kota!.startsWith('Kabupaten') ? kota! : 'Kota $kota')
        : 'Kota Jakarta Barat';

    final lineProvinsi = (provinsi != null && provinsi!.isNotEmpty)
        ? provinsi!
        : 'Daerah Khusus Ibukota Jakarta';

    final altVal = altitude ?? 28.7;
    final lineAltitude = 'Altitude:${altVal.toStringAsFixed(1)}msnm';
    final lineIndex = 'Index number: ${indexNumber ?? 23}';
    final lineCoords = (latitude != null && longitude != null)
        ? 'GPS: (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})'
        : null;

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0.1,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: Offset(1, 1),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.black87,
          offset: Offset(-0.5, -0.5),
          blurRadius: 2,
        ),
      ],
    );

    final stampContent = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formattedTime, style: textStyle, textAlign: TextAlign.right),
        Text(lineKelurahan, style: textStyle, textAlign: TextAlign.right),
        Text(lineKecamatan, style: textStyle, textAlign: TextAlign.right),
        Text(lineKota, style: textStyle, textAlign: TextAlign.right),
        Text(lineProvinsi, style: textStyle, textAlign: TextAlign.right),
        Text(lineAltitude, style: textStyle, textAlign: TextAlign.right),
        if (lineCoords != null) Text(lineCoords, style: textStyle, textAlign: TextAlign.right),
        Text(lineIndex, style: textStyle, textAlign: TextAlign.right),
      ],
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: stampContent,
      );
    }

    return stampContent;
  }
}
