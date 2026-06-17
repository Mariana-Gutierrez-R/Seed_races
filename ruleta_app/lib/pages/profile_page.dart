part of comic_ruleta_app;

// ================== PROFILE PAGE ==================
// Commit 1: pantalla visual de perfil.
// No conecta todavía EXP, monedas ni desbloqueos con backend.

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
  String _avatarAsset = 'assets/images/avatars/maga.png';

  final TextEditingController _apodoCtrl = TextEditingController();

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
  }

  @override
  void dispose() {
    _apodoCtrl.dispose();
    super.dispose();
  }

  int _colorToInt(Color c) => c.value;
  Color _intToColor(int value) => Color(value);

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final aleatorio = prefs.getBool('ajustes_colores_aleatorios');
    final fijo = prefs.getInt('ajustes_color_fijo');
    final random = prefs.getStringList('ajustes_colores_random');
    final apodo = prefs.getString('perfil_apodo');
    final avatar = prefs.getString('perfil_avatar_asset');

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

      if (_coloresAleatorios && _coloresRandomActivos.isNotEmpty) {
        _fondoActual = _coloresRandomActivos.elementAt(
          Random().nextInt(_coloresRandomActivos.length),
        );
      }

      _apodo = apodo?.trim().isNotEmpty == true ? apodo!.trim() : 'Peep Player';
      _avatarAsset = avatar?.trim().isNotEmpty == true
          ? avatar!.trim()
          : 'assets/images/avatars/maga.png';
    });
  }

  Future<void> _guardarApodo(String nuevoApodo) async {
    final limpio = nuevoApodo.trim();
    if (limpio.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_apodo', limpio);

    if (!mounted) return;
    setState(() => _apodo = limpio);
  }

  void _editarApodo() {
    _apodoCtrl.text = _apodo;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF2),
              borderRadius: BorderRadius.circular(24),
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
                const Text(
                  'EDITAR APODO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _apodoCtrl,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Apodo',
                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                    prefixIcon: const Icon(Icons.badge, color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
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
                const SizedBox(height: 14),
                _ProfileComicButton(
                  text: 'GUARDAR',
                  icon: Icons.save,
                  onTap: () async {
                    await _guardarApodo(_apodoCtrl.text);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirDesbloqueosPendiente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Desbloqueos se conectará en el siguiente commit.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetPendiente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset de cuenta se conectará en una fase posterior.'),
        duration: Duration(seconds: 2),
      ),
    );
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
              const Positioned.fill(child: _ComicSpeedLines()),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _ProfileTopButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        _ProfileTopButton(
                          icon: Icons.logout,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onLogout();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'MI\nPERFIL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 0.88,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(offset: Offset(4, 0), color: Colors.black),
                          Shadow(offset: Offset(-4, 0), color: Colors.black),
                          Shadow(offset: Offset(0, 4), color: Colors.black),
                          Shadow(offset: Offset(4, 4), color: Colors.black),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProfileComicCard(
                      child: Column(
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 0,
                                  offset: Offset(5, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _avatarAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 78,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _apodo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ProfileComicButton(
                            text: 'EDITAR APODO',
                            icon: Icons.edit,
                            onTap: _editarApodo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileComicCard(
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Expanded(
                                child: _ProfileStatBox(
                                  label: 'NIVEL',
                                  value: '1',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _ProfileStatBox(
                                  label: 'EXP',
                                  value: '0 / 100',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const _ProfileStatBox(
                            label: 'PEEP COINS',
                            value: '0',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Esta pantalla ya queda creada y lista para conectar EXP, avatares y monedas en los siguientes commits.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileComicCard(
                      child: Column(
                        children: [
                          _ProfileComicButton(
                            text: 'DESBLOQUEOS',
                            icon: Icons.lock_open,
                            onTap: _abrirDesbloqueosPendiente,
                          ),
                          const SizedBox(height: 10),
                          _ProfileComicButton(
                            text: 'RESET CUENTA',
                            icon: Icons.warning,
                            dark: true,
                            onTap: _resetPendiente,
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

class _ProfileTopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileTopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }
}

class _ProfileComicCard extends StatelessWidget {
  final Widget child;

  const _ProfileComicCard({required this.child});

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

class _ProfileComicButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  const _ProfileComicButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: dark ? Colors.black : const Color(0xFFFFD60A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: dark ? Colors.white : Colors.black, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
