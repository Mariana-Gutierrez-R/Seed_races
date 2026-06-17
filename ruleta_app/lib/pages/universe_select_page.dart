part of comic_ruleta_app;

// ================== UNIVERSE SELECT PAGE ==================

class UniverseSelectPage extends StatefulWidget {
  final ValueChanged<String> onUniversoSeleccionado;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const UniverseSelectPage({
    super.key,
    required this.onUniversoSeleccionado,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<UniverseSelectPage> createState() => _UniverseSelectPageState();
}

class _UniverseSelectPageState extends State<UniverseSelectPage> {
  bool _cargando = true;
  bool _hayError = false;
  String? _universoSeleccionado;
  List<String> _universos = [];

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

  @override
  void initState() {
    super.initState();
    _coloresRandomActivos = _fondos.toSet();
    _cargarPreferencias();
    _cargarUniversos();
  }

  int _colorToInt(Color c) => c.value;
  Color _intToColor(int value) => Color(value);

  Future<void> _cargarPreferencias() async {
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

  Future<void> _guardarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ajustes_colores_aleatorios', _coloresAleatorios);
    await prefs.setInt('ajustes_color_fijo', _colorToInt(_colorFijo));
    await prefs.setStringList(
      'ajustes_colores_random',
      _coloresRandomActivos.map((c) => _colorToInt(c).toString()).toList(),
    );
    await prefs.setString('ajustes_pico_ruleta', _picoSeleccionado);
  }

  Future<void> _cargarUniversos() async {
    setState(() {
      _cargando = true;
      _hayError = false;
    });

    try {
      final lista = await ApiService.getOrigenes();

      if (!mounted) return;

      setState(() {
        _universos = lista;
        _universoSeleccionado = lista.isNotEmpty ? lista.first : null;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hayError = true;
        _cargando = false;
      });
    }
  }

  void _abrirAjustes() {
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
              }) async {
                setState(() {
                  _coloresAleatorios = coloresAleatorios;
                  _colorFijo = colorFijo;
                  _fondoActual = fondoActual;
                  _coloresRandomActivos = coloresRandomActivos;
                  _picoSeleccionado = picoSeleccionado;
                });
                await _guardarPreferencias();
              },
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(onLogout: widget.onLogout),
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
                  children: [
                    _TopIconButton(icon: Icons.person, onTap: _abrirPerfil),
                    const SizedBox(width: 10),
                    _TopIconButton(icon: Icons.settings, onTap: _abrirAjustes),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 78, 20, 26),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 104,
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
                          const SizedBox(height: 18),
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
                              'ESTE ORIGEN SERÁ LA BASE DEL PERSONAJE AFÍN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (_cargando)
                            const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          else if (_hayError)
                            _ComicButton(
                              text: 'REINTENTAR',
                              variant: _ButtonVariant.blanco,
                              disabled: false,
                              onTap: _cargarUniversos,
                            )
                          else ...[
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: _universos.map((u) {
                                return _UniverseChip(
                                  label: u,
                                  selected: _universoSeleccionado == u,
                                  onTap: () =>
                                      setState(() => _universoSeleccionado = u),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 26),
                            _ComicMainActionButton(
                              text: 'CONTINUAR',
                              onTap: _continuar,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
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

class _UniverseChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UniverseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 150,
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : const Color(0xFFFFFDF2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: selected ? 5 : 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}
