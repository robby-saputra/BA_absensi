import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../../services/storage_service.dart';

class PengajuanIzinScreen extends StatefulWidget {
  const PengajuanIzinScreen({super.key});

  @override
  State<PengajuanIzinScreen> createState() => _PengajuanIzinScreenState();
}

class _PengajuanIzinScreenState extends State<PengajuanIzinScreen> {
  final alasan = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String jenis = 'izin';
  DateTime mulai = DateTime.now();
  DateTime selesai = DateTime.now();
  bool loading = false;
  PlatformFile? bukti;

  @override
  void dispose() {
    alasan.dispose();
    super.dispose();
  }

  Future<void> pickDate({required bool isMulai}) async {
    final result = await showDatePicker(
      context: context,
      initialDate: isMulai ? mulai : selesai,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff273c75),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;
    setState(() {
      if (isMulai) {
        mulai = result;
        if (selesai.isBefore(mulai)) selesai = mulai;
      } else {
        selesai = result;
      }
    });
  }

  String formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final userId = await StorageService.getUserId();
    if (userId == null) {
      showDialogInfo(
        title: 'Sesi Login Habis',
        message: 'Silakan login ulang sebelum mengirim pengajuan.',
        color: Colors.red,
        icon: Icons.lock,
      );
      return;
    }

    setState(() => loading = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/siswa/pengajuan-izin'),
      );
      request.headers['Accept'] = 'application/json';
      request.fields.addAll({
        'siswa_id': userId.toString(),
        'jenis': jenis,
        'tanggal_mulai': formatDate(mulai),
        'tanggal_selesai': formatDate(selesai),
        'alasan': alasan.text.trim(),
      });

      if (bukti?.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'bukti',
          bukti!.path!,
          filename: bukti!.name,
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['status'] == 'success') {
        await showDialogInfo(
          title: 'Pengajuan Terkirim',
          message: data['message'] ??
              'Pengajuan berhasil dikirim dan menunggu verifikasi.',
          color: Colors.green,
          icon: Icons.check_circle,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        await showDialogInfo(
          title: 'Pengajuan Gagal',
          message: data['message'] ?? 'Pengajuan belum bisa dikirim.',
          color: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showDialogInfo(
        title: 'Koneksi Bermasalah',
        message: e.toString(),
        color: Colors.red,
        icon: Icons.wifi_off,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pilihBukti() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        dialogTitle: 'Pilih bukti izin/sakit',
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final extension = (file.extension ?? '').toLowerCase();
      final allowed = ['jpg', 'jpeg', 'png', 'pdf'];

      if (!allowed.contains(extension)) {
        await showDialogInfo(
          title: 'Format Tidak Didukung',
          message: 'Pilih file JPG, PNG, atau PDF.',
          color: Colors.red,
          icon: Icons.error,
        );
        return;
      }

      if (file.path == null) {
        await showDialogInfo(
          title: 'File Tidak Bisa Dibaca',
          message: 'Silakan pilih file lain dari penyimpanan perangkat.',
          color: Colors.red,
          icon: Icons.folder_off,
        );
        return;
      }

      if (file.size > 4 * 1024 * 1024) {
        await showDialogInfo(
          title: 'File Terlalu Besar',
          message: 'Ukuran bukti maksimal 4 MB.',
          color: Colors.red,
          icon: Icons.error,
        );
        return;
      }

      setState(() => bukti = file);
    } catch (e) {
      if (!mounted) return;
      await showDialogInfo(
        title: 'Upload Belum Bisa Dibuka',
        message: 'Pemilih file gagal dibuka: $e',
        color: Colors.red,
        icon: Icons.folder_off,
      );
    }
  }

  Future<void> showDialogInfo({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff273c75),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Pengajuan Izin/Sakit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: child,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff273c75), Color(0xff40739e)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, color: Colors.white, size: 38),
                    SizedBox(height: 14),
                    Text(
                      'Ajukan izin atau sakit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Data akan masuk ke guru piket, guru mapel, dan admin untuk diverifikasi.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Pengajuan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: jenis,
                    decoration: inputDecoration(Icons.category),
                    items: const [
                      DropdownMenuItem(value: 'izin', child: Text('Izin')),
                      DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    ],
                    onChanged: (value) =>
                        setState(() => jenis = value ?? 'izin'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: dateButton(
                          'Tanggal Mulai',
                          mulai,
                          () => pickDate(isMulai: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: dateButton(
                          'Tanggal Selesai',
                          selesai,
                          () => pickDate(isMulai: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: alasan,
                    minLines: 4,
                    maxLines: 6,
                    validator: (value) {
                      if ((value ?? '').trim().length < 5) {
                        return 'Alasan minimal 5 karakter.';
                      }
                      return null;
                    },
                    decoration: inputDecoration(Icons.notes).copyWith(
                      labelText: 'Alasan',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: loading ? null : pilihBukti,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xff273c75).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              const Color(0xff273c75).withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file,
                              color: Color(0xff273c75)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload Bukti',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bukti == null
                                      ? 'JPG, PNG, atau PDF maksimal 4 MB'
                                      : '${bukti!.name} (${(bukti!.size / 1024).toStringAsFixed(0)} KB)',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff273c75),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Pilih File Bukti',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (bukti != null)
                            IconButton(
                              onPressed: () => setState(() => bukti = null),
                              icon: const Icon(Icons.close, color: Colors.red),
                            )
                          else
                            const Icon(Icons.chevron_right,
                                color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        loading ? 'Mengirim...' : 'Kirim Pengajuan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff273c75),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xff273c75)),
      filled: true,
      fillColor: const Color(0xfff5f6fa),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff273c75), width: 1.4),
      ),
    );
  }

  Widget dateButton(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff273c75).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xff273c75).withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_month,
                size: 18, color: const Color(0xff273c75)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(
              formatDate(value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
