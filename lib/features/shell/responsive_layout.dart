import 'package:flutter/material.dart';
import '../dashboard/desktop_dashboard.dart';
import '../dashboard/mobile_dashboard.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return desktop ?? const DesktopDashboard();
        } else {
          return mobile ?? const MobileDashboard();
        }
      },
    );
  }
}

