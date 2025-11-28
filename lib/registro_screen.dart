import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistroScreen extends StatefulWidget {
  final VoidCallback onRegistroSuccess;

  const RegistroScreen({super.key, required this.onRegistroSuccess});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _terminosAceptados = false;

  final _nombreFocusNode = FocusNode();
  final _apellidosFocusNode = FocusNode();
  final _dniFocusNode = FocusNode();
  final _telefonoFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final RegExp _dniRegex = RegExp(r'^[0-9]{8}$');
  final RegExp _telefonoRegex = RegExp(r'^[0-9]{9}$');

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    _nombreFocusNode.dispose();
    _apellidosFocusNode.dispose();
    _dniFocusNode.dispose();
    _telefonoFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _verificarDuplicados() async {
    try {
      final dniSnapshot = await FirebaseFirestore.instance
          .collection('Usuarios')
          .where('dni', isEqualTo: _dniController.text.trim())
          .limit(1)
          .get();

      if (dniSnapshot.docs.isNotEmpty) {
        return true;
      }

      final emailSnapshot = await FirebaseFirestore.instance
          .collection('Usuarios')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error verificando duplicados: $e');
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_terminosAceptados) {
      setState(() {
        _errorMessage = 'Debes aceptar los términos y condiciones';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final hayDuplicados = await _verificarDuplicados();
      if (hayDuplicados) {
        setState(() {
          _errorMessage = 'El DNI o email ya están registrados';
          _isLoading = false;
        });
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final hayDuplicadosDespuesDeAuth = await _verificarDuplicados();
      if (hayDuplicadosDespuesDeAuth) {
        await userCredential.user?.delete();
        setState(() {
          _errorMessage = 'El DNI o email ya están registrados';
          _isLoading = false;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(userCredential.user!.uid)
          .set({
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'dni': _dniController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'fechaRegistro': Timestamp.now(),
        'rol': 'cliente',
        'activo': true,
        'verificado': false,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);

      if (mounted) {
        widget.onRegistroSuccess();
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'El email ya está registrado';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email es inválido';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operación no permitida';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  void _moveToNextField(FocusNode nextFocus) {
    FocusScope.of(context).requestFocus(nextFocus);
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _mostrarTerminos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos y Condiciones'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Política de Privacidad y Términos de Uso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildTerminoItem('1. Recopilación de datos: Recopilamos información personal como nombre, DNI, email y teléfono para brindarte nuestros servicios.'),
              _buildTerminoItem('2. Uso de información: Tu información se utiliza para procesar pedidos, mejorar nuestros servicios y comunicarnos contigo.'),
              _buildTerminoItem('3. Protección de datos: Implementamos medidas de seguridad para proteger tu información personal.'),
              _buildTerminoItem('4. Tus derechos: Puedes acceder, rectificar o eliminar tu información personal en cualquier momento.'),
              _buildTerminoItem('5. Al crear una cuenta, aceptas recibir comunicaciones relacionadas con tus pedidos y promociones.'),
              const SizedBox(height: 16),
              const Text(
                'Al aceptar, confirmas que has leído y comprendido estos términos.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: const Color.fromARGB(255, 230, 38, 23),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 250, 243, 230),
              const Color.fromARGB(255, 255, 245, 235),
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        const Text(
                          'Completa tu Registro',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 230, 38, 23),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tus datos para crear tu cuenta',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                            _buildTextField(
                              controller: _nombreController,
                              focusNode: _nombreFocusNode,
                              label: 'Nombres',
                              icon: Icons.person,
                              nextFocus: _apellidosFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tus nombres';
                                }
                                if (value.length < 2) {
                                  return 'El nombre debe tener al menos 2 caracteres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _apellidosController,
                              focusNode: _apellidosFocusNode,
                              label: 'Apellidos',
                              icon: Icons.person_outline,
                              nextFocus: _dniFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tus apellidos';
                                }
                                if (value.length < 2) {
                                  return 'Los apellidos deben tener al menos 2 caracteres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _dniController,
                              focusNode: _dniFocusNode,
                              label: 'DNI',
                              icon: Icons.badge,
                              nextFocus: _telefonoFocusNode,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu DNI';
                                }
                                if (!_dniRegex.hasMatch(value)) {
                                  return 'El DNI debe tener 8 dígitos';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _telefonoController,
                              focusNode: _telefonoFocusNode,
                              label: 'Teléfono',
                              icon: Icons.phone,
                              nextFocus: _emailFocusNode,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu teléfono';
                                }
                                if (!_telefonoRegex.hasMatch(value)) {
                                  return 'El teléfono debe tener 9 dígitos';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              label: 'Correo Electrónico',
                              icon: Icons.email,
                              nextFocus: _passwordFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu email';
                                }
                                if (!_emailRegex.hasMatch(value)) {
                                  return 'Ingresa un email válido';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildPasswordField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              label: 'Contraseña',
                              obscureText: _obscurePassword,
                              onToggleVisibility: _togglePasswordVisibility,
                              nextFocus: _confirmPasswordFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              label: 'Confirmar Contraseña',
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: _toggleConfirmPasswordVisibility,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirma tu contraseña';
                                }
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 250, 250, 252),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _terminosAceptados 
                                      ? const Color.fromARGB(255, 230, 38, 23) 
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _terminosAceptados,
                                      onChanged: (value) {
                                        setState(() {
                                          _terminosAceptados = value ?? false;
                                        });
                                      },
                                      activeColor: const Color.fromARGB(255, 230, 38, 23),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _mostrarTerminos,
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(text: 'Acepto los '),
                                              TextSpan(
                                                text: 'términos y condiciones',
                                                style: TextStyle(
                                                  color: Color.fromARGB(255, 230, 38, 23),
                                                  fontWeight: FontWeight.bold,
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

                            const SizedBox(height: 20),

                            if (_errorMessage.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade600),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 14,
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
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 230, 38, 23),
                                    Color.fromARGB(255, 210, 28, 13),
                                  ],
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
                                    : const Text(
                                        'Crear Cuenta',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color.fromARGB(255, 250, 250, 252),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 230, 38, 23)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        keyboardType: keyboardType,
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        maxLines: maxLines,
        onFieldSubmitted: nextFocus != null ? (_) => _moveToNextField(nextFocus) : null,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color.fromARGB(255, 250, 250, 252),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.lock, color: const Color.fromARGB(255, 230, 38, 23)),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade500,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: nextFocus != null ? (_) => _moveToNextField(nextFocus) : null,
        validator: validator,
      ),
    );
  }
}
