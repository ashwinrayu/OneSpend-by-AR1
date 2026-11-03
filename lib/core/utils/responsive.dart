import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static bool isDesktop(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width >= 850;
    }
    // If native desktop platform and wide screen, treat as desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return MediaQuery.of(context).size.width >= 720;
    }
    return MediaQuery.of(context).size.width >= 850;
  }

  static bool isMobile(BuildContext context) => !isDesktop(context);

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return desktop;
    }
    return mobile;
  }
}

