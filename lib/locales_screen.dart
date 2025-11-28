import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/logo_widget.dart';
import 'firebase_reconnection_mixin.dart';

class LocalesScreen extends StatefulWidget {
  const LocalesScreen({super.key});

  @override
  State<LocalesScreen> createState() => _LocalesScreenState();
}

class _LocalesScreenState extends State<LocalesScreen> with FirebaseReconnectionMixin{
  List<Map<String, dynamic>> _locales = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _obtenerLocales();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback callback) {
    if (!_isDisposed && mounted) {
      setState(callback);
    }
  }

  Future<void> _obtenerLocales() async {
    final connected = await ensureFirebaseConnection();
    if (!connected) {
      _safeSetState(() {
        _isLoading = false;
      });
      return;
    }
  
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Locales')
          .orderBy('nombre')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (_isDisposed) return;
  
      final localesList = snapshot.docs.map((doc) {
        final data = doc.data();
        final ubicacion = data['ubicacion'] ?? data['Ubicacion'];
        
        return {
          'id': doc.id,
          'nombre': data['nombre'],
          'direccion': data['direccion'],
          'telefono': data['telefono'],
          'horario': data['horario'],
          'ubicacion': ubicacion,
        };
      }).toList();
  
      _safeSetState(() {
        _locales = localesList;
        _isLoading = false;
      });
  
    } on FirebaseException catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de Firebase: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timeout de conexión: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar locales: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDetallesLocal(Map<String, dynamic> local) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetallesLocalSheet(local: local),
    );
  }

  Future<void> _abrirWhatsApp() async {
    try {
      const url = 'https://wa.me/51924611149';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _mostrarMensaje('WhatsApp no está disponible');
      }
    } catch (e) {
      _mostrarMensaje('Error al abrir WhatsApp: $e');
    }
  }

  Future<void> _realizarLlamada() async {
    try {
      const url = 'tel:924611149';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _mostrarNumeroParaCopiar();
      }
    } catch (e) {
      _mostrarNumeroParaCopiar();
    }
  }

  void _mostrarNumeroParaCopiar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Número de Teléfono'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudo abrir la aplicación de teléfono.'),
            const SizedBox(height: 10),
            const Text('Número:'),
            const SizedBox(height: 5),
            SelectableText(
              '924 611 149',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Copia el número y realiza la llamada manualmente.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              _copiarAlPortapapeles('924611149');
              Navigator.pop(context);
              _mostrarMensaje('Número copiado al portapapeles');
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  void _copiarAlPortapapeles(String texto) {
    debugPrint('Número para copiar: $texto');
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<Position?> _obtenerUbicacionUsuario() async {
    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        _mostrarMensaje('Activa el servicio de ubicación');
        return null;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          _mostrarMensaje('Permiso de ubicación denegado');
          return null;
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        _mostrarMensaje('Permiso de ubicación denegado permanentemente');
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      _mostrarMensaje('Error obteniendo ubicación: $e');
      return null;
    }
  }

  void _abrirEnMapas(double lat, double lng, String nombre) async {
    try {
      final posicion = await _obtenerUbicacionUsuario();
      final destino = '$lat,$lng';
      final url = posicion != null
          ? 'https://www.google.com/maps/dir/?api=1&origin=${posicion.latitude},${posicion.longitude}&destination=$destino&travelmode=driving'
          : 'https://www.google.com/maps/search/?api=1&query=$destino';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _mostrarMensaje('No se pudo abrir el mapa');
      }
    } catch (e) {
      _mostrarMensaje('Error al abrir mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Nuestros Locales',
        showLogo: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogoWidget(size: 80),
                  SizedBox(height: 16),
                  Text('Cargando locales...'),
                ],
              ),
            )
          : _locales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoWidget(size: 100),
                      const SizedBox(height: 16),
                      const Text(
                        'No se encontraron locales',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _locales.length,
                        itemBuilder: (context, index) {
                          final local = _locales[index];
                          return _LocalCard(
                            local: local,
                            onTap: () => _mostrarDetallesLocal(local),
                            onWhatsAppTap: _abrirWhatsApp,
                            onCallTap: _realizarLlamada,
                            onMapTap: () {
                              final geoPoint = local['ubicacion'] as GeoPoint?;
                              if (geoPoint != null) {
                                _abrirEnMapas(
                                  geoPoint.latitude,
                                  geoPoint.longitude,
                                  local['nombre'],
                                );
                              } else {
                                _mostrarMensaje('Ubicación no disponible');
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _LocalCard extends StatelessWidget {
  final Map<String, dynamic> local;
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onCallTap;
  final VoidCallback onMapTap;

  const _LocalCard({
    required this.local,
    required this.onTap,
    required this.onWhatsAppTap,
    required this.onCallTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = local['nombre'] ?? 'Sin nombre';
    final direccion = local['direccion'] ?? 'Sin dirección';
    final horario = local['horario'] ?? 'Horario no disponible';
    final hasLocation = local['ubicacion'] != null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 230, 38, 23),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasLocation)
                    Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 20,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      direccion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      horario,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMapTap,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Ver en mapa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 230, 38, 23),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 230, 38, 23),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onWhatsAppTap,
                    icon: Image.asset(
                      'assets/images/whatsapp.png',
                      width: 24,
                      height: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    tooltip: 'Contactar por WhatsApp',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onCallTap,
                    icon: const Icon(Icons.phone, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Llamar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetallesLocalSheet extends StatelessWidget {
  final Map<String, dynamic> local;

  const _DetallesLocalSheet({
    required this.local,
  });

  Future<void> _abrirWhatsApp() async {
    try {
      const url = 'https://wa.me/51924611149';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      debugPrint('Error WhatsApp: $e');
    }
  }

  Future<void> _realizarLlamada(BuildContext context) async {
    try {
      const url = 'tel:924611149';
      final ctx = context;
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (!ctx.mounted) return;
        _mostrarDialogoNumero(ctx);
      }
    } catch (e) {
      if (!context.mounted) return;
      _mostrarDialogoNumero(context);
    }
  }

  void _mostrarDialogoNumero(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Número de Contacto'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Número:'),
            SizedBox(height: 10),
            SelectableText(
              '924 611 149',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEnMapas() async {
    final geoPoint = local['ubicacion'] as GeoPoint?;
    if (geoPoint == null) return;

    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${geoPoint.latitude},${geoPoint.longitude}'));
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.deniedForever || permiso == LocationPermission.denied) {
        await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${geoPoint.latitude},${geoPoint.longitude}'));
      }

      final posicion = await Geolocator.getCurrentPosition();
      final url = 'https://www.google.com/maps/dir/?api=1&origin=${posicion.latitude},${posicion.longitude}&destination=${geoPoint.latitude},${geoPoint.longitude}&travelmode=driving';
      await launchUrl(Uri.parse(url));
    } catch (_) {
      await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${geoPoint.latitude},${geoPoint.longitude}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = local['nombre'] ?? 'Sin nombre';
    final direccion = local['direccion'] ?? 'Sin dirección';
    final horario = local['horario'] ?? 'Horario no disponible';
    final geoPoint = local['ubicacion'] as GeoPoint?;
    final hasLocation = geoPoint != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 230, 38, 23),
            ),
          ),
          
          const SizedBox(height: 20),
          
          _DetailItem(
            icon: Icons.location_on,
            title: 'Dirección:',
            value: direccion,
          ),
          
          _DetailItem(
            icon: Icons.access_time,
            title: 'Horario:',
            value: horario,
          ),

          if (hasLocation)
            _DetailItem(
              icon: Icons.gps_fixed,
              title: 'Coordenadas:',
              value: '${geoPoint.latitude.toStringAsFixed(4)}, ${geoPoint.longitude.toStringAsFixed(4)}',
            ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              if (hasLocation) 
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _abrirEnMapas,
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir en Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (hasLocation) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _abrirWhatsApp,
                  icon: Image.asset(
                    'assets/images/whatsapp.png',
                    width: 24,
                    height: 24,
                  ),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _realizarLlamada(context),
                  icon: const Icon(Icons.phone),
                  label: const Text('Llamar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color.fromARGB(255, 230, 38, 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
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
