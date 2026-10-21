// ============================================================
// Jakdrain — Home Screen (Shell with Bottom Navigation)
// Menggabungkan semua tab utama dengan navigasi bawah.
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jakdrain/providers/navigation_provider.dart';
import 'package:jakdrain/ui/screens/dashboard_screen.dart';
import 'package:jakdrain/ui/screens/map_view_screen.dart';
import 'package:jakdrain/ui/screens/camera_scan_screen_fixed.dart';
import 'package:jakdrain/ui/screens/report_list_screen.dart';
import 'package:jakdrain/ui/screens/profile_screen.dart';
import 'package:jakdrain/ui/widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Daftar layar utama (kecuali kamera yang full-screen).
  final List<Widget> _screens = const [
    DashboardScreen(),
    MapViewScreen(),
    CameraScanScreen(),
    ReportListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navProvider.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: navProvider.currentIndex,
            onTap: (index) {
              navProvider.setIndex(index);
            },
          ),
        );
      },
    );
  }
}
