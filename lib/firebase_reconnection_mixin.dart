import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

mixin FirebaseReconnectionMixin<T extends StatefulWidget> on State<T> {
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;

  Future<bool> ensureFirebaseConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        try {
          await user.reload();
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
          debugPrint('✅ Usuario reconectado: ${user.uid}');
        } catch (authError) {
          debugPrint('⚠️ Error refrescando autenticación: $authError');
          debugPrint('🔓 Continuando como usuario invitado');
        }
      } else {
        debugPrint('🔓 Modo invitado - sin autenticación');
      }
      
      
      await FirebaseFirestore.instance
          .collection('Menu')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
          
      _reconnectAttempts = 0;
      debugPrint('✅ Conexión a Firestore verificada correctamente');
      return true;
      
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('❌ ERROR DE PERMISOS: No tienes acceso a Firestore');
        debugPrint('🔧 Posible solución: Verificar reglas de seguridad en Firebase Console');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error de permisos. Verificando conexión...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        return await _reintentarConexion();
      } else {
        debugPrint('❌ Error de Firebase: ${e.code} - ${e.message}');
        return await _reintentarConexion();
      }
    } catch (e) {
      debugPrint('❌ Error general en ensureFirebaseConnection: $e');
      return await _reintentarConexion();
    }
  }

  Future<bool> _reintentarConexion() async {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint('🔄 Reintento $_reconnectAttempts de $_maxReconnectAttempts');
      
      await Future.delayed(Duration(seconds: _reconnectAttempts * 2));
      
      try {
        await Firebase.initializeApp();
        debugPrint('✅ Firebase reinicializado en reintento $_reconnectAttempts');
        return true;
      } catch (reconnectError) {
        debugPrint('❌ Error en reintento $_reconnectAttempts: $reconnectError');
        return await ensureFirebaseConnection();
      }
    } else {
      debugPrint('🚫 Máximo de reintentos alcanzado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión persistente. Reinicia la aplicación.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
  }
}
