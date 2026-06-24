part of comic_ruleta_app;

// ================== COMIC PAINTERS ==================

class _HeroGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.56);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.32),
              Colors.white.withOpacity(0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.48, 1.0],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.55),
          );

    canvas.drawCircle(center, size.width * 0.55, glowPaint);

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.18);
    final shadowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.93),
      width: size.width * 0.55,
      height: 18,
    );
    canvas.drawOval(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthComicDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.07);
    const step = 20.0;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final strength = ((x / size.width) * 0.35 + (y / size.height) * 0.55)
            .clamp(0.2, 1.0);
        canvas.drawCircle(Offset(x, y), 0.9 + strength * 1.05, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmileComicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height * 1.55, size.width, 0);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniCityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(.75);
    final widths = [12.0, 9.0, 14.0, 8.0, 11.0, 15.0, 10.0];
    double x = 0;
    for (int i = 0; i < widths.length && x < size.width; i++) {
      final h = 12.0 + (i % 4) * 5.0;
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, widths[i], h), p);
      x += widths[i] + 3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerComicPainter extends CustomPainter {
  final String tipo;

  const _PointerComicPainter({this.tipo = 'clasico'});

  @override
  void paint(Canvas canvas, Size size) {
    switch (tipo) {
      case 'esfera':
        _drawEsfera(canvas, size);
        break;
      case 'murcielago':
        _drawMurcielago(canvas, size);
        break;
      case 'rayo':
        _drawRayo(canvas, size);
        break;
      case 'anillo':
        _drawAnillo(canvas, size);
        break;
      case 'clasico':
      default:
        _drawClasico(canvas, size);
        break;
    }
  }

  void _drawClasico(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  void _drawEsfera(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.38;

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFF9500));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final starPaint = Paint()..color = const Color(0xFFFF3B30);
    for (int i = 0; i < 4; i++) {
      final dx = center.dx + (i - 1.5) * radius * 0.28;
      canvas.drawCircle(Offset(dx, center.dy), radius * 0.08, starPaint);
    }
  }

  void _drawMurcielago(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.50, h * 0.25)
      ..lineTo(w * 0.58, h * 0.43)
      ..quadraticBezierTo(w * 0.75, h * 0.18, w * 0.96, h * 0.36)
      ..quadraticBezierTo(w * 0.82, h * 0.44, w * 0.78, h * 0.70)
      ..quadraticBezierTo(w * 0.64, h * 0.55, w * 0.55, h * 0.78)
      ..lineTo(w * 0.50, h * 0.60)
      ..lineTo(w * 0.45, h * 0.78)
      ..quadraticBezierTo(w * 0.36, h * 0.55, w * 0.22, h * 0.70)
      ..quadraticBezierTo(w * 0.18, h * 0.44, w * 0.04, h * 0.36)
      ..quadraticBezierTo(w * 0.25, h * 0.18, w * 0.42, h * 0.43)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.black);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawRayo(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.58, h * 0.02)
      ..lineTo(w * 0.22, h * 0.55)
      ..lineTo(w * 0.48, h * 0.55)
      ..lineTo(w * 0.35, h * 0.98)
      ..lineTo(w * 0.80, h * 0.38)
      ..lineTo(w * 0.54, h * 0.38)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD60A));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawAnillo(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.36;
    final paint = Paint()
      ..color = const Color(0xFFFFD60A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PointerComicPainter oldDelegate) {
    return oldDelegate.tipo != tipo;
  }
}

class _WheelComicPainter extends CustomPainter {
  final List<String> items;
  final bool modoClasico;

  const _WheelComicPainter({required this.items, required this.modoClasico});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final n = items.length;
    final visualSegments = n;
    final slice = 2 * pi / visualSegments;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    final colors = <Color>[
      const Color(0xFFFFD60A),
      const Color(0xFFFF3B30),
      const Color(0xFF34C759),
      const Color(0xFF00B7FF),
      const Color(0xFF6A0DAD),
      const Color(0xFFFF9500),
      const Color(0xFFFFFFFF),
      const Color(0xFFFFB6C1),
    ];

    final segmentColors = _buildSegmentColors(visualSegments, colors);

    for (int i = 0; i < visualSegments; i++) {
      final start = -pi / 2 + i * slice;
      Color col = segmentColors[i];

      if (modoClasico) {
        final g = ((col.red * 0.3) + (col.green * 0.59) + (col.blue * 0.11))
            .round();
        col = Color.fromARGB(255, g, g, g);
      }

      canvas.drawArc(rect, start, slice, true, Paint()..color = col);
      canvas.drawArc(
        rect,
        start,
        slice,
        true,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = n > 36 ? 0.8 : (n > 24 ? 1.1 : 2.2),
      );

      final label = n <= 16 ? items[i] : _shortLabel(items[i]);
      final angle = start + slice / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: _fontSizeForCount(label, n),
            fontWeight: FontWeight.w900,
            color: modoClasico ? Colors.white : Colors.black,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * _labelMaxWidthFactor(n));

