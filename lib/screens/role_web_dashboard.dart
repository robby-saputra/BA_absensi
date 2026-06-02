import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api.dart';
import '../services/storage_service.dart';

class RoleWebDashboard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const RoleWebDashboard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  State<RoleWebDashboard> createState() => _RoleWebDashboardState();
}

class _RoleWebDashboardState extends State<RoleWebDashboard> {
  String nama = 'User';
  bool loading = true;
  List<dynamic> features = [];

  @override
  void initState() {
    super.initState();
    loadContext();
  }

  Future<void> loadContext() async {
    final value = await StorageService.getNama();
    final userId = await StorageService.getUserId();
    if (!mounted) return;
    setState(() {
      nama = value ?? 'User';
      loading = true;
    });

    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/role-context/$userId'),
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        features = data['features'] ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> openWeb(String path) async {
    final uri = Uri.parse('$webBaseUrl$path');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka dashboard web')),
      );
    }
  }

  Future<void> logout() async {
    await StorageService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  IconData featureIcon(String icon) {
    if (icon == 'admin') return Icons.admin_panel_settings;
    if (icon == 'piket') return Icons.qr_code_scanner;
    if (icon == 'wali') return Icons.groups;
    if (icon == 'siswa') return Icons.badge;
    return Icons.school;
  }

  Color featureColor(String icon) {
    if (icon == 'admin') return Colors.redAccent;
    if (icon == 'piket') return Colors.orange;
    if (icon == 'wali') return Colors.green;
    if (icon == 'siswa') return Colors.purple;
    return widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: widget.color,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadContext,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 48),
                  const SizedBox(height: 18),
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.subtitle,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (features.isEmpty)
              dashboardAction(
                title: 'Belum Ada Akses Aktif',
                subtitle: 'Role Anda belum memiliki fitur mobile aktif.',
                icon: Icons.info_outline,
                color: Colors.grey,
                onTap: () {},
              )
            else
              ...features.map((raw) {
                final item = Map<String, dynamic>.from(raw);
                final path = item['path'];
                return dashboardAction(
                  title: item['title'] ?? '-',
                  subtitle: item['subtitle'] ?? '-',
                  icon: featureIcon(item['icon'] ?? ''),
                  color: featureColor(item['icon'] ?? ''),
                  onTap: path == null ? () {} : () => openWeb(path),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget dashboardAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
