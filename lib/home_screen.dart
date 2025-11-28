import 'package:flutter/material.dart';
import 'menu.dart';
import 'carrito_screen.dart';
import 'pedidos_screen.dart';
import 'locales_screen.dart';
import 'pago_screen.dart';
import 'seleccion_mesa_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/custom_app_bar.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _carrito = [];
  bool _mostrarSnackbarPedidoExitoso = false;

  void _onCarritoChanged() {
    debugPrint('Carrito cambiado, productos: ${_carrito.length}');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mostrarSnackbarPedidoExitoso) {
        _mostrarSnackBarPedidoExitoso();
        _mostrarSnackbarPedidoExitoso = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        debugPrint('Conexión a Firebase verificada en HomeScreen');
      }
    } catch (e) {
      debugPrint('Error verificando conexión Firebase: $e');
      _mostrarError('Error de conexión. Por favor, reinicia la aplicación.');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _checkFirebaseConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    final user = FirebaseAuth.instance.currentUser;

    switch (_currentIndex) {
      case 0:
        return MenuScreen(
          carrito: _carrito,
          onNavigateToCart: _navigateToCart,
          onRealizarPedido: _realizarPedido,
          onCarritoChanged: _onCarritoChanged,
        );
      case 1:
        return const LocalesScreen();
      case 2:
        return const PedidosScreen();
      case 3:
        if (user != null) {
          return SeleccionMesaScreen(usuarioId: user.uid);
        } else {
          return _buildUsuarioNoAutenticado();
        }
      default:
        return MenuScreen(
          carrito: _carrito,
          onNavigateToCart: _navigateToCart,
          onRealizarPedido: _realizarPedido,
          onCarritoChanged: _onCarritoChanged,
        );
    }
  }

  Widget _buildUsuarioNoAutenticado() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Inicia sesión para hacer reservas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    onLoginSuccess: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToCart() {
    _showCartDialog();
  }

  void _showCartDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: CarritoScreen(
          carrito: _carrito,
          onProceedToPayment: (carrito, total) {
            Navigator.of(context).pop();
            _navigateToPayment(carrito, total);
          },
          onCarritoChanged: _onCarritoChanged,
        ),
      ),
    );
  }

  void _navigateToPayment(List<Map<String, dynamic>> carrito, double total) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PagoScreen(
          carrito: carrito,
          total: total,
          onRealizarPedido: _realizarPedido,
          onPagoCompletado: _onPagoCompletado,
        ),
      ),
    ).then((_) {
      if (_mostrarSnackbarPedidoExitoso) {
        _mostrarSnackBarPedidoExitoso();
        _mostrarSnackbarPedidoExitoso = false;
      }
    });
  }

  void _onPagoCompletado() {
    debugPrint('onPagoCompletado llamado - Navegando a pedidos');

    setState(() {
      _currentIndex = 2;
    });

    _mostrarSnackbarPedidoExitoso = true;

    if (mounted) {
      setState(() {});
    }
  }

  void _mostrarSnackBarPedidoExitoso() {
    debugPrint('Mostrando snackbar de pedido exitoso');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Pedido realizado exitosamente!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _realizarPedido(Map<String, dynamic> pedidoData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarError('Usuario no autenticado');
      return;
    }

    try {
      final pedidoCompleto = {
        ...pedidoData,
        'userId': user.uid,
        'userEmail': user.email,
        'fecha': Timestamp.now(),
        'estado': 'pendiente',
        'cancelable': true,
      };

      debugPrint('Guardando pedido en Firebase...');
      await FirebaseFirestore.instance
          .collection('Pedidos')
          .add(pedidoCompleto);
      debugPrint('Pedido guardado exitosamente en Firebase');

      setState(() {
        _carrito.clear();
      });
      _onCarritoChanged();
    } catch (e) {
      debugPrint('Error al guardar pedido: $e');
      _mostrarError('Error al realizar pedido: $e');
      rethrow;
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color.fromARGB(255, 230, 38, 23),
          unselectedItemColor: const Color(0xFFB8B8B8),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: "Menú",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Locales"),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "Pedidos",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_restaurant),
              label: "Reservas",
            ),
          ],
        ),
      ),
    );
  }
}
