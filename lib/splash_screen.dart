import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget homeScreen;
  
  const SplashScreen({super.key, required this.homeScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _loadingProgress = 0.0;
  bool _isLoadingComplete = false;
  bool _isDisposed = false;
  

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
    
    _startLoading();
  }

  Future<void> _startLoading() async {
    await _actualizarCarga(50, "Inicializando...");
    await Future.delayed(const Duration(milliseconds: 300));
    await _actualizarCarga(100, "Listo");
    
    _safeSetState(() {
      _isLoadingComplete = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted && !_isDisposed) {
      _navigateToAppropriateScreen();
    }
  }

  void _navigateToAppropriateScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onLoginSuccess: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => widget.homeScreen),
            );
          },
        ),
      ),
    );
  }

  Future<void> _actualizarCarga(int progress, String message) async {
    _safeSetState(() {
      _loadingProgress = progress.toDouble();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _safeSetState(VoidCallback callback) {
    if (mounted && !_isDisposed) {
      setState(callback);
    }
  }

  

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 243, 230),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/chickenLoading.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color.fromARGB(255, 230, 38, 23),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              "La Leña",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 230, 38, 23),
                fontFamily: 'Poppins',
              ),
            ),
            
            const SizedBox(height: 10),
            
            Text(
              "Cargando...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
            
            const SizedBox(height: 30),
            
            Container(
              width: 250,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${_loadingProgress.toInt()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 230, 38, 23),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  LinearProgressIndicator(
                    value: _loadingProgress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color.fromARGB(255, 230, 38, 23),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 12,
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    _getLoadingMessage(_loadingProgress),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoadingComplete)
              const Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '¡Listo!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getLoadingMessage(double progress) {
    if (progress < 30) {
      return "Inicializando aplicación...";
    } else if (progress < 60) {
      return "Cargando menú...";
    } else if (progress < 90) {
      return "Preparando imágenes...";
    } else {
      return "Finalizando...";
    }
  }
}
