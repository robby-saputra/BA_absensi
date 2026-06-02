import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NilaiScreen extends StatefulWidget {
  final int siswaId;

  const NilaiScreen({
    super.key,
    required this.siswaId,
  });

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  List data = [];
  List filteredData = [];

  bool loading = true;

  String selectedFilter = 'Semua';

  Future getNilai() async {
    try {
      var url = Uri.parse(
        'http://192.168.1.5:8000/api/nilai/${widget.siswaId}',
      );

      var response = await http.get(url);

      List result = jsonDecode(response.body);

      setState(() {
        data = result;
        filteredData = result;

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil data nilai'),
        ),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | FILTER NILAI
  |--------------------------------------------------------------------------
  */
  void filterData(String jenis) {
    setState(() {
      selectedFilter = jenis;

      if (jenis == 'Semua') {
        filteredData = data;
      } else {
        filteredData = data.where((item) {
          return item['jenis_nilai']
              .toString()
              .toLowerCase()
              .contains(jenis.toLowerCase());
        }).toList();
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | WARNA NILAI
  |--------------------------------------------------------------------------
  */
  Color nilaiColor(int nilai) {
    if (nilai >= 85) {
      return Colors.green;
    }

    if (nilai >= 75) {
      return Colors.orange;
    }

    return Colors.red;
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
  void initState() {
    super.initState();
    getNilai();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff273c75),
        elevation: 0,
        title: const Text(
          'Nilai Saya',
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
                        Icons.assignment,
                        size: 90,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Belum Ada Nilai',
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
                            'Total Data Nilai',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data.length} Nilai',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
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
                          filterButton('Tugas'),
                          filterButton('UH'),
                          filterButton('UTS'),
                          filterButton('UAS'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    /*
          |--------------------------------------------------------------------------
          | LIST NILAI
          |--------------------------------------------------------------------------
          */
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final item = filteredData[index];

                          int nilai =
                              int.tryParse(item['nilai'].toString()) ?? 0;

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /*
                      |--------------------------------------------------------------------------
                      | ICON NILAI
                      |--------------------------------------------------------------------------
                      */
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: nilaiColor(nilai)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.assignment,
                                    color: nilaiColor(nilai),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 15),

                                /*
                      |--------------------------------------------------------------------------
                      | DETAIL NILAI
                      |--------------------------------------------------------------------------
                      */
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['nama_mapel'],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Jenis : ${item['jenis_nilai']}',
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Semester : ${item['semester']}',
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Tahun Ajaran : ${item['tahun_ajaran']}',
                                      ),

                                      /*
                            |--------------------------------------------------------------------------
                            | KETERANGAN GURU
                            |--------------------------------------------------------------------------
                            */
                                      if (item['keterangan'] != null &&
                                          item['keterangan']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                color: Colors.orange,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item['keterangan'],
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                /*
                      |--------------------------------------------------------------------------
                      | NILAI
                      |--------------------------------------------------------------------------
                      */
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: nilaiColor(nilai)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    nilai.toString(),
                                    style: TextStyle(
                                      color: nilaiColor(nilai),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
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
}
