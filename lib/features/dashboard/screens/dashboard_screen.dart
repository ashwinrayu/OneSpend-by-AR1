import 'package:flutter/material.dart';
import '../../shell/responsive_layout.dart';
import '../desktop_dashboard.dart';
import '../mobile_dashboard.dart';

export '../desktop_dashboard.dart';
export '../mobile_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileDashboard(),
      desktop: DesktopDashboard(),
    );
  }
}
