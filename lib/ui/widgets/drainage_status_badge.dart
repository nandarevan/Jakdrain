// ============================================================
// Jakdrain — DrainageStatusBadge Widget
// Badge visual untuk menampilkan status drainase.
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jakdrain/core/theme.dart';
import 'package:jakdrain/data/models.dart';

class DrainageStatusBadge extends StatelessWidget {
  final DrainageStatus status;
  final bool showIcon;
  final double fontSize;

  const DrainageStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(config.icon, size: 12, color: config.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            config.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case DrainageStatus.kritis:
        return _BadgeConfig(
          label: 'Kritis',
          textColor: JakdrainColors.critical,
          bgColor: JakdrainColors.criticalLight,
          icon: Icons.warning_rounded,
        );
      case DrainageStatus.waspada:
        return _BadgeConfig(
          label: 'Waspada',
          textColor: JakdrainColors.warning,
          bgColor: JakdrainColors.warningLight,
          icon: Icons.info_outline_rounded,
        );
      case DrainageStatus.aman:
        return _BadgeConfig(
          label: 'Aman',
          textColor: JakdrainColors.safe,
          bgColor: JakdrainColors.safeLight,
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color textColor;
  final Color bgColor;
  final IconData icon;

  const _BadgeConfig({
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.icon,
  });
}

/// Badge untuk status tugas PPSU.
class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;

  const TaskStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      TaskStatus.baruDilihat => (
        'Baru Dilihat',
        JakdrainColors.electricBlue,
        JakdrainColors.lightBlue50,
      ),
      TaskStatus.dalamPengerukan => (
        'Dalam Pengerukan',
        JakdrainColors.warning,
        JakdrainColors.warningLight,
      ),
      TaskStatus.selesai => (
        'Selesai',
        JakdrainColors.safe,
        JakdrainColors.safeLight,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
