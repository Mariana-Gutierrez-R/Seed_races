part of comic_ruleta_app;

// ================== API SERVICE ==================

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String authBaseUrl = 'http://10.0.2.2:8001';

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


  static Future<Map<String, dynamic>> _getAuth(
    String path, [
    Map<String, String>? params,
  ]) async {
    final uri = params == null
        ? Uri.parse('$authBaseUrl$path')
        : Uri.parse('$authBaseUrl$path').replace(queryParameters: params);

    final res = await http.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AUTH HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _postAuth(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http
        .post(
          Uri.parse('$authBaseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AUTH HTTP ${res.statusCode}: ${res.body}');
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

  static Future<List<String>> getCategoriasTodas() async {
    final d = await _get('/categorias-todas');
    return List<String>.from(d['categorias'] ?? []);
  }

  static Future<List<String>> getRazasTodas() async {
    final d = await _get('/razas-todas');
    return List<String>.from(d['razas'] ?? []);
  }

  static Future<List<String>> getSubrazasTodas() async {
    final d = await _get('/subrazas-todas');
    return List<String>.from(d['subrazas'] ?? []);
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


  static Future<Map<String, dynamic>> getPerfilUsuario(int idUsuario) async {
    return _getAuth('/perfil/$idUsuario');
  }

  static Future<Map<String, dynamic>> actualizarAvatarPerfil({
    required int idUsuario,
    required String avatarKey,
  }) async {
    return _postAuth(
      '/perfil/avatar',
      body: {
        'id_usuario': idUsuario,
        'avatar_key': avatarKey,
      },
    );
  }
}
