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

  static Future<void> _guardarSesion(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = data['usuario'] as Map<String, dynamic>;

    await prefs.setString('token', data['token'].toString());
    await prefs.setInt('id_usuario', usuario['id_usuario'] as int);
    await prefs.setString(
      'nombre_usuario',
      usuario['nombre_usuario'].toString(),
    );
    await prefs.setString('correo', usuario['correo'].toString());
    await prefs.setString(
      'proveedor_login',
      usuario['proveedor_login']?.toString() ?? 'local',
    );
    if (usuario['telefono'] != null) {
      await prefs.setString('telefono', usuario['telefono'].toString());
    }
  }

  static Future<Map<String, dynamic>> _postAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Error en autenticación');
    }

    return data;
  }

  static Future<Map<String, dynamic>> registrar({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    return _postAuth('/auth/registro', {
      'nombre_usuario': nombreUsuario,
      'correo': correo,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final data = await _postAuth('/auth/login', {
      'correo': correo,
      'password': password,
    });
    await _guardarSesion(data);
    return data;
  }

  static Future<Map<String, dynamic>> loginGoogleDemo() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final data = await _postAuth('/auth/google-login', {
      'id_externo': 'google_demo_$stamp',
      'correo': 'google$stamp@test.com',
      'nombre_usuario': 'Google Player',
      'foto_perfil': 'https://foto.com/google.jpg',
    });
    await _guardarSesion(data);
    return data;
  }

  static Future<Map<String, dynamic>> loginFacebookDemo() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final data = await _postAuth('/auth/facebook-login', {
      'id_externo': 'facebook_demo_$stamp',
      'correo': 'facebook$stamp@test.com',
      'nombre_usuario': 'Facebook Player',
      'foto_perfil': 'https://foto.com/facebook.jpg',
    });
    await _guardarSesion(data);
    return data;
  }

  static Future<String> solicitarCodigoTelefono(String telefono) async {
    final data = await _postAuth('/auth/phone-login', {'telefono': telefono});
    return data['codigo_demo'].toString();
  }

  static Future<Map<String, dynamic>> verificarCodigoTelefono({
    required String telefono,
    required String codigo,
  }) async {
    final data = await _postAuth('/auth/verificar-codigo', {
      'telefono': telefono,
      'codigo': codigo,
    });
    await _guardarSesion(data);
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
  final telefonoCtrl = TextEditingController(text: '+573001112233');
  final codigoCtrl = TextEditingController();

  String mensaje = '';

  @override
  void dispose() {
    nombreCtrl.dispose();
    correoCtrl.dispose();
    passwordCtrl.dispose();
    telefonoCtrl.dispose();
    codigoCtrl.dispose();
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
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _loginSocialDemo(String tipo) async {
    setState(() {
      mensaje = tipo == 'google'
          ? 'Google todavía no está conectado de forma real. Falta configurar google_sign_in y Google Cloud.'
          : 'Facebook todavía no está conectado de forma real. Falta configurar flutter_facebook_auth y Meta Developer.';
    });
  }

  Future<void> _mostrarTelefono() async {
    String? codigoGenerado;
    bool verificando = false;
    codigoCtrl.clear();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> enviarOVerificar() async {
              if (verificando) return;
              setModalState(() => verificando = true);

              try {
                if (codigoGenerado == null) {
                  final code = await AuthService.solicitarCodigoTelefono(
                    telefonoCtrl.text.trim(),
                  );
                  codigoCtrl.text = code;
                  setModalState(() => codigoGenerado = code);
                } else {
                  await AuthService.verificarCodigoTelefono(
                    telefono: telefonoCtrl.text.trim(),
                    codigo: codigoCtrl.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                  widget.onLoginOk();
                }
              } catch (e) {
                setState(
                  () => mensaje = e.toString().replaceAll('Exception: ', ''),
                );
              } finally {
                setModalState(() => verificando = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF2),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.black, width: 5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 0,
                      offset: Offset(6, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _ExplosiveTitle(
                      text: 'ENTRAR CON\nTELÉFONO',
                      subtitle: 'CÓDIGO DE ACCESO',
                    ),
                    const SizedBox(height: 14),
                    _AuthComicInput(
                      controller: telefonoCtrl,
                      label: 'Teléfono',
                      icon: Icons.phone,
                    ),
                    const SizedBox(height: 12),
                    if (codigoGenerado != null) ...[
                      _AuthComicInput(
                        controller: codigoCtrl,
                        label: 'Código',
                        icon: Icons.password,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Modo demo: el código se llena automáticamente. En producción llegaría por SMS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _ComicMainActionButton(
                      text: verificando
                          ? 'PROCESANDO...'
                          : (codigoGenerado == null
                                ? 'ENVIAR CÓDIGO'
                                : 'VERIFICAR Y ENTRAR'),
                      onTap: verificando ? null : enviarOVerificar,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFD60A)),
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthComicDots()),
            const Positioned.fill(child: _ComicSpeedLines()),
            Positioned(left: 20, top: 70, child: _FloatingStar(size: 34)),
            Positioned(right: 24, top: 92, child: _FloatingStar(size: 25)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                  child: Column(
                    children: [
                      _ExplosiveTitle(
                        text: modoRegistro
                            ? '¡CREA TU\nPERSONAJE!'
                            : '¡ACCEDE A TU\nUNIVERSO!',
                        subtitle: modoRegistro
                            ? '¡TU HISTORIA COMIENZA AQUÍ!'
                            : 'TUS PERSONAJES TE ESPERAN',
                      ),
                      const SizedBox(height: 18),
                      _ComicMascotBox(
                        text: modoRegistro ? 'PEEP\nCLUB' : 'READY\nPLAYER',
                        icon: modoRegistro ? Icons.edit : Icons.menu_book,
                      ),
                      const SizedBox(height: 16),
                      if (modoRegistro) ...[
                        _AuthComicInput(
                          controller: nombreCtrl,
                          label: 'Nombre de usuario',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _AuthComicInput(
                        controller: correoCtrl,
                        label: 'Correo Electrónico',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 10),
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
                          onPressed: () => setState(
                            () => ocultarPassword = !ocultarPassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ComicMainActionButton(
                        text: cargando
                            ? 'CARGANDO...'
                            : (modoRegistro ? 'CREAR CUENTA' : 'ENTRAR'),
                        onTap: cargando ? null : _procesar,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: cargando
                            ? null
                            : () => setState(() {
                                modoRegistro = !modoRegistro;
                                mensaje = '';
                              }),
                        child: Text(
                          modoRegistro
                              ? '¿Ya tienes cuenta?  Inicia Sesión'
                              : '¿No tienes cuenta?  Regístrate',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _ComicDividerLabel(text: 'O continúa con'),
                      const SizedBox(height: 10),
                      _SocialComicButton(
                        text: 'Continuar con Google',
                        iconText: 'G',
                        color: Colors.white,
                        onTap: cargando
                            ? null
                            : () => _loginSocialDemo('google'),
                      ),
                      const SizedBox(height: 8),
                      _SocialComicButton(
                        text: 'Continuar con Facebook',
                        iconText: 'f',
                        color: const Color(0xFF1877F2),
                        onTap: cargando
                            ? null
                            : () => _loginSocialDemo('facebook'),
                      ),
                      const SizedBox(height: 8),
                      _SocialComicButton(
                        text: 'Continuar con Teléfono',
                        icon: Icons.phone,
                        color: const Color(0xFF34C759),
                        onTap: cargando ? null : _mostrarTelefono,
                      ),
                      if (mensaje.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MiniStatusComic(texto: mensaje),
                      ],
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
        fillColor: const Color(0xFFFFFDF2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 3.5),
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
    final d = await _get('/roles');
    return List<String>.from(d['roles'] ?? []);
  }

  static Future<List<String>> getArmas(EstadoJuego j) async {
    final d = await _get('/armas');
    return List<String>.from(d['armas'] ?? []);
  }

  static Future<List<String>> getTiposDano(EstadoJuego j) async {
    final d = await _get('/tipos-dano');
    return List<String>.from(d['tipos_dano'] ?? []);
  }

  static Future<List<String>> getMoralidades(EstadoJuego j) async {
    final d = await _get('/moralidades');
    return List<String>.from(d['moralidades'] ?? []);
  }

  static Future<List<String>> getNivelesAmenaza(EstadoJuego j) async {
    final d = await _get('/niveles-amenaza');
    return List<String>.from(d['niveles_amenaza'] ?? []);
  }

  static Future<List<String>> getTiposDibujo() async {
    final d = await _get('/tipos-dibujo');
    return List<String>.from(d['tipos_dibujo'] ?? []);
  }

  static Future<PersonajeModel?> getPersonajeAfin(EstadoJuego j) async {
    final data = await _post(
      '/personaje-afin',
      body: {
        'origin': j.origin,
        'category': j.category,
        'race': j.race,
        'subrace': j.subrace,
        'role': j.role,
      },
    );

    final personaje = data['personaje'];
    if (personaje is Map<String, dynamic>) {
      return PersonajeModel.fromJson(personaje);
    }
    return null;
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

  static int? _idTipoDibujoPorNombre(String tipoDibujo) {
    final normalizado = tipoDibujo.trim().toLowerCase();
    if (normalizado == 'anime') return 1;
    if (normalizado == 'cómic americano' || normalizado == 'comic americano')
      return 2;
    if (normalizado == 'pixel art') return 3;
    if (normalizado == 'caricatura') return 4;
    return null;
  }

  static Future<void> guardarTipoDibujo({required String tipoDibujo}) async {
    final idUsuario = await AuthService.getIdUsuario();
    final idTipoDibujo = _idTipoDibujoPorNombre(tipoDibujo);

    // El backend actual de /guardar-pregunta exige pregunta_id y respuesta_id.
    // Para guardar el estilo final sin romper el flujo, enviamos una pregunta/respuesta
    // base y además el id_tipo_dibujo seleccionado.
    await _post(
      '/guardar-pregunta',
      body: {
        'pregunta_id': 1,
        'respuesta_id': 1,
        'tipo_dibujo': tipoDibujo,
        'id_tipo_dibujo': idTipoDibujo,
        'id_usuario': idUsuario,
      },
    );
  }

  static Future<void> guardarRuletazo({
    required String nombreTablaRuleta,
    required String valor,
  }) async {
    final idUsuario = await AuthService.getIdUsuario();
    await _post(
      '/guardar-ruleta',
      body: {
        'nombre_tabla_ruleta': nombreTablaRuleta,
        'valor': valor,
        'id_usuario': idUsuario,
      },
    );
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
  bool _mostrandoTipoDibujo = false;
  bool _mostrandoLobby = false;

  String _resultadoFinal = '-';
  String _resultadoEnVivo = '-';
  String _estado = '';

  PreguntaModel? _preguntaActual;
  int? _respuestaSeleccionadaId;
  PersonajeModel? _personajeFinal;
  List<String> _tiposDibujo = [];
  String? _tipoDibujoSeleccionado;

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

  Color _fondoActual = const Color(0xFFFFD60A);
  bool _coloresAleatorios = true;
  Color _colorFijo = const Color(0xFFFFD60A);
  Set<Color> _coloresRandomActivos = {};
  String _picoSeleccionado = 'clasico';

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

    _coloresRandomActivos = _fondos.toSet();
    _cargarPreferenciasVisuales();
    _cargarNivel(NivelRuleta.origen);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _colorToInt(Color c) => c.value;

  Color _intToColor(int value) => Color(value);

  Future<void> _cargarPreferenciasVisuales() async {
    final prefs = await SharedPreferences.getInstance();
    final aleatorio = prefs.getBool('ajustes_colores_aleatorios');
    final fijo = prefs.getInt('ajustes_color_fijo');
    final random = prefs.getStringList('ajustes_colores_random');
    final pico = prefs.getString('ajustes_pico_ruleta');

    if (!mounted) return;

    setState(() {
      if (aleatorio != null) _coloresAleatorios = aleatorio;
      if (fijo != null) {
        _colorFijo = _intToColor(fijo);
        if (!_coloresAleatorios) _fondoActual = _colorFijo;
      }
      if (random != null && random.isNotEmpty) {
        _coloresRandomActivos = random
            .map(int.tryParse)
            .whereType<int>()
            .map(_intToColor)
            .toSet();
      }
      if (_coloresRandomActivos.isEmpty) {
        _coloresRandomActivos = _fondos.toSet();
      }
      if (pico != null && pico.trim().isNotEmpty) {
        _picoSeleccionado = pico;
      }
    });
  }

  Future<void> _guardarPreferenciasVisuales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ajustes_colores_aleatorios', _coloresAleatorios);
    await prefs.setInt('ajustes_color_fijo', _colorToInt(_colorFijo));
    await prefs.setStringList(
      'ajustes_colores_random',
      _coloresRandomActivos.map((c) => _colorToInt(c).toString()).toList(),
    );
    await prefs.setString('ajustes_pico_ruleta', _picoSeleccionado);
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

  String _nombreTablaParaNivel(NivelRuleta nivel) {
    switch (nivel) {
      case NivelRuleta.origen:
        return 'origin';
      case NivelRuleta.categoria:
        return 'category';
      case NivelRuleta.raza:
        return 'race';
      case NivelRuleta.subraza:
        return 'subrace';
      case NivelRuleta.rol:
        return 'role';
      case NivelRuleta.arma:
        return 'weapon';
      case NivelRuleta.tipoDano:
        return 'damage_type';
      case NivelRuleta.moralidad:
        return 'morality';
      case NivelRuleta.nivelAmenaza:
        return 'threat_level';
    }
  }

  // ================== EFFECTS ==================

  void _cambiarFondo() {
    setState(() {
      if (!_coloresAleatorios) {
        _fondoActual = _colorFijo;
        return;
      }

      final disponibles = _coloresRandomActivos.isEmpty
          ? _fondos
          : _fondos.where(_coloresRandomActivos.contains).toList();

      Color nuevo = disponibles[_rand.nextInt(disponibles.length)];
      if (disponibles.length > 1) {
        while (nuevo == _fondoActual) {
          nuevo = disponibles[_rand.nextInt(disponibles.length)];
        }
      }
      _fondoActual = nuevo;
    });
  }

  void _abrirPersonalizacion() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => _SettingsComicPage(
          fondoActual: _fondoActual,
          colorFijo: _colorFijo,
          coloresAleatorios: _coloresAleatorios,
          fondos: _fondos,
          coloresRandomActivos: _coloresRandomActivos,
          picoSeleccionado: _picoSeleccionado,
          onGuardar:
              ({
                required bool coloresAleatorios,
                required Color colorFijo,
                required Color fondoActual,
                required Set<Color> coloresRandomActivos,
                required String picoSeleccionado,
              }) {
                setState(() {
                  _coloresAleatorios = coloresAleatorios;
                  _colorFijo = colorFijo;
                  _fondoActual = fondoActual;
                  _coloresRandomActivos = coloresRandomActivos;
                  _picoSeleccionado = picoSeleccionado;
                });
                _guardarPreferenciasVisuales();
              },
          onLogout: widget.onLogout,
        ),
      ),
    );
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
      _mostrandoTipoDibujo = false;
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
      await ApiService.guardarRuletazo(
        nombreTablaRuleta: _nombreTablaParaNivel(_nivel),
        valor: selected,
      );

      final siguienteEvento = await ApiService.decidirEvento('ruleta');

      if (siguienteNivel == null) {
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await _mostrarSeleccionTipoDibujo();
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

  Future<void> _mostrarSeleccionTipoDibujo() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _procesando = true;
        _estado = 'Preparando estilo visual...';
      });
    }

    try {
      final tipos = await ApiService.getTiposDibujo();
      if (!mounted) return;
      setState(() {
        _tiposDibujo = tipos;
        _tipoDibujoSeleccionado = null;
        _mostrandoTipoDibujo = true;
        _mostrandoPregunta = false;
        _mostrandoLobby = false;
        _cargando = false;
        _procesando = false;
        _girando = false;
        _estado = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _procesando = false;
        _girando = false;
        _hayError = true;
        _estado = 'Error cargando estilos ❌';
      });
    }
  }

  Future<void> _guardarTipoDibujoYMostrarLobby(String tipo) async {
    if (_procesando) return;

    setState(() {
      _procesando = true;
      _tipoDibujoSeleccionado = tipo;
      _estado = 'Guardando estilo...';
    });

    try {
      await ApiService.guardarTipoDibujo(tipoDibujo: tipo);

      PersonajeModel? personajeAfin;
      try {
        personajeAfin = await ApiService.getPersonajeAfin(_juego);
      } catch (_) {
        personajeAfin = null;
      }

      if (!mounted) return;
      setState(() {
        _personajeFinal = personajeAfin;
        _mostrandoTipoDibujo = false;
        _mostrandoLobby = true;
        _mostrandoPregunta = false;
        _cargando = false;
        _procesando = false;
        _girando = false;
        _estado = personajeAfin == null
            ? 'Personaje generado ✅'
            : 'Personaje base más afín ✅';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
        _hayError = true;
        _estado = 'Error guardando estilo ❌';
      });
    }
  }

  Future<void> _continuarRuleta() async {
    if (_nivelPendiente != null) {
      await _cargarNivel(_nivelPendiente!, juego: _juego);
      return;
    }

    await _mostrarSeleccionTipoDibujo();
  }

  Future<void> _resetVisual() async {
    if (_girando) return;

    setState(() {
      _angle = 0.0;
      _juego = const EstadoJuego();
      _nivelPendiente = null;
      _mostrandoPregunta = false;
      _mostrandoTipoDibujo = false;
      _mostrandoLobby = false;
      _preguntaActual = null;
      _tiposDibujo = [];
      _tipoDibujoSeleccionado = null;
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
        _mostrandoTipoDibujo ||
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
              const Positioned.fill(child: _ComicSpeedLines()),
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
                          child: GestureDetector(
                            onTap: _abrirPersonalizacion,
                            child: Container(
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_mostrandoLobby) ...[
                          _LobbyComic(
                            personaje: _personajeFinal,
                            juego: _juego,
                            tipoDibujo: _tipoDibujoSeleccionado,
                            estado: _estado,
                            onVerImagen: _verImagenPersonaje,
                            onVolverTirar: _reiniciarJuego,
                          ),
                        ] else if (_mostrandoTipoDibujo) ...[
                          _TipoDibujoComic(
                            tipos: _tiposDibujo,
                            seleccionado: _tipoDibujoSeleccionado,
                            estado: _estado,
                            onSeleccionar: _guardarTipoDibujoYMostrarLobby,
                          ),
                        ] else if (!_mostrandoPregunta) ...[
                          _ExplosiveTitle(
                            text: 'RULETA CÓMIC',
                            subtitle: _nivel.titulo,
                          ),
                          const SizedBox(height: 16),

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
                                        painter: _PointerComicPainter(
                                          tipo: _picoSeleccionado,
                                        ),
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
                          const _ExplosiveTitle(
                            text: 'RESPONDE\nLA PREGUNTA',
                            subtitle: 'ELIGE TU RESPUESTA',
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

// ================== SETTINGS PAGE ==================

class _SettingsComicPage extends StatefulWidget {
  final Color fondoActual;
  final Color colorFijo;
  final bool coloresAleatorios;
  final List<Color> fondos;
  final Set<Color> coloresRandomActivos;
  final String picoSeleccionado;
  final void Function({
    required bool coloresAleatorios,
    required Color colorFijo,
    required Color fondoActual,
    required Set<Color> coloresRandomActivos,
    required String picoSeleccionado,
  })
  onGuardar;
  final VoidCallback onLogout;

  const _SettingsComicPage({
    required this.fondoActual,
    required this.colorFijo,
    required this.coloresAleatorios,
    required this.fondos,
    required this.coloresRandomActivos,
    required this.picoSeleccionado,
    required this.onGuardar,
    required this.onLogout,
  });

  @override
  State<_SettingsComicPage> createState() => _SettingsComicPageState();
}

class _SettingsComicPageState extends State<_SettingsComicPage> {
  late bool _coloresAleatorios;
  late Color _colorFijo;
  late Set<Color> _coloresRandom;
  late String _picoSeleccionado;

  @override
  void initState() {
    super.initState();
    _coloresAleatorios = widget.coloresAleatorios;
    _colorFijo = widget.colorFijo;
    _coloresRandom = widget.coloresRandomActivos.isEmpty
        ? widget.fondos.toSet()
        : widget.coloresRandomActivos.toSet();
    _picoSeleccionado = widget.picoSeleccionado;
  }

  void _guardar() {
    final fondoActual = _coloresAleatorios ? widget.fondoActual : _colorFijo;
    widget.onGuardar(
      coloresAleatorios: _coloresAleatorios,
      colorFijo: _colorFijo,
      fondoActual: fondoActual,
      coloresRandomActivos: _coloresRandom.toSet(),
      picoSeleccionado: _picoSeleccionado,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _coloresAleatorios ? widget.fondoActual : _colorFijo;

    return Scaffold(
      body: Container(
        color: bg,
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _ComicSpeedLines()),
              const Positioned.fill(child: _AuthComicDots()),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 3),
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
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _ExplosiveTitle(
                            text: 'AJUSTES',
                            subtitle: 'PERSONALIZA TU UNIVERSO',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      title: 'COLOR DE FONDO',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ComicToggleRow(
                            title: 'Color aleatorio',
                            subtitle: 'La app cambia de color cuando giras',
                            value: _coloresAleatorios,
                            onChanged: (v) {
                              setState(() => _coloresAleatorios = v);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'COLOR FIJO',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: widget.fondos.map((c) {
                              final selected = _colorFijo == c;
                              return GestureDetector(
                                onTap: () => setState(() => _colorFijo = c),
                                child: _ColorBubble(
                                  color: c,
                                  selected: selected,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      title: 'COLORES RANDOM',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elige qué colores pueden salir cuando el modo aleatorio esté activo.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: widget.fondos.map((c) {
                              final selected = _coloresRandom.contains(c);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (selected && _coloresRandom.length > 1) {
                                      _coloresRandom.remove(c);
                                    } else {
                                      _coloresRandom.add(c);
                                    }
                                  });
                                },
                                child: _ColorBubble(
                                  color: c,
                                  selected: selected,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'La app ya evita repetir el mismo color dos veces seguidas. La selección de colores queda lista para una mejora posterior.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      title: 'PICO DE LA RULETA',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elige la forma del marcador que apunta al resultado de la ruleta.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PicoOptionTile(
                            value: 'clasico',
                            label: 'Pico clásico',
                            selected: _picoSeleccionado == 'clasico',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'clasico'),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'esfera',
                            label: 'Esfera',
                            selected: _picoSeleccionado == 'esfera',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'esfera'),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'murcielago',
                            label: 'Murciélago',
                            selected: _picoSeleccionado == 'murcielago',
                            onTap: () => setState(
                              () => _picoSeleccionado = 'murcielago',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'rayo',
                            label: 'Rayo',
                            selected: _picoSeleccionado == 'rayo',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'rayo'),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'anillo',
                            label: 'Anillo',
                            selected: _picoSeleccionado == 'anillo',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'anillo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ComicMainActionButton(
                      text: 'GUARDAR AJUSTES',
                      onTap: _guardar,
                    ),
                    const SizedBox(height: 14),
                    _ComicButton(
                      text: 'CERRAR SESIÓN',
                      variant: _ButtonVariant.negro,
                      disabled: false,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onLogout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PicoOptionTile extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PicoOptionTile({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: selected ? 5 : 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: CustomPaint(
                size: const Size(38, 30),
                painter: _PointerComicPainter(tipo: value),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.black, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 19,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ComicToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ComicToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? Colors.black : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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

class _ColorBubble extends StatelessWidget {
  final Color color;
  final bool selected;

  const _ColorBubble({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: selected ? 54 : 46,
      height: selected ? 54 : 46,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: selected ? 5 : 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
        ],
      ),
      child: selected ? const Icon(Icons.check, color: Colors.black) : null,
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
    final isWhite = variant == _ButtonVariant.blanco;
    final bg = isWhite ? Colors.white : Colors.black;
    final fg = isWhite ? const Color(0xFF111111) : Colors.white;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: isWhite ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(5, 5),
              ),
              BoxShadow(
                color: Colors.white24,
                blurRadius: 0,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              shadows: isWhite
                  ? null
                  : const [Shadow(offset: Offset(2, 2), color: Colors.black)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComicMainActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _ComicMainActionButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 58,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF176), Color(0xFFFFD60A), Color(0xFFFFB000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.1,
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
  final String? tipoDibujo;
  final String estado;
  final VoidCallback onVerImagen;
  final VoidCallback onVolverTirar;

  const _LobbyComic({
    required this.personaje,
    required this.juego,
    required this.tipoDibujo,
    required this.estado,
    required this.onVerImagen,
    required this.onVolverTirar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = personaje?.characterName ?? 'PERSONAJE BASE';

    return Column(
      children: [
        const _ExplosiveTitle(
          text: '¡PERSONAJE\nCREADO!',
          subtitle: 'TU UNIVERSO YA TIENE PROTAGONISTA',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF2),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(7, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  border: Border.all(color: Colors.black, width: 4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  nombre.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LobbyRow(label: 'ORIGEN', value: juego.origin ?? '-'),
              _LobbyRow(label: 'CATEGORÍA', value: juego.category ?? '-'),
              _LobbyRow(label: 'RAZA', value: juego.race ?? '-'),
              _LobbyRow(label: 'SUBRAZA', value: juego.subrace ?? '-'),
              _LobbyRow(label: 'ROL', value: juego.role ?? '-'),
              _LobbyRow(label: 'ARMA', value: juego.weapon ?? '-'),
              _LobbyRow(label: 'DAÑO', value: juego.damageType ?? '-'),
              _LobbyRow(label: 'MORALIDAD', value: juego.morality ?? '-'),
              _LobbyRow(label: 'AMENAZA', value: juego.threatLevel ?? '-'),
              _LobbyRow(label: 'DIBUJO', value: tipoDibujo ?? '-'),
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
                text: 'CREAR IMAGEN',
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
  final IconData? icon;

  const _AnswerOptionComic({
    required this.texto,
    required this.selected,
    required this.onTap,
    this.icon,
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
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFFFD60A),
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon ?? Icons.auto_awesome, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
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

class _TipoDibujoComic extends StatelessWidget {
  final List<String> tipos;
  final String? seleccionado;
  final String estado;
  final ValueChanged<String> onSeleccionar;

  const _TipoDibujoComic({
    required this.tipos,
    required this.seleccionado,
    required this.estado,
    required this.onSeleccionar,
  });

  IconData _iconFor(String t) {
    final v = t.toLowerCase();
    if (v.contains('anime')) return Icons.auto_awesome;
    if (v.contains('pixel')) return Icons.grid_view;
    if (v.contains('caricatura')) return Icons.face_retouching_natural;
    return Icons.menu_book;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ExplosiveTitle(
          text: 'ELIGE EL\nESTILO',
          subtitle: '¿CÓMO QUIERES VER TU PERSONAJE?',
        ),
        const SizedBox(height: 18),
        ...tipos.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnswerOptionComic(
              texto: t,
              selected: seleccionado == t,
              icon: _iconFor(t),
              onTap: () => onSeleccionar(t),
            ),
          ),
        ),
        if (estado.isNotEmpty) _MiniStatusComic(texto: estado),
      ],
    );
  }
}

class _ExplosiveTitle extends StatelessWidget {
  final String text;
  final String subtitle;

  const _ExplosiveTitle({required this.text, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(5, 6),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 0.90,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 0.90,
                  letterSpacing: -0.6,
                  shadows: [
                    Shadow(offset: Offset(3, 0), color: Colors.black),
                    Shadow(offset: Offset(-3, 0), color: Colors.black),
                    Shadow(offset: Offset(0, 3), color: Colors.black),
                    Shadow(offset: Offset(0, -3), color: Colors.black),
                    Shadow(offset: Offset(2, 2), color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF2),
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0D47A1),
                  blurRadius: 0,
                  offset: Offset(3, 4),
                ),
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicMascotBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _ComicMascotBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border.all(color: Colors.black, width: 5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(7, 7)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: _AuthComicDots()),
          const Positioned(left: 16, top: 16, child: _PriceBadge()),
          Positioned(right: 18, top: 16, child: _FloatingStar(size: 22)),
          Positioned(left: 18, bottom: 10, child: _MiniCity(width: 86)),
          Positioned(right: 18, bottom: 10, child: _MiniCity(width: 72)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ComicBookFace(icon: icon),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A),
                    border: Border.all(color: Colors.black, width: 4),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    text.replaceAll('\n', ' '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicBookFace extends StatelessWidget {
  final IconData icon;

  const _ComicBookFace({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 4),
              ),
            ),
          ),
          Positioned(
            top: 2,
            left: 24,
            right: 24,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3B0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_ComicEye(), SizedBox(width: 12), _ComicEye()],
                  ),
                  SizedBox(height: 8),
                  _ComicSmile(),
                ],
              ),
            ),
          ),
          Positioned(left: -6, bottom: 24, child: _ComicGlove()),
          Positioned(right: -6, bottom: 24, child: _ComicGlove()),
          Positioned(
            right: -18,
            top: 22,
            child: Transform.rotate(
              angle: -0.25,
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFFFFD60A),
                shadows: const [
                  Shadow(offset: Offset(2, 2), color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicEye extends StatelessWidget {
  const _ComicEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 14,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ComicSmile extends StatelessWidget {
  const _ComicSmile();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(26, 12), painter: _SmileComicPainter());
  }
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

class _ComicGlove extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD60A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: const Text(
        '10¢',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniCity extends StatelessWidget {
  final double width;

  const _MiniCity({required this.width});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, 32), painter: _MiniCityPainter());
  }
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

class _ComicDividerLabel extends StatelessWidget {
  final String text;
  const _ComicDividerLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.black, thickness: 3)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.black, thickness: 3)),
      ],
    );
  }
}

class _SocialComicButton extends StatelessWidget {
  final String text;
  final String? iconText;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const _SocialComicButton({
    required this.text,
    this.iconText,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkIcon = color.computeLuminance() < 0.45;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: icon != null
                    ? Icon(
                        icon,
                        color: darkIcon ? Colors.white : Colors.black,
                        size: 18,
                      )
                    : Text(
                        iconText ?? '',
                        style: TextStyle(
                          color: darkIcon ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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

class _FloatingStar extends StatelessWidget {
  final double size;
  const _FloatingStar({required this.size});
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star,
      size: size,
      color: Colors.white,
      shadows: const [Shadow(offset: Offset(2, 2), color: Colors.black)],
    );
  }
}

class _ComicCloud extends StatelessWidget {
  final double width;
  const _ComicCloud({required this.width});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.42),
      painter: _CloudPainter(),
    );
  }
}

class _ComicSpeedLines extends StatelessWidget {
  const _ComicSpeedLines();
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ================== PAINTERS ==================

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

    for (int i = 0; i < visualSegments; i++) {
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
