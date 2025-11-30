import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_reconnection_mixin.dart';

class MenuScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final VoidCallback onNavigateToCart;
  final Function(Map<String, dynamic>) onRealizarPedido;
  final VoidCallback onCarritoChanged;

  const MenuScreen({
    super.key,
    required this.carrito,
    required this.onNavigateToCart,
    required this.onRealizarPedido,
    required this.onCarritoChanged,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin, FirebaseReconnectionMixin {
  String _terminoBusqueda = '';
  List<String> _favoritos = [];
  List<Map<String, dynamic>> _productosPopulares = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _iconAnimationController;
  late Animation<double> _scaleAnimation;

  List<Map<String, dynamic>> productos = [];
  final ValueNotifier<int> _carritoCounter = ValueNotifier<int>(0);

  String _nombreUsuario = '';
  String? _fotoBase64;
  String? _avatarAssetPath;
  bool _cargandoUsuario = true;

  final Map<String, IconData> _iconosCategorias = {
    'Originales': Icons.star,
    'Piqueos': Icons.restaurant,
    'Clásicos': Icons.favorite,
    'Parrillas': Icons.outdoor_grill,
    'Guarniciones': Icons.rice_bowl,
    'Bebidas': Icons.local_drink,
    'Postres': Icons.cake,
    'Picaditos': Icons.fastfood,
    'Ensaladas': Icons.eco,
    'Salsas': Icons.emoji_food_beverage,
    'Sin Categoría': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productos.isEmpty) {
        obtenerProductos();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _obtenerProductosPopulares();
      });
    });

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeOut),
    );

    _carritoCounter.value = _calcularTotalProductos();

    _cargarInformacionUsuario();
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _scrollController.dispose();
    _carritoCounter.dispose();
    super.dispose();
  }

  int _calcularTotalProductos() {
    int total = 0;
    for (var producto in widget.carrito) {
      final cantidad = (producto['cantidad'] as num).toInt();
      total += cantidad;
    }
    return total;
  }

  void _actualizarContadorCarrito() {
    _carritoCounter.value = _calcularTotalProductos();
    widget.onCarritoChanged();
  }

  void _cargarInformacionUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _cargandoUsuario = false;
          _nombreUsuario = 'Invitado';
        });
      }
      return;
    }

    try {
      debugPrint('Buscando usuario con UID: ${user.uid}');

      final userDoc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      if (userDoc.exists) {
        final userData = userDoc.data();
        debugPrint(
          'Usuario encontrado en colección "Usuarios": ${userData?['nombre']}',
        );
        if (mounted) {
            setState(() {
              _nombreUsuario = userData?['nombre'] ?? 'Usuario';
              _fotoBase64 = userData?['fotoBase64'] as String?;
              _avatarAssetPath = userData?['avatarAssetPath'] as String?;
              _cargandoUsuario = false;
            });
        }
      } else {
        debugPrint('Usuario no encontrado en la colección "Usuarios"');
        if (mounted) {
            setState(() {
              _nombreUsuario = 'Usuario';
              _fotoBase64 = null;
              _avatarAssetPath = null;
              _cargandoUsuario = false;
            });
        }
      }
    } catch (e) {
      debugPrint('Error cargando información del usuario: $e');
      if (mounted) {
        setState(() {
          _nombreUsuario = 'Usuario';
          _cargandoUsuario = false;
        });
      }
    }
  }

  void _cargarFavoritos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Usuario no autenticado, no se pueden cargar favoritos');
      return;
    }

    try {
      debugPrint('Cargando favoritos para usuario: ${user.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('Favoritos')
          .where('userId', isEqualTo: user.uid)
          .get();

      debugPrint('Favoritos encontrados: ${snapshot.docs.length}');

      if (mounted) {
        setState(() {
          _favoritos = snapshot.docs
              .map((doc) => doc['productoId'] as String)
              .toList();
        });
      }
      debugPrint('Favoritos cargados: $_favoritos');
    } catch (e) {
      debugPrint('Error cargando favoritos: $e');
    }
  }

  void _toggleFavorito(String productoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarSnackBar(
        'Debes iniciar sesión para usar favoritos',
        Colors.orange,
      );
      return;
    }

    try {
      final favoritoRef = FirebaseFirestore.instance
          .collection('Favoritos')
          .doc('${user.uid}_$productoId');

      if (_favoritos.contains(productoId)) {
        debugPrint('Removiendo favorito: $productoId');
        await favoritoRef.delete();
        if (mounted) {
          setState(() {
            _favoritos.remove(productoId);
          });
        }
        if (mounted) {
          _mostrarSnackBar('Removido de favoritos', Colors.orange);
        }
      } else {
        debugPrint('Agregando favorito: $productoId');
        await favoritoRef.set({
          'userId': user.uid,
          'productoId': productoId,
          'fecha': Timestamp.now(),
        });
        if (mounted) {
          setState(() {
            _favoritos.add(productoId);
          });
        }
        if (mounted) {
          _mostrarSnackBar('Agregado a favoritos', Colors.green);
        }
      }

      debugPrint('Favoritos actualizados: $_favoritos');
    } catch (e) {
      debugPrint('Error actualizando favorito: $e');
      if (mounted) {
        _mostrarSnackBar('Error actualizando favorito: $e', Colors.red);
      }
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    final snackBar = SnackBar(
      content: Text(mensaje),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String convertirEnlaceDriveADirecto(String enlaceDrive) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(enlaceDrive);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    } else {
      return enlaceDrive;
    }
  }

  Future<void> obtenerProductos() async {
    final connected = await ensureFirebaseConnection();
      if (!connected) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      try {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

      debugPrint('Obteniendo productos de Firebase...');

      final snapshot = await FirebaseFirestore.instance
          .collection('Menu')
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('Productos obtenidos: ${snapshot.docs.length}');


      final productosObtenidos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();

      if (mounted) {
        setState(() {
          productos = productosObtenidos;
          _isLoading = false;
        });
      }

      _precargarImagenes();

      _cargarFavoritos();
    } on FirebaseException catch (e) {
      debugPrint('Error de Firebase: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        _mostrarSnackBar('Error de conexión. Reintentando...', Colors.orange);
      }

      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) obtenerProductos();
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout obteniendo productos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        _mostrarSnackBar('Conexión lenta. Reintentando...', Colors.orange);
      }
    } catch (e) {
      debugPrint('Error obteniendo productos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        _mostrarSnackBar('Error al cargar productos: $e', Colors.red);
      }
    }
  }

  void _precargarImagenes() {
    try {
      for (final p in productos) {
        final url = convertirEnlaceDriveADirecto(p['imagen']?.toString() ?? '');
        if (url.isNotEmpty && mounted) {
          precacheImage(NetworkImage(url), context);
        }
      }
    } catch (_) {}
  }

  void _obtenerProductosPopulares() async {
    try {
      debugPrint('Obteniendo productos populares (PopularProductos)...');
      final statsSnapshot = await FirebaseFirestore.instance
          .collection('PopularProductos')
          .orderBy('vecesPedido', descending: true)
          .limit(5)
          .get();

      final statsMap = {
        for (final d in statsSnapshot.docs)
          (d.data()['productoId']?.toString() ?? ''):
              (d.data()['vecesPedido'] as num?)?.toInt() ?? 0
      }..removeWhere((k, v) => k.isEmpty);

      final ids = statsMap.keys.toList();
      if (ids.isEmpty) {
        if (mounted) {
          setState(() => _productosPopulares = []);
        }
        return;
      }

      final productosPopularesSnapshot = await FirebaseFirestore.instance
          .collection('Menu')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      if (mounted) {
        setState(() {
          _productosPopulares = productosPopularesSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                    'vecesPedido': statsMap[doc.id] ?? 0,
                  })
              .toList();
        });
      }
      debugPrint(
          'Productos populares (PopularProductos) cargados: ${_productosPopulares.length}');
    } catch (e) {
      debugPrint('Error obteniendo productos populares: $e');
    }
  }

  List<Map<String, dynamic>> _filtrarProductos() {
    List<Map<String, dynamic>> productosFiltrados = List.from(productos);

    productosFiltrados.sort((a, b) {
      final aEsFavorito = _favoritos.contains(a['id']);
      final bEsFavorito = _favoritos.contains(b['id']);
      if (aEsFavorito && !bEsFavorito) return -1;
      if (!aEsFavorito && bEsFavorito) return 1;
      return 0;
    });

    if (_terminoBusqueda.isNotEmpty) {
      productosFiltrados = productosFiltrados.where((producto) {
        final nombre = producto['nombre']?.toString().toLowerCase() ?? '';
        final descripcion =
            producto['descripcion']?.toString().toLowerCase() ?? '';
        final categoria = producto['categoria']?.toString().toLowerCase() ?? '';
        final termino = _terminoBusqueda.toLowerCase();

        return nombre.contains(termino) ||
            descripcion.contains(termino) ||
            categoria.contains(termino);
      }).toList();
    }

    return productosFiltrados;
  }

  Map<String, List<Map<String, dynamic>>> _agruparProductosPorCategoria(
    List<Map<String, dynamic>> productos,
  ) {
    final productosAgrupados = <String, List<Map<String, dynamic>>>{};

    for (var producto in productos) {
      final categoria = producto['categoria']?.toString() ?? 'Sin Categoría';
      if (!productosAgrupados.containsKey(categoria)) {
        productosAgrupados[categoria] = [];
      }
      productosAgrupados[categoria]!.add(producto);
    }

    return productosAgrupados;
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final existingIndex = widget.carrito.indexWhere(
      (item) => item['id'] == producto['id'],
    );

    setState(() {
      if (existingIndex != -1) {
        final cantidadActual = widget.carrito[existingIndex]['cantidad'] ?? 1;
        widget.carrito[existingIndex]['cantidad'] = cantidadActual + 1;
      } else {
        widget.carrito.add({...producto, 'cantidad': 1});
      }
    });

    _actualizarContadorCarrito();

    _iconAnimationController.forward().then((_) {
      _iconAnimationController.reverse();
    });

    _mostrarSnackBar(
      '${producto['nombre']} añadido al carrito',
      const Color.fromARGB(255, 230, 38, 23),
    );
  }

  

  void _mostrarDetallesProducto(Map<String, dynamic> producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetallesProductoSheet(
        producto: producto,
        esFavorito: _favoritos.contains(producto['id']),
        onToggleFavorito: () => _toggleFavorito(producto['id']),
        onAgregarAlCarrito: () => _agregarAlCarrito(producto),
      ),
    );
  }

  void _irAlCarrito() {
    widget.onNavigateToCart();
  }

  

  

  Future<void> _onRefresh() async {
    await obtenerProductos();
  }

  IconData _obtenerIconoCategoria(String categoria) {
    return _iconosCategorias[categoria] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final productosFiltrados = _filtrarProductos();
    final productosAgrupados = _agruparProductosPorCategoria(
      productosFiltrados,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            (_fotoBase64 != null)
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: MemoryImage(base64Decode(_fotoBase64!)),
                  )
                : (_avatarAssetPath != null
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage(_avatarAssetPath!),
                      )
                    : const Icon(Icons.person, size: 28, color: Colors.white)),
            const SizedBox(width: 8),
            if (!_cargandoUsuario && _nombreUsuario.isNotEmpty)
              Expanded(
                child: Text(
                  'Bienvenido, $_nombreUsuario',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFAFAFA),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            if (_cargandoUsuario)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE62617),
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _carritoCounter,
            builder: (context, cartCount, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const Icon(Icons.shopping_cart),
                    ),
                    onPressed: _irAlCarrito,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 230, 38, 23),
                  ),
                  SizedBox(height: 16),
                  Text('Cargando menú...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFFE62617),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _terminoBusqueda = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFE62617),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAE8C9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_productosPopulares.isNotEmpty &&
                      _terminoBusqueda.isEmpty)
                    SliverToBoxAdapter(child: _buildProductosPopulares()),

                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Menú (${productosFiltrados.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (_terminoBusqueda.isNotEmpty)
                            Text(
                              'Búsqueda: "$_terminoBusqueda"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (productosFiltrados.isNotEmpty)
                    _terminoBusqueda.isEmpty
                        ? _buildCategoriasConAcordeon(productosAgrupados)
                        : _buildResultadosBusqueda(productosFiltrados)
                  else
                    SliverToBoxAdapter(child: _buildEmptyState()),
                ],
              ),
            ),
    );
  }

  Widget _buildProductosPopulares() {
    final productosPopularesOrdenados = List.from(_productosPopulares);
    productosPopularesOrdenados.sort((a, b) {
      final aEsFavorito = _favoritos.contains(a['id']);
      final bEsFavorito = _favoritos.contains(b['id']);
      if (aEsFavorito && !bEsFavorito) return -1;
      if (!aEsFavorito && bEsFavorito) return 1;
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.transparent,
          child: const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Populares',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: productosPopularesOrdenados.length,
            itemBuilder: (context, index) {
              final producto = productosPopularesOrdenados[index];
              final urlImagenDirecta = convertirEnlaceDriveADirecto(
                producto['imagen'] ?? '',
              );
              final esFavorito = _favoritos.contains(producto['id']);

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _mostrarDetallesProducto(producto),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  color: const Color.fromARGB(
                                    255,
                                    250,
                                    243,
                                    230,
                                  ),
                                ),
                                child: urlImagenDirecta.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          urlImagenDirecta,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    250,
                                                    243,
                                                    230,
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(12),
                                                      ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            250,
                                            243,
                                            230,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.fastfood,
                                            color: Colors.grey,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    _toggleFavorito(producto['id']);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      esFavorito
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: esFavorito
                                          ? Colors.red
                                          : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto['nombre'] ?? 'Sin Nombre',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'S/${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 230, 38, 23),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${producto['vecesPedido'] ?? 0} pedidos',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: const Text(
                                  'Click para más detalles',
                                  style: TextStyle(
                                    fontSize: 6,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCategoriasConAcordeon(
    Map<String, List<Map<String, dynamic>>> productosAgrupados,
  ) {
    final categorias = productosAgrupados.keys.toList()..sort();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final categoria = categorias[index];
        final productosCategoria = productosAgrupados[categoria]!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: Icon(
              _obtenerIconoCategoria(categoria),
              color: const Color.fromARGB(255, 230, 38, 23),
            ),
            title: Text(
              categoria,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text('${productosCategoria.length} productos'),
            children: [_buildListaProductos(productosCategoria)],
          ),
        );
      }, childCount: categorias.length),
    );
  }

  Widget _buildResultadosBusqueda(
    List<Map<String, dynamic>> productosFiltrados,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final producto = productosFiltrados[index];
        final urlImagenDirecta = convertirEnlaceDriveADirecto(
          producto['imagen'] ?? '',
        );
        final esFavorito = _favoritos.contains(producto['id']);

        return _ProductoCard(
          producto: producto,
          urlImagenDirecta: urlImagenDirecta,
          esFavorito: esFavorito,
          onToggleFavorito: () => _toggleFavorito(producto['id']),
          onAgregarAlCarrito: () => _agregarAlCarrito(producto),
          onVerDetalles: () => _mostrarDetallesProducto(producto),
        );
      }, childCount: productosFiltrados.length),
    );
  }

  Widget _buildListaProductos(List<Map<String, dynamic>> productos) {
    return Column(
      children: productos.map((producto) {
        final urlImagenDirecta = convertirEnlaceDriveADirecto(
          producto['imagen'] ?? '',
        );
        final esFavorito = _favoritos.contains(producto['id']);

        return _ProductoCard(
          producto: producto,
          urlImagenDirecta: urlImagenDirecta,
          esFavorito: esFavorito,
          onToggleFavorito: () => _toggleFavorito(producto['id']),
          onAgregarAlCarrito: () => _agregarAlCarrito(producto),
          onVerDetalles: () => _mostrarDetallesProducto(producto),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            _terminoBusqueda.isEmpty
                ? 'No hay productos en el menú'
                : 'No se encontraron productos para "$_terminoBusqueda"',
            style: const TextStyle(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: obtenerProductos,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 230, 38, 23),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final String urlImagenDirecta;
  final bool esFavorito;
  final VoidCallback onToggleFavorito;
  final VoidCallback onAgregarAlCarrito;
  final VoidCallback onVerDetalles;

  const _ProductoCard({
    required this.producto,
    required this.urlImagenDirecta,
    required this.esFavorito,
    required this.onToggleFavorito,
    required this.onAgregarAlCarrito,
    required this.onVerDetalles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onVerDetalles,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 130,
          child: Row(
            children: [
              Container(
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  color: const Color.fromARGB(255, 250, 243, 230),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: urlImagenDirecta.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Image.network(
                                urlImagenDirecta,
                                fit: BoxFit.cover, // CAMBIADO A COVER
                                width: double.infinity, // AÑADIDO
                                height: double.infinity, // AÑADIDO
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          250,
                                          243,
                                          230,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 250, 243, 230),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onToggleFavorito,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            esFavorito ? Icons.favorite : Icons.favorite_border,
                            color: esFavorito ? Colors.red : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto['nombre'] ?? 'Sin Nombre',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: producto['disponibilidad'] ?? true
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'S/${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: producto['disponibilidad'] ?? true
                                      ? const Color.fromARGB(255, 230, 38, 23)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: (producto['disponibilidad'] ?? true)
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (producto['disponibilidad'] ?? true)
                                    ? 'Disponible'
                                    : 'No Disponible',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (producto['disponibilidad'] ?? true)
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 250, 243, 230),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color.fromARGB(255, 230, 38, 23),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              producto['categoria'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 24,
                        child: Material(
                          color: (producto['disponibilidad'] ?? true) == true
                              ? const Color.fromARGB(255, 230, 38, 23)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            onTap: (producto['disponibilidad'] ?? true) == true
                                ? onAgregarAlCarrito
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Center(
                              child: Icon(
                                Icons.shopping_cart,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetallesProductoSheet extends StatelessWidget {
  final Map<String, dynamic> producto;
  final bool esFavorito;
  final VoidCallback onToggleFavorito;
  final VoidCallback onAgregarAlCarrito;

  const _DetallesProductoSheet({
    required this.producto,
    required this.esFavorito,
    required this.onToggleFavorito,
    required this.onAgregarAlCarrito,
  });

  @override
  Widget build(BuildContext context) {
    final urlImagenOriginal = producto['imagen'] as String? ?? '';
    final urlImagenDirecta = _convertirEnlaceDriveADirecto(urlImagenOriginal);
    final descripcion = producto['descripcion'] ?? 'Sin descripción';
    final precio = producto['precio']?.toStringAsFixed(2) ?? '0.00';
    final categoria = producto['categoria'] ?? 'Sin categoría';
    final disponibilidad = producto['disponibilidad'] ?? true;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(255, 250, 243, 230),
            ),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: urlImagenDirecta.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            urlImagenDirecta,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      250,
                                      243,
                                      230,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 60,
                                    ),
                                  ),
                                ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 250, 243, 230),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 60,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleFavorito,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: esFavorito ? Colors.red : Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  producto['nombre'] ?? 'Sin Nombre',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                'S/$precio',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 230, 38, 23),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 250, 243, 230),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromARGB(255, 230, 38, 23),
                    width: 1,
                  ),
                ),
                child: Text(
                  categoria,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: disponibilidad ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                disponibilidad ? 'Disponible' : 'No disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: disponibilidad ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Descripción:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                descripcion,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: disponibilidad ? onAgregarAlCarrito : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 230, 38, 23),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(width: 8),
                  Text('Agregar al Carrito'),
                ],
              ),
            ),
          ),
        ],
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
