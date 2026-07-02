part of comic_ruleta_app;

// ================== MODE SELECT PAGE ==================

class ModeSelectPage extends StatefulWidget {
  final VoidCallback onModoAfin;
  final VoidCallback onModoCaotico;
  final VoidCallback onLogout;
  final VoidCallback? onOpenProfile;

  const ModeSelectPage({
    super.key,
    required this.onModoAfin,
    required this.onModoCaotico,
    required this.onLogout,
    this.onOpenProfile,
  });

  @override
  State<ModeSelectPage> createState() => _ModeSelectPageState();
}

class _ModeSelectPageState extends State<ModeSelectPage> {
  Color _fondoActual = const Color(0xFFFFD60A);
  bool _coloresAleatorios = false;
  Color _colorFijo = const Color(0xFFFFD60A);
  Set<Color> _coloresRandomActivos = {};
  Map<String, dynamic>? _perfilBurbuja;
  bool _cargandoPerfilBurbuja = true;

  final List<Color> _fondos = const [
    Color(0xFF00B7FF),
    Color(0xFFFF3B30),
    Color(0xFFFFD60A),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];

  @override
  void initState() {
    super.initState();
    _coloresRandomActivos = _fondos.toSet();
    _cargarPreferencias();
    _cargarPerfilBurbuja();
  }

  int _colorToInt(Color c) => c.value;
  Color _intToColor(int value) => Color(value);

  Future<void> _cargarPerfilBurbuja() async {
    final prefs = await SharedPreferences.getInstance();
    final apodoLocal = (prefs.getString('perfil_apodo') ?? '').trim();

    try {
      final idUsuario = await AuthService.getIdUsuario();

      if (idUsuario == null) {
        if (!mounted) return;
        setState(() {
          _perfilBurbuja = apodoLocal.isEmpty ? null : {'apodo': apodoLocal};
          _cargandoPerfilBurbuja = false;
        });
        return;
      }

      final perfilBackend = await ApiService.getPerfilBurbuja(idUsuario);
      final perfil = Map<String, dynamic>.from(perfilBackend);

      // El apodo actualmente se guarda desde la pantalla de perfil en
      // SharedPreferences. Por eso lo usamos como prioridad local para que
      // el lobby se actualice al volver desde Perfil sin tocar backend.
      if (apodoLocal.isNotEmpty) {
        perfil['apodo'] = apodoLocal;
      }

      if (!mounted) return;
      setState(() {
        _perfilBurbuja = perfil;
        _cargandoPerfilBurbuja = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _perfilBurbuja = apodoLocal.isEmpty ? null : {'apodo': apodoLocal};
        _cargandoPerfilBurbuja = false;
      });
    }
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final aleatorio = prefs.getBool('ajustes_colores_aleatorios');
    final fijo = prefs.getInt('ajustes_color_fijo');
    final random = prefs.getStringList('ajustes_colores_random');

    if (!mounted) return;

    setState(() {
      if (aleatorio != null) _coloresAleatorios = aleatorio;

      if (fijo != null) {
        _colorFijo = _intToColor(fijo);
      }

      _fondoActual = _colorFijo;

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
    });
  }

