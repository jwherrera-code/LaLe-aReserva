import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seleccion_mesa_screen.dart';

class PagoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final double total;
  final Function(Map<String, dynamic>) onRealizarPedido;
  final VoidCallback onPagoCompletado;

  const PagoScreen({
    super.key,
    required this.carrito,
    required this.total,
    required this.onRealizarPedido,
    required this.onPagoCompletado,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  String _metodoPago = 'efectivo';
  String _tipoPedido = 'recojo';
  bool _procesandoPago = false;
  bool _pedidoConfirmado = false;
  Map<String, dynamic> _datosYape = {};
  bool _cargandoDatos = true;
  String? _reservaId;

  final List<Map<String, dynamic>> _metodosPago = [
    {'id': 'efectivo', 'nombre': 'Efectivo', 'icono': Icons.money},
    {'id': 'yape', 'nombre': 'Yape', 'icono': Icons.phone_android},
    {'id': 'plin', 'nombre': 'Plin', 'icono': Icons.phone_iphone},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosYape();
  }

  Future<void> _cargarDatosYape() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ConfiguracionPagos')
          .doc('yape')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        if (mounted) {
          setState(() {
            _datosYape = snapshot.data()!;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _datosYape = {
              'numero': '92461149',
              'qrUrl': '',
              'nombre': 'Tu Nombre',
              'activo': true,
            };
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos Yape: $e');
      if (mounted) {
        setState(() {
          _datosYape = {
            'numero': '92461149',
            'qrUrl': '',
            'nombre': 'Tu Nombre',
            'activo': true,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
        });
      }
    }
  }

  Future<void> _procesarPago() async {
    if (_procesandoPago || _pedidoConfirmado) return;

    if (mounted) {
      setState(() {
        _procesandoPago = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _mostrarSnackBar('Usuario no autenticado', Colors.red);
        return;
      }

      if (_tipoPedido == 'reserva' && _reservaId == null) {
        _mostrarSnackBar('Selecciona mesa y hora antes de pagar', Colors.orange);
        setState(() {
          _procesandoPago = false;
        });
        return;
      }

      final pedidoData = {
        'productos': widget.carrito,
        'total': widget.total,
        'estado': 'pendiente',
        'metodoPago': _metodoPago,
        'tipo': _tipoPedido,
        'fecha': Timestamp.now(),
        'cancelable': true,
        'userId': user.uid,
        'userEmail': user.email,
        if (_reservaId != null) 'reserva_id': _reservaId,
      };

      debugPrint('Iniciando proceso de pedido...');

      await widget.onRealizarPedido(pedidoData);

      debugPrint('Pedido guardado exitosamente');

      if (mounted) {
        setState(() {
          _pedidoConfirmado = true;
          _procesandoPago = false;
        });
      }

      if (!mounted) return;
      _mostrarSnackBar('¡Pedido realizado exitosamente!', Colors.green);

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      widget.onPagoCompletado();
    } catch (e) {
      debugPrint('Error en _procesarPago: $e');
      if (mounted) {
        _mostrarSnackBar('Error al procesar el pago: $e', Colors.red);
        setState(() {
          _procesandoPago = false;
        });
      }
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

  Widget _buildVistaYape() {
    if (_cargandoDatos) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Paga con Yape',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: (_datosYape['qrUrl'] as String?)?.isNotEmpty == true
                ? Image.network(_datosYape['qrUrl'] as String, height: 200)
                : Image.asset('assets/images/qr.png', height: 200),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  _datosYape['numero'] ?? '92461149',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    _mostrarSnackBar('Número copiado', Colors.green);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrucciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('1. Copia el número o escanea el QR'),
                Text('2. Realiza el pago por Yape'),
                Text('3. Confirma el pago en la app'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaPlin() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Paga con Plin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '92461149',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    _mostrarSnackBar('Número copiado', Colors.green);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrucciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('1. Copia el número de teléfono'),
                Text('2. Realiza el pago por Plin'),
                Text('3. Confirma el pago en la app'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaEfectivo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Paga en Efectivo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.point_of_sale, size: 50, color: Colors.orange),
                SizedBox(height: 8),
                Text(
                  'Paga cuando recibas tu pedido',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'El repartidor llevará el vuelto necesario',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método de Pago'),
        backgroundColor: const Color.fromARGB(255, 230, 38, 23),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.carrito.map(
                      (producto) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${producto['nombre']} x${producto['cantidad']}',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'S/${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'S/${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 230, 38, 23),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Selecciona tipo de pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Reserva'),
                          subtitle: const Text('Hacer reserva antes del pago'),
                          trailing: Icon(
                            _tipoPedido == 'reserva'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          onTap: () {
                            setState(() {
                              _tipoPedido = 'reserva';
                            });
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag),
                          title: const Text('Recojo'),
                          subtitle: const Text('Recoger pedido sin reserva'),
                          trailing: Icon(
                            _tipoPedido == 'recojo'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          onTap: () {
                            setState(() {
                              _tipoPedido = 'recojo';
                            });
                          },
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Selecciona método de pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_tipoPedido == 'reserva')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.table_restaurant),
                            title: Text(_reservaId == null
                                ? 'Selecciona mesa y hora'
                                : 'Reserva seleccionada'),
                            subtitle: _reservaId == null
                                ? const Text('Necesario antes de pagar')
                                : Text('ID: $_reservaId'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                _mostrarSnackBar('Inicia sesión para reservar', Colors.red);
                                return;
                              }
                              final id = await Navigator.push<String?>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeleccionMesaScreen(
                                    usuarioId: user.uid,
                                    returnToCaller: true,
                                  ),
                                ),
                              );
                              if (mounted) {
                                setState(() {
                                  _reservaId = id;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ..._metodosPago.map(
                      (metodo) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Card(
                          child: ListTile(
                            leading: Icon(metodo['icono'] as IconData),
                            title: Text(metodo['nombre'] as String),
                            trailing: Icon(
                              _metodoPago == (metodo['id'] as String)
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            onTap: () {
                              setState(() {
                                _metodoPago = metodo['id'] as String;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_metodoPago == 'yape') _buildVistaYape(),
                    if (_metodoPago == 'plin') _buildVistaPlin(),
                    if (_metodoPago == 'efectivo') _buildVistaEfectivo(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: (_procesandoPago || _pedidoConfirmado)
                ? null
                : _procesarPago,
            style: ElevatedButton.styleFrom(
              backgroundColor: _pedidoConfirmado
                  ? Colors.grey
                  : (_procesandoPago
                        ? Colors.grey
                        : Theme.of(context).primaryColor),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _procesandoPago
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _pedidoConfirmado
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text('Pedido Confirmado'),
                    ],
                  )
                : const Text('Confirmar Pedido'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
