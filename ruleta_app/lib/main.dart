import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ComicRuletaApp());

class ComicRuletaApp extends StatelessWidget {
  const ComicRuletaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: false,
      ),
      home: const RuletaPage(),
    );
  }
}

class RuletaPage extends StatefulWidget {
  const RuletaPage({super.key});

  @override
  State<RuletaPage> createState() => _RuletaPageState();
}

class _RuletaPageState extends State<RuletaPage>
    with SingleTickerProviderStateMixin {
  // ================== ITEMS ==================
  final List<String> items = const [
    '1',
    '2',
    '3',
    '4',
    '5',
    'Ana',
    'Deisy',
    'Diana',
  ];

  // ================== API ==================
  final Uri apiUrl = Uri.parse('http://10.0.2.2:8000/giro');

  // ================== ANIMACIÓN ==================
  late final AnimationController _controller;
  final Random _rand = Random();
  double _angle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;

  // ================== ESTADO UI ==================
  bool _girando = false;
  bool _mostrarResultado = false;
  String _resultado = '';
  String _estado = '';
  int _contadorGiros = 0;

  // ================== MODO CLÁSICO ==================
  bool _modoClasico = false;
  bool _bannerClasico = false;

  // ================== POP ==================
  bool _popVisible = false;
  Offset _popPos = const Offset(0, 0);
  String _popText = 'POP!';

  // ================== COLORES FONDO ==================
  final List<Color> fondos = const [
    Color(0xFF00B7FF),
    Color(0xFFFF3B30),
    Color(0xFFFFD60A),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];
  Color _fondoActual = const Color(0xFFAF52DE);

  int get n => items.length;
  double get slice => 2 * pi / n;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _controller.addListener(() {
      final t = Curves.easeOutCubic.transform(_controller.value);
      setState(() {
        _angle = _startAngle + (_targetAngle - _startAngle) * t;
      });
    });

    _controller.addStatusListener((s) async {
      if (s == AnimationStatus.completed) {
        setState(() => _girando = false);

        final idx = _pickIndexUnderPointer();
        final selected = items[idx];

        setState(() {
          _resultado = selected;
          _mostrarResultado = true;
          _estado = '';
        });

        await _enviarAPython(selected);

        if (_modoClasico) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          if (mounted) setState(() => _modoClasico = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================== LÓGICA RESULTADO ==================
  int _pickIndexUnderPointer() {
    const pointer = -pi / 2;
    int best = 0;
    double bestDist = 1e9;

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + i * slice;
      final center = start + slice / 2 + _angle;
      final dist = _angDist(center, pointer);
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  double _norm(double a) {
    final t = a % (2 * pi);
    return t < 0 ? t + 2 * pi : t;
  }

  double _angDist(double a, double b) {
    final d = _norm(a - b);
    return d > pi ? 2 * pi - d : d;
  }

  // ================== API ==================
  Future<void> _enviarAPython(String valor) async {
    try {
      final res = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'valor': valor}),
      );

      if (res.statusCode == 200) {
        setState(() => _estado = 'Guardado ✅');
      } else {
        setState(() => _estado = 'Error ❌ (${res.statusCode})');
      }
    } catch (_) {
      setState(() => _estado = 'No conecta con Python ❌');
    }
  }

  // ================== EFECTOS UI ==================
  void _cambiarFondo() {
    final next = fondos[_rand.nextInt(fondos.length)];
    setState(() => _fondoActual = next);
  }

  void _popEn(Offset globalPos, {String text = 'POP!'}) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final local = overlay.globalToLocal(globalPos);

    setState(() {
      _popText = text;
      _popVisible = true;
      _popPos = local.translate(0, -18);
    });

    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (mounted) setState(() => _popVisible = false);
    });
  }

  Future<void> _mostrarBannerClasico() async {
    setState(() => _bannerClasico = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _bannerClasico = false);
  }

  // ================== ACCIONES ==================
  Future<void> _spin(Offset tapGlobal) async {
    if (_girando) return;

    _cambiarFondo();
    _popEn(tapGlobal);

    final siguienteNumero = _contadorGiros + 1;
    final activarClasicoEnEsteGiro = (siguienteNumero % 5 == 0);

    setState(() {
      _girando = true;
      _mostrarResultado = false;
      _resultado = '';
      _estado = '';
      _contadorGiros++;
      if (activarClasicoEnEsteGiro) _modoClasico = true;
    });

    if (activarClasicoEnEsteGiro) {
      await _mostrarBannerClasico();
    }

    final extraTurns = 6 + _rand.nextInt(4);
    final randomStop = _rand.nextDouble() * 2 * pi;

    setState(() {
      _startAngle = _angle;
      _targetAngle = _angle + extraTurns * 2 * pi + randomStop;
    });

    _controller
      ..reset()
      ..forward();
  }

  void _reset(Offset tapGlobal) {
    if (_girando) return;

    _cambiarFondo();
    _popEn(tapGlobal);

    setState(() {
      _angle = 0.0;
      _mostrarResultado = false;
      _resultado = '';
      _estado = '';
    });
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wheelSize = min(w * 0.82, 360.0);

    final bg = _modoClasico ? Colors.white : _fondoActual;
    final titleColor = _modoClasico ? Colors.black : Colors.white;

    return Scaffold(
      body: Container(
        color: bg,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _ComicDotsBackground(modoClasico: _modoClasico),
              ),

              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _bannerClasico ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const _BannerComic(text: 'MODO CLÁSICO ACTIVADO'),
                ),
              ),

              Positioned(
                left: _popPos.dx - 60,
                top: _popPos.dy - 40,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: _popVisible ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 140),
                    child: AnimatedOpacity(
                      opacity: _popVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 140),
                      child: _PopComic(text: _popText),
                    ),
                  ),
                ),
              ),

              // SUBIMOS TODO (ya no abajo pegado)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: Column(
                    children: [
                      // TITULO
                      Text(
                        'RULETA CÓMIC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          letterSpacing: 1.0,
                          shadows: const [
                            Shadow(
                              offset: Offset(3, 3),
                              blurRadius: 0,
                              color: Colors.black,
                            ),
                            Shadow(
                              offset: Offset(-3, 3),
                              blurRadius: 0,
                              color: Colors.black,
                            ),
                            Shadow(
                              offset: Offset(3, -3),
                              blurRadius: 0,
                              color: Colors.black,
                            ),
                            Shadow(
                              offset: Offset(-3, -3),
                              blurRadius: 0,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // RUEDA (sin sombra abajo y SIN recortes)
                      SizedBox(
                        width: wheelSize + 36,
                        height: wheelSize + 46,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 0,
                              child: CustomPaint(
                                size: const Size(62, 44),
                                painter: _PointerComicPainter(
                                  modoClasico: _modoClasico,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 26,
                              child: CustomPaint(
                                size: Size(wheelSize, wheelSize),
                                painter: _WheelComicPainter(
                                  items: items,
                                  modoClasico: _modoClasico,
                                ),
                                child: Transform.rotate(
                                  angle: _angle,
                                  child: CustomPaint(
                                    size: Size(wheelSize, wheelSize),
                                    painter: _WheelComicPainter(
                                      items: items,
                                      modoClasico: _modoClasico,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // (nota) El painter del aro está dentro del painter de la rueda: por eso no se corta
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // BOTONES (POP sale donde haces tap)
                      Row(
                        children: [
                          Expanded(
                            child: _ComicButton(
                              text: 'GIRAR',
                              filled: true,
                              disabled: _girando,
                              modoClasico: _modoClasico,
                              onTapDown: (d) => _spin(d.globalPosition),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ComicButton(
                              text: 'REINICIAR',
                              filled: false,
                              disabled: _girando,
                              modoClasico: _modoClasico,
                              onTapDown: (d) => _reset(d.globalPosition),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // RESULTADO
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) {
                          return ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          );
                        },
                        child: _mostrarResultado
                            ? _ResultadoComic(
                                valor: _resultado,
                                estado: _estado,
                                modoClasico: _modoClasico,
                              )
                            : const SizedBox(key: ValueKey('empty')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================== BOTÓN CÓMIC ================== */

class _ComicButton extends StatelessWidget {
  final String text;
  final bool filled;
  final bool disabled;
  final bool modoClasico;
  final void Function(TapDownDetails d) onTapDown;

  const _ComicButton({
    required this.text,
    required this.filled,
    required this.disabled,
    required this.modoClasico,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? Colors.white : Colors.transparent;
    final fg = filled
        ? Colors.black
        : (modoClasico ? Colors.black : Colors.white);
    final borderColor = Colors.black;

    return GestureDetector(
      onTapDown: disabled ? null : onTapDown,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(4, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              shadows: filled
                  ? null
                  : const [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(-2, 2),
                        blurRadius: 0,
                        color: Colors.black,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================== RESULTADO CÓMIC ================== */

class _ResultadoComic extends StatelessWidget {
  final String valor;
  final String estado;
  final bool modoClasico;

  const _ResultadoComic({
    required this.valor,
    required this.estado,
    required this.modoClasico,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final fg = Colors.black;

    return Container(
      key: const ValueKey('result'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'RESULTADO TOTAL',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 40,
              height: 1,
            ),
          ),
          if (estado.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              estado,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

/* ================== BANNER CÓMIC ================== */

class _BannerComic extends StatelessWidget {
  final String text;
  const _BannerComic({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/* ================== POP CÓMIC ================== */

class _PopComic extends StatelessWidget {
  final String text;
  const _PopComic({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PopBurstPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

/* ================== FONDO PUNTOS ================== */

class _ComicDotsBackground extends StatelessWidget {
  final bool modoClasico;
  const _ComicDotsBackground({required this.modoClasico});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotsPainter(modoClasico: modoClasico));
  }
}

/* ================== PAINTERS ================== */

class _PointerComicPainter extends CustomPainter {
  final bool modoClasico;
  _PointerComicPainter({required this.modoClasico});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w / 2, h)
      ..lineTo(0, 0)
      ..lineTo(w, 0)
      ..close();

    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final dot = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(w / 2, h * 0.52), 4, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheelComicPainter extends CustomPainter {
  final List<String> items;
  final bool modoClasico;

  const _WheelComicPainter({required this.items, required this.modoClasico});

  @override
  void paint(Canvas canvas, Size size) {
    final n = items.length;
    final slice = 2 * pi / n;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    final baseColors = <Color>[
      const Color(0xFFFFD60A),
      const Color(0xFFFF3B30),
      const Color(0xFF34C759),
      const Color(0xFF00B7FF),
      const Color(0xFFAF52DE),
      const Color(0xFFFF9500),
      const Color(0xFF1C1C1E),
      const Color(0xFFFFFFFF),
    ];

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + (i * slice);

      Color col = baseColors[i % baseColors.length];
      if (modoClasico) {
        final g = ((col.red * 0.3) + (col.green * 0.59) + (col.blue * 0.11))
            .round();
        col = Color.fromARGB(255, g, g, g);
      }

      final paint = Paint()..color = col;
      canvas.drawArc(rect, start, slice, true, paint);

      final border = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawArc(rect, start, slice, true, border);

      final angle = start + slice / 2;

      final tp = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(2, 2), blurRadius: 0, color: Colors.black),
              Shadow(offset: Offset(-2, 2), blurRadius: 0, color: Colors.black),
              Shadow(offset: Offset(2, -2), blurRadius: 0, color: Colors.black),
              Shadow(
                offset: Offset(-2, -2),
                blurRadius: 0,
                color: Colors.black,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.95);

      final pos = Offset(
        c.dx + cos(angle) * (r * 0.62) - tp.width / 2,
        c.dy + sin(angle) * (r * 0.62) - tp.height / 2,
      );

      canvas.save();
      canvas.translate(pos.dx + tp.width / 2, pos.dy + tp.height / 2);
      canvas.rotate(angle + pi / 2);
      canvas.translate(-(pos.dx + tp.width / 2), -(pos.dy + tp.height / 2));
      tp.paint(canvas, pos);
      canvas.restore();
    }

    final ringColor = modoClasico ? Colors.black : const Color(0xFFFFD60A);

    final ringOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..color = ringColor;
    canvas.drawCircle(c, r * 0.97, ringOuter);

    final ringOuterBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.black;
    canvas.drawCircle(c, r * 0.97, ringOuterBorder);

    final centerFill = Paint()..color = Colors.white;
    canvas.drawCircle(c, r * 0.14, centerFill);

    final centerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.black;
    canvas.drawCircle(c, r * 0.14, centerBorder);
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
    final p = Paint()
      ..color = modoClasico
          ? Colors.black.withOpacity(0.10)
          : Colors.black.withOpacity(0.18);
    const step = 18.0;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 2.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) =>
      oldDelegate.modoClasico != modoClasico;
}

class _PopBurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path();
    final cx = r.center.dx;
    final cy = r.center.dy;

    const spikes = 12;
    final outer = min(r.width, r.height) * 0.52;
    final inner = outer * 0.65;

    for (int i = 0; i < spikes * 2; i++) {
      final ang = (pi * 2) * (i / (spikes * 2));
      final rad = i.isEven ? outer : inner;
      final x = cx + cos(ang) * rad;
      final y = cy + sin(ang) * rad;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fill = Paint()..color = const Color(0xFFFFD60A);
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
