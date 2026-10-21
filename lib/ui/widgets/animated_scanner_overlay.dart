// ============================================================
// Jakdrain — Animated Scanner Overlay Widget
// Overlay animasi scanning pada kamera viewfinder.
// ============================================================
import 'package:flutter/material.dart';
import 'package:jakdrain/core/theme.dart';

/// Overlay frame guide dan animasi scan wave.
class AnimatedScannerOverlay extends StatefulWidget {
  final bool isScanning;

  const AnimatedScannerOverlay({super.key, this.isScanning = false});

  @override
  State<AnimatedScannerOverlay> createState() => _AnimatedScannerOverlayState();
}

class _AnimatedScannerOverlayState extends State<AnimatedScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth * 0.82;
        final frameHeight = constraints.maxHeight * 0.45;
        final left = (constraints.maxWidth - frameWidth) / 2;
        final top = (constraints.maxHeight - frameHeight) / 2.5;

        return Stack(
          children: [
            // Semi-transparent dark overlay di luar frame
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _OverlayPainter(
                frameRect: Rect.fromLTWH(left, top, frameWidth, frameHeight),
              ),
            ),

            // Frame guide corners
            Positioned(
              left: left,
              top: top,
              child: _FrameCorners(width: frameWidth, height: frameHeight),
            ),

            // Scan line (garis bergerak ke atas-bawah saat scanning)
            if (widget.isScanning)
              AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  final lineY = top + (_scanLineAnimation.value * frameHeight);
                  return Positioned(
                    left: left + 8,
                    top: lineY,
                    child: Container(
                      width: frameWidth - 16,
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            JakdrainColors.skyBlueAccent.withValues(alpha: 0),
                            JakdrainColors.skyBlueAccent,
                            JakdrainColors.skyBlueAccent.withValues(alpha: 0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: JakdrainColors.skyBlueAccent
                                .withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Guide text
            Positioned(
              left: left,
              top: top + frameHeight + 16,
              width: frameWidth,
              child: Text(
                widget.isScanning
                    ? 'Memindai kondisi drainase...'
                    : 'Posisikan kamera sejajar dengan\npermukaan selokan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Menggambar overlay gelap di luar area frame.
class _OverlayPainter extends CustomPainter {
  final Rect frameRect;

  _OverlayPainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final framePath = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)));
    final overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, framePath);

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      frameRect != oldDelegate.frameRect;
}

/// Corner brackets untuk frame guide.
class _FrameCorners extends StatelessWidget {
  final double width;
  final double height;

  const _FrameCorners({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CornerPainter(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JakdrainColors.skyBlueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    const r = 10.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(cornerLen, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(size.width, cornerLen),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height - r)
        ..arcToPoint(Offset(r, size.height),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(cornerLen, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width - r, size.height)
        ..arcToPoint(Offset(size.width, size.height - r),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(size.width, size.height - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
