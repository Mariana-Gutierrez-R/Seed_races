part of comic_ruleta_app;

// ================== PROFILE PAGE - STEP 2 ==================
// Perfil visual y navegable. No conecta todavía backend, EXP real ni monedas reales.

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
    _cargarPerfilTemporal();
  }

  int _colorToInt(Color c) => c.value;
  Color _intToColor(int value) => Color(value);

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

  Future<void> _cargarPerfilTemporal() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _apodo = prefs.getString('perfil_apodo') ?? 'Peep Player';
    });
  }

  Future<void> _guardarApodo(String apodo) async {
    final limpio = apodo.trim();

    if (limpio.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_apodo', limpio);

    if (!mounted) return;

    setState(() => _apodo = limpio);
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
                      child: Column(
                        children: [
                          Container(
                            width: 118,
                            height: 118,
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
                            child: const Icon(
                              Icons.person,
                              color: Colors.black,
                              size: 68,
                            ),
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
                            'Esta pantalla queda lista para conectar EXP, avatares y monedas en los siguientes commits.',
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
