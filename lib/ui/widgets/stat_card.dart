// ============================================================
// Jakdrain — StatCard Widget
// Kartu statistik ringkas untuk dashboard.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jakdrain/core/theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? JakdrainColors.electricBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 154,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted
                ? color.withValues(alpha: 0.4)
                : JakdrainColors.divider.withValues(alpha: 0.6),
            width: isHighlighted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? color.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon dengan background warna
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (isHighlighted)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Value besar dengan FittedBox agar tidak overflow di layar kecil/font besar
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? color : JakdrainColors.deepNavy,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JakdrainColors.subtleGray,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Versi animasi StatCard yang muncul dengan fade + slide.
class AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final bool isHighlighted;
  final int delayMs;
  final VoidCallback? onTap;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
    this.isHighlighted = false,
    this.delayMs = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: title,
      value: value,
      icon: icon,
      accentColor: accentColor,
      isHighlighted: isHighlighted,
      onTap: onTap,
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: delayMs),
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: delayMs),
          curve: Curves.easeOutCubic,
        );
  }
}
