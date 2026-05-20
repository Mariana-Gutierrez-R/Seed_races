import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ComicRuletaApp());

class ComicRuletaApp extends StatefulWidget {
  const ComicRuletaApp({super.key});

  @override
  State<ComicRuletaApp> createState() => _ComicRuletaAppState();
}

class _ComicRuletaAppState extends State<ComicRuletaApp> {
  bool _verificandoSesion = true;
  bool _logueado = false;

  @override
  void initState() {
    super.initState();
    _verificarSesionGuardada();
  }

  Future<void> _verificarSesionGuardada() async {
    final idUsuario = await AuthService.getIdUsuario();

    if (!mounted) return;

    setState(() {
      _logueado = idUsuario != null;
      _verificandoSesion = false;
    });
  }

  void _entrarAlJuego() {
    setState(() {
      _logueado = true;
    });
  }

  Future<void> _cerrarSesion() async {
    await AuthService.logout();

    if (!mounted) return;

    setState(() {
      _logueado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      home: _verificandoSesion
          ? const _AuthLoadingComic()
          : _logueado
          ? RuletaPage(onLogout: _cerrarSesion)
          : LoginPage(onLoginOk: _entrarAlJuego),
    );
  }
}

class _AuthLoadingComic extends StatelessWidget {
  const _AuthLoadingComic();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFD60A),
      body: Center(
        child: Text(
          'CARGANDO...',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ================== AUTH SERVICE ==================

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8001';

  static Future<Map<String, dynamic>> registrar({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/registro'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre_usuario': nombreUsuario,
            'correo': correo,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 8));

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Error registrando usuario');
    }

    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'correo': correo, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Error iniciando sesión');
    }

    final prefs = await SharedPreferences.getInstance();
    final usuario = data['usuario'] as Map<String, dynamic>;

    await prefs.setString('token', data['token'].toString());
    await prefs.setInt('id_usuario', usuario['id_usuario'] as int);
    await prefs.setString(
      'nombre_usuario',
      usuario['nombre_usuario'].toString(),
    );
    await prefs.setString('correo', usuario['correo'].toString());

    return data;
  }

  static Future<int?> getIdUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_usuario');
  }

  static Future<String?> getNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre_usuario');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

