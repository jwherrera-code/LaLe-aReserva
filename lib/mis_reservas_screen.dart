import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'reserva_service.dart';
import 'reserva_model.dart';

class MisReservasScreen extends StatefulWidget {
  final String usuarioId;

  const MisReservasScreen({super.key, required this.usuarioId});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final ReservaService _reservaService = ReservaService();

  void _mostrarSnackBar(String mensaje, Color color) {
    final snackBar = SnackBar(content: Text(mensaje), backgroundColor: color, duration: const Duration(seconds: 3));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _confirmarCancelacion(Reserva reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('¿Deseas cancelar esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reservaService.cancelarReserva(reserva.id!);
                try {
                  final pedidos = await FirebaseFirestore.instance
                      .collection('Pedidos')
                      .where('reserva_id', isEqualTo: reserva.id)
                      .get();
                  for (final d in pedidos.docs) {
                    await d.reference.update({'estado': 'cancelado', 'cancelable': false});
                  }
                } catch (_) {}
                _mostrarSnackBar('Reserva cancelada', Colors.green);
              } catch (e) {
                _mostrarSnackBar('Error al cancelar: $e', Colors.red);
              }
            },
            child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<List<Reserva>>(
        stream: _reservaService.obtenerReservasUsuario(widget.usuarioId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error cargando reservas'));
          }

          final reservas = (snapshot.data ?? [])
            ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

          if (reservas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No tienes reservas registradas'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = reservas[index];
              final fecha = '${r.fechaHora.day}/${r.fechaHora.month}/${r.fechaHora.year}';
              final hora = '${r.fechaHora.hour.toString().padLeft(2, '0')}:${r.fechaHora.minute.toString().padLeft(2, '0')}';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.table_restaurant, color: Colors.deepOrange),
                  title: Text('Mesa ${r.mesaNombre} • $fecha $hora'),
                  subtitle: Text('${r.cantidadPersonas} personas • ${r.nombreCliente}'),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmarCancelacion(r),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
