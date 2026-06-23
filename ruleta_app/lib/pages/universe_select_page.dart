part of comic_ruleta_app;

// ================== UNIVERSE SELECT PAGE ==================

class UniverseSelectPage extends StatefulWidget {
  final ValueChanged<String> onUniversoSeleccionado;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback? onOpenProfile;

  const UniverseSelectPage({
    super.key,
    required this.onUniversoSeleccionado,
    required this.onBack,
    required this.onLogout,
    this.onOpenProfile,
  });

  @override
  State<UniverseSelectPage> createState() => _UniverseSelectPageState();
}

class _UniverseSelectPageState extends State<UniverseSelectPage> {
  String? _universoSeleccionado;

  Color _fondoActual = const Color(0xFFFFD60A);
  bool _coloresAleatorios = false;
  Color _colorFijo = const Color(0xFFFFD60A);
  Set<Color> _coloresRandomActivos = {};

  final List<Color> _fondos = const [
    Color(0xFF00B7FF),
    Color(0xFFFF3B30),
    Color(0xFFFFD60A),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFFFF9500),
  ];

  final List<String> _universos = const [
    'Dragon Ball',
    'DC Comics',
    'Greek Mythology',
    'LOTR',
  ];

  @override
  void initState() {
    super.initState();
    _coloresRandomActivos = _fondos.toSet();
    _universoSeleccionado = _universos.first;
    _cargarPreferencias();
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
      if (fijo != null) _colorFijo = _intToColor(fijo);
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

  void _continuar() {
    final universo = _universoSeleccionado;
    if (universo == null || universo.trim().isEmpty) return;
    widget.onUniversoSeleccionado(universo);
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
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 86, 20, 26),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 112,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ELIGE TU\nUNIVERSO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 0.88,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  offset: Offset(4, 0),
                                  color: Colors.black,
                                ),
                                Shadow(
                                  offset: Offset(-4, 0),
                                  color: Colors.black,
                                ),
                                Shadow(
                                  offset: Offset(0, 4),
                                  color: Colors.black,
                                ),
                                Shadow(
                                  offset: Offset(0, -4),
                                  color: Colors.black,
                                ),
                                Shadow(
                                  offset: Offset(5, 5),
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 4),
                            ),
                            child: const Text(
                              '¿QUÉ UNIVERSO QUIERES COMO BASE?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          ..._universos.map(
                            (u) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _UniverseOptionTile(
                                label: u,
                                selected: _universoSeleccionado == u,
                                onTap: () {
                                  setState(() => _universoSeleccionado = u);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ComicMainActionButton(
                            text: 'CONTINUAR',
                            onTap: _continuar,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 18,
                left: 18,
                child: _TopIconButton(
                  icon: Icons.arrow_back,
                  onTap: widget.onBack,
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onOpenProfile != null) ...[
                      _TopIconButton(
                        icon: Icons.person,
                        onTap: widget.onOpenProfile!,
                      ),
                      const SizedBox(width: 10),
                    ],
                    _TopIconButton(icon: Icons.settings, onTap: _abrirAjustes),
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

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
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

class _UniverseOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UniverseOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (label) {
      case 'Dragon Ball':
        return Icons.radar;
      case 'DC Comics':
        return Icons.bathtub;
      case 'Greek Mythology':
        return Icons.flash_on;
      case 'LOTR':
        return Icons.auto_fix_high;
      default:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : const Color(0xFFFFFDF2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: selected ? 5 : 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Icon(_icon, color: Colors.black, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.black, size: 28),
          ],
        ),
      ),
    );
  }
}
