part of comic_ruleta_app;

// ================== COMIC WIDGETS ==================

enum _ButtonVariant { blanco, negro }

class _ComicButton extends StatelessWidget {
  final String text;
  final _ButtonVariant variant;
  final bool disabled;
  final VoidCallback onTap;

  const _ComicButton({
    required this.text,
    required this.variant,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = variant == _ButtonVariant.blanco;
    final bg = isWhite ? Colors.white : Colors.black;
    final fg = isWhite ? const Color(0xFF111111) : Colors.white;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: isWhite ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(5, 5),
              ),
              BoxShadow(
                color: Colors.white24,
                blurRadius: 0,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              shadows: isWhite
                  ? null
                  : const [Shadow(offset: Offset(2, 2), color: Colors.black)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComicMainActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _ComicMainActionButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 58,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF176), Color(0xFFFFD60A), Color(0xFFFFB000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultadoComic extends StatelessWidget {
  final String valor;
  final String estado;

  const _ResultadoComic({required this.valor, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'RESULTADO',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                height: 1,
              ),
            ),
          ),
          if (estado.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              estado,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LobbyComic extends StatelessWidget {
  final PersonajeModel? personaje;
  final EstadoJuego juego;
  final String? tipoDibujo;
  final String estado;
  final VoidCallback onVerImagen;
  final VoidCallback onVolverTirar;

  const _LobbyComic({
    required this.personaje,
    required this.juego,
    required this.tipoDibujo,
    required this.estado,
    required this.onVerImagen,
    required this.onVolverTirar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = personaje?.characterName ?? 'PERSONAJE ALEATORIO';

    return Column(
      children: [
        const _ExplosiveTitle(
          text: '¡PERSONAJE\nCREADO!',
          subtitle: 'TU UNIVERSO YA TIENE PROTAGONISTA',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF2),
            borderRadius: BorderRadius.circular(26),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  border: Border.all(color: Colors.black, width: 4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  nombre.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LobbyRow(label: 'ORIGEN', value: juego.origin ?? '-'),
              _LobbyRow(label: 'CATEGORÍA', value: juego.category ?? '-'),
              _LobbyRow(label: 'RAZA', value: juego.race ?? '-'),
              _LobbyRow(label: 'SUBRAZA', value: juego.subrace ?? '-'),
              _LobbyRow(label: 'ROL', value: juego.role ?? '-'),
              _LobbyRow(label: 'ARMA', value: juego.weapon ?? '-'),
              _LobbyRow(label: 'DAÑO', value: juego.damageType ?? '-'),
              _LobbyRow(label: 'MORALIDAD', value: juego.morality ?? '-'),
              _LobbyRow(label: 'AMENAZA', value: juego.threatLevel ?? '-'),
              _LobbyRow(label: 'DIBUJO', value: tipoDibujo ?? '-'),
              if (estado.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  estado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ComicButton(
                text: 'CREAR IMAGEN',
                variant: _ButtonVariant.blanco,
                disabled: false,
                onTap: onVerImagen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComicButton(
                text: 'VOLVER A TIRAR',
                variant: _ButtonVariant.negro,
                disabled: false,
                onTap: onVolverTirar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LobbyRow extends StatelessWidget {
  final String label;
  final String value;

  const _LobbyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBubbleComic extends StatelessWidget {
  final String texto;

  const _QuestionBubbleComic({required this.texto});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: 5),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5)),
          ],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AnswerOptionComic extends StatelessWidget {
  final String texto;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _AnswerOptionComic({
    required this.texto,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD60A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 5),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFFFD60A),
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon ?? Icons.auto_awesome, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusComic extends StatelessWidget {
  final String texto;

  const _MiniStatusComic({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BannerComic extends StatelessWidget {
  final String text;

  const _BannerComic({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ComicDotsBackground extends StatelessWidget {
  final bool modoClasico;

  const _ComicDotsBackground({required this.modoClasico});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotsPainter(modoClasico: modoClasico));
  }
}

class _TipoDibujoComic extends StatelessWidget {
  final List<String> tipos;
  final String? seleccionado;
  final String estado;
  final ValueChanged<String> onSeleccionar;

  const _TipoDibujoComic({
    required this.tipos,
    required this.seleccionado,
    required this.estado,
    required this.onSeleccionar,
  });

  IconData _iconFor(String t) {
    final v = t.toLowerCase();
    if (v.contains('anime')) return Icons.auto_awesome;
    if (v.contains('pixel')) return Icons.grid_view;
    if (v.contains('caricatura')) return Icons.face_retouching_natural;
    return Icons.menu_book;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ExplosiveTitle(
          text: 'ELIGE EL\nESTILO',
          subtitle: '¿CÓMO QUIERES VER TU PERSONAJE?',
        ),
        const SizedBox(height: 18),
        ...tipos.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnswerOptionComic(
              texto: t,
              selected: seleccionado == t,
              icon: _iconFor(t),
              onTap: () => onSeleccionar(t),
            ),
          ),
        ),
        if (estado.isNotEmpty) _MiniStatusComic(texto: estado),
      ],
    );
  }
}

class _ExplosiveTitle extends StatelessWidget {
  final String text;
  final String subtitle;

  const _ExplosiveTitle({required this.text, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(5, 6),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 0.90,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 0.90,
                  letterSpacing: -0.6,
                  shadows: [
                    Shadow(offset: Offset(3, 0), color: Colors.black),
                    Shadow(offset: Offset(-3, 0), color: Colors.black),
                    Shadow(offset: Offset(0, 3), color: Colors.black),
                    Shadow(offset: Offset(0, -3), color: Colors.black),
                    Shadow(offset: Offset(2, 2), color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF2),
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0D47A1),
                  blurRadius: 0,
                  offset: Offset(3, 4),
                ),
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicMascotBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _ComicMascotBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border.all(color: Colors.black, width: 5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(7, 7)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: _AuthComicDots()),
          const Positioned(left: 16, top: 16, child: _PriceBadge()),
          Positioned(right: 18, top: 16, child: _FloatingStar(size: 22)),
          Positioned(left: 18, bottom: 10, child: _MiniCity(width: 86)),
          Positioned(right: 18, bottom: 10, child: _MiniCity(width: 72)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ComicBookFace(icon: icon),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A),
                    border: Border.all(color: Colors.black, width: 4),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    text.replaceAll('\n', ' '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicBookFace extends StatelessWidget {
  final IconData icon;

  const _ComicBookFace({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 4),
              ),
            ),
          ),
          Positioned(
            top: 2,
            left: 24,
            right: 24,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3B0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_ComicEye(), SizedBox(width: 12), _ComicEye()],
                  ),
                  SizedBox(height: 8),
                  _ComicSmile(),
                ],
              ),
            ),
          ),
          Positioned(left: -6, bottom: 24, child: _ComicGlove()),
          Positioned(right: -6, bottom: 24, child: _ComicGlove()),
          Positioned(
            right: -18,
            top: 22,
            child: Transform.rotate(
              angle: -0.25,
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFFFFD60A),
                shadows: const [
                  Shadow(offset: Offset(2, 2), color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicEye extends StatelessWidget {
  const _ComicEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 14,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ComicSmile extends StatelessWidget {
  const _ComicSmile();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(26, 12), painter: _SmileComicPainter());
  }
}

class _ComicGlove extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD60A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: const Text(
        '10¢',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniCity extends StatelessWidget {
  final double width;

  const _MiniCity({required this.width});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, 32), painter: _MiniCityPainter());
  }
}

class _ComicDividerLabel extends StatelessWidget {
  final String text;
  const _ComicDividerLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.black, thickness: 3)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.black, thickness: 3)),
      ],
    );
  }
}

class _SocialComicButton extends StatelessWidget {
  final String text;
  final String? iconText;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const _SocialComicButton({
    required this.text,
    this.iconText,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkIcon = color.computeLuminance() < 0.45;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: icon != null
                    ? Icon(
                        icon,
                        color: darkIcon ? Colors.white : Colors.black,
                        size: 18,
                      )
                    : Text(
                        iconText ?? '',
                        style: TextStyle(
                          color: darkIcon ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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

class _FloatingStar extends StatelessWidget {
  final double size;
  const _FloatingStar({required this.size});
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star,
      size: size,
      color: Colors.white,
      shadows: const [Shadow(offset: Offset(2, 2), color: Colors.black)],
    );
  }
}

class _ComicCloud extends StatelessWidget {
  final double width;
  const _ComicCloud({required this.width});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.42),
      painter: _CloudPainter(),
    );
  }
}

class _ComicSpeedLines extends StatelessWidget {
  const _ComicSpeedLines();
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AuthComicCard extends StatelessWidget {
  final Widget child;

  const _AuthComicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(6, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _AuthComicInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _AuthComicInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFDF2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 3.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 5),
        ),
      ),
    );
  }
}

class _AuthComicButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool dark;

  const _AuthComicButton({
    required this.text,
    required this.onTap,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthComicDots extends StatelessWidget {
  const _AuthComicDots();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthComicDotsPainter());
  }
}