// ================== LOGIN PAGE ==================

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginOk;

  const LoginPage({super.key, required this.onLoginOk});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool modoRegistro = false;
  bool cargando = false;
  bool ocultarPassword = true;

  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String mensaje = '';

  @override
  void dispose() {
    nombreCtrl.dispose();
    correoCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesar() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      if (modoRegistro) {
        await AuthService.registrar(
          nombreUsuario: nombreCtrl.text.trim(),
          correo: correoCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        );

        setState(() {
          modoRegistro = false;
          mensaje = 'Usuario registrado. Ahora inicia sesión.';
        });
      } else {
        await AuthService.login(
          correo: correoCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        );

        widget.onLoginOk();
      }
    } catch (e) {
      setState(() {
        mensaje = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFD60A)),
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthComicDots()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'RULETA CÓMIC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(offset: Offset(3, 3), color: Colors.black),
                            Shadow(offset: Offset(-3, 3), color: Colors.black),
                            Shadow(offset: Offset(3, -3), color: Colors.black),
                            Shadow(offset: Offset(-3, -3), color: Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '¡CREA TU PERSONAJE!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AuthComicCard(
                        child: Column(
                          children: [
                            Text(
                              modoRegistro ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (modoRegistro)
                              _AuthComicInput(
                                controller: nombreCtrl,
                                label: 'Nombre de usuario',
                                icon: Icons.person,
                              ),
                            if (modoRegistro) const SizedBox(height: 12),
                            _AuthComicInput(
                              controller: correoCtrl,
                              label: 'Correo',
                              icon: Icons.email,
                            ),
                            const SizedBox(height: 12),
                            _AuthComicInput(
                              controller: passwordCtrl,
                              label: 'Contraseña',
                              icon: Icons.lock,
                              obscure: ocultarPassword,
                              suffix: IconButton(
                                icon: Icon(
                                  ocultarPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    ocultarPassword = !ocultarPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _AuthComicButton(
                              text: cargando
                                  ? 'CARGANDO...'
                                  : (modoRegistro ? 'REGISTRAR' : 'ENTRAR'),
                              onTap: cargando ? null : _procesar,
                              dark: true,
                            ),
                            const SizedBox(height: 12),
                            _AuthComicButton(
                              text: modoRegistro
                                  ? 'YA TENGO CUENTA'
                                  : 'CREAR CUENTA',
                              onTap: cargando
                                  ? null
                                  : () {
                                      setState(() {
                                        modoRegistro = !modoRegistro;
                                        mensaje = '';
                                      });
                                    },
                              dark: false,
                            ),
                            if (mensaje.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                mensaje,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthComicCard extends StatelessWidget {
  final Widget child;

  const _AuthComicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(6, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _AuthComicInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _AuthComicInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: const Color(0xFFFFF3B0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 5),
        ),
      ),
    );
  }
}

class _AuthComicButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool dark;

  const _AuthComicButton({
    required this.text,
    required this.onTap,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? Colors.black : Colors.white,
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
          child: Text(
            text,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthComicDots extends StatelessWidget {
  const _AuthComicDots();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthComicDotsPainter());
  }
}

class _AuthComicDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.18);
    const step = 14.0;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 2.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================== MODELS ==================

class PreguntaModel {
  final int id;
  final String texto;
  final List<RespuestaModel> respuestas;

  const PreguntaModel({
    required this.id,
    required this.texto,
    required this.respuestas,
  });
}

class RespuestaModel {
  final int id;
  final String texto;

  const RespuestaModel({required this.id, required this.texto});
}

class PersonajeModel {
  final int? idCharacter;
  final String characterName;
  final String originName;
  final String categoryName;
  final String raceName;
  final String subraceName;
  final String roleName;
  final String weaponName;
  final String damageTypeName;
  final String moralityName;
  final String threatLevelName;

  const PersonajeModel({
    required this.idCharacter,
    required this.characterName,
    required this.originName,
    required this.categoryName,
    required this.raceName,
    required this.subraceName,
    required this.roleName,
    required this.weaponName,
    required this.damageTypeName,
    required this.moralityName,
    required this.threatLevelName,
  });

  factory PersonajeModel.fromJson(Map<String, dynamic> json) {
    return PersonajeModel(
      idCharacter: json['id_character'] as int?,
      characterName: json['character_name']?.toString() ?? 'Sin nombre',
      originName: json['origin_name']?.toString() ?? '-',
      categoryName: json['category_name']?.toString() ?? '-',
      raceName: json['race_name']?.toString() ?? '-',
      subraceName: json['subrace_name']?.toString() ?? '-',
      roleName: json['role_name']?.toString() ?? '-',
      weaponName: json['weapon_name']?.toString() ?? '-',
      damageTypeName: json['damage_type_name']?.toString() ?? '-',
      moralityName: json['morality_name']?.toString() ?? '-',
      threatLevelName: json['threat_level_name']?.toString() ?? '-',
    );
  }
}

class EstadoJuego {
  final String? origin;
  final String? category;
  final String? race;
  final String? subrace;
  final String? role;
  final String? weapon;
  final String? damageType;
  final String? morality;
  final String? threatLevel;

  const EstadoJuego({
    this.origin,
    this.category,
    this.race,
    this.subrace,
    this.role,
    this.weapon,
    this.damageType,
    this.morality,
    this.threatLevel,
  });

  EstadoJuego copyWith({
    String? origin,
    String? category,
    String? race,
    String? subrace,
    String? role,
    String? weapon,
    String? damageType,
    String? morality,
    String? threatLevel,
  }) {
    return EstadoJuego(
      origin: origin ?? this.origin,
      category: category ?? this.category,
      race: race ?? this.race,
      subrace: subrace ?? this.subrace,
      role: role ?? this.role,
      weapon: weapon ?? this.weapon,
      damageType: damageType ?? this.damageType,
      morality: morality ?? this.morality,
      threatLevel: threatLevel ?? this.threatLevel,
    );
  }

  bool get completo {
    return origin != null &&
        category != null &&
        race != null &&
        subrace != null &&
        role != null &&
        weapon != null &&
        damageType != null &&
        morality != null &&
        threatLevel != null;
  }
}

enum NivelRuleta {
  origen,
  categoria,
  raza,
  subraza,
  rol,
  arma,
  tipoDano,
  moralidad,
  nivelAmenaza,
}

extension NivelRuletaExt on NivelRuleta {
  String get titulo {
    switch (this) {
      case NivelRuleta.origen:
        return 'GIRAR ORIGEN';
      case NivelRuleta.categoria:
        return 'GIRAR CATEGORÍA';
      case NivelRuleta.raza:
        return 'GIRAR RAZA';
      case NivelRuleta.subraza:
        return 'GIRAR SUBRAZA';
      case NivelRuleta.rol:
        return 'GIRAR ROL';
      case NivelRuleta.arma:
        return 'GIRAR ARMA';
      case NivelRuleta.tipoDano:
        return 'GIRAR TIPO DE DAÑO';
      case NivelRuleta.moralidad:
        return 'GIRAR MORALIDAD';
      case NivelRuleta.nivelAmenaza:
        return 'GIRAR NIVEL DE AMENAZA';
    }
  }
}

// ================== API ==================

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? params,
  ]) async {
    final uri = params == null
        ? Uri.parse('$baseUrl$path')
        : Uri.parse('$baseUrl$path').replace(queryParameters: params);

    final res = await http.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    if (res.body.isEmpty) return {};
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Map<String, String> _params(EstadoJuego j) {
    final m = <String, String>{};

    if (j.origin != null) m['origin'] = j.origin!;
    if (j.category != null) m['category'] = j.category!;
    if (j.race != null) m['race'] = j.race!;
    if (j.subrace != null) m['subrace'] = j.subrace!;
    if (j.role != null) m['role'] = j.role!;
    if (j.weapon != null) m['weapon'] = j.weapon!;
    if (j.damageType != null) m['damage_type'] = j.damageType!;
    if (j.morality != null) m['morality'] = j.morality!;
    if (j.threatLevel != null) m['threat_level'] = j.threatLevel!;

    return m;
  }

  static Future<List<String>> getOrigenes() async {
    final d = await _get('/origenes');
    return List<String>.from(d['origenes'] ?? []);
  }

  static Future<List<String>> getCategorias(EstadoJuego j) async {
    final d = await _get('/categorias', _params(j));
    return List<String>.from(d['categorias'] ?? []);
  }

  static Future<List<String>> getRazas(EstadoJuego j) async {
    final d = await _get('/razas', _params(j));
    return List<String>.from(d['razas'] ?? []);
  }

  static Future<List<String>> getSubrazas(EstadoJuego j) async {
    final d = await _get('/subrazas', _params(j));
    return List<String>.from(d['subrazas'] ?? []);
  }

  static Future<List<String>> getRoles(EstadoJuego j) async {
    final d = await _get('/roles', _params(j));
    return List<String>.from(d['roles'] ?? []);
  }

  static Future<List<String>> getArmas(EstadoJuego j) async {
    final d = await _get('/armas', _params(j));
    return List<String>.from(d['armas'] ?? []);
  }

  static Future<List<String>> getTiposDano(EstadoJuego j) async {
    final d = await _get('/tipos-dano', _params(j));
    return List<String>.from(d['tipos_dano'] ?? []);
  }

  static Future<List<String>> getMoralidades(EstadoJuego j) async {
    final d = await _get('/moralidades', _params(j));
    return List<String>.from(d['moralidades'] ?? []);
  }

  static Future<List<String>> getNivelesAmenaza(EstadoJuego j) async {
    final d = await _get('/niveles-amenaza', _params(j));
    return List<String>.from(d['niveles_amenaza'] ?? []);
  }

  static Future<String?> decidirEvento(String eventoActual) async {
    final d = await _get('/decidir-evento', {'evento_actual': eventoActual});

    return d['siguiente'] as String?;
  }

  static Future<PreguntaModel> getPreguntaRandom() async {
    final d = await _get('/pregunta-random');

    return PreguntaModel(
      id: d['pregunta_id'] as int,
      texto: d['texto_pregunta'] as String,
      respuestas: (d['respuestas'] as List)
          .map(
            (r) => RespuestaModel(
              id: r['id'] as int,
              texto: r['texto_respuesta'] as String,
            ),
          )
          .toList(),
    );
  }

  static Future<void> guardarPregunta({
    required int preguntaId,
    required int respuestaId,
  }) async {
    final idUsuario = await AuthService.getIdUsuario();

    await _post(
      '/guardar-pregunta',
      body: {
        'pregunta_id': preguntaId,
        'respuesta_id': respuestaId,
        'id_usuario': idUsuario,
      },
    );
  }

  static Future<PersonajeModel?> guardarRuleta({
    required EstadoJuego juego,
  }) async {
    final idUsuario = await AuthService.getIdUsuario();

    final d = await _post(
      '/guardar-ruleta',
      body: {
        'origin': juego.origin,
        'category': juego.category,
        'race': juego.race,
        'subrace': juego.subrace,
        'role': juego.role,
        'weapon': juego.weapon,
        'damage_type': juego.damageType,
        'morality': juego.morality,
        'threat_level': juego.threatLevel,
        'id_usuario': idUsuario,
      },
    );

    final personaje = d['personaje'];

    if (personaje is Map<String, dynamic>) {
      return PersonajeModel.fromJson(personaje);
    }

    return null;
  }

  static Future<void> reiniciarJuego() async {
    final idUsuario = await AuthService.getIdUsuario();

    await _post('/reiniciar-juego', body: {'id_usuario': idUsuario});
  }
}

// ================== PAGE ==================

class RuletaPage extends StatefulWidget {
  final VoidCallback onLogout;

  const RuletaPage({super.key, required this.onLogout});

  @override
  State<RuletaPage> createState() => _RuletaPageState();
}

class _RuletaPageState extends State<RuletaPage>
    with SingleTickerProviderStateMixin {
  EstadoJuego _juego = const EstadoJuego();
  NivelRuleta _nivel = NivelRuleta.origen;
  NivelRuleta? _nivelPendiente;

  List<String> _items = [];

  bool _cargando = true;
  bool _girando = false;
  bool _procesando = false;
  bool _hayError = false;
  bool _mostrandoPregunta = false;
  bool _mostrandoLobby = false;

  String _resultadoFinal = '-';
  String _resultadoEnVivo = '-';
  String _estado = '';

  PreguntaModel? _preguntaActual;
  int? _respuestaSeleccionadaId;
  PersonajeModel? _personajeFinal;

  late final AnimationController _controller;
  final Random _rand = Random();

  double _angle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  double _punteroWiggle = 0.0;
  int _lastTick = -999;

  bool _modoClasico = false;
  bool _bannerClasico = false;
  int _contadorGiros = 0;

  Color _fondoActual = const Color(0xFFAF52DE);

  final List<Color> _fondos = const [
    Color(0xFF00B7FF),
    Color(0xFFFF3B30),
    Color(0xFFFFD60A),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];

  int get _n => _items.isEmpty ? 1 : _items.length;
  double get _slice => 2 * pi / _n;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _controller.addListener(_onTick);
    _controller.addStatusListener(_onStatus);

    _cargarNivel(NivelRuleta.origen);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================== ANIMATION ==================

  void _onTick() {
    final t = Curves.easeOutQuart.transform(_controller.value);
    final ang = _startAngle + (_targetAngle - _startAngle) * t;

    final tick = (ang / _slice).floor();

    if (tick != _lastTick) {
      _lastTick = tick;
      _hacerTickPuntero();
    }

    if (_items.isNotEmpty && mounted) {
      setState(() {
        _angle = ang;
        _resultadoEnVivo = _items[_pickIndex(ang)];
      });
    }
  }

  Future<void> _onStatus(AnimationStatus s) async {
    if (s != AnimationStatus.completed || _items.isEmpty) return;

    final selected = _items[_pickIndex(_angle)];

    if (mounted) {
      setState(() {
        _girando = false;
        _resultadoFinal = selected;
        _estado = '';
      });
    }

    await _procesarSeleccionRuleta(selected);

    if (_modoClasico) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) setState(() => _modoClasico = false);
    }
  }

  // ================== WHEEL LOGIC ==================

  int _pickIndex(double ang) {
    int best = 0;
    double bestDist = 1e9;

    for (int i = 0; i < _n; i++) {
      final center = -pi / 2 + i * _slice + _slice / 2 + ang;
      final d = _angDist(center, 0.0);

      if (d < bestDist) {
        bestDist = d;
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

  NivelRuleta? _siguienteNivel(NivelRuleta nivel) {
    switch (nivel) {
      case NivelRuleta.origen:
        return NivelRuleta.categoria;
      case NivelRuleta.categoria:
        return NivelRuleta.raza;
      case NivelRuleta.raza:
        return NivelRuleta.subraza;
      case NivelRuleta.subraza:
        return NivelRuleta.rol;
      case NivelRuleta.rol:
        return NivelRuleta.arma;
      case NivelRuleta.arma:
        return NivelRuleta.tipoDano;
      case NivelRuleta.tipoDano:
        return NivelRuleta.moralidad;
      case NivelRuleta.moralidad:
        return NivelRuleta.nivelAmenaza;
      case NivelRuleta.nivelAmenaza:
        return null;
    }
  }

  EstadoJuego _actualizarJuego(String selected) {
    switch (_nivel) {
      case NivelRuleta.origen:
        return _juego.copyWith(origin: selected);
      case NivelRuleta.categoria:
        return _juego.copyWith(category: selected);
      case NivelRuleta.raza:
        return _juego.copyWith(race: selected);
      case NivelRuleta.subraza:
        return _juego.copyWith(subrace: selected);
      case NivelRuleta.rol:
        return _juego.copyWith(role: selected);
      case NivelRuleta.arma:
        return _juego.copyWith(weapon: selected);
      case NivelRuleta.tipoDano:
        return _juego.copyWith(damageType: selected);
      case NivelRuleta.moralidad:
        return _juego.copyWith(morality: selected);
      case NivelRuleta.nivelAmenaza:
        return _juego.copyWith(threatLevel: selected);
    }
  }

  // ================== EFFECTS ==================

  void _cambiarFondo() {
    setState(() {
      _fondoActual = _fondos[_rand.nextInt(_fondos.length)];
    });
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

  // ================== LOAD DATA ==================

  Future<void> _cargarNivel(NivelRuleta nivel, {EstadoJuego? juego}) async {
    final j = juego ?? _juego;

    if (!mounted) return;

    setState(() {
      _cargando = true;
      _hayError = false;
      _mostrandoPregunta = false;
      _mostrandoLobby = false;
      _nivel = nivel;
      _estado = '';
    });

    try {
      List<String> lista = [];

      switch (nivel) {
        case NivelRuleta.origen:
          lista = await ApiService.getOrigenes();
          break;
        case NivelRuleta.categoria:
          lista = await ApiService.getCategorias(j);
          break;
        case NivelRuleta.raza:
          lista = await ApiService.getRazas(j);
          break;
        case NivelRuleta.subraza:
          lista = await ApiService.getSubrazas(j);
          break;
        case NivelRuleta.rol:
          lista = await ApiService.getRoles(j);
          break;
        case NivelRuleta.arma:
          lista = await ApiService.getArmas(j);
          break;
        case NivelRuleta.tipoDano:
          lista = await ApiService.getTiposDano(j);
          break;
        case NivelRuleta.moralidad:
          lista = await ApiService.getMoralidades(j);
          break;
        case NivelRuleta.nivelAmenaza:
          lista = await ApiService.getNivelesAmenaza(j);
          break;
      }

      if (!mounted) return;

      setState(() {
        _items = lista;
        _cargando = false;
        _procesando = false;
        _girando = false;
        _resultadoEnVivo = lista.isNotEmpty ? lista.first : '-';
        _resultadoFinal = lista.isNotEmpty ? lista.first : '-';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _procesando = false;
        _girando = false;
        _hayError = true;
        _estado = 'Error de conexión ❌';
      });
    }
  }

  Future<void> _cargarPregunta() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _hayError = false;
      _mostrandoPregunta = true;
      _mostrandoLobby = false;
      _estado = '';
    });

    try {
      final p = await ApiService.getPreguntaRandom();

      if (!mounted) return;

      setState(() {
        _preguntaActual = p;
        _respuestaSeleccionadaId = null;
        _cargando = false;
        _procesando = false;
        _girando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _procesando = false;
        _girando = false;
        _hayError = true;
        _mostrandoPregunta = false;
        _estado = 'Error cargando pregunta ❌';
      });
    }
  }

  // ================== GAME FLOW ==================

  Future<void> _procesarSeleccionRuleta(String selected) async {
    if (_procesando) return;

    setState(() {
      _procesando = true;
      _estado = 'Resultado: $selected';
    });

    final nuevoJuego = _actualizarJuego(selected);
    final siguienteNivel = _siguienteNivel(_nivel);

    _juego = nuevoJuego;
    _nivelPendiente = siguienteNivel;

    try {
      final siguienteEvento = await ApiService.decidirEvento('ruleta');

      if (siguienteNivel == null) {
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await _guardarRuletaYMostrarLobby(nuevoJuego);
        return;
      }

      if (siguienteEvento == 'pregunta') {
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await _cargarPregunta();
        return;
      }

      if (siguienteEvento == 'ruleta') {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await _continuarRuleta();
        return;
      }

      if (mounted) {
        setState(() {
          _estado = 'Evento desconocido ❌';
          _hayError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _estado = 'Error de conexión ❌';
          _hayError = true;
        });
      }
    } finally {
      if (mounted && !_mostrandoPregunta && !_mostrandoLobby) {
        setState(() {
          _procesando = false;
          _cargando = false;
          _girando = false;
        });
      }
    }
  }

  Future<void> _guardarRespuesta(int respuestaId) async {
    if (_procesando || _preguntaActual == null) return;

    setState(() {
      _procesando = true;
      _respuestaSeleccionadaId = respuestaId;
      _estado = 'Guardando...';
    });

    try {
      await ApiService.guardarPregunta(
        preguntaId: _preguntaActual!.id,
        respuestaId: respuestaId,
      );

      final siguienteEvento = await ApiService.decidirEvento('pregunta');

      if (siguienteEvento == 'pregunta') {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await _cargarPregunta();
        return;
      }

      if (siguienteEvento == 'ruleta') {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await _continuarRuleta();
        return;
      }

      if (mounted) {
        setState(() {
          _estado = 'Evento desconocido ❌';
          _hayError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _estado = 'Error al procesar respuesta ❌';
          _hayError = true;
        });
      }
    } finally {
      if (mounted && !_mostrandoPregunta && !_mostrandoLobby) {
        setState(() {
          _procesando = false;
          _cargando = false;
          _girando = false;
        });
      }
    }
  }

  Future<void> _guardarRuletaYMostrarLobby(EstadoJuego juegoFinal) async {
    if (!juegoFinal.completo) return;

    if (mounted) {
      setState(() {
        _cargando = true;
        _procesando = true;
        _estado = 'Guardando personaje...';
      });
    }

    try {
      final personaje = await ApiService.guardarRuleta(juego: juegoFinal);

      if (!mounted) return;

      setState(() {
        _personajeFinal = personaje;
        _mostrandoLobby = true;
        _mostrandoPregunta = false;
        _cargando = false;
        _procesando = false;
        _girando = false;
        _estado = personaje == null
            ? 'Personaje guardado, pero no hubo coincidencia exacta'
            : 'Personaje generado ✅';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _procesando = false;
        _girando = false;
        _hayError = true;
        _estado = 'Error guardando ruleta ❌';
      });
    }
  }

  Future<void> _continuarRuleta() async {
    if (_nivelPendiente != null) {
      await _cargarNivel(_nivelPendiente!, juego: _juego);
      return;
    }

    await _guardarRuletaYMostrarLobby(_juego);
  }

  Future<void> _resetVisual() async {
    if (_girando) return;

    setState(() {
      _angle = 0.0;
      _juego = const EstadoJuego();
      _nivelPendiente = null;
      _mostrandoPregunta = false;
      _mostrandoLobby = false;
      _preguntaActual = null;
      _respuestaSeleccionadaId = null;
      _personajeFinal = null;
      _estado = '';
      _hayError = false;
      _procesando = false;
      _cargando = false;
      _girando = false;
    });

    await _cargarNivel(NivelRuleta.origen);
  }

  Future<void> _reiniciarJuego() async {
    if (_girando || _procesando) return;

    setState(() {
      _cargando = true;
      _procesando = true;
      _estado = 'Reiniciando...';
      _hayError = false;
    });

    try {
      await ApiService.reiniciarJuego();

      _cambiarFondo();

      await _resetVisual();
    } catch (_) {
      if (mounted) {
        setState(() {
          _hayError = true;
          _estado = 'Error al reiniciar ❌';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
          _procesando = false;
          _girando = false;
        });
      }
    }
  }

  void _verImagenPersonaje() {
    setState(() {
      _estado = 'Imagen pendiente de integración 🖼️';
    });
  }

  // ================== ACTIONS ==================

  Future<void> _spin() async {
    if (_girando ||
        _cargando ||
        _procesando ||
        _items.isEmpty ||
        _mostrandoPregunta ||
        _mostrandoLobby ||
        _hayError) {
      return;
    }

    _cambiarFondo();

    final siguiente = _contadorGiros + 1;
    final activarClasico = siguiente % 5 == 0;

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
      _resultadoEnVivo = _items[_pickIndex(_angle)];
    });

    _controller
      ..reset()
      ..forward();
  }

  // ================== BUILD ==================

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
                        Align(
                          alignment: Alignment.topRight,
                          child: PopupMenuButton<String>(
                            color: Colors.white,
                            elevation: 8,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 0,
                                    offset: Offset(3, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            onSelected: (value) {
                              if (value == 'logout') {
                                widget.onLogout();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'logout',
                                child: Text(
                                  'Cerrar sesión',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_mostrandoLobby) ...[
                          _LobbyComic(
                            personaje: _personajeFinal,
                            juego: _juego,
                            estado: _estado,
                            onVerImagen: _verImagenPersonaje,
                            onVolverTirar: _reiniciarJuego,
                          ),
                        ] else if (!_mostrandoPregunta) ...[
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
                          const SizedBox(height: 16),
                          Text(
                            _nivel.titulo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: 1.0,
                              shadows: _modoClasico
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: wheelSize + 60,
                            height: wheelSize + 70,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                if (_cargando)
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
                                else if (_hayError)
                                  SizedBox(
                                    width: wheelSize,
                                    height: wheelSize,
                                    child: Center(
                                      child: _ComicButton(
                                        text: 'REINTENTAR',
                                        variant: _ButtonVariant.blanco,
                                        disabled: false,
                                        onTap: () => _cargarNivel(_nivel),
                                      ),
                                    ),
                                  )
                                else
                                  Transform.rotate(
                                    angle: _angle,
                                    child: CustomPaint(
                                      size: Size(wheelSize, wheelSize),
                                      painter: _WheelComicPainter(
                                        items: _items,
                                        modoClasico: _modoClasico,
                                      ),
                                    ),
                                  ),
                                if (!_hayError)
                                  Positioned(
                                    right: 2,
                                    child: Transform.rotate(
                                      angle: (pi / 2) + _punteroWiggle,
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
                                      _girando ||
                                      _cargando ||
                                      _procesando ||
                                      _items.isEmpty ||
                                      _hayError,
                                  onTap: _spin,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ComicButton(
                                  text: 'REINICIAR',
                                  variant: _ButtonVariant.negro,
                                  disabled: _girando || _procesando,
                                  onTap: _reiniciarJuego,
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
                          Text(
                            'RESPONDE LA PREGUNTA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_cargando)
                            const CircularProgressIndicator(color: Colors.white)
                          else if (_preguntaActual != null) ...[
                            _QuestionBubbleComic(texto: _preguntaActual!.texto),
                            const SizedBox(height: 14),
                            ..._preguntaActual!.respuestas.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AnswerOptionComic(
                                  texto: r.texto,
                                  selected: _respuestaSeleccionadaId == r.id,
                                  onTap: () => _guardarRespuesta(r.id),
                                ),
                              ),
                            ),
                          ],
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

// ================== WIDGETS ==================

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
              textAlign: TextAlign.center,
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

class _LobbyComic extends StatelessWidget {
  final PersonajeModel? personaje;
  final EstadoJuego juego;
  final String estado;
  final VoidCallback onVerImagen;
  final VoidCallback onVolverTirar;

  const _LobbyComic({
    required this.personaje,
    required this.juego,
    required this.estado,
    required this.onVerImagen,
    required this.onVolverTirar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = personaje?.characterName ?? 'Sin coincidencia exacta';

    return Column(
      children: [
        const SizedBox(height: 18),
        const _BannerComic(text: 'PERSONAJE GENERADO'),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                nombre.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 14),
              _LobbyRow(label: 'ORIGEN', value: juego.origin ?? '-'),
              _LobbyRow(label: 'CATEGORÍA', value: juego.category ?? '-'),
              _LobbyRow(label: 'RAZA', value: juego.race ?? '-'),
              _LobbyRow(label: 'SUBRAZA', value: juego.subrace ?? '-'),
              _LobbyRow(label: 'ROL', value: juego.role ?? '-'),
              _LobbyRow(label: 'ARMA', value: juego.weapon ?? '-'),
              _LobbyRow(label: 'DAÑO', value: juego.damageType ?? '-'),
              _LobbyRow(label: 'MORALIDAD', value: juego.morality ?? '-'),
              _LobbyRow(label: 'AMENAZA', value: juego.threatLevel ?? '-'),
              if (estado.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  estado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ComicButton(
                text: 'VER IMAGEN',
                variant: _ButtonVariant.blanco,
                disabled: false,
                onTap: onVerImagen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComicButton(
                text: 'VOLVER A TIRAR',
                variant: _ButtonVariant.negro,
                disabled: false,
                onTap: onVolverTirar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LobbyRow extends StatelessWidget {
  final String label;
  final String value;

  const _LobbyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        ..strokeWidth = 6,
    );
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

    final colors = <Color>[
      const Color(0xFFFFD60A),
      const Color(0xFFFF3B30),
      const Color(0xFF34C759),
      const Color(0xFF00B7FF),
      const Color(0xFF6A0DAD),
      const Color(0xFFFF9500),
      const Color(0xFFFFB6C1),
      const Color(0xFFFFFFFF),
    ];

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + i * slice;

      Color col = colors[i % colors.length];

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
          ..strokeWidth = 2.2,
      );

      final angle = start + slice / 2;
      final label = items[i];

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: _fontSize(label),
            fontWeight: FontWeight.w900,
            color: modoClasico ? Colors.white : Colors.black,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.52);

      final cx = c.dx + cos(angle) * r * 0.63;
      final cy = c.dy + sin(angle) * r * 0.63;

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

    canvas.drawCircle(c, r * 0.14, Paint()..color = Colors.white);

    canvas.drawCircle(
      c,
      r * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.black,
    );
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
