import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/services/ambient_sound_service.dart';

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 35; i++) {
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

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _AmbientPainter(
              particles: _particles,
              trackId: ambientState.activeTrackId!,
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double opacity;

  _Particle(Random rand) {
    reset(rand);
  }

  void reset(Random rand) {
    x = rand.nextDouble();
    y = rand.nextDouble();
    speed = 0.003 + rand.nextDouble() * 0.007;
    size = 2.0 + rand.nextDouble() * 4.0;
    opacity = 0.2 + rand.nextDouble() * 0.5;
  }
}

class _AmbientPainter extends CustomPainter {
  final List<_Particle> particles;
  final String trackId;
  final double animationValue;

  _AmbientPainter({
    required this.particles,
    required this.trackId,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (trackId) {
      case 'rain':
        _paintRain(canvas, size);
        break;
      case 'forest':
        _paintForest(canvas, size);
        break;
      case 'campfire':
        _paintCampfire(canvas, size);
        break;
      case 'waves':
        _paintWaves(canvas, size);
        break;
      case 'whitenoise':
        _paintCosmic(canvas, size);
        break;
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.iceBlue.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final y = ((p.y + animationValue * (p.speed * 80)) % 1.0) * size.height;
      final x = ((p.x - animationValue * 0.1) % 1.0) * size.width;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 14),
        paint,
      );
    }
  }

  void _paintForest(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final y = ((p.y + animationValue * (p.speed * 15)) % 1.0) * size.height;
      final waveOffset = sin((animationValue * 2 * pi) + p.x * 10) * 15;
      final x = (p.x * size.width) + waveOffset;

      paint.color = AppColors.softGreen.withValues(alpha: p.opacity * 0.6);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  void _paintCampfire(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Rise upwards
      final y = size.height - (((p.y + animationValue * (p.speed * 30)) % 1.0) * size.height);
      final sway = sin(animationValue * 4 * pi + p.y * 8) * 12;
      final x = (p.x * size.width) + sway;

      paint.color = AppColors.amber.withValues(alpha: p.opacity * 0.7);
      canvas.drawCircle(Offset(x, y), p.size * 0.9, paint);
    }
  }

  void _paintWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.iceBlue.withValues(alpha: 0.25);

    final path = Path();
    final baseY = size.height * 0.85;

    path.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x += 10) {
      final y = baseY + sin((x / 50) + (animationValue * 2 * pi)) * 14;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final path2 = Path();
    final baseY2 = size.height * 0.89;
    paint.color = AppColors.neonPurple.withValues(alpha: 0.2);
    path2.moveTo(0, baseY2);
    for (double x = 0; x <= size.width; x += 10) {
      final y = baseY2 + cos((x / 60) + (animationValue * 2 * pi)) * 10;
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint);
  }

  void _paintCosmic(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final alphaPulse = (sin(animationValue * 2 * pi + p.x * 5) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: p.opacity * alphaPulse * 0.8);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => true;
}
