import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ComicRuletaApp());

class ComicRuletaApp extends StatelessWidget {
  const ComicRuletaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
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
  // ================== API ==================
  final String baseUrl = 'http://10.0.2.2:8000';

  // ================== DRILL DOWN ==================
  List<String> items = [];
  String? categoriaSeleccionada;
  String? subrazaSeleccionada;
  String? rolSeleccionado;

  int nivelActual = 0;
  bool cargando = true;

  // ================== PREGUNTA ==================
  bool mostrandoPregunta = false;
  int? preguntaId;
  String preguntaTexto = '';
  List<Map<String, dynamic>> respuestas = [];
  int? respuestaSeleccionadaId;

  // ================== ANIMACIÓN ==================
  late final AnimationController _controller;
  final Random _rand = Random();

  double _angle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;

  // ================== UI ==================
  bool _girando = false;
  String _resultadoFinal = '-';
  String _resultadoEnVivo = '-';
  String _estado = '';
  int _contadorGiros = 0;

  bool _modoClasico = false;
  bool _bannerClasico = false;

  final List<Color> fondos = const [
    Color(0xFF00B7FF),
    Color(0xFFFF3B30),
    Color(0xFFFFD60A),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];
  Color _fondoActual = const Color(0xFFAF52DE);

  double _punteroWiggle = 0.0;
  int _lastTick = -999;

  int get n => items.isEmpty ? 1 : items.length;
  double get slice => 2 * pi / n;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _controller.addListener(() {
      final t = Curves.easeOutQuart.transform(_controller.value);
      final ang = _startAngle + (_targetAngle - _startAngle) * t;

      final tick = (ang / slice).floor();
      if (tick != _lastTick) {
        _lastTick = tick;
        _hacerTickPuntero();
      }

      if (items.isNotEmpty) {
        setState(() {
          _angle = ang;
          _resultadoEnVivo = items[_pickIndexUnderPointer(ang)];
        });
      }
    });

