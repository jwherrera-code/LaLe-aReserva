import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'reserva_model.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Mesa>> obtenerTodasLasMesas() {
    return _firestore.collection('Mesas').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Mesa.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<Usuario?> obtenerUsuario(String usuarioId) async {
    try {
      final doc = await _firestore.collection('Usuarios').doc(usuarioId).get();
      if (doc.exists) {
        return Usuario.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo usuario: $e');
      return null;
    }
  }

  Future<bool> verificarDisponibilidad(
    String mesaId,
    DateTime fechaHora,
  ) async {
    try {
      final inicioHora = DateTime(
        fechaHora.year,
        fechaHora.month,
        fechaHora.day,
        fechaHora.hour,
      );
      final finHora = DateTime(
        fechaHora.year,
        fechaHora.month,
        fechaHora.day,
        fechaHora.hour,
        59,
        59,
      );

      debugPrint('Verificando disponibilidad mesaId=$mesaId entre $inicioHora y $finHora');

      final snapshot = await _firestore
          .collection('Reservas')
          .where('mesa_id', isEqualTo: mesaId)
          .get();

      final reservasEnHora = snapshot.docs.where((d) {
        final ts = d.data()['fecha_hora'] as Timestamp?;
        if (ts == null) return false;
        final dt = ts.toDate();
        return dt.isAfter(inicioHora.subtract(const Duration(milliseconds: 1))) &&
        dt.isBefore(finHora.add(const Duration(milliseconds: 1)));
      }).toList();

      debugPrint('Reservas coincidentes en la hora: ${reservasEnHora.length}');

      return reservasEnHora.isEmpty;
    } catch (e) {
      debugPrint('Error verificando disponibilidad: $e');
      rethrow;
    }
  }

  Future<String> crearReserva(Reserva reserva) async {
    try {
      final ref = await _firestore.collection('Reservas').add(reserva.toMap());
      return ref.id;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  Future<List<Reserva>> obtenerReservasFuturasMesa(String mesaId) async {
    try {
      final ahora = DateTime.now();
      final snapshot = await _firestore
          .collection('Reservas')
          .where('mesa_id', isEqualTo: mesaId)
          .get();

      final list = snapshot.docs
          .map((doc) => Reserva.fromMap(doc.id, doc.data()))
          .where((r) => r.fechaHora.isAfter(ahora))
          .toList();

      return list;
    } catch (e) {
      return [];
    }
  }

  Stream<List<Reserva>> obtenerReservasUsuario(String usuarioId) {
    return _firestore
        .collection('Reservas')
        .where('usuario_id', isEqualTo: usuarioId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Reserva.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
          return list;
        });
  }

  Future<void> cancelarReserva(String reservaId) async {
    try {
      await _firestore.collection('Reservas').doc(reservaId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
