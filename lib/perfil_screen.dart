import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String? _fotoBase64;
  bool _cargandoFoto = false;
  String? _avatarAssetPath;

  static const List<String> _imagenesPrecargadas = [
    'assets/images/iconPollo.png',
    'assets/images/iconChoclo.png',
    'assets/images/iconPapa.png',
    'assets/images/iconPalta.png',
    'assets/images/iconChorizo.png',
    'assets/images/iconCuy.png',
    'assets/images/iconGato.png',
    'assets/images/iconPerro.png',
    'assets/images/iconPierna.png',
    'assets/images/iconEnsalada.png',
    'assets/images/iconPaltaPotaxie.png',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Usuario no autenticado';
      });
      return;
    }

    try {
      debugPrint('Cargando datos del usuario con UID: ${user.uid}');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        debugPrint('Datos del usuario encontrados: $userData');
        
        setState(() {
          _userData = userData ?? {};
          _isLoading = false;
          _fotoBase64 = userData?['fotoBase64'] as String?;
          _avatarAssetPath = userData?['avatarAssetPath'] as String?;
        });
      } else {
        debugPrint('No se encontraron datos del usuario en Firestore');
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontraron datos del usuario';
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
    }
  }

  Future<void> _seleccionarImagenPrecargada() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarSnackBar('Usuario no autenticado', Colors.red);
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    const Text(
                      'Elegir avatar de perfil',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _imagenesPrecargadas.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await FirebaseFirestore.instance
                              .collection('Usuarios')
                              .doc(user.uid)
                              .update({
                                'avatarAssetPath': null,
                              });
                          setState(() {
                            _avatarAssetPath = null;
                          });
                              _mostrarSnackBar('Avatar removido', Colors.green);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                              child: const Center(
                                child: Text(
                                  'Sin avatar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        }
                        final asset = _imagenesPrecargadas[index - 1];
                        return InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('Usuarios')
                                  .doc(user.uid)
                                  .update({
                                    'avatarAssetPath': asset,
                                    'fotoBase64': null,
                                  });
                              setState(() {
                                _avatarAssetPath = asset;
                                _fotoBase64 = null;
                              });
                              _mostrarSnackBar('Avatar establecido', Colors.green);
                            } catch (e) {
                              _mostrarSnackBar('Error guardando avatar: $e', Colors.red);
                            }
                          },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 250, 243, 230),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(asset),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seleccionarImagen(bool desdeCamara) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarSnackBar('Usuario no autenticado', Colors.red);
      return;
    }

    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: desdeCamara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
    );
    if (img == null) return;

    setState(() {
      _cargandoFoto = true;
    });

    try {
      final bytes = await File(img.path).readAsBytes();
      final base64String = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .update({'fotoBase64': base64String});

      setState(() {
        _fotoBase64 = base64String;
        _cargandoFoto = false;
      });

      _mostrarSnackBar('Foto actualizada', Colors.green);
    } catch (e) {
      setState(() {
        _cargandoFoto = false;
      });
      _mostrarSnackBar('Error actualizando foto: $e', Colors.red);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    final snackBar = SnackBar(
      content: Text(mensaje),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _editarCampo(String campo, String valorActual, String titulo, TextInputType keyboardType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarSnackBar('Usuario no autenticado', Colors.red);
      return;
    }

    String nuevoValor = valorActual;
    bool isGuardando = false;

    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: valorActual);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Editar $titulo'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: titulo,
                  border: const OutlineInputBorder(),
                  hintText: 'Ingrese $titulo',
                ),
                keyboardType: keyboardType,
                autofocus: true,
                onChanged: (value) {
                  nuevoValor = value;
                },
              ),
              actions: [
                if (!isGuardando)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                ElevatedButton(
                  onPressed: isGuardando
                      ? null
                      : () async {
                          final valor = nuevoValor.trim();
                          
                  if (valor.isEmpty && campo != 'telefono') {
                            _mostrarSnackBar('$titulo es obligatorio', Colors.orange);
                            return;
                          }

                          setDialogState(() {
                            isGuardando = true;
                          });

                          try {
                            final dialogContext = context;
                            await FirebaseFirestore.instance
                                .collection('Usuarios')
                                .doc(user.uid)
                                .update({
                                  campo: valor,
                                });

                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            setState(() {
                              _isLoading = true;
                            });
                            await _cargarDatosUsuario();
                            
                            _mostrarSnackBar('$titulo actualizado exitosamente', Colors.green);
                          } catch (e) {
                            debugPrint('Error actualizando $campo: $e');
                            _mostrarSnackBar('Error al actualizar $titulo: $e', Colors.red);
                            setDialogState(() {
                              isGuardando = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                    foregroundColor: Colors.white,
                  ),
                  child: isGuardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(String titulo, String? valor, IconData icono, String campoFirestore, TextInputType keyboardType, {bool editable = true}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          icono,
          color: const Color.fromARGB(255, 230, 38, 23),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          valor ?? 'No disponible',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: editable 
            ? IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color.fromARGB(255, 230, 38, 23),
                  size: 20,
                ),
                onPressed: () => _editarCampo(
                  campoFirestore, 
                  valor ?? '', 
                  titulo, 
                  keyboardType
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 230, 38, 23),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 230, 38, 23),
                  ),
                  SizedBox(height: 16),
                  Text('Cargando información...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _cargarDatosUsuario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatosUsuario,
                  color: const Color.fromARGB(255, 230, 38, 23),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color.fromARGB(255, 250, 243, 230),
                                    backgroundImage: _fotoBase64 != null
                                        ? MemoryImage(base64Decode(_fotoBase64!))
                                        : (_avatarAssetPath != null
                                            ? AssetImage(_avatarAssetPath!)
                                            : null),
                                    child: _fotoBase64 == null
                                        ? (_avatarAssetPath == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Color.fromARGB(255, 230, 38, 23),
                                              )
                                            : null)
                                        : null,
                                  ),
                                  if (_cargandoFoto)
                                    const Positioned.fill(
                                      child: ColoredBox(
                                        color: Color(0x88000000),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Color.fromARGB(255, 230, 38, 23),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _cargandoFoto ? null : () => _seleccionarImagen(true),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Cámara'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _cargandoFoto ? null : () => _seleccionarImagen(false),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Galería'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _cargandoFoto ? null : _seleccionarImagenPrecargada,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Avatares'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_userData['nombre'] ?? ''} ${_userData['apellidos'] ?? ''}'.trim().isEmpty 
                                    ? 'Usuario' 
                                    : '${_userData['nombre'] ?? ''} ${_userData['apellidos'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? 'No disponible',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 230, 38, 23),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInfoItem(
                          'Nombres',
                          _userData['nombre'],
                          Icons.person_outline,
                          'nombre',
                          TextInputType.text,
                          editable: true,
                        ),
                        
                        _buildInfoItem(
                          'Apellidos',
                          _userData['apellidos'],
                          Icons.person_outline,
                          'apellidos',
                          TextInputType.text,
                          editable: true,
                        ),
                        
                        _buildInfoItem(
                          'Teléfono',
                          _userData['telefono'],
                          Icons.phone,
                          'telefono',
                          TextInputType.phone,
                          editable: true,
                        ),
                        
                        _buildInfoItem(
                          'Correo Electrónico',
                          _userData['email'] ?? FirebaseAuth.instance.currentUser?.email,
                          Icons.email,
                          'email',
                          TextInputType.emailAddress,
                          editable: false,
                        ),
                        
                        _buildInfoItem(
                          'DNI',
                          _userData['dni'],
                          Icons.badge,
                          'dni',
                          TextInputType.text,
                          editable: false,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
