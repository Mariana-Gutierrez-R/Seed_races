part of comic_ruleta_app;

// ================== PROFILE PAGE - STEP 6 ==================
// Perfil visual + avatar real conectado con auth.py / MySQL.
// Este paso muestra EXP, nivel y Peep Coins reales desde perfil_usuario.

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  int _expTotal = 0;
  int _peepCoins = 0;

  Color _fondoActual = const Color(0xFFFFD60A);
  bool _coloresAleatorios = false;
  Color _colorFijo = const Color(0xFFFFD60A);
  Set<Color> _coloresRandomActivos = {};

  String _apodo = 'Peep Player';
  String _avatarKey = 'maga';
  bool _cargandoPerfil = true;
  bool _guardandoAvatar = false;
  String? _mensajePerfil;
  late final AnimationController _avatarPulseController;
  late final Animation<double> _avatarPulseAnimation;

  final List<Color> _fondos = const [
    Color(0xFF00B7FF),
    Color(0xFFFF3B30),
    Color(0xFFFFD60A),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];

  final List<_AvatarOption> _avatares = const [
    _AvatarOption(
      keyName: 'maga',
      label: 'MAGA',
      assetPath: 'assets/images/avatars/maga.png',
      requiredLevel: 0,
    ),
    _AvatarOption(
      keyName: 'payaso',
      label: 'PAYASO',
      assetPath: 'assets/images/avatars/payaso.png',
      requiredLevel: 0,
    ),
    _AvatarOption(
      keyName: 'sayajin',
      label: 'SAYAJIN',
      assetPath: 'assets/images/avatars/sayajin.png',
      requiredLevel: 5,
    ),
    _AvatarOption(
      keyName: 'dragon',
      label: 'DRAGÓN',
      assetPath: 'assets/images/avatars/dragon.png',
      requiredLevel: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _avatarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _avatarPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_avatarPulseController);
    _coloresRandomActivos = _fondos.toSet();
    _cargarPreferencias();
    _cargarPerfil();

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _avatarPulseController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _avatarPulseController.dispose();
    super.dispose();
  }

  int _colorToInt(Color c) => c.value;
  Color _intToColor(int value) => Color(value);

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    final coloresAleatorios =
        prefs.getBool('ajustes_colores_aleatorios') ?? false;
    final colorFijoInt = prefs.getInt('ajustes_color_fijo');
    final fondoActualInt = prefs.getInt('ajustes_fondo_actual');
    final randomStrings = prefs.getStringList('ajustes_colores_random');

    final randomActivos = randomStrings == null
        ? _fondos.toSet()
        : randomStrings.map((s) => _intToColor(int.parse(s))).toSet();

    if (!mounted) return;

    setState(() {
      _coloresAleatorios = coloresAleatorios;
      _colorFijo = colorFijoInt == null
          ? const Color(0xFFFFD60A)
          : _intToColor(colorFijoInt);
      _fondoActual = fondoActualInt == null
          ? _colorFijo
          : _intToColor(fondoActualInt);
      _coloresRandomActivos = randomActivos.isEmpty
          ? _fondos.toSet()
          : randomActivos;
    });
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargandoPerfil = true;
      _mensajePerfil = null;
    });

    try {
      final idUsuario = await AuthService.getIdUsuario();
      if (idUsuario == null) {
        throw Exception('No se encontró usuario en sesión.');
      }

      final data = await ApiService.getPerfilUsuario(idUsuario);

      if (!mounted) return;

      final expTotal = _safeInt(data['exp_total']);
      final peepCoins = _safeInt(data['peep_coins']);

      final prefs = await SharedPreferences.getInstance();
      final expAnterior = prefs.getInt('perfil_exp_total') ?? 0;
      final nivelAnterior = _nivelDesdeExp(expAnterior);
      final nivelNuevo = _nivelDesdeExp(expTotal);
      final mostrarSubidaNivel = nivelNuevo > nivelAnterior;

      await prefs.setInt('perfil_exp_total', expTotal);
      await prefs.setInt('perfil_peep_coins', peepCoins);

      setState(() {
        _apodo = (data['apodo'] ?? data['nombre_usuario'] ?? 'Peep Player')
            .toString();
        _avatarKey = (data['avatar_key'] ?? 'maga').toString();
        _expTotal = expTotal;
        _peepCoins = peepCoins;
        _cargandoPerfil = false;
      });

      if (mostrarSubidaNivel && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mostrarDialogoSubidaNivel(
            nivelAnterior: nivelAnterior,
            nivelNuevo: nivelNuevo,
            expTotal: expTotal,
            peepCoins: peepCoins,
          );
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _apodo = prefs.getString('perfil_apodo') ?? 'Peep Player';
        _avatarKey = prefs.getString('perfil_avatar_key') ?? 'maga';
        _expTotal = prefs.getInt('perfil_exp_total') ?? 0;
        _peepCoins = prefs.getInt('perfil_peep_coins') ?? 0;
        _cargandoPerfil = false;
        _mensajePerfil =
            'No se pudo cargar el perfil desde MySQL. Revisa auth.py en puerto 8001.';
      });
    }
  }

  int _nivelDesdeExp(int expTotal) {
    final nivel = (expTotal ~/ 100) + 1;
    return nivel < 1 ? 1 : nivel;
  }

  Future<void> _mostrarDialogoSubidaNivel({
    required int nivelAnterior,
    required int nivelNuevo,
    required int expTotal,
    required int peepCoins,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF2),
              borderRadius: BorderRadius.circular(28),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⭐ ¡SUBISTE DE NIVEL! ⭐',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NIVEL $nivelAnterior  →  NIVEL $nivelNuevo',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'EXP TOTAL: $expTotal',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PEEP COINS: $peepCoins',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sigue jugando para desbloquear nuevos avatares y punteros.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 18),
                _ComicMainActionButton(
                  text: 'CONTINUAR',
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  int get _nivelActual => _nivelDesdeExp(_expTotal);

  int get _expActualNivel {
    final exp = _expTotal % 100;
    return exp < 0 ? 0 : exp;
  }

  int get _expSiguienteNivel => 100;

  double get _progresoExp {
    if (_expSiguienteNivel <= 0) return 0;
    return (_expActualNivel / _expSiguienteNivel).clamp(0.0, 1.0);
  }

  Future<void> _guardarApodo(String apodo) async {
    final limpio = apodo.trim();

    if (limpio.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_apodo', limpio);

    if (!mounted) return;

    setState(() => _apodo = limpio);
  }

  bool _avatarDesbloqueado(_AvatarOption avatar) {
    return _nivelActual >= avatar.requiredLevel;
  }

  Future<void> _guardarAvatar(_AvatarOption avatar) async {
    if (_guardandoAvatar) return;

    if (!_avatarDesbloqueado(avatar)) {
      setState(() {
        _mensajePerfil =
            'Este avatar se desbloquea en nivel ${avatar.requiredLevel}.';
      });
      return;
    }

    setState(() {
      _guardandoAvatar = true;
      _mensajePerfil = null;
    });

    try {
      final idUsuario = await AuthService.getIdUsuario();
      if (idUsuario == null) {
        throw Exception('No se encontró usuario en sesión.');
      }

      await ApiService.actualizarAvatarPerfil(
        idUsuario: idUsuario,
        avatarKey: avatar.keyName,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('perfil_avatar_key', avatar.keyName);

      if (!mounted) return;

      setState(() {
        _avatarKey = avatar.keyName;
        _guardandoAvatar = false;
        _mensajePerfil = 'Avatar actualizado correctamente.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardandoAvatar = false;
        _mensajePerfil =
            'No se pudo guardar el avatar. Revisa auth.py y MySQL.';
      });
    }
  }

  void _editarApodo() {
    final ctrl = TextEditingController(text: _apodo);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                  text: 'EDITAR\nAPODO',
                  subtitle: 'TU NOMBRE DE HÉROE',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge, color: Colors.black),
                    labelText: 'Apodo',
                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFFFDF2),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 4,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ComicMainActionButton(
                  text: 'GUARDAR',
                  onTap: () async {
                    await _guardarApodo(ctrl.text);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirAvatarPantallaCompleta() {
    if (_cargandoPerfil) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (dialogContext) {
        return Material(
          color: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(dialogContext),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 260,
                          height: 260,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              _avatarPath(_avatarKey),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 130,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Future.delayed(
                              const Duration(milliseconds: 120),
                              () {
                                if (!mounted) return;
                                _abrirSelectorAvatarJuego();
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 34,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF343434),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Text(
                              'Cambiar avatar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirSelectorAvatarJuego() {
    if (_avatares.isEmpty) return;

    String avatarSeleccionado = _avatarKey;
    String? mensajeLocal;
    bool guardandoLocal = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                18 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0CF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black, width: 5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 0,
                    offset: Offset(6, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _ProfileStepIconButton(
                          icon: Icons.close,
                          onTap: () => Navigator.pop(sheetContext),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _ExplosiveTitle(
                            text: 'CAMBIAR\nAVATAR',
                            subtitle: 'ELIGE TU PERSONAJE',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: _avatares.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatares[index];
                        final selected = avatar.keyName == avatarSeleccionado;
                        final locked =
                            !_avatarDesbloqueado(avatar) && !selected;

                        return _AvatarChoiceCard(
                          avatar: avatar,
                          selected: selected,
                          locked: locked,
                          saving: guardandoLocal,
                          onTap: () {
                            setSheetState(() {
                              avatarSeleccionado = avatar.keyName;
                              mensajeLocal = null;
                            });
                          },
                        );
                      },
                    ),
                    if (mensajeLocal != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        mensajeLocal!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _ComicMainActionButton(
                      text: guardandoLocal ? 'GUARDANDO...' : 'GUARDAR',
                      onTap: guardandoLocal
                          ? null
                          : () async {
                              final avatar = _avatares.firstWhere(
                                (item) => item.keyName == avatarSeleccionado,
                                orElse: () => _avatares.first,
                              );

                              if (!_avatarDesbloqueado(avatar)) {
                                setSheetState(() {
                                  mensajeLocal =
                                      'Este avatar se desbloquea en nivel ${avatar.requiredLevel}.';
                                });
                                return;
                              }

                              setSheetState(() {
                                guardandoLocal = true;
                                mensajeLocal = null;
                              });

                              await _guardarAvatar(avatar);

                              if (!mounted) return;
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
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

  void _abrirDesbloqueos() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const UnlocksPage()),
    );
  }

  void _cerrarSesionDesdePerfil() {
    Navigator.pop(context);
    widget.onLogout();
  }

  String _avatarPath(String key) {
    return 'assets/images/avatars/$key.png';
  }

  @override
  Widget build(BuildContext context) {
    final bg = _coloresAleatorios ? _fondoActual : _colorFijo;

    return Scaffold(
      body: Container(
        color: bg,
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: _ComicDotsBackground(modoClasico: false),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _ProfileStepIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: _ExplosiveTitle(
                            text: 'MI\nPERFIL',
                            subtitle: 'PROGRESO DEL JUGADOR',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _ProfileStepCard(
                      child: _cargandoPerfil
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                          : Column(
                              children: [
                                ScaleTransition(
                                  scale: _avatarPulseAnimation,
                                  child: GestureDetector(
                                    onTap: _abrirAvatarPantallaCompleta,
                                    onLongPress: _abrirAvatarPantallaCompleta,
                                    child: _ProfileAvatarPreview(
                                      assetPath: _avatarPath(_avatarKey),
                                      fallbackIcon: Icons.person,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _apodo,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'AVATAR: ${_avatarKey.toUpperCase()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _ComicMainActionButton(
                                  text: 'EDITAR APODO',
                                  onTap: _editarApodo,
                                ),
                                if (_mensajePerfil != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    _mensajePerfil!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileStepCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileStepStatBox(
                                  label: 'NIVEL',
                                  value: _nivelActual.toString(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileStepStatBox(
                                  label: 'PEEP COINS',
                                  value: _peepCoins.toString(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'EXP $_expActualNivel / $_expSiguienteNivel  •  TOTAL $_expTotal',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: LinearProgressIndicator(
                              value: _progresoExp,
                              minHeight: 22,
                              backgroundColor: Colors.white,
                              color: const Color(0xFF34C759),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'EXP y Peep Coins se leen desde MySQL. Cada 100 EXP suma un nivel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileStepCard(
                      child: Column(
                        children: [
                          _ComicMainActionButton(
                            text: 'VER DESBLOQUEOS',
                            onTap: _abrirDesbloqueos,
                          ),
                          const SizedBox(height: 12),
                          _ComicButton(
                            text: 'CERRAR SESIÓN',
                            variant: _ButtonVariant.blanco,
                            disabled: false,
                            onTap: _cerrarSesionDesdePerfil,
                          ),
                        ],
                      ),
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

class _AvatarOption {
  final String keyName;
  final String label;
  final String assetPath;
  final int requiredLevel;

  const _AvatarOption({
    required this.keyName,
    required this.label,
    required this.assetPath,
    required this.requiredLevel,
  });
}

class _ProfileAvatarPreview extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;

  const _ProfileAvatarPreview({
    required this.assetPath,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Icon(fallbackIcon, color: Colors.black, size: 72);
          },
        ),
      ),
    );
  }
}

class _AvatarChoiceCard extends StatelessWidget {
  final _AvatarOption avatar;
  final bool selected;
  final bool locked;
  final bool saving;
  final VoidCallback onTap;

  const _AvatarChoiceCard({
    required this.avatar,
    required this.selected,
    required this.locked,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = saving || locked;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD60A)
              : locked
              ? const Color(0xFFE6E6E6)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: selected ? 5 : 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColorFiltered(
                      colorFilter: locked
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Image.asset(
                        avatar.assetPath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFFFFDF2),
                            child: const Icon(
                              Icons.person,
                              color: Colors.black,
                              size: 42,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  avatar.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selected
                      ? 'EQUIPADO'
                      : locked
                      ? 'NIVEL ${avatar.requiredLevel}'
                      : 'EQUIPAR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (locked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock, color: Colors.black, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStepIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileStepIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 26),
      ),
    );
  }
}

class _ProfileStepCard extends StatelessWidget {
  final Widget child;

  const _ProfileStepCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(6, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileStepStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStepStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD60A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
