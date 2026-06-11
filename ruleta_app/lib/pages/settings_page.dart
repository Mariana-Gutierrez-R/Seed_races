part of comic_ruleta_app;

// ================== SETTINGS PAGE ==================

class _SettingsComicPage extends StatefulWidget {
  final Color fondoActual;
  final Color colorFijo;
  final bool coloresAleatorios;
  final List<Color> fondos;
  final Set<Color> coloresRandomActivos;
  final String picoSeleccionado;
  final void Function({
    required bool coloresAleatorios,
    required Color colorFijo,
    required Color fondoActual,
    required Set<Color> coloresRandomActivos,
    required String picoSeleccionado,
  })
  onGuardar;
  final VoidCallback onLogout;

  const _SettingsComicPage({
    required this.fondoActual,
    required this.colorFijo,
    required this.coloresAleatorios,
    required this.fondos,
    required this.coloresRandomActivos,
    required this.picoSeleccionado,
    required this.onGuardar,
    required this.onLogout,
  });

  @override
  State<_SettingsComicPage> createState() => _SettingsComicPageState();
}

class _SettingsComicPageState extends State<_SettingsComicPage> {
  late bool _coloresAleatorios;
  late Color _colorFijo;
  late Set<Color> _coloresRandom;
  late String _picoSeleccionado;

  @override
  void initState() {
    super.initState();
    _coloresAleatorios = widget.coloresAleatorios;
    _colorFijo = widget.colorFijo;
    _coloresRandom = widget.coloresRandomActivos.isEmpty
        ? widget.fondos.toSet()
        : widget.coloresRandomActivos.toSet();
    _picoSeleccionado = widget.picoSeleccionado;
  }

  void _guardar() {
    final fondoActual = _coloresAleatorios ? widget.fondoActual : _colorFijo;
    widget.onGuardar(
      coloresAleatorios: _coloresAleatorios,
      colorFijo: _colorFijo,
      fondoActual: fondoActual,
      coloresRandomActivos: _coloresRandom.toSet(),
      picoSeleccionado: _picoSeleccionado,
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
              const Positioned.fill(child: _ComicSpeedLines()),
              const Positioned.fill(child: _AuthComicDots()),
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
                          child: _ExplosiveTitle(
                            text: 'AJUSTES',
                            subtitle: 'PERSONALIZA TU UNIVERSO',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                                onTap: () => setState(() => _colorFijo = c),
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
                          const SizedBox(height: 10),
                          const Text(
                            'La app ya evita repetir el mismo color dos veces seguidas. La selección de colores queda lista para una mejora posterior.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      title: 'PICO DE LA RULETA',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elige la forma del marcador que apunta al resultado de la ruleta.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PicoOptionTile(
                            value: 'clasico',
                            label: 'Pico clásico',
                            selected: _picoSeleccionado == 'clasico',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'clasico'),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'radar',
                            label: 'Radar',
                            selected:
                                _picoSeleccionado == 'radar' ||
                                _picoSeleccionado == 'esfera',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'radar'),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'murcielago',
                            label: 'Murciélago',
                            selected: _picoSeleccionado == 'murcielago',
                            onTap: () => setState(
                              () => _picoSeleccionado = 'murcielago',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'rayo',
                            label: 'Rayo',
                            selected: _picoSeleccionado == 'rayo',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'rayo'),
                          ),
                          const SizedBox(height: 10),
                          _PicoOptionTile(
                            value: 'espada',
                            label: 'Espada',
                            selected:
                                _picoSeleccionado == 'espada' ||
                                _picoSeleccionado == 'anillo',
                            onTap: () =>
                                setState(() => _picoSeleccionado = 'espada'),
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

class _PicoOptionTile extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PicoOptionTile({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: selected ? 5 : 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 116,
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: _PointerVisual(tipo: value, width: 106, height: 82),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.black, size: 24),
          ],
        ),
      ),
    );
  }
}

class _PointerVisual extends StatelessWidget {
  final String tipo;
  final double width;
  final double height;

  const _PointerVisual({
    required this.tipo,
    required this.width,
    required this.height,
  });

  String? get _assetPath {
    switch (tipo) {
      case 'clasico':
        return 'assets/images/puntero_clasico.png';
      case 'rayo':
        return 'assets/images/puntero_rayo.png';
      case 'murcielago':
        return 'assets/images/puntero_murcielago.png';
      case 'espada':
      case 'anillo':
        return 'assets/images/puntero_espada.png';
      case 'radar':
      case 'esfera':
        return 'assets/images/puntero_radar.png';
      default:
        return 'assets/images/puntero_clasico.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assetPath;

    if (asset == null) {
      return CustomPaint(
        size: Size(width, height),
        painter: _PointerComicPainter(tipo: tipo),
      );
    }

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.red,
            size: 28,
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 19,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ComicToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ComicToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? Colors.black : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorBubble extends StatelessWidget {
  final Color color;
  final bool selected;

  const _ColorBubble({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: selected ? 54 : 46,
      height: selected ? 54 : 46,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: selected ? 5 : 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3)),
        ],
      ),
      child: selected ? const Icon(Icons.check, color: Colors.black) : null,
    );
  }
}
