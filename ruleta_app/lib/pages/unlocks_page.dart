part of comic_ruleta_app;

// ================== UNLOCKS PAGE - PLACEHOLDER ==================
// Pantalla visual inicial. La lógica real se conecta en un commit posterior.

class UnlocksPage extends StatelessWidget {
  const UnlocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFD60A),
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
                        _UnlocksStepIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: _ExplosiveTitle(
                            text: 'DESBLOQUEOS',
                            subtitle: 'AVATARES Y PUNTEROS',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _UnlocksStepCard(
                      title: 'AVATARES',
                      children: const [
                        _UnlocksStepItem(text: 'Maga - disponible'),
                        _UnlocksStepItem(text: 'Payaso - disponible'),
                        _UnlocksStepItem(text: 'Sayajin - nivel 5'),
                        _UnlocksStepItem(text: 'Dragón - nivel 10'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _UnlocksStepCard(
                      title: 'PUNTEROS',
                      children: const [
                        _UnlocksStepItem(text: 'Clásico - disponible'),
                        _UnlocksStepItem(text: 'Radar - nivel 5'),
                        _UnlocksStepItem(text: 'Murciélago - nivel 10'),
                        _UnlocksStepItem(text: 'Rayo - nivel 15'),
                        _UnlocksStepItem(text: 'Espada - nivel 20'),
                      ],
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

class _UnlocksStepIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _UnlocksStepIconButton({required this.icon, required this.onTap});

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

class _UnlocksStepCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _UnlocksStepCard({required this.title, required this.children});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _UnlocksStepItem extends StatelessWidget {
  final String text;

  const _UnlocksStepItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD60A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
