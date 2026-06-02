import 'package:flutter/material.dart';

import '../role_web_dashboard.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleWebDashboard(
      title: 'Dashboard Superadmin',
      subtitle: 'Akses penuh superadmin tersedia di dashboard web.',
      icon: Icons.admin_panel_settings,
      color: Color(0xff273c75),
    );
  }
}