  Future<void> _guardarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ajustes_colores_aleatorios', _coloresAleatorios);
    await prefs.setInt('ajustes_color_fijo', _colorToInt(_colorFijo));
    await prefs.setStringList(
      'ajustes_colores_random',
      _coloresRandomActivos.map((c) => _colorToInt(c).toString()).toList(),
    );
  }

  void _abrirAjustes() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ModeColorSettingsPage(
          fondoActual: _fondoActual,
          colorFijo: _colorFijo,
          coloresAleatorios: _coloresAleatorios,
          fondos: _fondos,
          coloresRandomActivos: _coloresRandomActivos,
          onLogout: widget.onLogout,
          onGuardar:
              ({
                required bool coloresAleatorios,
                required Color colorFijo,
                required Color fondoActual,
                required Set<Color> coloresRandomActivos,
              }) async {
                setState(() {
                  _coloresAleatorios = coloresAleatorios;
                  _colorFijo = colorFijo;
                  _fondoActual = fondoActual;
                  _coloresRandomActivos = coloresRandomActivos;
                });
                await _guardarPreferencias();
              },
        ),
      ),
    );
  }

  void _abrirPerfil() {
    widget.onOpenProfile?.call();

    // Al volver desde perfil, refrescamos los datos por si cambió apodo,
    // avatar, nivel o monedas. No afecta navegación ni lógica del juego.
    Future.delayed(const Duration(milliseconds: 350), _cargarPerfilBurbuja);
    Future.delayed(const Duration(milliseconds: 900), _cargarPerfilBurbuja);
    Future.delayed(const Duration(milliseconds: 1600), _cargarPerfilBurbuja);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _coloresAleatorios ? _fondoActual : _colorFijo;

    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          color: bg,
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: _ComicDotsBackground(modoClasico: false),
                ),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 120, 18, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 142,
                        ),
                        child: Column(
                          children: [
                            const _ModeHeader(),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ModeCard(
                                    title: 'UNIVERSO\nAFÍN',
                                    subtitle:
                                        'Elige un universo y encuentra el personaje base más parecido.',
                                    imagePath:
                                        'assets/images/modo_personaje_afin.jpeg',
                                    onTap: widget.onModoAfin,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _ModeCard(
                                    title: 'MODO\nCAÓTICO',
                                    subtitle:
                                        'Todo se genera de forma aleatoria. Solo caos creativo.',
                                    imagePath:
                                        'assets/images/modo_caotico.jpeg',
                                    onTap: widget.onModoCaotico,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                Positioned(
                  top: 10,
                  left: 14,
                  right: 14,
                  child: _ModeLobbyPlayerHud(
                    perfil: _perfilBurbuja,
                    cargando: _cargandoPerfilBurbuja,
                    onOpenProfile: widget.onOpenProfile == null
                        ? null
                        : _abrirPerfil,
                    onOpenSettings: _abrirAjustes,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeLobbyPlayerHud extends StatelessWidget {
  final Map<String, dynamic>? perfil;
  final bool cargando;
  final VoidCallback? onOpenProfile;
  final VoidCallback onOpenSettings;

  const _ModeLobbyPlayerHud({
    required this.perfil,
    required this.cargando,
    required this.onOpenProfile,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final apodo = cargando
        ? 'Cargando...'
        : (perfil?['apodo'] ?? 'Jugador').toString();
    final avatarAsset =
        (perfil?['avatar_asset'] ?? 'assets/images/avatars/maga.png')
            .toString();
    final nivel = int.tryParse('${perfil?['nivel_actual'] ?? 1}') ?? 1;
    final coins = int.tryParse('${perfil?['peep_coins'] ?? 0}') ?? 0;
    final expEnNivel = int.tryParse('${perfil?['exp_en_nivel'] ?? 0}') ?? 0;
    final progresoRaw =
        double.tryParse('${perfil?['progreso_nivel'] ?? 0}') ?? 0.0;
    final progreso = progresoRaw.clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeLobbyAvatar(avatarAsset: avatarAsset),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeLobbyNameBar(apodo: apodo),
              const SizedBox(height: 7),
              Row(
                children: [
                  if (onOpenProfile != null) ...[
                    _ModeLobbySmallButton(
                      icon: Icons.person,
                      onTap: onOpenProfile!,
                    ),
                    const SizedBox(width: 7),
                  ],
                  _ModeLobbySmallButton(
                    icon: Icons.settings,
                    onTap: onOpenSettings,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _ModeLobbyExpBar(
                      nivel: nivel,
                      expEnNivel: expEnNivel,
                      progreso: progreso,
                    ),
                  ),
                  const SizedBox(width: 7),
                  _ModeLobbyCoinsBar(coins: coins),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeLobbyAvatar extends StatelessWidget {
  final String avatarAsset;

  const _ModeLobbyAvatar({required this.avatarAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          avatarAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.black, size: 32),
        ),
      ),
    );
  }
}

class _ModeLobbyNameBar extends StatelessWidget {
  final String apodo;

  const _ModeLobbyNameBar({required this.apodo});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
        ],
      ),
      child: Text(
        apodo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
    );
  }
}

class _ModeLobbySmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModeLobbySmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 19),
      ),
    );
  }
}

