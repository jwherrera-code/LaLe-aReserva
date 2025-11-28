import 'package:flutter/material.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final Function(List<Map<String, dynamic>>, double) onProceedToPayment;
  final VoidCallback onCarritoChanged;
  
  const CarritoScreen({
    super.key, 
    required this.carrito,
    required this.onProceedToPayment,
    required this.onCarritoChanged,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {

  double _calcularTotal() {
    double total = 0;
    for (var producto in widget.carrito) {
      final precio = (producto['precio'] as num).toDouble();
      final cantidad = (producto['cantidad'] as num).toInt();
      total += precio * cantidad;
    }
    return total;
  }

  int _calcularTotalProductos() {
    int total = 0;
    for (var producto in widget.carrito) {
      final cantidad = (producto['cantidad'] as num).toInt();
      total += cantidad;
    }
    return total;
  }

  void _incrementarCantidad(int index) {
    setState(() {
      widget.carrito[index]['cantidad'] = (widget.carrito[index]['cantidad'] as num).toInt() + 1;
    });
    widget.onCarritoChanged();
  }

  void _decrementarCantidad(int index) {
    setState(() {
      final cantidadActual = (widget.carrito[index]['cantidad'] as num).toInt();
      if (cantidadActual > 1) {
        widget.carrito[index]['cantidad'] = cantidadActual - 1;
      } else {
        widget.carrito.removeAt(index);
      }
    });
    widget.onCarritoChanged();
  }

  void _eliminarProducto(int index) {
    setState(() {
      widget.carrito.removeAt(index);
    });
    widget.onCarritoChanged();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado del carrito'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _vaciarCarrito() {
    if (widget.carrito.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vaciar Carrito'),
          content: const Text('¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.carrito.clear();
                });
                widget.onCarritoChanged();
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Carrito vaciado'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Vaciar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _procederAlPago() {
    if (widget.carrito.isEmpty) return;
    
    final total = _calcularTotal();
    widget.onProceedToPayment(List.from(widget.carrito), total);
  }

  Widget _buildBotonPago() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'S/${_calcularTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 230, 38, 23),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.carrito.isEmpty ? null : _procederAlPago,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceder al Pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalProductos = _calcularTotalProductos();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Carrito de Compras',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 230, 38, 23),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (widget.carrito.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 250, 243, 230),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromARGB(255, 230, 38, 23),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          size: 16,
                          color: Color.fromARGB(255, 230, 38, 23),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalProductos ${totalProductos == 1 ? 'producto' : 'productos'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 230, 38, 23),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  ElevatedButton.icon(
                    onPressed: _vaciarCarrito,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'Vaciar Carrito',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: widget.carrito.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tu carrito está vacío',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Agrega productos desde el menú',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Volver al Menú'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.carrito.length,
                    itemBuilder: (context, index) {
                      final producto = widget.carrito[index];
                      final precio = (producto['precio'] as num).toDouble();
                      final cantidad = (producto['cantidad'] as num).toInt();
                      final subtotal = precio * cantidad;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color.fromARGB(255, 250, 243, 230),
                                ),
                                child: _buildImagenProducto(producto),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto['nombre'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/${precio.toStringAsFixed(2)} c/u',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Subtotal: S/${subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 230, 38, 23),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 250, 243, 230),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color.fromARGB(255, 230, 38, 23),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _decrementarCantidad(index),
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: Color.fromARGB(255, 230, 38, 23),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            cantidad.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _incrementarCantidad(index),
                                          icon: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Color.fromARGB(255, 230, 38, 23),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  IconButton(
                                    onPressed: () => _eliminarProducto(index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Eliminar producto',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          if (widget.carrito.isNotEmpty) _buildBotonPago(),
        ],
      ),
    );
  }

  Widget _buildImagenProducto(Map<String, dynamic> producto) {
    final urlImagenOriginal = producto['imagen'] as String? ?? '';
    final urlImagenDirecta = _convertirEnlaceDriveADirecto(urlImagenOriginal);

    if (urlImagenDirecta.isEmpty) {
      return const Center(
        child: Icon(
          Icons.fastfood,
          color: Colors.grey,
          size: 30,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        urlImagenDirecta,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 30,
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color.fromARGB(255, 230, 38, 23),
              strokeWidth: 2,
            ),
          );
        },
      ),
    );
  }

  String _convertirEnlaceDriveADirecto(String enlaceDrive) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(enlaceDrive);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    } else {
      return enlaceDrive;
    }
  }
}