    _controller.addStatusListener((s) async {
      if (s == AnimationStatus.completed && items.isNotEmpty) {
        final idx = _pickIndexUnderPointer(_angle);
        final selected = items[idx];

        setState(() {
          _girando = false;
          _resultadoFinal = selected;
          _estado = '';
        });

        await _procesarSeleccion(selected);

        if (_modoClasico) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          if (mounted) setState(() => _modoClasico = false);
        }
      }
    });

    _cargarCategorias();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================== HTTP ==================
  Future<Map<String, dynamic>> _getJson(Uri url) async {
    final res = await http.get(url);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      cargando = true;
      mostrandoPregunta = false;
      nivelActual = 0;
      categoriaSeleccionada = null;
      subrazaSeleccionada = null;
      rolSeleccionado = null;
      preguntaId = null;
      preguntaTexto = '';
      respuestas = [];
      respuestaSeleccionadaId = null;
      _resultadoFinal = '-';
      _resultadoEnVivo = '-';
      _estado = '';
    });

    try {
      final data = await _getJson(Uri.parse('$baseUrl/categorias'));
      final categorias = List<String>.from(data['categorias'] ?? []);

      setState(() {
        items = categorias;
        cargando = false;
        if (items.isNotEmpty) {
          _resultadoEnVivo = items.first;
          _resultadoFinal = items.first;
        }
      });
    } catch (_) {
      setState(() {
        cargando = false;
        _estado = 'Error cargando categorías ❌';
      });
    }
  }

  Future<void> _cargarSubrazas(String category) async {
    setState(() {
      cargando = true;
      nivelActual = 1;
      subrazaSeleccionada = null;
      rolSeleccionado = null;
      _estado = '';
    });

    try {
      final url = Uri.parse(
        '$baseUrl/subrazas',
      ).replace(queryParameters: {'category': category});

      final data = await _getJson(url);
      final subrazas = List<String>.from(data['subrazas'] ?? []);

      setState(() {
        items = subrazas;
        cargando = false;
        if (items.isNotEmpty) {
          _resultadoEnVivo = items.first;
          _resultadoFinal = items.first;
        }
      });
    } catch (_) {
      setState(() {
        cargando = false;
        _estado = 'Error cargando subrazas ❌';
      });
    }
  }

  Future<void> _cargarRoles(String category, String subrace) async {
    setState(() {
      cargando = true;
      nivelActual = 2;
      rolSeleccionado = null;
      _estado = '';
    });

    try {
      final url = Uri.parse(
        '$baseUrl/roles',
      ).replace(queryParameters: {'category': category, 'subrace': subrace});

      final data = await _getJson(url);
      final roles = List<String>.from(data['roles'] ?? []);

      setState(() {
        items = roles;
        cargando = false;
        if (items.isNotEmpty) {
          _resultadoEnVivo = items.first;
          _resultadoFinal = items.first;
        }
      });
    } catch (_) {
      setState(() {
        cargando = false;
        _estado = 'Error cargando roles ❌';
      });
    }
  }

  Future<void> _cargarPreguntaRandom() async {
    setState(() {
      cargando = true;
      mostrandoPregunta = true;
      _estado = '';
    });

    try {
      final data = await _getJson(Uri.parse('$baseUrl/pregunta-random'));

      setState(() {
        preguntaId = data['pregunta_id'];
        preguntaTexto = data['texto_pregunta'] ?? '';
        respuestas = List<Map<String, dynamic>>.from(data['respuestas'] ?? []);
        respuestaSeleccionadaId = null;
        cargando = false;
      });
    } catch (_) {
      setState(() {
        cargando = false;
        _estado = 'Error cargando pregunta ❌';
      });
    }
  }

  Future<void> _guardarResultadoCompleto(int respuestaId) async {
    if (categoriaSeleccionada == null ||
        subrazaSeleccionada == null ||
        rolSeleccionado == null ||
        preguntaId == null) {
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/guardar-resultado-completo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': categoriaSeleccionada,
          'subrace': subrazaSeleccionada,
          'role': rolSeleccionado,
          'pregunta_id': preguntaId,
          'respuesta_id': respuestaId,
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            respuestaSeleccionadaId = respuestaId;
            _estado = 'Guardado ✅';
          });
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _resetTotal();
        }
      } else {
        if (mounted) setState(() => _estado = 'Error guardando ❌');
      }
    } catch (_) {
      if (mounted) setState(() => _estado = 'No conecta con backend ❌');
    }
  }

  // ================== FLUJO ==================
  Future<void> _procesarSeleccion(String selected) async {
    if (nivelActual == 0) {
      categoriaSeleccionada = selected;
      await _cargarSubrazas(selected);
      return;
    }

    if (nivelActual == 1) {
      subrazaSeleccionada = selected;
      await _cargarRoles(categoriaSeleccionada!, selected);
      return;
    }

    if (nivelActual == 2) {
      rolSeleccionado = selected;
      await _cargarPreguntaRandom();
      return;
    }
  }

  // ================== RUEDA ==================
  int _pickIndexUnderPointer(double ang) {
    const pointer = -pi / 2;
    int best = 0;
    double bestDist = 1e9;

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + i * slice;
      final center = start + slice / 2 + ang;
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

  // ================== EFECTOS ==================
  void _cambiarFondo() {
    final next = fondos[_rand.nextInt(fondos.length)];
    setState(() => _fondoActual = next);
  }

  Future<void> _mostrarBannerClasico() async {
    setState(() => _bannerClasico = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _bannerClasico = false);
  }

  void _hacerTickPuntero() {
    if (!_girando) return;
    setState(() => _punteroWiggle = -0.18);
    Future<void>.delayed(const Duration(milliseconds: 55), () {
      if (mounted) setState(() => _punteroWiggle = 0.0);
    });
  }

  // ================== ACCIONES ==================
  Future<void> _spin() async {
    if (_girando || cargando || items.isEmpty || mostrandoPregunta) return;

    _cambiarFondo();

    final siguiente = _contadorGiros + 1;
    final activarClasico = (siguiente % 5 == 0);

    setState(() {
      _girando = true;
      _estado = '';
      _contadorGiros++;
      if (activarClasico) _modoClasico = true;
    });

    if (activarClasico) {
      await _mostrarBannerClasico();
    }

    final extraTurns = 8 + _rand.nextInt(6);
    final randomStop = _rand.nextDouble() * 2 * pi;

    setState(() {
      _startAngle = _angle;
      _targetAngle = _angle + extraTurns * 2 * pi + randomStop;
      _lastTick = -999;
      _resultadoEnVivo = items[_pickIndexUnderPointer(_angle)];
    });

    _controller
      ..reset()
      ..forward();
  }

  void _resetTotal() {
    if (_girando) return;
    _cambiarFondo();
    _angle = 0.0;
    _cargarCategorias();
  }

  String _tituloNivel() {
    if (mostrandoPregunta) return 'RESPONDE LA PREGUNTA';
    if (nivelActual == 0) return 'GIRAR CATEGORÍA';
    if (nivelActual == 1) return 'GIRAR SUBRAZA';
    return 'GIRAR ROL';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wheelSize = min(w * 0.76, 340.0);

    final bg = _modoClasico ? Colors.white : _fondoActual;
    final titleColor = _modoClasico ? Colors.black : Colors.white;
    final valorMostrado = _girando ? _resultadoEnVivo : _resultadoFinal;

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

              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (!mostrandoPregunta) ...[
                          Text(
                            'RULETA CÓMIC',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: 1.0,
                              shadows: _modoClasico
                                  ? null
                                  : const [
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

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _InfoCardComic(
                                  titulo: 'CATEGORÍA',
                                  valor: categoriaSeleccionada ?? '-',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _InfoCardComic(
                                  titulo: 'SUBRAZA',
                                  valor: subrazaSeleccionada ?? '-',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _InfoCardComic(
                                  titulo: 'ROL',
                                  valor: rolSeleccionado ?? '-',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                        ],

                        Text(
                          _tituloNivel(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                            letterSpacing: 1.0,
                            shadows: _modoClasico || mostrandoPregunta
                                ? null
                                : const [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                      color: Colors.black,
                                    ),
                                  ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (!mostrandoPregunta) ...[
                          SizedBox(
                            width: wheelSize + 60,
                            height: wheelSize + 70,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                if (cargando)
                                  SizedBox(
                                    width: wheelSize,
                                    height: wheelSize,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _modoClasico
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  Transform.rotate(
                                    angle: _angle,
                                    child: CustomPaint(
                                      size: Size(wheelSize, wheelSize),
                                      painter: _WheelComicPainter(
                                        items: items,
                                        modoClasico: _modoClasico,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 14,
                                  child: Transform.rotate(
                                    angle: _punteroWiggle,
                                    child: CustomPaint(
                                      size: const Size(64, 46),
                                      painter: _PointerComicPainter(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ComicButton(
                                  text: 'GIRAR',
                                  variant: _ButtonVariant.blanco,
                                  disabled:
                                      _girando || cargando || items.isEmpty,
                                  onTap: _spin,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ComicButton(
                                  text: 'REINICIAR',
                                  variant: _ButtonVariant.negro,
                                  disabled: _girando,
                                  onTap: _resetTotal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ResultadoComic(
                            valor: valorMostrado,
                            estado: _estado,
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          _QuestionBubbleComic(texto: preguntaTexto),
                          const SizedBox(height: 14),
                          Column(
                            children: respuestas.map((r) {
                              final id = r['id'] as int;
                              final texto = r['texto_respuesta'] as String;
                              final selected = respuestaSeleccionadaId == id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AnswerOptionComic(
                                  texto: texto,
                                  selected: selected,
                                  onTap: () => _guardarResultadoCompleto(id),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          if (_estado.isNotEmpty)
                            _MiniStatusComic(texto: _estado),
                        ],
                      ],
                    ),
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

// ================== BOTÓN ==================

enum _ButtonVariant { blanco, negro }

class _ComicButton extends StatelessWidget {
  final String text;
  final _ButtonVariant variant;
  final bool disabled;
  final VoidCallback onTap;

  const _ComicButton({
    required this.text,
    required this.variant,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = variant == _ButtonVariant.blanco ? Colors.white : Colors.black;
    final fg = variant == _ButtonVariant.blanco
        ? const Color(0xFF111111)
        : Colors.white;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 5),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ================== INFO CARD ==================

class _InfoCardComic extends StatelessWidget {
  final String titulo;
  final String valor;

  const _InfoCardComic({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Text(
                valor,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== RESULTADO ==================

class _ResultadoComic extends StatelessWidget {
  final String valor;
  final String estado;

  const _ResultadoComic({required this.valor, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'RESULTADO',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                height: 1,
              ),
            ),
          ),
          if (estado.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              estado,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================== PREGUNTA ==================

class _QuestionBubbleComic extends StatelessWidget {
  final String texto;

  const _QuestionBubbleComic({required this.texto});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: 5),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
          ],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AnswerOptionComic extends StatelessWidget {
  final String texto;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerOptionComic({
    required this.texto,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 5),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

class _MiniStatusComic extends StatelessWidget {
  final String texto;

  const _MiniStatusComic({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ================== BANNER ==================

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

// ================== FONDO ==================

class _ComicDotsBackground extends StatelessWidget {
  final bool modoClasico;

  const _ComicDotsBackground({required this.modoClasico});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotsPainter(modoClasico: modoClasico));
  }
}

// ================== PAINTERS ==================

class _PointerComicPainter extends CustomPainter {
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
    if (items.isEmpty) return;

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

      final fillPaint = Paint()..color = col;
      canvas.drawArc(rect, start, slice, true, fillPaint);

      final border = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawArc(rect, start, slice, true, border);

      final angle = start + slice / 2;
      final label = items[i];

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: _fontSizeForText(label),
            fontWeight: FontWeight.w900,
            color: modoClasico ? Colors.white : Colors.black,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.52);

      final radiusText = r * 0.63;
      final centerX = c.dx + cos(angle) * radiusText;
      final centerY = c.dy + sin(angle) * radiusText;

      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(angle);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final ringColor = modoClasico ? Colors.black : Colors.white;

    final ringOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..color = ringColor;
    canvas.drawCircle(c, r * 0.97, ringOuter);

    final ringOuterBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.black;
    canvas.drawCircle(c, r * 0.97, ringOuterBorder);

    final centerFill = Paint()..color = Colors.white;
    canvas.drawCircle(c, r * 0.14, centerFill);

    final centerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.black;
    canvas.drawCircle(c, r * 0.14, centerBorder);
  }

  double _fontSizeForText(String text) {
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
    const step = 18.0;
    final center = Offset(size.width / 2, size.height / 2.2);
    final maxDist = sqrt(size.width * size.width + size.height * size.height);

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final p = Offset(x, y);
        final dist = (p - center).distance;
        final norm = (dist / maxDist).clamp(0.0, 1.0);

        if (dist < 150) continue;

        final alpha = modoClasico
            ? (0.22 * norm).clamp(0.0, 0.22)
            : (0.30 * norm).clamp(0.0, 0.30);

        final paint = Paint()..color = Colors.black.withOpacity(alpha);

        final radius = 1.0 + (1.6 * norm);
        canvas.drawCircle(p, radius, paint);
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
    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..lineTo(size.width * 0.24, size.height + 16)
      ..lineTo(size.width * 0.30, size.height)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
