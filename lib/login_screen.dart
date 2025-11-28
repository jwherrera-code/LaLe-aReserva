import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/logo_widget.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;
  String _errorMessage = '';
  bool _isDisposed = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      final savedEmail = prefs.getString(_savedEmailKey) ?? '';
      final savedPassword = prefs.getString(_savedPasswordKey) ?? '';

      if (mounted && !_isDisposed) {
        setState(() {
          _rememberMe = rememberMe;
          if (_rememberMe && savedEmail.isNotEmpty) {
            _emailController.text = savedEmail;
          }
          if (_rememberMe && savedPassword.isNotEmpty) {
            _passwordController.text = savedPassword;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_savedEmailKey, _emailController.text.trim());
        await prefs.setString(_savedPasswordKey, _passwordController.text.trim());
      } else {
        await prefs.setBool(_rememberMeKey, false);
        await prefs.remove(_savedEmailKey);
        await prefs.remove(_savedPasswordKey);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (_rememberMe) {
          await _saveCredentials();
        } else {
          await _clearSavedCredentials();
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          _safeSetState(() {
            _errorMessage = 'Las contraseñas no coinciden';
            _isLoading = false;
          });
          return;
        }

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (_rememberMe) {
          await _saveCredentials();
        }
      }

      if (mounted && !_isDisposed) {
        _safeSetState(() {
          _isLoading = false;
        });
        widget.onLoginSuccess();
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este email';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email es inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operación no permitida';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          errorMessage = 'Ocurrió un error de autenticación. Verifica tus datos e intenta nuevamente.';
      }
      _safeSetState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  void _safeSetState(VoidCallback callback) {
    if (mounted && !_isDisposed) {
      setState(callback);
    }
  }

  void _toggleMode() {
    _safeSetState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
      _confirmPasswordController.clear();
    });
    _formKey.currentState?.reset();
  }

  void _navigateToRegistroScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroScreen(
          onRegistroSuccess: widget.onLoginSuccess,
        ),
      ),
    );
  }

  void _togglePasswordVisibility() {
    _safeSetState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    _safeSetState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _onRememberMeChanged(bool? value) {
    _safeSetState(() {
      _rememberMe = value ?? false;
    });
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu email para recibir un enlace de recuperación:'),
            const SizedBox(height: 16),
            TextFormField(
              autofocus: true,
              controller: TextEditingController(text: _emailController.text),
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              if (email.isEmpty || !email.contains('@')) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un email válido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Enlace de recuperación enviado a $email'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error al enviar enlace: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _moveToNextField(FocusNode nextFocus) {
    FocusScope.of(context).requestFocus(nextFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 250, 243, 230),
              const Color.fromARGB(255, 255, 245, 235),
              const Color.fromARGB(255, 255, 247, 240),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 230, 38, 23).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: LogoWidget(
                          size: 100,
                          color: Color.fromARGB(255, 230, 38, 23),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 230, 38, 23),
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    Text(
                      _isLogin 
                          ? 'Bienvenido de vuelta' 
                          : 'Crea tu nueva cuenta',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_rounded,
                                      color: const Color.fromARGB(255, 230, 38, 23),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(255, 250, 250, 252),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 230, 38, 23),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    _moveToNextField(_passwordFocusNode);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Ingresa un email válido';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      color: const Color.fromARGB(255, 230, 38, 23),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                            ? Icons.visibility_off_rounded 
                                            : Icons.visibility_rounded,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(255, 250, 250, 252),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 230, 38, 23),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    if (_isLogin) {
                                      _submit();
                                    } else {
                                      _moveToNextField(_confirmPasswordFocusNode);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu contraseña';
                                    }
                                    if (value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              if (!_isLogin)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmPasswordFocusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Confirmar Contraseña',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: const Color.fromARGB(255, 230, 38, 23),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword 
                                              ? Icons.visibility_off_rounded 
                                              : Icons.visibility_rounded,
                                          color: Colors.grey.shade500,
                                        ),
                                        onPressed: _toggleConfirmPasswordVisibility,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 250, 250, 252),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(255, 230, 38, 23),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      _submit();
                                    },
                                    validator: !_isLogin
                                        ? (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor confirma tu contraseña';
                                            }
                                            if (value != _passwordController.text) {
                                              return 'Las contraseñas no coinciden';
                                            }
                                            return null;
                                          }
                                        : null,
                                  ),
                                ),

                              if (!_isLogin) const SizedBox(height: 20),

                              if (_isLogin)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 250, 250, 252),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: _onRememberMeChanged,
                                              activeColor: const Color.fromARGB(255, 230, 38, 23),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Recordarme',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          color: const Color.fromARGB(255, 230, 38, 23),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 24),

                              if (_errorMessage.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(255, 230, 38, 23),
                                      const Color.fromARGB(255, 210, 28, 13),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(255, 230, 38, 23).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 250, 250, 252),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLogin
                                          ? '¿No tienes cuenta?'
                                          : '¿Ya tienes cuenta?',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _isLoading ? null : 
                                        _isLogin ? _navigateToRegistroScreen : _toggleMode,
                                      child: Text(
                                        _isLogin ? 'Regístrate' : 'Inicia Sesión',
                                        style: const TextStyle(
                                          color: Color.fromARGB(255, 230, 38, 23),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
