import 'package:flutter/material.dart';
import 'reserva_model.dart';
import 'reserva_service.dart';
import 'confirmacion_reserva_screen.dart';

class SeleccionFechaHoraScreen extends StatefulWidget {
  final Mesa mesa;
  final int numeroPersonas;
  final String usuarioId;
  final bool returnToCaller;

  const SeleccionFechaHoraScreen({
    super.key,
    required this.mesa,
    required this.numeroPersonas,
    required this.usuarioId,
    this.returnToCaller = false,
  });

  @override
  State<SeleccionFechaHoraScreen> createState() => _SeleccionFechaHoraScreenState();
}

class _SeleccionFechaHoraScreenState extends State<SeleccionFechaHoraScreen> {
  final ReservaService _reservaService = ReservaService();
  DateTime _fechaSeleccionada = DateTime.now();
  String? _horaSeleccionada;
  bool _cargando = false;
  List<String> _horasOcupadas = [];

  List<String> get _horasDisponibles {
    List<String> horas = [];
    for (int i = 12; i <= 22; i++) {
      horas.add('${i.toString().padLeft(2, '0')}:00');
    }
    return horas;
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        _horaSeleccionada = null;
      });
      await _cargarHorasOcupadas();
    }
  }

  Future<void> _cargarHorasOcupadas() async {
    try {
      final reservas = await _reservaService.obtenerReservasFuturasMesa(widget.mesa.id);
      final mismasFechas = reservas.where((r) =>
          r.fechaHora.year == _fechaSeleccionada.year &&
          r.fechaHora.month == _fechaSeleccionada.month &&
          r.fechaHora.day == _fechaSeleccionada.day);
      setState(() {
        _horasOcupadas = mismasFechas
            .map((r) => '${r.fechaHora.hour.toString().padLeft(2, '0')}:00')
            .toSet()
            .toList();
      });
    } catch (_) {}
  }

  Future<bool> _verificarDisponibilidad() async {
    if (_horaSeleccionada == null) return false;
    
    final partesHora = _horaSeleccionada!.split(':');
    final hora = int.parse(partesHora[0]);
    final minuto = int.parse(partesHora[1]);
    
    final fechaHora = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      hora,
      minuto,
    );

    return await _reservaService.verificarDisponibilidad(widget.mesa.id, fechaHora);
  }

  void _continuarADatosPersonales() async {
    if (_horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una hora')),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final disponible = await _verificarDisponibilidad();
      if (!mounted) return;
      
      if (!disponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La mesa no está disponible en este horario')),
        );
        setState(() {
          _cargando = false;
        });
        return;
      }

      final partesHora = _horaSeleccionada!.split(':');
      final hora = int.parse(partesHora[0]);
      final minuto = int.parse(partesHora[1]);
      
      final fechaHora = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        hora,
        minuto,
      );

      if (!mounted) return;
      final reservaId = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmacionReservaScreen(
            mesa: widget.mesa,
            numeroPersonas: widget.numeroPersonas,
            fechaHora: fechaHora,
            usuarioId: widget.usuarioId,
            returnToCaller: widget.returnToCaller,
          ),
        ),
      );

      if (mounted && widget.returnToCaller && reservaId != null) {
        Navigator.pop(context, reservaId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Fecha y Hora'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.table_restaurant, color: Theme.of(context).primaryColor),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mesa.nombre,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text('${widget.numeroPersonas} personas'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Fecha',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(
                              '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                            ),
                            onPressed: _seleccionarFecha,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Hora',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _horaSeleccionada,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Selecciona una hora',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            items: _horasDisponibles
                                .where((h) => !_horasOcupadas.contains(h))
                                .map((String hora) {
                              return DropdownMenuItem<String>(
                                value: hora,
                                child: Text(hora),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _horaSeleccionada = newValue;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Horario disponible: 12:00 - 22:00',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (_horasOcupadas.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Horas ocupadas: ${_horasOcupadas.join(', ')}',
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continuarADatosPersonales,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'CONTINUAR A DATOS PERSONALES',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
