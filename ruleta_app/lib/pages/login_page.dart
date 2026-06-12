part of comic_ruleta_app;

// ================== LOGIN PAGE ==================

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginOk;

  const LoginPage({super.key, required this.onLoginOk});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool modoRegistro = false;
  bool cargando = false;
  bool ocultarPassword = true;

  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController(text: '+573001112233');
  final codigoCtrl = TextEditingController();

  String mensaje = '';

  @override
  void dispose() {
    nombreCtrl.dispose();
    correoCtrl.dispose();
    passwordCtrl.dispose();
    telefonoCtrl.dispose();
    codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesar() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      if (modoRegistro) {
        await AuthService.registrar(
          nombreUsuario: nombreCtrl.text.trim(),
          correo: correoCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        );

        setState(() {
          modoRegistro = false;
          mensaje = 'Usuario registrado. Ahora inicia sesión.';
        });
      } else {
        await AuthService.login(
          correo: correoCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        );

        widget.onLoginOk();
      }
    } catch (e) {
      setState(() {
        mensaje = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _loginSocialDemo(String tipo) async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      if (tipo == 'google') {
        await AuthService.loginGoogleDemo();

        if (!mounted) return;

        widget.onLoginOk();
        return;
      }

      if (tipo == 'facebook') {
        setState(() {
          mensaje =
              'Facebook todavía no está conectado. Primero terminaremos Google Login.';
        });
        return;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mensaje = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> _mostrarTelefono() async {
    bool codigoEnviado = false;
    bool verificando = false;

    codigoCtrl.clear();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            Future<void> enviarCodigo() async {
              if (verificando) return;

              setModalState(() => verificando = true);

              try {
                await AuthService.solicitarCodigoTelefono(
                  telefonoCtrl.text.trim(),
                );

                setModalState(() {
                  codigoEnviado = true;
                });
              } catch (e) {
                if (!mounted) return;

                setState(() {
                  mensaje = e.toString().replaceAll('Exception: ', '');
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } finally {
                if (dialogContext.mounted) {
                  setModalState(() => verificando = false);
                }
              }
            }

            Future<void> verificarCodigo() async {
              if (verificando) return;

              setModalState(() => verificando = true);

              try {
                await AuthService.verificarCodigoTelefono(
                  telefono: telefonoCtrl.text.trim(),
                  codigo: codigoCtrl.text.trim(),
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (!mounted) return;
                widget.onLoginOk();
              } catch (e) {
                if (!mounted) return;

                setState(() {
                  mensaje = e.toString().replaceAll('Exception: ', '');
                });
              } finally {
                if (dialogContext.mounted) {
                  setModalState(() => verificando = false);
                }
              }
            }

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
                      text: 'ENTRAR CON\nTELÉFONO',
                      subtitle: 'CÓDIGO DE ACCESO',
                    ),
                    const SizedBox(height: 14),
                    _AuthComicInput(
                      controller: telefonoCtrl,
                      label: 'Teléfono',
                      icon: Icons.phone,
                    ),
                    const SizedBox(height: 12),
                    if (codigoEnviado) ...[
                      _AuthComicInput(
                        controller: codigoCtrl,
                        label: 'Código de verificación',
                        icon: Icons.password,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa el código enviado por SMS o el código de prueba configurado en Firebase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _ComicMainActionButton(
                      text: verificando
                          ? 'PROCESANDO...'
                          : (codigoEnviado
                                ? 'VERIFICAR Y ENTRAR'
                                : 'ENVIAR CÓDIGO'),
                      onTap: verificando
                          ? null
                          : (codigoEnviado ? verificarCodigo : enviarCodigo),
                    ),
                    const SizedBox(height: 10),
                    _ComicButton(
                      text: 'CANCELAR',
                      variant: _ButtonVariant.negro,
                      disabled: verificando,
                      onTap: () {
                        if (!verificando) {
                          Navigator.pop(dialogContext);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFD60A)),
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthComicDots()),
            const Positioned.fill(child: _ComicSpeedLines()),
            Positioned(left: 20, top: 70, child: _FloatingStar(size: 34)),
            Positioned(right: 24, top: 92, child: _FloatingStar(size: 25)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                  child: Column(
                    children: [
                      _ExplosiveTitle(
                        text: modoRegistro
                            ? '¡CREA TU\nPERSONAJE!'
                            : '¡ACCEDE A TU\nUNIVERSO!',
                        subtitle: modoRegistro
                            ? '¡TU HISTORIA COMIENZA AQUÍ!'
                            : 'TUS PERSONAJES TE ESPERAN',
                      ),
                      const SizedBox(height: 18),
                      _PeepClubAssetHero(modoRegistro: modoRegistro),
                      const SizedBox(height: 8),
                      if (modoRegistro) ...[
                        _AuthComicInput(
                          controller: nombreCtrl,
                          label: 'Nombre de usuario',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _AuthComicInput(
                        controller: correoCtrl,
                        label: 'Correo Electrónico',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 10),
                      _AuthComicInput(
                        controller: passwordCtrl,
                        label: 'Contraseña',
                        icon: Icons.lock,
                        obscure: ocultarPassword,
                        suffix: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () => setState(
                            () => ocultarPassword = !ocultarPassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ComicMainActionButton(
                        text: cargando
                            ? 'CARGANDO...'
                            : (modoRegistro ? 'CREAR CUENTA' : 'ENTRAR'),
                        onTap: cargando ? null : _procesar,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: cargando
                            ? null
                            : () => setState(() {
                                modoRegistro = !modoRegistro;
                                mensaje = '';
                              }),
                        child: Text(
                          modoRegistro
                              ? '¿Ya tienes cuenta?  Inicia Sesión'
                              : '¿No tienes cuenta?  Regístrate',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _ComicDividerLabel(text: 'O continúa con'),
                      const SizedBox(height: 10),
                      _SocialComicButton(
                        text: 'Continuar con Google',
                        iconText: 'G',
                        color: Colors.white,
                        onTap: cargando
                            ? null
                            : () => _loginSocialDemo('google'),
                      ),
                      const SizedBox(height: 8),
                      _SocialComicButton(
                        text: 'Continuar con Facebook',
                        iconText: 'f',
                        color: const Color(0xFF1877F2),
                        onTap: cargando
                            ? null
                            : () => _loginSocialDemo('facebook'),
                      ),
                      const SizedBox(height: 8),
                      _SocialComicButton(
                        text: 'Continuar con Teléfono',
                        icon: Icons.phone,
                        color: const Color(0xFF34C759),
                        onTap: cargando ? null : _mostrarTelefono,
                      ),
                      if (mensaje.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MiniStatusComic(texto: mensaje),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeepClubAssetHero extends StatelessWidget {
  final bool modoRegistro;

  const _PeepClubAssetHero({required this.modoRegistro});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = modoRegistro
        ? min(screenHeight * 0.34, 315.0)
        : min(screenHeight * 0.38, 355.0);

    return SizedBox(
      width: double.infinity,
      height: imageHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _HeroGlowPainter()),
            ),
          ),
          Image.asset(
            'assets/images/peep_club.png',
            height: imageHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: imageHeight * 0.82,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.black, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 0,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'No se encontró:\\nassets/images/peep_club.png',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
