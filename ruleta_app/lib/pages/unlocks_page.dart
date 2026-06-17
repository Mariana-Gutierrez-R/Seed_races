part of comic_ruleta_app;

// ================== UNLOCKS PAGE ==================
// Placeholder mínimo para que el archivo exista.
// La funcionalidad real de desbloqueos va en otro commit.

class UnlocksPage extends StatelessWidget {
  const UnlocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFD60A),
      body: Center(
        child: Text(
          'DESBLOQUEOS\nPRÓXIMAMENTE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
