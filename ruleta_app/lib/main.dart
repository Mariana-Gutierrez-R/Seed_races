library comic_ruleta_app;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

part 'models/models.dart';
part 'services/auth_service.dart';
part 'services/api_service.dart';
part 'pages/login_page.dart';
part 'pages/mode_select_page.dart';
part 'pages/universe_select_page.dart';
part 'pages/ruleta_page.dart';
part 'pages/settings_page.dart';
part 'pages/profile_page.dart';
part 'pages/unlocks_page.dart';
part 'widgets/comic_widgets.dart';
part 'painters/comic_painters.dart';
part 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ComicRuletaApp());
}

class ComicRuletaApp extends StatefulWidget {
  const ComicRuletaApp({super.key});

  @override
  State<ComicRuletaApp> createState() => _ComicRuletaAppState();
}

class _ComicRuletaAppState extends State<ComicRuletaApp> {
  bool _verificandoSesion = true;
  bool _logueado = false;

  String _pantallaActual = 'login';
  String _modoJuego = 'afin';
  String? _universoSeleccionado;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
      _pantallaActual = idUsuario != null ? 'modos' : 'login';
      _modoJuego = 'afin';
      _universoSeleccionado = null;
    });
  }

  void _entrarAlJuego() {
    setState(() {
      _logueado = true;
      _pantallaActual = 'modos';
      _modoJuego = 'afin';
      _universoSeleccionado = null;
    });
  }

  void _seleccionarModoAfin() {
    setState(() {
      _modoJuego = 'afin';
      _universoSeleccionado = null;
      _pantallaActual = 'universos';
    });
  }

  void _seleccionarUniversoAfin(String universo) {
    setState(() {
      _modoJuego = 'afin';
      _universoSeleccionado = universo;
      _pantallaActual = 'ruleta';
    });
  }

  void _seleccionarModoCaotico() {
    setState(() {
      _modoJuego = 'caotico';
      _universoSeleccionado = null;
      _pantallaActual = 'ruleta';
    });
  }

  void _volverAModos() {
    setState(() {
      _pantallaActual = 'modos';
      _modoJuego = 'afin';
      _universoSeleccionado = null;
    });
  }

  void _abrirPerfil() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(onLogout: _cerrarSesion),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await AuthService.logout();

    if (!mounted) return;

    setState(() {
      _logueado = false;
      _pantallaActual = 'login';
      _modoJuego = 'afin';
      _universoSeleccionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget home;

    if (_verificandoSesion) {
      home = const _AuthLoadingComic();
    } else if (!_logueado || _pantallaActual == 'login') {
      home = LoginPage(onLoginOk: _entrarAlJuego);
    } else if (_pantallaActual == 'universos') {
      home = UniverseSelectPage(
        key: const ValueKey('pantalla_universos'),
        onBack: _volverAModos,
        onLogout: _cerrarSesion,
        onOpenProfile: _abrirPerfil,
        onUniversoSeleccionado: _seleccionarUniversoAfin,
      );
    } else if (_pantallaActual == 'ruleta') {
      final keyRuleta =
          'ruleta_${_modoJuego}_${_universoSeleccionado ?? "sin_universo"}';

      home = RuletaPage(
        key: ValueKey(keyRuleta),
        onLogout: _cerrarSesion,
        onBackToModes: _volverAModos,
        onOpenProfile: _abrirPerfil,
        modoJuego: _modoJuego,
        universoFijo: _universoSeleccionado,
      );
    } else {
      home = ModeSelectPage(
        key: const ValueKey('pantalla_modos'),
        onModoAfin: _seleccionarModoAfin,
        onModoCaotico: _seleccionarModoCaotico,
        onLogout: _cerrarSesion,
        onOpenProfile: _abrirPerfil,
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      home: home,
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
