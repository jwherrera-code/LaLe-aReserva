import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Error global: $error\nStack: $stack');
    return true;
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseAuth.instance.setLanguageCode('es');

  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (_) {}
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AppLifecycleState changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        _startInactivityTimer();
        _reconnectFirebase();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isAppInBackground = true;
        _inactivityTimer?.cancel();
        break;
      case AppLifecycleState.detached:
        _inactivityTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
        _isAppInBackground = true;
        _inactivityTimer?.cancel();
        break;
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (!_isAppInBackground) {}
    });
  }

  Future<void> _reconnectFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        debugPrint('Firebase reconectado exitosamente');
      }
    } catch (e) {
      debugPrint('Error reconectando Firebase: $e');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase reinicializado exitosamente');
      } catch (initError) {
        debugPrint('Error reinicializando Firebase: $initError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFFE62617),
        primarySwatch: const MaterialColor(0xFFE62617, {
          50: Color(0xFFFFE8E6),
          100: Color(0xFFFCCFCC),
          200: Color(0xFFF7A9A6),
          300: Color(0xFFF1827D),
          400: Color(0xFFEC5C55),
          500: Color(0xFFE62617),
          600: Color(0xFFC72216),
          700: Color(0xFFA91D13),
          800: Color(0xFF8B180F),
          900: Color(0xFF6D130C),
        }),
        scaffoldBackgroundColor: const Color(0xFFFAE8C9),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E0502),
          foregroundColor: Color(0xFFFAFAFA),
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFE62617),
          unselectedItemColor: Color(0xFFB8B8B8),
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE62617),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE62617)),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFE62617),
          selectionColor: Color(0xFFE62617),
          selectionHandleColor: Color(0xFFE62617),
        ),
      ),
      home: kIsWeb
          ? const _WebAdminGate()
          : const SplashScreen(homeScreen: HomeScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _WebAdminGate extends StatelessWidget {
  const _WebAdminGate();

  bool _isAdmin(User? user) {
    final email = user?.email?.toLowerCase();
    return email == 'admin@lalena.com';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginScreen(onLoginSuccess: () {});
        }

        if (!_isAdmin(user)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso restringido')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Esta página es solo para administradores.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }

        return const AdminDashboard();
      },
    );
  }
}
