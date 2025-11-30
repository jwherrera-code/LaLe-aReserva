import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedRoute = '/productos';

  // Controladores para productos
  final TextEditingController _prodNombreController = TextEditingController();
  final TextEditingController _prodPrecioController = TextEditingController();
  final TextEditingController _prodDescripcionController = TextEditingController();
  final TextEditingController _prodImagenController = TextEditingController();
  final TextEditingController _prodCategoriaController = TextEditingController();
  bool _prodDisponibilidad = true;
  String? _prodEditingId;
  String _prodOrdenDisponibilidad = 'Todos';
  final List<String> _categorias = const [
    'Originales', 'Piqueos', 'Clásicos', 'Parrillas', 'Guarniciones',
    'Bebidas', 'Postres', 'Picaditos', 'Ensaladas', 'Salsas', 'Sin Categoría'
  ];

  // Controladores para locales
  final TextEditingController _locNombreController = TextEditingController();
  final TextEditingController _locDireccionController = TextEditingController();
  final TextEditingController _locTelefonoController = TextEditingController();
  final TextEditingController _locHorarioController = TextEditingController();
  final TextEditingController _locLatController = TextEditingController();
  final TextEditingController _locLngController = TextEditingController();
  String? _locEditingId;

  // Filtros para reservas
  DateTime? _filterDate;
  String? _filterHour;

  // Filtros para pedidos
  String? _pedidosEstado = 'todos';
  String _pedidosUserFilter = '';
  bool _pedidosFechaAsc = true;

  // Estados locales

  // Colores de la aplicación
  final Color _colorNegro = const Color(0xFF0E0502);
  final Color _colorBlanco = const Color(0xFFFAFAFA);
  final Color _colorCrema = const Color(0xFFFAE8C9);
  final Color _colorRojo = const Color(0xFFE62617);
  
  Color _badgeBgColor(String estado) {
    final e = estado.toLowerCase();
    if (e == 'entregado') return Colors.green;
    if (e == 'cancelado') return Colors.red.shade100;
    if (e == 'pendiente') return Colors.orange;
    return _colorCrema;
  }
  
  Color _badgeTextColor(String estado) {
    final e = estado.toLowerCase();
    if (e == 'entregado') return _colorBlanco;
    if (e == 'cancelado') return Colors.red.shade800;
    if (e == 'pendiente') return _colorBlanco;
    return _colorNegro;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _prodNombreController.dispose();
    _prodPrecioController.dispose();
    _prodDescripcionController.dispose();
    _prodImagenController.dispose();
    _prodCategoriaController.dispose();
    _locNombreController.dispose();
    _locDireccionController.dispose();
    _locTelefonoController.dispose();
    _locHorarioController.dispose();
    _locLatController.dispose();
    _locLngController.dispose();
    super.dispose();
  }

  

  Future<Map<String, Map<String, dynamic>>> _fetchUsuariosPorIds(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final firestore = FirebaseFirestore.instance;
    final allIds = ids.toList();
    final Map<String, Map<String, dynamic>> result = {};
    const chunkSize = 10;
    for (var i = 0; i < allIds.length; i += chunkSize) {
      final chunk = allIds.sublist(i, math.min(i + chunkSize, allIds.length));
      final snap = await firestore
          .collection('Usuarios')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        result[d.id] = d.data();
      }
    }
    return result;
  }

  void _guardarProducto() async {
    final nombre = _prodNombreController.text.trim();
    final precio = double.tryParse(_prodPrecioController.text) ?? 0.0;
    final descripcion = _prodDescripcionController.text.trim();
    final imagen = _prodImagenController.text.trim();
    final categoria = _prodCategoriaController.text.trim();
    
    if (nombre.isEmpty || precio <= 0 || categoria.isEmpty) {
      _mostrarSnackBar('Por favor complete todos los campos requeridos');
      return;
    }

    try {
      final ref = FirebaseFirestore.instance.collection('Menu');
      final data = {
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'imagen': imagen,
        'categoria': categoria,
        'disponibilidad': _prodDisponibilidad,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };
      
      if (_prodEditingId == null) {
        await ref.add(data);
        _mostrarSnackBar('Producto agregado exitosamente');
      } else {
        await ref.doc(_prodEditingId).update(data);
        _mostrarSnackBar('Producto actualizado exitosamente');
      }
      
      _limpiarFormularioProducto();
      setState(() {});
    } catch (e) {
      _mostrarSnackBar('Error al guardar el producto: $e');
    }
  }

  void _limpiarFormularioProducto() {
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
    final confirm = await _mostrarDialogoConfirmacion('¿Está seguro de eliminar este producto?');
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('Menu').doc(id).delete();
        _mostrarSnackBar('Producto eliminado exitosamente');
        setState(() {});
      } catch (e) {
        _mostrarSnackBar('Error al eliminar el producto: $e');
      }
    }
  }

  void _guardarLocal() async {
    final nombre = _locNombreController.text.trim();
    final direccion = _locDireccionController.text.trim();
    final telefono = _locTelefonoController.text.trim();
    final horario = _locHorarioController.text.trim();
    final lat = double.tryParse(_locLatController.text.trim());
    final lng = double.tryParse(_locLngController.text.trim());
    
    if (nombre.isEmpty || direccion.isEmpty) {
      _mostrarSnackBar('Nombre y dirección son campos requeridos');
      return;
    }

    try {
      final ref = FirebaseFirestore.instance.collection('Locales');
      final data = {
        'nombre': nombre,
        'direccion': direccion,
        'telefono': telefono,
        'horario': horario,
        'ubicacion': (lat != null && lng != null) ? {'lat': lat, 'lng': lng} : null,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };
      
      if (_locEditingId == null) {
        await ref.add(data);
        _mostrarSnackBar('Local agregado exitosamente');
      } else {
        await ref.doc(_locEditingId).update(data);
        _mostrarSnackBar('Local actualizado exitosamente');
      }
      
      _limpiarFormularioLocal();
    } catch (e) {
      _mostrarSnackBar('Error al guardar el local: $e');
    }
  }

  void _limpiarFormularioLocal() {
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
    final confirm = await _mostrarDialogoConfirmacion('¿Está seguro de eliminar este local?');
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('Locales').doc(id).delete();
        _mostrarSnackBar('Local eliminado exitosamente');
      } catch (e) {
        _mostrarSnackBar('Error al eliminar el local: $e');
      }
    }
  }

  Future<void> _marcarPedidoEntregado(String id) async {
    final confirm = await _mostrarDialogoConfirmacion('¿Marcar este pedido como entregado?');
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('Pedidos').doc(id).update({
          'estado': 'entregado', 
          'cancelable': false,
          'fechaEntrega': FieldValue.serverTimestamp(),
        });
        _mostrarSnackBar('Pedido marcado como entregado');
        setState(() {});
      } catch (e) {
        _mostrarSnackBar('Error al actualizar el pedido: $e');
      }
    }
  }

  Future<void> _actualizarReserva(String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('Reservas').doc(id).update(data);
      _mostrarSnackBar('Reserva actualizada exitosamente');
      setState(() {});
    } catch (e) {
      _mostrarSnackBar('Error al actualizar la reserva: $e');
    }
  }

  Future<void> _eliminarReserva(String id) async {
    final confirm = await _mostrarDialogoConfirmacion('¿Está seguro de eliminar esta reserva?');
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('Reservas').doc(id).delete();
        _mostrarSnackBar('Reserva eliminada exitosamente');
        setState(() {});
      } catch (e) {
        _mostrarSnackBar('Error al eliminar la reserva: $e');
      }
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _colorRojo,
      ),
    );
  }

  Future<bool?> _mostrarDialogoConfirmacion(String mensaje) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorRojo,
              foregroundColor: _colorBlanco,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _aplicarOrdenDisponibilidad(List<QueryDocumentSnapshot> productos) {
    productos = List<QueryDocumentSnapshot>.from(productos);
    
    if (_prodOrdenDisponibilidad == 'Disponibles primero') {
      productos.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final ad = (dataA['disponibilidad'] ?? true) == true ? 0 : 1;
        final bd = (dataB['disponibilidad'] ?? true) == true ? 0 : 1;
        return ad.compareTo(bd);
      });
    } else if (_prodOrdenDisponibilidad == 'No disponibles primero') {
      productos.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final ad = (dataA['disponibilidad'] ?? true) == true ? 1 : 0;
        final bd = (dataB['disponibilidad'] ?? true) == true ? 1 : 0;
        return ad.compareTo(bd);
      });
    }
    
    return productos;
  }

  Widget _buildProductos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Productos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _colorNegro,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _limpiarFormularioProducto,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorRojo,
                  foregroundColor: _colorBlanco,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Ordenar por disponibilidad:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: _colorNegro),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _colorCrema,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _prodOrdenDisponibilidad,
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'Disponibles primero', child: Text('Disponibles primero')),
                        DropdownMenuItem(value: 'No disponibles primero', child: Text('No disponibles primero')),
                      ],
                      onChanged: (v) => setState(() => _prodOrdenDisponibilidad = v ?? 'Todos'),
                      dropdownColor: _colorCrema,
                      style: TextStyle(color: _colorNegro),
                      underline: const SizedBox(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Productos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _colorRojo,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prodNombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre *',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _prodPrecioController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Precio *',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _colorCrema,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _prodCategoriaController.text.isNotEmpty ? _prodCategoriaController.text : null,
                            items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _prodCategoriaController.text = v ?? ''),
                            decoration: InputDecoration(
                              labelText: 'Categoría *',
                              filled: true,
                              fillColor: Colors.transparent,
                              labelStyle: TextStyle(color: _colorNegro),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _colorRojo, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prodDescripcionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _prodImagenController,
                              decoration: InputDecoration(
                                labelText: 'URL Imagen',
                                filled: true,
                                fillColor: _colorCrema,
                                labelStyle: TextStyle(color: _colorNegro),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _colorRojo, width: 2),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: _colorCrema,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _colorRojo.withValues(alpha: 0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (_prodImagenController.text.trim().isNotEmpty)
                                    ? Image.network(
                                        _prodImagenController.text.trim(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Center(
                                          child: Icon(Icons.broken_image, color: _colorRojo, size: 40),
                                        ),
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: _colorRojo,
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Icon(Icons.image, color: _colorRojo, size: 40),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _colorCrema,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Disponible', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro)),
                                Switch(
                                  value: _prodDisponibilidad,
                                  onChanged: (v) => setState(() => _prodDisponibilidad = v),
                                  activeThumbColor: _colorRojo,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _prodEditingId == null ? _guardarProducto : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colorRojo,
                                  foregroundColor: _colorBlanco,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Añadir'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _prodEditingId != null ? _guardarProducto : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colorNegro,
                                  foregroundColor: _colorBlanco,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Actualizar'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _limpiarFormularioProducto,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _colorRojo,
                                  side: BorderSide(color: _colorRojo),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Menu').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _colorRojo));
                }
                final docs = snapshot.data?.docs ?? const [];
                final productosFiltrados = _aplicarOrdenDisponibilidad(docs);
                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: _colorRojo),
                        const SizedBox(height: 16),
                        Text('No hay productos registrados', style: TextStyle(fontSize: 18, color: _colorNegro)),
                      ],
                    ),
                  );
                }
                return _buildListaProductos(productosFiltrados);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos(List<QueryDocumentSnapshot> productos) {
    return ListView.builder(
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final doc = productos[index];
        final data = doc.data() as Map<String, dynamic>;
        final disponible = (data['disponibilidad'] ?? true) == true;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _colorCrema,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(disponible ? Icons.restaurant : Icons.remove_circle, color: disponible ? Colors.green : _colorRojo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (data['nombre'] ?? '').toString(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _colorNegro),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: disponible ? Colors.green : _colorRojo,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              disponible ? 'Disponible' : 'No disponible',
                              style: TextStyle(color: _colorBlanco, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, size: 18, color: _colorRojo),
                          const SizedBox(width: 6),
                          Text((data['categoria'] ?? '').toString(), style: TextStyle(color: _colorNegro)),
                          const SizedBox(width: 16),
                          Icon(Icons.attach_money, size: 18, color: _colorRojo),
                          const SizedBox(width: 6),
                          Text('S/ ${(data['precio'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: _colorNegro, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _editarProducto(data, doc.id),
                            style: ElevatedButton.styleFrom(backgroundColor: _colorRojo, foregroundColor: _colorBlanco),
                            child: const Text('Editar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _eliminarProducto(doc.id),
                            style: OutlinedButton.styleFrom(foregroundColor: _colorRojo, side: BorderSide(color: _colorRojo)),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPedidos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Gestión de Pedidos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _colorNegro,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado:', style: TextStyle(color: _colorNegro, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _colorCrema,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _pedidosEstado,
                          items: const [
                            DropdownMenuItem(value: 'todos', child: Center(child: Text('Todos'))),
                            DropdownMenuItem(value: 'pendiente', child: Center(child: Text('Pendiente'))),
                            DropdownMenuItem(value: 'entregado', child: Center(child: Text('Entregado'))),
                            DropdownMenuItem(value: 'cancelado', child: Center(child: Text('Cancelado'))),
                          ],
                          onChanged: (v) => setState(() => _pedidosEstado = v),
                          dropdownColor: _colorCrema,
                          style: TextStyle(color: _colorNegro),
                          underline: const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Usuario:', style: TextStyle(color: _colorNegro, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Nombre/Email/DNI',
                            filled: true,
                            fillColor: _colorCrema,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (v) => setState(() => _pedidosUserFilter = v.trim().toLowerCase()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha:', style: TextStyle(color: _colorNegro, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _colorCrema,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<bool>(
                          value: _pedidosFechaAsc,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Ascendente')),
                            DropdownMenuItem(value: false, child: Text('Descendente')),
                          ],
                          onChanged: (v) => setState(() => _pedidosFechaAsc = v ?? true),
                          dropdownColor: _colorCrema,
                          style: TextStyle(color: _colorNegro),
                          underline: const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Pedidos').orderBy('fecha', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _colorRojo));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: _colorNegro)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay pedidos registrados', style: TextStyle(color: _colorNegro)));
                }

                var docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final ta = (a.data() as Map<String, dynamic>)['fecha'];
                  final tb = (b.data() as Map<String, dynamic>)['fecha'];
                  final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return _pedidosFechaAsc ? da.compareTo(db) : db.compareTo(da);
                });
                
                if (_pedidosEstado != null && _pedidosEstado != 'todos') {
                  docs = docs.where((d) => ((d.data() as Map<String, dynamic>)['estado'] ?? '').toString() == _pedidosEstado).toList();
                }

                if (_pedidosUserFilter.isNotEmpty) {
                  final ids = docs
                      .map((d) => ((d.data() as Map<String, dynamic>)['userId'] ?? '').toString())
                      .where((id) => id.isNotEmpty)
                      .toSet();
                  return FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: _fetchUsuariosPorIds(ids),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: _colorRojo));
                      }
                      final usuariosMap = userSnap.data ?? {};
                      final filtro = _pedidosUserFilter.toLowerCase();
                      final filtrados = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final uid = (data['userId'] ?? '').toString().toLowerCase();
                        final emailPedido = (data['userEmail'] ?? '').toString().toLowerCase();
                        final user = usuariosMap[uid];
                        final nombre = ((user?['nombre'] ?? '') as String).toLowerCase();
                        final apellidos = ((user?['apellidos'] ?? '') as String).toLowerCase();
                        final emailUsuario = ((user?['email'] ?? '') as String).toLowerCase();
                        final dni = ((user?['dni'] ?? '') as String).toLowerCase();
                        final nombreCompleto = ('$nombre $apellidos').trim();
                        return uid.contains(filtro) ||
                            emailPedido.contains(filtro) ||
                            emailUsuario.contains(filtro) ||
                            dni.contains(filtro) ||
                            nombre.contains(filtro) ||
                            apellidos.contains(filtro) ||
                            nombreCompleto.contains(filtro);
                      }).toList();

                      return _buildTablaPedidos(filtrados, usuariosMap);
                    },
                  );
                }

                return _buildTablaPedidos(docs, {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaPedidos(List<QueryDocumentSnapshot> docs, Map<String, Map<String, dynamic>> usuariosMap) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: _colorBlanco,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DataTable(
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro))),
              DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro))),
              DataColumn(label: Text('Mesa', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro))),
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro))),
              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: _colorNegro))),
            ],
            rows: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final estado = (data['estado'] ?? '').toString();
              final fecha = data['fecha'];
              final dt = fecha is Timestamp ? fecha.toDate() : null;
              final fechaTxt = dt != null 
                  ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                  : '';
              final uid = (data['userId'] ?? '').toString();
              final reservaId = (data['reserva_id'] ?? '').toString();
              final mesaInline = (data['mesa'] ?? data['mesa_nombre'] ?? data['mesa_numero'] ?? '').toString();

              Widget usuarioWidget;
              if (usuariosMap.containsKey(uid)) {
                final user = usuariosMap[uid];
                final name = (user?['nombre'] ?? '').toString();
                final apellidos = (user?['apellidos'] ?? '').toString();
                final email = (data['userEmail'] ?? '').toString();
                final displayName = (name.isNotEmpty || apellidos.isNotEmpty)
                    ? ('$name $apellidos').trim()
                    : (email.isNotEmpty ? email : uid);
                usuarioWidget = SelectableText(displayName, style: TextStyle(color: _colorNegro));
              } else {
                usuarioWidget = FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('Usuarios').doc(uid).get(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _colorRojo, strokeWidth: 2));
                    }
                    final userData = snap.data?.data() as Map<String, dynamic>?;
                    final name = (userData?['nombre'] ?? '').toString();
                    final apellidos = (userData?['apellidos'] ?? '').toString();
                    final email = (data['userEmail'] ?? '').toString();
                    final displayName = (name.isNotEmpty || apellidos.isNotEmpty)
                        ? ('$name $apellidos').trim()
                        : (email.isNotEmpty ? email : uid);
                    return SelectableText(displayName, style: TextStyle(color: _colorNegro));
                  },
                );
              }

              Widget mesaWidget;
              if (mesaInline.isNotEmpty) {
                mesaWidget = SelectableText(mesaInline, style: TextStyle(color: _colorNegro));
              } else if (reservaId.isNotEmpty) {
                mesaWidget = FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('Reservas').doc(reservaId).get(),
                  builder: (context, rsnap) {
                    if (rsnap.connectionState == ConnectionState.waiting) {
                      return SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _colorRojo, strokeWidth: 2));
                    }
                    final rdata = rsnap.data?.data() as Map<String, dynamic>?;
                    final mesa = (rdata?['mesa_nombre'] ?? rdata?['mesa_id'] ?? '').toString();
                    return SelectableText(mesa.isNotEmpty ? mesa : '-', style: TextStyle(color: _colorNegro));
                  },
                );
              } else {
                mesaWidget = SelectableText('-', style: TextStyle(color: _colorNegro));
              }

              return DataRow(
                cells: [
                  DataCell(usuarioWidget),
                  DataCell(SelectableText('S/ ${(data['total'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: _colorNegro))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _badgeBgColor(estado),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estado,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _badgeTextColor(estado),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  DataCell(mesaWidget),
                  DataCell(SelectableText(fechaTxt, style: TextStyle(color: _colorNegro))),
                  DataCell(
                    (estado != 'entregado' && estado != 'cancelado')
                        ? ElevatedButton(
                            onPressed: () => _marcarPedidoEntregado(doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorRojo,
                              foregroundColor: _colorBlanco,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Entregado', style: TextStyle(fontSize: 12)),
                          )
                        : Text(
                            estado == 'entregado' ? 'Entregado' : 'Cancelado',
                            style: TextStyle(
                              color: estado == 'entregado' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  

  Widget _buildReservas() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Gestión de Reservas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _colorNegro,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filtrar por fecha:', style: TextStyle(color: _colorNegro, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _colorCrema,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.calendar_today, color: _colorRojo),
                            title: Text(
                              _filterDate != null 
                                  ? '${_filterDate!.day}/${_filterDate!.month}/${_filterDate!.year}'
                                  : 'Seleccionar fecha',
                              style: TextStyle(color: _colorNegro),
                            ),
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _filterDate ?? DateTime.now(),
                                firstDate: DateTime(2000, 1, 1),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _filterDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filtrar por hora:', style: TextStyle(color: _colorNegro, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _colorCrema,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _filterHour,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            items: List.generate(11, (i) => 12 + i)
                                .map((h) => DropdownMenuItem(
                                      value: '${h.toString().padLeft(2, '0')}:00',
                                      child: Text('${h.toString().padLeft(2, '0')}:00'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _filterHour = v),
                            dropdownColor: _colorCrema,
                            style: TextStyle(color: _colorNegro),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _filterDate = null;
                      _filterHour = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorRojo,
                      foregroundColor: _colorBlanco,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Limpiar Filtros'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Reservas').orderBy('fecha_hora', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _colorRojo));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: _colorNegro)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay reservas registradas', style: TextStyle(color: _colorNegro)));
                }

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['fecha_hora'];
                  final dt = ts is Timestamp ? ts.toDate() : null;
                  final matchesDate = _filterDate == null || (dt != null && 
                      dt.year == _filterDate!.year && 
                      dt.month == _filterDate!.month && 
                      dt.day == _filterDate!.day);
                  final matchesHour = _filterHour == null || (dt != null && 
                      '${dt.hour.toString().padLeft(2, '0')}:00' == _filterHour);
                  return matchesDate && matchesHour;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('No hay reservas que coincidan con los filtros', style: TextStyle(color: _colorNegro)));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final cant = (data['cantidad_personas'] ?? 0).toString();
                    final nombre = (data['nombre_cliente'] ?? '').toString();
                    final mesa = (data['mesa_nombre'] ?? '').toString();
                    final ts = data['fecha_hora'];
                    final dt = ts is Timestamp ? ts.toDate() : null;
                    final fechaTexto = dt != null
                        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                        : (ts?.toString() ?? '');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  nombre.isNotEmpty ? nombre : 'Sin nombre',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _colorNegro),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _colorRojo,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Mesa: $mesa', 
                                    style: TextStyle(color: _colorBlanco, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: _colorRojo),
                                const SizedBox(width: 6),
                                Text(fechaTexto, style: TextStyle(fontWeight: FontWeight.w500, color: _colorNegro)),
                                const SizedBox(width: 16),
                                Icon(Icons.people, size: 18, color: _colorRojo),
                                const SizedBox(width: 6),
                                Text('$cant personas', style: TextStyle(fontWeight: FontWeight.w500, color: _colorNegro)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final controller = TextEditingController(text: cant);
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Editar cantidad de personas', style: TextStyle(color: _colorNegro)),
                                        content: TextField(
                                          controller: controller,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Cantidad de personas',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: _colorRojo, width: 2),
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text('Cancelar', style: TextStyle(color: _colorNegro)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, controller.text),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _colorRojo,
                                              foregroundColor: _colorBlanco,
                                            ),
                                            child: const Text('Guardar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (result != null) {
                                      final n = int.tryParse(result) ?? int.parse(cant);
                                      await _actualizarReserva(doc.id, {'cantidad_personas': n});
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar Personas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _colorRojo,
                                    foregroundColor: _colorBlanco,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _eliminarReserva(doc.id),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _colorRojo,
                                    side: BorderSide(color: _colorRojo),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocales() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Gestión de Locales',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _colorNegro,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locNombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre *',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _locDireccionController,
                          decoration: InputDecoration(
                            labelText: 'Dirección *',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locTelefonoController,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _locHorarioController,
                          decoration: InputDecoration(
                            labelText: 'Horario',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locLatController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Latitud',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _locLngController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Longitud',
                            filled: true,
                            fillColor: _colorCrema,
                            labelStyle: TextStyle(color: _colorNegro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _colorRojo, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _guardarLocal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorRojo,
                              foregroundColor: _colorBlanco,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(_locEditingId == null ? 'Agregar Local' : 'Actualizar Local'),
                          ),
                          if (_locEditingId != null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _limpiarFormularioLocal,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _colorRojo,
                                side: BorderSide(color: _colorRojo),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Locales').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _colorRojo));
                }
                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 64, color: _colorRojo),
                        const SizedBox(height: 16),
                        Text('No hay locales registrados', style: TextStyle(fontSize: 18, color: _colorNegro)),
                      ],
                    ),
                  );
                }
                return _buildListaLocales(docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaLocales(List<QueryDocumentSnapshot> locales) {
    return ListView.builder(
      itemCount: locales.length,
      itemBuilder: (context, index) {
        final doc = locales[index];
        final data = doc.data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (data['nombre'] ?? '').toString(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _colorNegro),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _editarLocal(data, doc.id),
                          style: ElevatedButton.styleFrom(backgroundColor: _colorRojo, foregroundColor: _colorBlanco),
                          child: const Text('Editar'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _eliminarLocal(doc.id),
                          style: OutlinedButton.styleFrom(foregroundColor: _colorRojo, side: BorderSide(color: _colorRojo)),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: _colorRojo),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text((data['direccion'] ?? '').toString(), style: TextStyle(color: _colorNegro)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: _colorRojo),
                    const SizedBox(width: 6),
                    Text((data['telefono'] ?? '').toString(), style: TextStyle(color: _colorNegro)),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 18, color: _colorRojo),
                    const SizedBox(width: 6),
                    Text((data['horario'] ?? '').toString(), style: TextStyle(color: _colorNegro)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: _colorNegro,
        foregroundColor: _colorBlanco,
        elevation: 0,
        centerTitle: true,
      ),
      sideBar: SideBar(
        key: ValueKey('sidebar-$_selectedRoute'),
        backgroundColor: _colorCrema,
        activeBackgroundColor: _colorRojo,
        activeIconColor: _colorBlanco,
        activeTextStyle: TextStyle(color: _colorBlanco, fontWeight: FontWeight.bold),
        textStyle: TextStyle(color: _colorNegro, fontWeight: FontWeight.w500),
        iconColor: _colorNegro,
        items: const [
          AdminMenuItem(
            title: 'Productos',
            icon: Icons.restaurant,
            route: '/productos',
          ),
          AdminMenuItem(
            title: 'Pedidos',
            icon: Icons.list_alt,
            route: '/pedidos',
          ),
          AdminMenuItem(
            title: 'Reservas',
            icon: Icons.event,
            route: '/reservas',
          ),
          AdminMenuItem(
            title: 'Locales',
            icon: Icons.store,
            route: '/locales',
          ),
        ],
        selectedRoute: _selectedRoute,
        onSelected: (item) {
          setState(() {
            _selectedRoute = item.route ?? '/productos';
          });
        },
        
      ),
      body: Builder(
        builder: (context) {
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
        },
      ),
    );
  }
}
