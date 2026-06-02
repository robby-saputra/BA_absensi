import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';

class RiwayatScreen extends StatefulWidget {
  final int siswaId;

  const RiwayatScreen({
    super.key,
    required this.siswaId,
  });

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List data = [];
  List filteredData = [];

  bool loading = true;

  String selectedFilter = 'Semua';

  /*
  |--------------------------------------------------------------------------
  | GET RIWAYAT
  |--------------------------------------------------------------------------
  */
  Future getRiwayat() async {
    try {
      var url = Uri.parse('$baseUrl/riwayat/${widget.siswaId}');

      var response = await http.get(url);

      List result = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        data = result;
        filteredData = result;

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      /*
      |--------------------------------------------------------------------------
      | OPTIONAL ERROR
      |--------------------------------------------------------------------------
      | Tidak perlu snackbar keras supaya UX lebih clean
      */
    }
  }

  /*
  |--------------------------------------------------------------------------
  | FILTER DATA
  |--------------------------------------------------------------------------
  */
  void filterData(String jenis) {
    setState(() {
      selectedFilter = jenis;

      if (jenis == 'Semua') {
        filteredData = data;
      } else if (jenis == 'Masuk') {
        filteredData = data.where((item) {
          return item['jenis'].toString().toLowerCase().contains('masuk');
        }).toList();
      } else if (jenis == 'Pulang') {
        filteredData = data.where((item) {
          return item['jenis'].toString().toLowerCase().contains('pulang');
        }).toList();
      } else {
        filteredData = data.where((item) {
          return item['jenis'].toString().toLowerCase().contains('mapel');
        }).toList();
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | STATUS COLOR
  |--------------------------------------------------------------------------
  */
  Color statusColor(String status) {
    if (status.toLowerCase() == 'hadir') {
      return Colors.green;
    }

    if (status.toLowerCase() == 'telat') {
      return Colors.orange;
    }

    return Colors.red;
  }

  /*
  |--------------------------------------------------------------------------
  | ICON JENIS ABSENSI
  |--------------------------------------------------------------------------
  */
  IconData jenisIcon(String jenis) {
    if (jenis.toLowerCase().contains('masuk')) {
      return Icons.login;
    }

    if (jenis.toLowerCase().contains('pulang')) {
      return Icons.logout;
    }

    return Icons.school;
  }

  /*
  |--------------------------------------------------------------------------
  | TOTAL HADIR
  |--------------------------------------------------------------------------
  */
  int totalHadir() {
    return data.where((item) {
      String status = item['status'].toString().toLowerCase();

      return status == 'hadir' || status == 'telat';
    }).length;
  }

  /*
  |--------------------------------------------------------------------------
  | TOTAL TELAT
  |--------------------------------------------------------------------------
  */
  int totalTelat() {
    return data.where((item) {
      return item['status'].toString().toLowerCase() == 'telat';
    }).length;
  }

  @override
  void initState() {
    super.initState();
    getRiwayat();
  }

  /*
  |--------------------------------------------------------------------------
  | FILTER BUTTON
  |--------------------------------------------------------------------------
  */
  Widget filterButton(String title) {
    bool active = selectedFilter == title;

    return GestureDetector(
      onTap: () {
        filterData(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: active ? const Color(0xff273c75) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xff273c75).withValues(alpha: 0.25),
                    blurRadius: 10,
                  )
                ]
              : [],
          border: Border.all(
            color: const Color(0xff273c75),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xff273c75),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff273c75),
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : filteredData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.history,
                        size: 90,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Belum Ada Riwayat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    /*
          |--------------------------------------------------------------------------
          | HEADER
          |--------------------------------------------------------------------------
          */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff273c75),
                            Color(0xff40739e),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Riwayat',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data.length} Absensi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: statCard(
                                  title: 'Hadir',
                                  value: totalHadir().toString(),
                                  icon: Icons.check_circle,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: statCard(
                                  title: 'Telat',
                                  value: totalTelat().toString(),
                                  icon: Icons.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /*
          |--------------------------------------------------------------------------
          | FILTER
          |--------------------------------------------------------------------------
          */
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        children: [
                          filterButton('Semua'),
                          filterButton('Masuk'),
                          filterButton('Pulang'),
                          filterButton('Mapel'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    /*
          |--------------------------------------------------------------------------
          | LIST RIWAYAT
          |--------------------------------------------------------------------------
          */
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final item = filteredData[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                /*
                      |--------------------------------------------------------------------------
                      | ICON
                      |--------------------------------------------------------------------------
                      */
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff273c75)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    jenisIcon(item['jenis']),
                                    color: const Color(0xff273c75),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 15),

                                /*
                      |--------------------------------------------------------------------------
                      | DETAIL
                      |--------------------------------------------------------------------------
                      */
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['jenis'],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item['tanggal'],
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item['jam_scan'] ?? '-',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                /*
                      |--------------------------------------------------------------------------
                      | STATUS
                      |--------------------------------------------------------------------------
                      */
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor(
                                      item['status'],
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    item['status'],
                                    style: TextStyle(
                                      color: statusColor(
                                        item['status'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | STAT CARD
  |--------------------------------------------------------------------------
  */
  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
