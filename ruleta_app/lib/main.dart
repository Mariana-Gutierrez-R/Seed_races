import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeMenuPage(),
    );
  }
}

/* -------------------- HOME MENU -------------------- */

class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LA RUEDA DEL DESTINO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE6C46A),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Elige el tipo de ruleta',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6C46A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WheelNumbersPage()),
                  ),
                  child: const Text(
                    'RULETA DE NÚMEROS (1 a 5)',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE6C46A),
                    side: const BorderSide(color: Color(0xFF3A2E22)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WheelNamesPage()),
                  ),
                  child: const Text(
                    'RULETA DE NOMBRES',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

/* -------------------- SHARED WHEEL BASE -------------------- */

class WheelBasePage extends StatefulWidget {
  final String title;
  final List<String> items; // numbers as "1".."5" or names
  final Uri apiUrl; // python endpoint
  final Map<String, dynamic> Function(String selected) bodyBuilder;
  final String Function(String selected) prettyResult;

  const WheelBasePage({
    super.key,
    required this.title,
    required this.items,
    required this.apiUrl,
    required this.bodyBuilder,
    required this.prettyResult,
  });

  @override
  State<WheelBasePage> createState() => _WheelBasePageState();
}

class _WheelBasePageState extends State<WheelBasePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random();

  double _angle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;

  bool _girando = false;
  String _resultado = '-';
  String _estado = '';

  int get n => widget.items.length;
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

        final selectedIndex = _pickIndexUnderPointer();
        final selected = widget.items[selectedIndex];

        setState(() {
          _resultado = widget.prettyResult(selected);
        });

        await _sendToPython(selected);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _pickIndexUnderPointer() {
    // Pointer is at TOP (-pi/2).
    const pointer = -pi / 2;

    int best = 0;
    double bestDist = 1e9;

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + i * slice; // same as painter
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

  Future<void> _sendToPython(String selected) async {
    try {
      final res = await http.post(
        widget.apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(widget.bodyBuilder(selected)),
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

  void _spin() {
    if (_girando) return;

    final extraTurns = 6 + _rand.nextInt(4);
    final randomStop = _rand.nextDouble() * 2 * pi;

    setState(() {
      _girando = true;
      _estado = '';
      _resultado = '-';

      _startAngle = _angle;
      _targetAngle = _angle + extraTurns * 2 * pi + randomStop;
    });

    _controller
      ..reset()
      ..forward();
  }

  void _reset() {
    if (_girando) return;
    setState(() {
      _angle = 0.0;
      _resultado = '-';
      _estado = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wheelSize = min(w * 0.75, 330.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFFE6C46A),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE6C46A)),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(
              width: wheelSize,
              height: wheelSize + 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 2,
                    child: CustomPaint(
                      size: const Size(44, 30),
                      painter: _PointerGoldPainterDown(),
                    ),
                  ),
                  Transform.rotate(
                    angle: _angle,
                    child: CustomPaint(
                      size: Size(wheelSize, wheelSize),
                      painter: _WheelPainter(items: widget.items),
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
                onPressed: _girando ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6C46A),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'GIRAR RULETA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _girando ? null : _reset,
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0B),
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
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resultado,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE6C46A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_estado.isNotEmpty)
                    Text(
                      _estado,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- NUMBERS PAGE -------------------- */

class WheelNumbersPage extends StatelessWidget {
  const WheelNumbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['1', '2', '3', '4', '5'];

    return WheelBasePage(
      title: 'Ruleta de números',
      items: items,
      apiUrl: Uri.parse('http://10.0.2.2:8000/numero'),
      bodyBuilder: (selected) => {'numero': int.parse(selected)},
      prettyResult: (selected) => selected,
    );
  }
}

/* -------------------- NAMES PAGE -------------------- */

class WheelNamesPage extends StatelessWidget {
  const WheelNamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['Ana', 'Daisy', 'Diana'];

    return WheelBasePage(
      title: 'Ruleta de nombres',
      items: items,
      apiUrl: Uri.parse('http://10.0.2.2:8000/texto'),
      bodyBuilder: (selected) => {'nombre': selected},
      prettyResult: (selected) => selected,
    );
  }
}

/* -------------------- PAINTERS -------------------- */

class _WheelPainter extends CustomPainter {
  final List<String> items;
  const _WheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final n = items.length;
    final slice = 2 * pi / n;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // colors: red/black + 1 green if you want (simple)
    final colors = <Color>[];
    for (int i = 0; i < n; i++) {
      if (i == 0) {
        colors.add(const Color(0xFF0E9F6E));
      } else {
        colors.add(
          i.isEven ? const Color(0xFF111111) : const Color(0xFFDC2626),
        );
      }
    }

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + (i * slice);
      final paint = Paint()..color = colors[i];
      canvas.drawArc(rect, start, slice, true, paint);

      final angle = start + slice / 2;

      final tp = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.9);

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

    final center = Paint()..color = const Color(0xFFE6C46A);
    canvas.drawCircle(c, r * 0.12, center);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
