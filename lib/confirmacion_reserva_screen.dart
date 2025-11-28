import 'package:flutter/material.dart';
import 'reserva_model.dart';
import 'reserva_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class ConfirmacionReservaScreen extends StatefulWidget {
  final Mesa mesa;
  final int numeroPersonas;
  final DateTime fechaHora;
  final String usuarioId;
  final bool returnToCaller;

  const ConfirmacionReservaScreen({
    super.key,
    required this.mesa,
    required this.numeroPersonas,
    required this.fechaHora,
    required this.usuarioId,
    this.returnToCaller = false,
  });

  @override
  State<ConfirmacionReservaScreen> createState() => _ConfirmacionReservaScreenState();
}

class _ConfirmacionReservaScreenState extends State<ConfirmacionReservaScreen> {
  final ReservaService _reservaService = ReservaService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  bool _isLoading = false;
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final usuario = await _reservaService.obtenerUsuario(widget.usuarioId);
      if (!mounted) return;
      if (usuario != null) {
        setState(() {
          _nombreController.text = usuario.nombre;
          _apellidosController.text = usuario.apellidos;
          _telefonoController.text = usuario.telefono;
          _emailController.text = usuario.email;
          _dniController.text = usuario.dni;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos usuario: $e');
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
        });
      }
    }
  }

  Future<void> _confirmarReserva() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para confirmar la reserva'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => LoginScreen(
              onLoginSuccess: () {
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      }
      return;
    }
    if (_nombreController.text.isEmpty || 
        _apellidosController.text.isEmpty || 
        _telefonoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final disponible = await _reservaService.verificarDisponibilidad(
        widget.mesa.id,
        widget.fechaHora,
      );

      if (!mounted) return;
      if (!disponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La mesa ya no está disponible para este horario')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final reserva = Reserva(
        mesaId: widget.mesa.id,
        mesaNombre: widget.mesa.nombre,
        usuarioId: widget.usuarioId,
        nombreCliente: '${_nombreController.text} ${_apellidosController.text}',
        telefonoCliente: _telefonoController.text,
        emailCliente: _emailController.text,
        fechaHora: widget.fechaHora,
        cantidadPersonas: widget.numeroPersonas,
      );
      final reservaId = await _reservaService.crearReserva(reserva);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Reserva confirmada para ${widget.mesa.nombre}!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      if (widget.returnToCaller) {
        Navigator.of(context).pop(reservaId);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar la reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _cargandoDatos || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen de tu reserva',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _InfoItem(
                            icon: Icons.table_restaurant,
                            title: 'Mesa',
                            value: widget.mesa.nombre,
                          ),
                          _InfoItem(
                            icon: Icons.people,
                            title: 'Personas',
                            value: '${widget.numeroPersonas}',
                          ),
                          _InfoItem(
                            icon: Icons.calendar_today,
                            title: 'Fecha',
                            value: '${widget.fechaHora.day}/${widget.fechaHora.month}/${widget.fechaHora.year}',
                          ),
                          _InfoItem(
                            icon: Icons.access_time,
                            title: 'Hora',
                            value: '${widget.fechaHora.hour}:${widget.fechaHora.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tus datos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Puedes editar tus datos si es necesario',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nombreController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _apellidosController,
                                  decoration: InputDecoration(
                                    labelText: 'Apellidos *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _telefonoController,
                            decoration: InputDecoration(
                              labelText: 'Teléfono *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true, // Email no editable
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _dniController,
                            decoration: InputDecoration(
                              labelText: 'DNI',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                            readOnly: true, // DNI no editable
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '* Campos obligatorios',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmarReserva,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'CONFIRMAR RESERVA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepOrange),
          SizedBox(width: 10),
          Text(
            '$title: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
