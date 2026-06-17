part of comic_ruleta_app;

// ================== RULETA PAGE ==================

class RuletaPage extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onBackToModes;
  final VoidCallback? onOpenProfile;

  // modoJuego:
  // - 'afin': si universoFijo viene definido, se salta la ruleta de origen.
  // - 'caotico': usa todas las opciones de cada tabla, sin filtros.
  final String modoJuego;
  final String? universoFijo;

  const RuletaPage({
    super.key,
    required this.onLogout,
    required this.onBackToModes,
    this.onOpenProfile,
    this.modoJuego = 'afin',
    this.universoFijo,
  });

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

  bool get _esModoCaotico => widget.modoJuego == 'caotico';

  bool get _usaUniversoFijo {
    return widget.modoJuego == 'afin' &&
        widget.universoFijo != null &&
        widget.universoFijo!.trim().isNotEmpty;
  }

  EstadoJuego _juegoInicialParaModo() {
    if (_usaUniversoFijo) {
      return EstadoJuego(origin: widget.universoFijo!.trim());
    }
    return const EstadoJuego();
  }

  NivelRuleta _nivelInicialParaModo() {
    return _usaUniversoFijo ? NivelRuleta.categoria : NivelRuleta.origen;
  }

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

    _juego = _juegoInicialParaModo();
    _nivel = _nivelInicialParaModo();
    _cargarNivel(_nivel, juego: _juego);
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

  void _abrirPerfil() {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(onLogout: widget.onLogout),
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
          lista = _esModoCaotico
              ? await ApiService.getCategoriasTodas()
              : await ApiService.getCategorias(j);
          break;
        case NivelRuleta.raza:
          lista = _esModoCaotico
              ? await ApiService.getRazasTodas()
              : await ApiService.getRazas(j);
          break;
        case NivelRuleta.subraza:
          lista = _esModoCaotico
              ? await ApiService.getSubrazasTodas()
              : await ApiService.getSubrazas(j);
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

      if (!_esModoCaotico) {
        try {
          personajeAfin = await ApiService.getPersonajeAfin(_juego);
        } catch (_) {
          personajeAfin = null;
        }
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
        _estado = _esModoCaotico
            ? 'Personaje aleatorio generado ✅'
            : (personajeAfin == null
                  ? 'Personaje generado ✅'
                  : 'Personaje base más afín ✅');
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

    final juegoInicial = _juegoInicialParaModo();

    setState(() {
      _angle = 0.0;
      _juego = juegoInicial;
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

    await _cargarNivel(_nivelInicialParaModo(), juego: juegoInicial);
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: widget.onBackToModes,
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
                                  Icons.arrow_back,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _abrirPerfil,
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
                                      Icons.person,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
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
                              ],
                            ),
                          ],
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
                                    right: -18,
                                    child: Transform.rotate(
                                      angle: (pi / 2) + _punteroWiggle,
                                      child: _PointerVisual(
                                        tipo: _picoSeleccionado,
                                        width: 120,
                                        height: 92,
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