      final cx = c.dx + cos(angle) * r * _labelRadiusFactor(n);
      final cy = c.dy + sin(angle) * r * _labelRadiusFactor(n);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final ringColor = modoClasico ? Colors.black : Colors.white;
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..color = ringColor,
    );
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.black,
    );

    canvas.drawCircle(c, r * 0.15, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      r * 0.15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.black,
    );

    final starPainter = TextPainter(
      text: const TextSpan(
        text: '★',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    starPainter.paint(
      canvas,
      Offset(c.dx - starPainter.width / 2, c.dy - starPainter.height / 2),
    );
  }

  List<Color> _buildSegmentColors(int count, List<Color> palette) {
    if (count <= 0) return const [];
    if (palette.isEmpty) return List<Color>.filled(count, Colors.white);

    final result = <Color>[];

    for (int i = 0; i < count; i++) {
      var colorIndex = i % palette.length;
      var color = palette[colorIndex];

      if (result.isNotEmpty && color == result.last) {
        colorIndex = (colorIndex + 1) % palette.length;
        color = palette[colorIndex];
      }

      result.add(color);
    }

    if (result.length > 2 && result.first == result.last) {
      for (final candidate in palette) {
        if (candidate != result.first &&
            candidate != result[result.length - 2]) {
          result[result.length - 1] = candidate;
          break;
        }
      }
    }

    return result;
  }

  String _shortLabel(String text) {
    final parts = text.trim().split(RegExp(r'\\s+'));
    if (parts.length == 1)
      return parts.first.substring(0, min(3, parts.first.length)).toUpperCase();
    return parts.take(2).map((p) => p.substring(0, 1).toUpperCase()).join();
  }

  double _fontSizeForCount(String text, int count) {
    if (count <= 8) return _fontSize(text);
    if (count <= 16) return text.length <= 10 ? 11.5 : 9.8;
    if (count <= 28) return 8.8;
    if (count <= 45) return 7.5;
    return 6.4;
  }

  double _labelMaxWidthFactor(int count) {
    if (count <= 12) return 0.50;
    if (count <= 24) return 0.42;
    if (count <= 45) return 0.34;
    return 0.28;
  }

  double _labelRadiusFactor(int count) {
    if (count <= 16) return 0.62;
    if (count <= 36) return 0.68;
    return 0.72;
  }

  double _fontSize(String text) {
    if (text.length <= 8) return 15;
    if (text.length <= 12) return 13;
    if (text.length <= 18) return 11.5;
    return 10;
  }

  @override
  bool shouldRepaint(covariant _WheelComicPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.modoClasico != modoClasico;
  }
}

class _DotsPainter extends CustomPainter {
  final bool modoClasico;

  _DotsPainter({required this.modoClasico});

  @override
  void paint(Canvas canvas, Size size) {
    const step = 12.0;
    const clearRadius = 190.0;
    const fadeRadius = 360.0;

    final center = Offset(size.width / 2, size.height * 0.43);

    final corners = <Offset>[
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final p = Offset(x, y);
        final distToWheel = (p - center).distance;

        if (distToWheel <= clearRadius) continue;

        double cornerStrength = 0.0;

        for (final c in corners) {
          final influence =
              (1.0 - ((p - c).distance / (size.longestSide * 0.95))).clamp(
                0.0,
                1.0,
              );

          if (influence > cornerStrength) {
            cornerStrength = influence;
          }
        }

        final fadeToWheel =
            ((distToWheel - clearRadius) / (fadeRadius - clearRadius)).clamp(
              0.0,
              1.0,
            );

        final strength = (cornerStrength * fadeToWheel).clamp(0.0, 1.0);

        if (strength < 0.05) continue;

        final opacity = modoClasico
            ? (0.10 + 0.22 * strength).clamp(0.0, 0.30)
            : (0.14 + 0.34 * strength).clamp(0.0, 0.46);

        final radius = 1.0 + (3.4 * strength);

        canvas.drawCircle(
          p,
          radius,
          Paint()..color = Colors.black.withOpacity(opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) {
    return oldDelegate.modoClasico != modoClasico;
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..lineTo(size.width * 0.24, size.height + 16)
      ..lineTo(size.width * 0.30, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final path = Path();
    final points = 22;
    for (int i = 0; i < points; i++) {
      final a = -pi / 2 + (2 * pi * i / points);
      final r = i.isEven ? size.width * 0.48 : size.width * 0.38;
      final p = Offset(
        c.dx + cos(a) * r,
        c.dy + sin(a) * min(r * 0.42, size.height * 0.45),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFF3B30));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final circles = [
      Offset(size.width * .18, size.height * .65),
      Offset(size.width * .34, size.height * .42),
      Offset(size.width * .52, size.height * .50),
      Offset(size.width * .70, size.height * .40),
      Offset(size.width * .84, size.height * .65),
    ];
    final radii = [
      size.height * .30,
      size.height * .38,
      size.height * .34,
      size.height * .40,
      size.height * .30,
    ];
    for (int i = 0; i < circles.length; i++) {
      canvas.drawCircle(circles[i], radii[i], paint);
    }
    for (int i = 0; i < circles.length; i++) {
      canvas.drawCircle(circles[i], radii[i], stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpeedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withOpacity(.22)
      ..strokeWidth = 3;
    final center = Offset(size.width / 2, size.height * .35);
    final starts = [
      Offset(0, size.height * .05),
      Offset(size.width, size.height * .08),
      Offset(0, size.height * .35),
      Offset(size.width, size.height * .38),
      Offset(size.width * .12, 0),
      Offset(size.width * .88, 0),
    ];
    for (final s in starts) {
      canvas.drawLine(s, Offset.lerp(s, center, .35)!, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
