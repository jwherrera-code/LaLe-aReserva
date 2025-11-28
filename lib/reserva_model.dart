import 'package:cloud_firestore/cloud_firestore.dart';

class Mesa {
  String id;
  String nombre;
  int capacidad;
  String? imagenUrl;
  
  Mesa({
    required this.id,
    required this.nombre,
    required this.capacidad,
    this.imagenUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'capacidad': capacidad,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
    };
  }

  factory Mesa.fromMap(String id, Map<String, dynamic> map) {
    return Mesa(
      id: id,
      nombre: map['nombre'] ?? '',
      capacidad: (map['capacidad'] as num?)?.toInt() ?? 4,
      imagenUrl: map['imagen_url'],
    );
  }
}

class Reserva {
  String? id;
  String mesaId;
  String mesaNombre;
  String usuarioId;
  String nombreCliente;
  String telefonoCliente;
  String emailCliente;
  DateTime fechaHora;
  int cantidadPersonas;
  
  Reserva({
    this.id,
    required this.mesaId,
    required this.mesaNombre,
    required this.usuarioId,
    required this.nombreCliente,
    required this.telefonoCliente,
    required this.emailCliente,
    required this.fechaHora,
    required this.cantidadPersonas,
  });

  Map<String, dynamic> toMap() {
    return {
      'mesa_id': mesaId,
      'mesa_nombre': mesaNombre,
      'usuario_id': usuarioId,
      'nombre_cliente': nombreCliente,
      'telefono_cliente': telefonoCliente,
      'email_cliente': emailCliente,
      'fecha_hora': Timestamp.fromDate(fechaHora),
      'cantidad_personas': cantidadPersonas,
    };
  }

  factory Reserva.fromMap(String id, Map<String, dynamic> map) {
    return Reserva(
      id: id,
      mesaId: map['mesa_id'] ?? '',
      mesaNombre: map['mesa_nombre'] ?? '',
      usuarioId: map['usuario_id'] ?? '',
      nombreCliente: map['nombre_cliente'] ?? '',
      telefonoCliente: map['telefono_cliente'] ?? '',
      emailCliente: map['email_cliente'] ?? '',
      fechaHora: (map['fecha_hora'] as Timestamp).toDate(),
      cantidadPersonas: (map['cantidad_personas'] as num).toInt(),
    );
  }
}

class Usuario {
  String id;
  String nombre;
  String apellidos;
  String telefono;
  String email;
  String dni;
  String rol;
  bool activo;
  bool verificado;
  DateTime fechaRegistro;
  
  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.dni,
    required this.rol,
    required this.activo,
    required this.verificado,
    required this.fechaRegistro,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory Usuario.fromMap(String id, Map<String, dynamic> map) {
    return Usuario(
      id: id,
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      dni: map['dni'] ?? '',
      rol: map['rol'] ?? 'cliente',
      activo: map['activo'] ?? true,
      verificado: map['verificado'] ?? false,
      fechaRegistro: (map['fechaRegistro'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'dni': dni,
      'rol': rol,
      'activo': activo,
      'verificado': verificado,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
    };
  }
}
