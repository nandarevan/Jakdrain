// ============================================================
// Jakdrain — Jakarta Micro-Drainage & Sedimentation Predictor
// Sistem Monitoring & Prediksi Sedimentasi Drainase Mikro DKI Jakarta
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/providers/navigation_provider.dart';
import 'package:jakdrain/providers/map_filter_provider.dart';
import 'package:jakdrain/providers/camera_scan_provider.dart';
import 'package:jakdrain/providers/user_provider.dart';
import 'package:jakdrain/providers/drainage_provider.dart';
import 'package:jakdrain/ui/screens/login_screen.dart';
import 'package:jakdrain/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan Google Services
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization: $e');
  }

  // Inisialisasi locale data bahasa Indonesia untuk intl DateFormat
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  // Set preferensi orientasi layar portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set style status bar & navigasi sistem
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inisialisasi Sesi Login (Periksa apakah belum 2 menit)
  final userProvider = UserProvider();
  await userProvider.initSession();

  runApp(JakdrainApp(userProvider: userProvider));
}

/// Root widget aplikasi Jakdrain dengan MultiProvider & Theme terintegrasi.
class JakdrainApp extends StatelessWidget {
  final UserProvider userProvider;

  const JakdrainApp({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => DrainageProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => MapFilterProvider()),
        ChangeNotifierProvider(create: (_) => CameraScanProvider()),
      ],
      child: MaterialApp(
        title: 'Jakdrain',
        debugShowCheckedModeBanner: false,
        theme: JakdrainTheme.lightTheme,
        home: const JakdrainSessionGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Gate sesi yang mendeteksi lifecycle & aktivitas sentuhan (timeout 2 menit)
class JakdrainSessionGate extends StatefulWidget {
  const JakdrainSessionGate({super.key});

  @override
  State<JakdrainSessionGate> createState() => _JakdrainSessionGateState();
}

class _JakdrainSessionGateState extends State<JakdrainSessionGate> with WidgetsBindingObserver {
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
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi dibuka kembali dari background/minimize:
      // Hanya logout jika sudah LEBIH DARI 2 MENIT! Jika belum 2 menit, TETAP LOGIN!
      userProvider.checkSessionValidity();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Rekam waktu saat aplikasi diminimize atau layar dikunci
      userProvider.updateActiveTimestamp(forcePersist: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        // Tangkap setiap sentuhan layar untuk mereset countdown timeout 2 menit
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => userProvider.updateActiveTimestamp(),
          child: userProvider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
