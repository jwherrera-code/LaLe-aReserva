import 'package:flutter/material.dart';
import 'reserva_model.dart';
import 'reserva_service.dart';
import 'seleccion_fecha_hora_screen.dart';
import 'mis_reservas_screen.dart';

class SeleccionMesaScreen extends StatefulWidget {
  final String usuarioId;
  final bool returnToCaller;

  const SeleccionMesaScreen({super.key, required this.usuarioId, this.returnToCaller = false});

  @override
  State<SeleccionMesaScreen> createState() => _SeleccionMesaScreenState();
}

class _SeleccionMesaScreenState extends State<SeleccionMesaScreen> {
  final ReservaService _reservaService = ReservaService();
  int _numeroPersonas = 2;
  Mesa? _mesaSeleccionada;

  bool _esMesaAdecuada(Mesa mesa) {
    return mesa.capacidad >= _numeroPersonas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Mesa'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Mis reservas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MisReservasScreen(usuarioId: widget.usuarioId),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Theme.of(context).iconTheme.color),
                    SizedBox(width: 10),
                    const Text('Número de personas:'),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<int>(
                        initialValue: _numeroPersonas,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        iconSize: 28,
                        items: List<int>.generate(12, (i) => i + 1).map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _numeroPersonas = newValue!;
                            _mesaSeleccionada = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              'Mesas Disponibles:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            
            Expanded(
              child: StreamBuilder<List<Mesa>>(
                stream: _reservaService.obtenerTodasLasMesas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar mesas'));
                  }
                  
                  final todasLasMesas = snapshot.data ?? [];
                  final mesasFiltradas = todasLasMesas.where(_esMesaAdecuada).toList();
                  mesasFiltradas.sort((a, b) {
                    int parseNum(String s) {
                      final n = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
                      return n ?? 0;
                    }
                    return parseNum(a.nombre).compareTo(parseNum(b.nombre));
                  });
                  
                  if (mesasFiltradas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No hay mesas disponibles'),
                          Text('para $_numeroPersonas personas'),
                        ],
                      ),
                    );
                  }
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: mesasFiltradas.length,
                    itemBuilder: (context, index) {
                      final mesa = mesasFiltradas[index];
                      final estaSeleccionada = _mesaSeleccionada?.id == mesa.id;
                      
                      return _MesaItem(
                        mesa: mesa,
                        estaSeleccionada: estaSeleccionada,
                        onTap: () => setState(() => _mesaSeleccionada = mesa),
                      );
                    },
                  );
                },
              ),
            ),
            
            SizedBox(height: 20),
            
            if (_mesaSeleccionada != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final reservaId = await Navigator.push<String?>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeleccionFechaHoraScreen(
                          mesa: _mesaSeleccionada!,
                          numeroPersonas: _numeroPersonas,
                          usuarioId: widget.usuarioId,
                          returnToCaller: widget.returnToCaller,
                        ),
                      ),
                    );
                    if (mounted && widget.returnToCaller && reservaId != null) {
                      Navigator.pop(context, reservaId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'CONTINUAR CON MESA ${_mesaSeleccionada!.nombre}',
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

class _MesaItem extends StatelessWidget {
  final Mesa mesa;
  final bool estaSeleccionada;
  final VoidCallback onTap;

  const _MesaItem({
    required this.mesa,
    required this.estaSeleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: estaSeleccionada ? Theme.of(context).primaryColor : Colors.blue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 32,
              color: Colors.white,
            ),
            SizedBox(height: 5),
            Text(
              'Mesa ${mesa.nombre}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '${mesa.capacidad} personas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
