// ============================================================
// Jakdrain — Camera Scan Provider
// Mengelola state proses pemindaian kamera dan hasil AI.
// ============================================================
import 'package:flutter/material.dart';
import 'package:jakdrain/core/mock_ai.dart';

enum ScanState { idle, scanning, processing, done, error }

class CameraScanProvider extends ChangeNotifier {
  ScanState _state = ScanState.idle;
  AiScanResult? _lastResult;
  String? _errorMessage;

  ScanState get state => _state;
  AiScanResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;

  /// Mulai proses scan — tampilkan animasi scanning lalu proses AI.
  Future<void> startScan() async {
    _state = ScanState.scanning;
    _errorMessage = null;
    notifyListeners();

    // Delay animasi scan wave
    await Future.delayed(const Duration(milliseconds: 1200));

    _state = ScanState.processing;
    notifyListeners();

    try {
      _lastResult = await MockAiProcessor.analyzeImage();
      _state = ScanState.done;
    } catch (e) {
      _state = ScanState.error;
      _errorMessage = 'Gagal memproses gambar. Silakan coba lagi.';
    }
    notifyListeners();
  }

  /// Reset state untuk scan ulang.
  void resetScan() {
    _state = ScanState.idle;
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
