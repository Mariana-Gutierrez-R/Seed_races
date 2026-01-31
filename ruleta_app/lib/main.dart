import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const RuletaCasinoApp());

class RuletaCasinoApp extends StatelessWidget {
  const RuletaCasinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RuletaCasinoPage(),
    );
  }
}

class RuletaCasinoPage extends StatefulWidget {
  const RuletaCasinoPage({super.key});

  @override
  State<RuletaCasinoPage> createState() => _RuletaCasinoPageState();
}

class _RuletaCasinoPageState extends State<RuletaCasinoPage>
    with SingleTickerProviderStateMixin {
  static const int n = 5;
  static const double slice = 2 * pi / n;

  final Uri apiUrl = Uri.parse('http://10.0.2.2:8000/spin');

  late final AnimationController _controller;
  late Animation<double> _anim;

  final _rand = Random();
  double _angle = 0.0;
  bool _girando = false;

  int? _resultado;
  String _estadoEnvio = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _anim = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() => setState(() => _angle = _anim.value))
      ..addStatusListener((s) async {
        if (s == AnimationStatus.completed) {
          setState(() => _girando = false);

          // ✅ Espera un micro-momento para asegurar ángulo final
          await Future<void>.delayed(const Duration(milliseconds: 1));

          // ✅ Resultado REAL: lo que queda bajo el piquito (ARRIBA)
          final real = _calcularNumeroSegunPiquitoRobusto();
          setState(() => _resultado = real);

          // ✅ Enviar a Python (si está corriendo)
          await _enviarAPython(real);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _norm(double a) {
    final t = a % (2 * pi);
    return t < 0 ? t + 2 * pi : t;
  }

  // Distancia angular mínima entre a y b (0..pi)
  double _angDist(double a, double b) {
    final d = (_norm(a - b));
    return d > pi ? 2 * pi - d : d;
  }

  // ✅ Método robusto: escoge el segmento cuyo CENTRO queda más cerca del piquito.
  // Piquito está ARRIBA (mundo -pi/2). Tu ruleta pinta segmentos empezando en -pi/2.
  int _calcularNumeroSegunPiquitoRobusto() {
    const double pointer = -pi / 2;

    int bestIndex = 0;
    double bestDist = 999999;

    for (int i = 0; i < n; i++) {
      // inicio del segmento i en el painter:
      final start = -pi / 2 + i * slice;

      // centro del segmento i, ya con la rotación actual de la ruleta:
      final center = start + slice / 2 + _angle;

      final dist = _angDist(center, pointer);
      if (dist < bestDist) {
        bestDist = dist;
        bestIndex = i;
      }
    }

    return bestIndex + 1; // 1..5
  }

  Future<void> _enviarAPython(int numero) async {
    try {
      final res = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'numero': numero}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _estadoEnvio =
              '✅ Python recibió (ejecución: ${data['numero_ejecucion'] ?? '-'})';
        });
      } else {
        setState(() {
          _estadoEnvio = '⚠️ Python respondió ${res.statusCode}: ${res.body}';
        });
      }
    } catch (_) {
      setState(() {
        _estadoEnvio =
            '❌ No conecta con Python (servidor apagado o puerto 8000).';
      });
    }
  }

  void _girar() {
    if (_girando) return;

    final current = _angle;

    // ✅ Gira libremente (no elige número antes)
    final extraTurns = 6 + _rand.nextInt(4);
    final randomStop = _rand.nextDouble() * 2 * pi;
    final end = current + extraTurns * 2 * pi + randomStop;

    setState(() {
      _girando = true;
      _estadoEnvio = '';
      _resultado = null;
    });

    _anim = Tween<double>(
      begin: current,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller
      ..reset()
      ..forward();
  }

  void _reiniciar() {
    if (_girando) return;
    setState(() {
      _resultado = null;
      _estadoEnvio = '';
      _angle = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wheelSize = min(w * 0.75, 330.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1B1715), Color(0xFF0F0C0B)],
            center: Alignment.topCenter,
            radius: 1.25,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                const Text(
                  'LA RUEDA DEL\nDESTINO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE6C46A),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gira y descubre tu número (1 a 5)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: wheelSize,
                  height: wheelSize + 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: wheelSize * 1.05,
                        height: wheelSize * 1.05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 40,
                              spreadRadius: 10,
                              color: const Color(0xFFE6C46A).withOpacity(0.28),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        child: CustomPaint(
                          size: const Size(44, 30),
                          painter: _PointerGoldPainterDown(),
                        ),
                      ),
                      Transform.rotate(
                        angle: _angle,
                        child: CustomPaint(
                          size: Size(wheelSize, wheelSize),
                          painter: _CasinoWheelPainter(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _girando ? null : _girar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6C46A),
                      foregroundColor: const Color(0xFF1B1715),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'GIRAR RULETA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _girando ? null : _reiniciar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE6C46A),
                      side: const BorderSide(color: Color(0xFF3A2E22)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'REINICIAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11100F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3A2E22)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'RESULTADO',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _resultado?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE6C46A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_estadoEnvio.isNotEmpty)
                        Text(
                          _estadoEnvio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CasinoWheelPainter extends CustomPainter {
  static const int n = 5;
  static const double slice = 2 * pi / n;

  final List<Color> colors = const [
    Color(0xFF0E9F6E),
    Color(0xFFDC2626),
    Color(0xFF111111),
    Color(0xFFDC2626),
    Color(0xFF111111),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + (i * slice);
      final paint = Paint()..color = colors[i];
      canvas.drawArc(rect, start, slice, true, paint);

      final angle = start + slice / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

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

    final ringOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..color = const Color(0xFFE6C46A);
    canvas.drawCircle(c, r * 0.97, ringOuter);

    final ringInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.02
      ..color = const Color(0xFF2C241D);
    canvas.drawCircle(c, r * 0.86, ringInner);

    final center = Paint()..color = const Color(0xFFE6C46A);
    canvas.drawCircle(c, r * 0.14, center);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerGoldPainterDown extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFE6C46A);
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
