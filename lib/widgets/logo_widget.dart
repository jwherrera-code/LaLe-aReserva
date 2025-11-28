import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key, 
    this.size = 120, 
    this.isAppBar = false,
    this.color,
  });

  final double size;
  final bool isAppBar;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/iconLogo.png',
      height: isAppBar ? 40 : size,
      width: isAppBar ? 40 : size,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: isAppBar ? 40 : size,
          height: isAppBar ? 40 : size,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 230, 38, 23),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restaurant,
            color: Colors.white,
            size: isAppBar ? 20 : size * 0.4,
          ),
        );
      },
    );
  }
}