import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/core/services/ambient_sound_service.dart';

/// Ultra-smooth, battery-efficient ambient visual layer.
///
/// Features isolated render layer ([RepaintBoundary]), pre-allocated drawing objects,
/// and premium atmospheric animations (Tide / Endel inspired) for:
/// - Rain (soft luminous streaks & floor ripple splashes)
/// - Forest (gentle bioluminescent floating fireflies)
/// - Campfire (rising glowing golden embers & warm floor glow)
/// - Ocean Waves (deep oceanic swell with glowing crest)
/// - White Noise / Cosmic (twinkling nebula starfield)
class AmbientVisualLayer extends ConsumerStatefulWidget {
  const AmbientVisualLayer({super.key});

  @override
  ConsumerState<AmbientVisualLayer> createState() => _AmbientVisualLayerState();
}

class _AmbientVisualLayerState extends ConsumerState<AmbientVisualLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // 12-second smooth loop for peaceful pacing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 24 particles provide a rich, non-distracting atmospheric ambiance
    for (int i = 0; i < 24; i++) {
      _particles.add(_Particle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambientState = ref.watch(ambientSoundProvider);

    if (!ambientState.isPlaying || ambientState.activeTrackId == null) {
      return const SizedBox.shrink();
    }

    // RepaintBoundary isolates paint updates to this layer,
    // ensuring the timer, controls, and tree visuals do NOT re-composite every frame!
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _AtmosphericAmbientPainter(
                particles: _particles,
                trackId: ambientState.activeTrackId!,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double baseOpacity;
  late double phase;

  _Particle(Random rand) {
    reset(rand);
  }

  void reset(Random rand) {
    x = rand.nextDouble();
    y = rand.nextDouble();
    speed = 0.002 + rand.nextDouble() * 0.005;
    size = 2.0 + rand.nextDouble() * 3.5;
    baseOpacity = 0.25 + rand.nextDouble() * 0.50;
    phase = rand.nextDouble() * 2 * pi;
  }
}

class _AtmosphericAmbientPainter extends CustomPainter {
  final List<_Particle> particles;
  final String trackId;
  final double progress;

  // Reusable paint instances to eliminate per-frame object allocations
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;

  _AtmosphericAmbientPainter({
    required this.particles,
    required this.trackId,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (trackId) {
      case 'rain':
        _paintAtmosphericRain(canvas, size);
        break;
      case 'forest':
        _paintBioluminescentForest(canvas, size);
        break;
      case 'campfire':
        _paintCampfireEmbers(canvas, size);
        break;
      case 'waves':
        _paintOceanSwell(canvas, size);
        break;
      case 'whitenoise':
        _paintCosmicNebula(canvas, size);
        break;
    }
  }

  // ─── 1. RAIN: Luminous angled raindrops & ground ripple mist ────────────
  void _paintAtmosphericRain(Canvas canvas, Size size) {
    _strokePaint
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x387DF9FF); // Soft Ice Blue

    for (final p in particles) {
      final y = ((p.y + progress * (p.speed * 120)) % 1.0) * size.height;
      final x = ((p.x - progress * 0.15) % 1.0) * size.width;

      final length = 12.0 + p.size * 3.0;
      // 12-degree angle
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 2.5, y + length),
        _strokePaint,
      );

      // Subtle splash ripple near bottom
      if (y > size.height * 0.82) {
        final rippleProgress = (y - size.height * 0.82) / (size.height * 0.18);
        final rippleAlpha = ((1.0 - rippleProgress) * 0.25).clamp(0.0, 0.25);
        _strokePaint
          ..strokeWidth = 0.8
          ..color = Color.fromRGBO(125, 249, 255, rippleAlpha);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y + length),
            width: 8.0 + rippleProgress * 12.0,
            height: 3.0 + rippleProgress * 4.0,
          ),
          _strokePaint,
        );
      }
    }
  }

  // ─── 2. FOREST: Floating glowing fireflies with soft radial auras ────────
  void _paintBioluminescentForest(Canvas canvas, Size size) {
    for (final p in particles) {
      // Natural organic floating drift
      final driftX = sin(progress * 2 * pi + p.phase) * 18.0;
      final driftY = cos(progress * 2 * pi + p.phase) * 12.0;
      final x = (p.x * size.width + driftX) % size.width;
      final y = ((p.y - progress * (p.speed * 15)) % 1.0) * size.height + driftY;

      // Breathing light pulse
      final pulse = (sin(progress * 4 * pi + p.phase) + 1.0) * 0.5;
      final alpha = (p.baseOpacity * (0.3 + pulse * 0.7)).clamp(0.0, 1.0);

      // Outer soft aura
      _glowPaint.color = Color.fromRGBO(74, 222, 128, alpha * 0.25); // softGreen
      canvas.drawCircle(Offset(x, y), p.size * 3.2, _glowPaint);

      // Inner glowing core
      _fillPaint.color = Color.fromRGBO(217, 249, 157, alpha * 0.85); // bright lime
      canvas.drawCircle(Offset(x, y), p.size * 0.9, _fillPaint);
    }
  }

  // ─── 3. CAMPFIRE: Rising warm embers & breathing hearth glow ─────────────
  void _paintCampfireEmbers(Canvas canvas, Size size) {
    // Warm ambient hearth glow at the bottom
    final hearthPulse = (sin(progress * 3 * pi) + 1.0) * 0.5;
    final hearthRect = Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25);
    _glowPaint.shader = RadialGradient(
      center: Alignment.bottomCenter,
      radius: 0.9,
      colors: [
        Color.fromRGBO(251, 191, 36, 0.08 + hearthPulse * 0.05), // Amber
        Colors.transparent,
      ],
    ).createShader(hearthRect);
    canvas.drawRect(hearthRect, _glowPaint);
    _glowPaint.shader = null;

    // Rising flickering embers
    for (final p in particles) {
      final y = size.height - (((p.y + progress * (p.speed * 45)) % 1.0) * size.height);
      final sway = sin(progress * 6 * pi + p.phase) * (8.0 + p.size * 2.0);
      final x = (p.x * size.width + sway) % size.width;

      // Fade out as it rises to the top
      final heightRatio = (y / size.height).clamp(0.0, 1.0);
      final alpha = (p.baseOpacity * heightRatio * 0.9).clamp(0.0, 1.0);

      // Warm glow around ember
      _glowPaint.color = Color.fromRGBO(249, 115, 22, alpha * 0.35); // Orange
      canvas.drawCircle(Offset(x, y), p.size * 2.2, _glowPaint);

      // Bright ember point
      _fillPaint.color = Color.fromRGBO(254, 240, 138, alpha); // Bright gold
      canvas.drawCircle(Offset(x, y), p.size * 0.7, _fillPaint);
    }
  }

  // ─── 4. OCEAN WAVES: Deep swells with luminous glowing crests ────────────
  void _paintOceanSwell(Canvas canvas, Size size) {
    final baseY = size.height * 0.88;

    // Primary Swell
    _strokePaint
      ..strokeWidth = 2.0
      ..color = const Color(0x407DF9FF); // Ice blue crest

    final wavePath1 = Path();
    wavePath1.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x += 16) {
      final y = baseY + sin((x / 65) + (progress * 2 * pi)) * 10;
      wavePath1.lineTo(x, y);
    }
    canvas.drawPath(wavePath1, _strokePaint);

    // Secondary Deeper Swell
    _strokePaint
      ..strokeWidth = 1.4
      ..color = const Color(0x288A2BE2); // Neon purple undertone

    final wavePath2 = Path();
    final baseY2 = size.height * 0.92;
    wavePath2.moveTo(0, baseY2);
    for (double x = 0; x <= size.width; x += 16) {
      final y = baseY2 + cos((x / 80) + (progress * 2 * pi)) * 8;
      wavePath2.lineTo(x, y);
    }
    canvas.drawPath(wavePath2, _strokePaint);

    // Gentle floating sea foam motes
    for (final p in particles) {
      if (p.y > 0.70) {
        final x = (p.x * size.width + sin(progress * 2 * pi + p.phase) * 10) % size.width;
        final y = p.y * size.height;
        final alpha = (p.baseOpacity * 0.4).clamp(0.0, 1.0);
        _fillPaint.color = Color.fromRGBO(125, 249, 255, alpha);
        canvas.drawCircle(Offset(x, y), p.size * 0.6, _fillPaint);
      }
    }
  }

  // ─── 5. COSMIC / WHITE NOISE: Twinkling starlight nebula ─────────────────
  void _paintCosmicNebula(Canvas canvas, Size size) {
    for (final p in particles) {
      // Gentle twinkle oscillation
      final twinkle = (sin(progress * 4 * pi + p.phase) + 1.0) * 0.5;
      final alpha = (p.baseOpacity * (0.2 + twinkle * 0.8)).clamp(0.0, 1.0);

      final x = p.x * size.width;
      final y = p.y * size.height;

      // Star halo
      _glowPaint.color = Color.fromRGBO(200, 220, 255, alpha * 0.20);
      canvas.drawCircle(Offset(x, y), p.size * 2.5, _glowPaint);

      // Sharp star center
      _fillPaint.color = Color.fromRGBO(255, 255, 255, alpha * 0.90);
      canvas.drawCircle(Offset(x, y), p.size * 0.6, _fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphericAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.trackId != trackId;
  }
}