class _ModeLobbyExpBar extends StatelessWidget {
  final int nivel;
  final int expEnNivel;
  final double progreso;

  const _ModeLobbyExpBar({
    required this.nivel,
    required this.expEnNivel,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = (constraints.maxWidth - 6).clamp(
            0.0,
            double.infinity,
          );
          final progressWidth = innerWidth * progreso.clamp(0.0, 1.0);

          return Stack(
            children: [
              if (progressWidth > 0)
                Positioned(
                  left: 3,
                  top: 3,
                  bottom: 3,
                  child: Container(
                    width: progressWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.black, size: 15),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Nv $nivel · $expEnNivel/100',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeLobbyCoinsBar extends StatelessWidget {
  final int coins;

  const _ModeLobbyCoinsBar({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      constraints: const BoxConstraints(minWidth: 64, maxWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE35A),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC400),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Text(
              r'$',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$coins',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModeTopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }
}

class _ModeHeader extends StatelessWidget {
  const _ModeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Text(
          'ELIGE TU\nMODO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 0.88,
            letterSpacing: 1.1,
            shadows: [
              Shadow(offset: Offset(4, 0), color: Colors.black),
              Shadow(offset: Offset(-4, 0), color: Colors.black),
              Shadow(offset: Offset(0, 4), color: Colors.black),
              Shadow(offset: Offset(0, -4), color: Colors.black),
              Shadow(offset: Offset(5, 5), color: Colors.black),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: const Text(
            '¿CÓMO QUIERES CREAR TU PERSONAJE?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              height: 145,
              width: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 25,
              height: 0.88,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _ComicMainActionButton(text: 'JUGAR', onTap: onTap),
        ],
      ),
    );
  }
}

// ================== AJUSTES SOLO COLORES PARA PANTALLA DE MODOS ==================

class _ModeColorSettingsPage extends StatefulWidget {
  final Color fondoActual;
  final Color colorFijo;
  final bool coloresAleatorios;
  final List<Color> fondos;
  final Set<Color> coloresRandomActivos;
  final VoidCallback onLogout;
  final void Function({
    required bool coloresAleatorios,
    required Color colorFijo,
    required Color fondoActual,
    required Set<Color> coloresRandomActivos,
  })
  onGuardar;

  const _ModeColorSettingsPage({
    required this.fondoActual,
    required this.colorFijo,
    required this.coloresAleatorios,
    required this.fondos,
    required this.coloresRandomActivos,
    required this.onLogout,
    required this.onGuardar,
  });

  @override
  State<_ModeColorSettingsPage> createState() => _ModeColorSettingsPageState();
}

class _ModeColorSettingsPageState extends State<_ModeColorSettingsPage> {
  late bool _coloresAleatorios;
  late Color _colorFijo;
  late Set<Color> _coloresRandom;

  @override
  void initState() {
    super.initState();
    _coloresAleatorios = widget.coloresAleatorios;
    _colorFijo = widget.colorFijo;
    _coloresRandom = widget.coloresRandomActivos.isEmpty
        ? widget.fondos.toSet()
        : widget.coloresRandomActivos.toSet();
  }

  void _guardar() {
    final fondoActual = _coloresAleatorios ? widget.fondoActual : _colorFijo;

    widget.onGuardar(
      coloresAleatorios: _coloresAleatorios,
      colorFijo: _colorFijo,
      fondoActual: fondoActual,
      coloresRandomActivos: _coloresRandom.toSet(),
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
              const Positioned.fill(
                child: _ComicDotsBackground(modoClasico: false),
              ),
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
                          child: Text(
                            'AJUSTES',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  offset: Offset(4, 4),
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                                onTap: () {
                                  setState(() {
                                    _colorFijo = c;
                                    _coloresAleatorios = false;
                                  });
                                },
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
