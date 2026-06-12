part of comic_ruleta_app;

// ================== AUTH SERVICE ==================

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8001';

  static String? _phoneVerificationId;

  static Future<void> _guardarSesion(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = data['usuario'] as Map<String, dynamic>;

    await prefs.setString('token', data['token'].toString());
    await prefs.setInt('id_usuario', usuario['id_usuario'] as int);
    await prefs.setString(
      'nombre_usuario',
      usuario['nombre_usuario'].toString(),
    );
    await prefs.setString('correo', usuario['correo']?.toString() ?? '');
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
    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('Inicio de sesión con Google cancelado');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final firebaseUserCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final user = firebaseUserCredential.user;

    if (user == null) {
      throw Exception('No se pudo obtener el usuario de Firebase');
    }

    final data = await _postAuth('/auth/google-login', {
      'id_externo': user.uid,
      'correo': user.email ?? googleUser.email,
      'nombre_usuario':
          user.displayName ?? googleUser.displayName ?? 'Google Player',
      'foto_perfil': user.photoURL ?? googleUser.photoUrl ?? '',
    });

    await _guardarSesion(data);
    return data;
  }

  static Future<Map<String, dynamic>> loginFacebookDemo() async {
    throw Exception(
      'Login con Facebook pendiente: primero configuraremos Google y teléfono.',
    );
  }

  static Future<String> solicitarCodigoTelefono(String telefono) async {
    if (telefono.trim().isEmpty) {
      throw Exception('Debes escribir un número de teléfono');
    }

    final completer = Completer<String>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: telefono.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // En algunos dispositivos Android Firebase puede verificar automáticamente.
        // Si eso ocurre, se inicia sesión en Firebase sin pedir código manual.
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(e.message ?? 'Error verificando teléfono'),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _phoneVerificationId = verificationId;

        if (!completer.isCompleted) {
          completer.complete('');
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _phoneVerificationId = verificationId;
      },
    );

    return completer.future;
  }

  static Future<Map<String, dynamic>> verificarCodigoTelefono({
    required String telefono,
    required String codigo,
  }) async {
    if (_phoneVerificationId == null) {
      throw Exception('Primero debes solicitar el código SMS');
    }

    if (codigo.trim().isEmpty) {
      throw Exception('Debes escribir el código recibido por SMS');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _phoneVerificationId!,
      smsCode: codigo.trim(),
    );

    final firebaseUserCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final user = firebaseUserCredential.user;

    if (user == null) {
      throw Exception('No se pudo obtener el usuario de Firebase');
    }

    final prefs = await SharedPreferences.getInstance();

    final idLocal = user.uid.hashCode.abs();

    await prefs.setString('token', user.uid);
    await prefs.setInt('id_usuario', idLocal);
    await prefs.setString('nombre_usuario', 'Usuario Teléfono');
    await prefs.setString('correo', user.email ?? '');
    await prefs.setString('telefono', telefono.trim());
    await prefs.setString('proveedor_login', 'phone');

    return {
      'token': user.uid,
      'usuario': {
        'id_usuario': idLocal,
        'nombre_usuario': 'Usuario Teléfono',
        'correo': user.email ?? '',
        'telefono': telefono.trim(),
        'proveedor_login': 'phone',
      },
    };
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
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
