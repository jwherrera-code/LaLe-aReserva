import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedRoute = '/productos';

  final TextEditingController _prodNombreController = TextEditingController();
  final TextEditingController _prodPrecioController = TextEditingController();
  final TextEditingController _prodDescripcionController = TextEditingController();
  final TextEditingController _prodImagenController = TextEditingController();
  final TextEditingController _prodCategoriaController = TextEditingController();
  bool _prodDisponibilidad = true;
  String? _prodEditingId;

  final TextEditingController _locNombreController = TextEditingController();
  final TextEditingController _locDireccionController = TextEditingController();
  final TextEditingController _locTelefonoController = TextEditingController();
  final TextEditingController _locHorarioController = TextEditingController();
  final TextEditingController _locLatController = TextEditingController();
  final TextEditingController _locLngController = TextEditingController();
  String? _locEditingId;

  void _guardarProducto() async {
    final nombre = _prodNombreController.text.trim();
    final precio = double.tryParse(_prodPrecioController.text) ?? 0.0;
    final descripcion = _prodDescripcionController.text.trim();
    final imagen = _prodImagenController.text.trim();
    final categoria = _prodCategoriaController.text.trim();
    if (nombre.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('Menu');
    final data = {
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'imagen': imagen,
      'categoria': categoria,
      'disponibilidad': _prodDisponibilidad,
    };
    if (_prodEditingId == null) {
      await ref.add(data);
    } else {
      await ref.doc(_prodEditingId).update(data);
    }
    _prodNombreController.clear();
    _prodPrecioController.clear();
    _prodDescripcionController.clear();
    _prodImagenController.clear();
    _prodCategoriaController.clear();
    _prodDisponibilidad = true;
    _prodEditingId = null;
    setState(() {});
  }

  void _editarProducto(Map<String, dynamic> data, String id) {
    _prodNombreController.text = (data['nombre'] ?? '').toString();
    _prodPrecioController.text = (data['precio'] ?? 0).toString();
    _prodDescripcionController.text = (data['descripcion'] ?? '').toString();
    _prodImagenController.text = (data['imagen'] ?? '').toString();
    _prodCategoriaController.text = (data['categoria'] ?? '').toString();
    _prodDisponibilidad = (data['disponibilidad'] ?? true) == true;
    _prodEditingId = id;
    setState(() {});
  }

  Future<void> _eliminarProducto(String id) async {
    await FirebaseFirestore.instance.collection('Menu').doc(id).delete();
    setState(() {});
  }

  void _guardarLocal() async {
    final nombre = _locNombreController.text.trim();
    final direccion = _locDireccionController.text.trim();
    final telefono = _locTelefonoController.text.trim();
    final horario = _locHorarioController.text.trim();
    final lat = double.tryParse(_locLatController.text.trim());
    final lng = double.tryParse(_locLngController.text.trim());
    if (nombre.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('Locales');
    final data = {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'horario': horario,
      'ubicacion': (lat != null && lng != null) ? {'lat': lat, 'lng': lng} : null,
    };
    if (_locEditingId == null) {
      await ref.add(data);
    } else {
      await ref.doc(_locEditingId).update(data);
    }
    _locNombreController.clear();
    _locDireccionController.clear();
    _locTelefonoController.clear();
    _locHorarioController.clear();
    _locLatController.clear();
    _locLngController.clear();
    _locEditingId = null;
    setState(() {});
  }

  void _editarLocal(Map<String, dynamic> data, String id) {
    _locNombreController.text = (data['nombre'] ?? '').toString();
    _locDireccionController.text = (data['direccion'] ?? '').toString();
    _locTelefonoController.text = (data['telefono'] ?? '').toString();
    _locHorarioController.text = (data['horario'] ?? '').toString();
    final ubic = data['ubicacion'];
    if (ubic is Map) {
      _locLatController.text = (ubic['lat']?.toString() ?? '');
      _locLngController.text = (ubic['lng']?.toString() ?? '');
    } else {
      _locLatController.text = '';
      _locLngController.text = '';
    }
    _locEditingId = id;
    setState(() {});
  }

  Future<void> _eliminarLocal(String id) async {
    await FirebaseFirestore.instance.collection('Locales').doc(id).delete();
    setState(() {});
  }

  Future<void> _marcarPedidoEntregado(String id) async {
    await FirebaseFirestore.instance.collection('Pedidos').doc(id).update({'estado': 'entregado', 'cancelable': false});
    setState(() {});
  }

  Future<void> _actualizarReserva(String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('Reservas').doc(id).update(data);
    setState(() {});
  }

  Future<void> _eliminarReserva(String id) async {
    await FirebaseFirestore.instance.collection('Reservas').doc(id).delete();
    setState(() {});
  }

  Widget _buildProductos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _prodNombreController, decoration: const InputDecoration(labelText: 'Nombre'))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _prodPrecioController, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _prodCategoriaController, decoration: const InputDecoration(labelText: 'Categoría'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _prodDescripcionController, decoration: const InputDecoration(labelText: 'Descripción'))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _prodImagenController, decoration: const InputDecoration(labelText: 'URL Imagen'))),
            const SizedBox(width: 16),
            Row(children: [
              const Text('Disponible'),
              Switch(value: _prodDisponibilidad, onChanged: (v) => setState(() => _prodDisponibilidad = v)),
            ]),
            const SizedBox(width: 16),
            ElevatedButton(onPressed: _guardarProducto, child: Text(_prodEditingId == null ? 'Agregar' : 'Actualizar')),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Menu').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Precio')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Disponible')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text((data['nombre'] ?? '').toString())),
                        DataCell(Text('S/ ${(data['precio'] ?? 0).toString()}')),
                        DataCell(Text((data['categoria'] ?? '').toString())),
                        DataCell(Text(((data['disponibilidad'] ?? true) ? 'Sí' : 'No'))),
                        DataCell(Row(children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editarProducto(data, doc.id)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarProducto(doc.id)),
                        ])),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Pedidos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Usuario')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text((data['userId'] ?? '').toString())),
                  DataCell(Text('S/ ${(data['total'] ?? 0).toString()}')),
                  DataCell(Text((data['estado'] ?? '').toString())),
                  DataCell(Row(children: [
                    ElevatedButton(onPressed: () => _marcarPedidoEntregado(doc.id), child: const Text('Entregado')),
                  ])),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservas() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Reservas').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Mesa')),
                DataColumn(label: Text('Fecha/Hora')),
                DataColumn(label: Text('Personas')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final cant = (data['cantidad_personas'] ?? 0).toString();
                final nombre = (data['nombre_cliente'] ?? '').toString();
                final mesa = (data['mesa_nombre'] ?? '').toString();
                final ts = data['fecha_hora'];
                final fechaTexto = ts is Timestamp ? ts.toDate().toString() : ts?.toString() ?? '';
                return DataRow(cells: [
                  DataCell(Text(nombre)),
                  DataCell(Text(mesa)),
                  DataCell(Text(fechaTexto)),
                  DataCell(Text(cant)),
                  DataCell(Row(children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async {
                      final controller = TextEditingController(text: cant);
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Editar personas'),
                          content: TextField(controller: controller, keyboardType: TextInputType.number),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
                          ],
                        ),
                      );
                      if (result != null) {
                        final n = int.tryParse(result) ?? int.parse(cant);
                        await _actualizarReserva(doc.id, {'cantidad_personas': n});
                      }
                    }),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarReserva(doc.id)),
                  ])),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocales() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          Expanded(child: TextField(controller: _locNombreController, decoration: const InputDecoration(labelText: 'Nombre'))),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _locDireccionController, decoration: const InputDecoration(labelText: 'Dirección'))),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _locTelefonoController, decoration: const InputDecoration(labelText: 'Teléfono'))),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _locHorarioController, decoration: const InputDecoration(labelText: 'Horario'))),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _locLatController, decoration: const InputDecoration(labelText: 'Latitud'), keyboardType: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _locLngController, decoration: const InputDecoration(labelText: 'Longitud'), keyboardType: TextInputType.number)),
          const SizedBox(width: 16),
          ElevatedButton(onPressed: _guardarLocal, child: Text(_locEditingId == null ? 'Agregar' : 'Actualizar')),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Locales').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Dirección')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Horario')),
                    DataColumn(label: Text('Lat')),
                    DataColumn(label: Text('Lng')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ubic = data['ubicacion'];
                    final latStr = (ubic is Map) ? (ubic['lat']?.toString() ?? '') : '';
                    final lngStr = (ubic is Map) ? (ubic['lng']?.toString() ?? '') : '';
                    return DataRow(cells: [
                      DataCell(Text((data['nombre'] ?? '').toString())),
                      DataCell(Text((data['direccion'] ?? '').toString())),
                      DataCell(Text((data['telefono'] ?? '').toString())),
                      DataCell(Text((data['horario'] ?? '').toString())),
                      DataCell(Text(latStr)),
                      DataCell(Text(lngStr)),
                      DataCell(Row(children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editarLocal(data, doc.id)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarLocal(doc.id)),
                      ])),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(title: const Text('Panel de Administración'), backgroundColor: kIsWeb ? Colors.blue : Colors.deepOrange,),
      sideBar: SideBar(
        items: const [
          AdminMenuItem(title: 'Productos', icon: Icons.restaurant, route: '/productos'),
          AdminMenuItem(title: 'Pedidos', icon: Icons.list_alt, route: '/pedidos'),
          AdminMenuItem(title: 'Reservas', icon: Icons.event, route: '/reservas'),
          AdminMenuItem(title: 'Locales', icon: Icons.store, route: '/locales'),
        ],
        selectedRoute: _selectedRoute,
        onSelected: (item) {
          setState(() {
            _selectedRoute = item.route ?? '/productos';
          });
        },
      ),
      body: Builder(builder: (context) {
        switch (_selectedRoute) {
          case '/pedidos':
            return _buildPedidos();
          case '/reservas':
            return _buildReservas();
          case '/locales':
            return _buildLocales();
          case '/productos':
          default:
            return _buildProductos();
        }
      }),
    );
  }
}
