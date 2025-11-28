import 'package:flutter/material.dart';
import 'logo_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showLogo;
  final String? title;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomAppBar({
    super.key, 
    this.actions, 
    this.showLogo = true,
    this.title,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: showLogo 
          ? const LogoWidget(isAppBar: true)
          : title != null 
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                )
              : null,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
      elevation: 0,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
