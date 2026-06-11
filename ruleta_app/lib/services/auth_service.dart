part of comic_ruleta_app;

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
