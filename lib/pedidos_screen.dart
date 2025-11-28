import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarPedidos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Pedidos')
          .where('userId', isEqualTo: user.uid)
          .get();

      final pedidosList = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      pedidosList.sort((a, b) {
        final fechaA = a['fecha'] as Timestamp?;
        final fechaB = b['fecha'] as Timestamp?;
        if (fechaA == null || fechaB == null) return 0;
        return fechaB.compareTo(fechaA);
      });

      if (!mounted) return;
      setState(() {
        _pedidos = pedidosList;
        _isLoading = false;
      });
    } catch (e) {
      _mostrarSnackBar('Error al cargar pedidos: $e', Colors.red);
      if (mounted) {
        setState(() {
          _isLoading = false;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _cancelarPedido(String pedidoId) async {
    try {
      final ref = FirebaseFirestore.instance.collection('Pedidos').doc(pedidoId);
      final doc = await ref.get();
      await ref.update({'estado': 'cancelado', 'cancelable': false});

      final data = doc.data();
      final reservaId = data != null ? data['reserva_id'] as String? : null;
      if (reservaId != null && reservaId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('Reservas').doc(reservaId).delete();
        } catch (_) {}
      }

      _mostrarSnackBar('Pedido cancelado exitosamente', Colors.green);
      if (mounted) {
        _cargarPedidos();
      }
    } catch (e) {
      _mostrarSnackBar('Error al cancelar pedido: $e', Colors.red);
    }
  }

  void _mostrarDialogoCancelacion(String pedidoId, String estado) {
    if (estado != 'pendiente') {
      _mostrarSnackBar('No se puede cancelar un pedido $estado', Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: const Text(
            '¿Estás seguro de que quieres cancelar este pedido?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelarPedido(pedidoId);
              },
              child: const Text(
                'Sí, cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _filtrarPedidosEstados(Set<String> estados) {
    return _pedidos
        .where((pedido) => estados.contains(pedido['estado']))
        .toList();
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFE62617);
      case 'entregado':
        return Colors.blueGrey;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(Timestamp fecha) {
    final date = fecha.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFAE8C9),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFFAE8C9),
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Entregados'),
            Tab(text: 'Cancelados'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaPedidos(_filtrarPedidosEstados({'pendiente'}), true),
                _buildListaPedidos(_filtrarPedidosEstados({'entregado'}), false),
                _buildListaPedidos(_filtrarPedidosEstados({'cancelado'}), false),
              ],
            ),
    );
  }

  Widget _buildListaPedidos(
    List<Map<String, dynamic>> pedidos,
    bool mostrarBotonCancelar,
  ) {
    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
          final productos = List<Map<String, dynamic>>.from(
            pedido['productos'] ?? [],
          );
          final total = pedido['total'] ?? 0.0;
          final fecha = pedido['fecha'] as Timestamp?;
          final estado = pedido['estado'] ?? 'pendiente';
          final metodoPago = pedido['metodoPago'] ?? 'efectivo';
          final tipoPedido = pedido['tipo'] ?? 'recojo';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fecha != null
                            ? _formatearFecha(fecha)
                            : 'Fecha no disponible',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getColorEstado(estado).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getColorEstado(estado)),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            color: _getColorEstado(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Tipo: ${tipoPedido.toUpperCase()} • Método: ${metodoPago.toUpperCase()}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  ...productos
                      .take(3)
                      .map(
                        (producto) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${producto['nombre']} x${producto['cantidad']}',
                              ),
                              Text(
                                'S/${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      ),

                  if (productos.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${productos.length - 3} productos más...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: S/${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 230, 38, 23),
                        ),
                      ),
                      if (mostrarBotonCancelar &&
                          (pedido['cancelable'] ?? true))
                        ElevatedButton(
                          onPressed: () =>
                              _mostrarDialogoCancelacion(pedido['id'], estado),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color.fromARGB(
                              255,
                              230,
                              38,
                              23,
                            ),
                            side: const BorderSide(
                              color: Color.fromARGB(255, 230, 38, 23),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Cancelar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
