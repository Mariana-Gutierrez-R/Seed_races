part of comic_ruleta_app;

// ================== PROFILE PAGE - STEP 3 ==================
// Perfil visual + avatar real conectado con auth.py / MySQL.

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Color _fondoActual = const Color(0xFFFFD60A);
  bool _coloresAleatorios = false;
  Color _colorFijo = const Color(0xFFFFD60A);
  Set<Color> _coloresRandomActivos = {};

  String _apodo = 'Peep Player';
  String _avatarKey = 'maga';
  bool _cargandoPerfil = true;
  bool _guardandoAvatar = false;
  String? _mensajePerfil;

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
    ),
    _AvatarOption(
      keyName: 'payaso',
      label: 'PAYASO',
      assetPath: 'assets/images/avatars/payaso.png',
    ),
    _AvatarOption(
      keyName: 'sayajin',
      label: 'SAYAJIN',
      assetPath: 'assets/images/avatars/sayajin.png',
    ),
    _AvatarOption(
      keyName: 'dragon',
      label: 'DRAGÓN',
      assetPath: 'assets/images/avatars/dragon.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _coloresRandomActivos = _fondos.toSet();
    _cargarPreferencias();
    _cargarPerfil();
  }

  int _colorToInt(Color c) => c.value;
  Color _intToColor(int value) => Color(value);

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    final coloresAleatorios = prefs.getBool('ajustes_colores_aleatorios') ?? false;
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
      _coloresRandomActivos = randomActivos.isEmpty ? _fondos.toSet() : randomActivos;
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

      setState(() {
        _apodo = (data['apodo'] ?? data['nombre_usuario'] ?? 'Peep Player').toString();
        _avatarKey = (data['avatar_key'] ?? 'maga').toString();
        _cargandoPerfil = false;
      });
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _apodo = prefs.getString('perfil_apodo') ?? 'Peep Player';
        _avatarKey = prefs.getString('perfil_avatar_key') ?? 'maga';
        _cargandoPerfil = false;
        _mensajePerfil = 'No se pudo cargar el perfil desde MySQL. Revisa auth.py en puerto 8001.';
      });
    }
  }

  Future<void> _guardarApodo(String apodo) async {
    final limpio = apodo.trim();

    if (limpio.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_apodo', limpio);

    if (!mounted) return;

    setState(() => _apodo = limpio);
  }

  Future<void> _guardarAvatar(String avatarKey) async {
    if (_guardandoAvatar) return;

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
        avatarKey: avatarKey,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('perfil_avatar_key', avatarKey);

      if (!mounted) return;

      setState(() {
        _avatarKey = avatarKey;
        _guardandoAvatar = false;
        _mensajePerfil = 'Avatar actualizado correctamente.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardandoAvatar = false;
        _mensajePerfil = 'No se pudo guardar el avatar. Revisa auth.py y MySQL.';
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
                      borderSide: const BorderSide(color: Colors.black, width: 4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.black, width: 5),
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
                              child: CircularProgressIndicator(color: Colors.black),
                            )
                          : Column(
                              children: [
                                _ProfileAvatarPreview(
                                  assetPath: _avatarPath(_avatarKey),
                                  fallbackIcon: Icons.person,
                                ),
                                const SizedBox(height: 16),
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
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileStepCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _ExplosiveTitle(
                            text: 'CAMBIAR\nAVATAR',
                            subtitle: 'GUARDADO EN MYSQL',
                          ),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: _avatares.length,
                            itemBuilder: (context, index) {
                              final avatar = _avatares[index];
                              final selected = avatar.keyName == _avatarKey;

                              return _AvatarChoiceCard(
                                avatar: avatar,
                                selected: selected,
                                disabled: _guardandoAvatar,
                                onTap: () => _guardarAvatar(avatar.keyName),
                              );
                            },
                          ),
                          if (_guardandoAvatar) ...[
                            const SizedBox(height: 14),
                            const Center(
                              child: CircularProgressIndicator(color: Colors.black),
                            ),
                          ],
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
                            children: const [
                              Expanded(
                                child: _ProfileStepStatBox(
                                  label: 'NIVEL',
                                  value: '1',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _ProfileStepStatBox(
                                  label: 'PEEP COINS',
                                  value: '0',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'EXP 0 / 100',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: const LinearProgressIndicator(
                              value: 0,
                              minHeight: 22,
                              backgroundColor: Colors.white,
                              color: Color(0xFF34C759),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'En este commit solo conectamos el avatar con MySQL. EXP, monedas y niveles van en commits separados.',
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

  const _AvatarOption({
    required this.keyName,
    required this.label,
    required this.assetPath,
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
  final bool disabled;
  final VoidCallback onTap;

  const _AvatarChoiceCard({
    required this.avatar,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: selected ? 5 : 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  avatar.assetPath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFFFFFDF2),
                      child: const Icon(Icons.person, color: Colors.black, size: 42),
                    );
                  },
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
              selected ? 'EQUIPADO' : 'EQUIPAR',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 11,
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
