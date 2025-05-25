// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import '../models/event_model.dart'; 
import '../services/database_helper.dart'; 
import 'package:intl/intl.dart'; 

class AttendanceListScreen extends StatefulWidget {
  final Event event;

  const AttendanceListScreen({super.key, required this.event, required Map<String, dynamic> subCategory});

  @override
  // ignore: library_private_types_in_public_api
  _AttendanceListScreenState createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _attendanceList = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final attendanceData = await _databaseHelper.getAttendanceByEvent(widget.event.nama! as int);
    setState(() {
      _attendanceList = attendanceData;
    });
  }

  Future<String> _getParticipantName(int participantId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'participants',
      where: 'id = ?',
      whereArgs: [participantId],
      columns: ['nama'],
    );
    if (result.isNotEmpty) {
      return result.first['nama'] as String;
    }
    return 'Nama Tidak Ditemukan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Absensi: ${widget.event.nama}'),
      ),
      body: _attendanceList.isEmpty
          ? const Center(child: const Text('Belum ada data absensi untuk event ini.'))
          : ListView.builder(
              itemCount: _attendanceList.length,
              itemBuilder: (context, index) {
                final attendance = _attendanceList[index];
                return FutureBuilder<String>(
                  future: _getParticipantName(attendance['participant_id'] as int),
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                    String participantName = 'Memuat Nama...';
                    if (snapshot.hasData) {
                      participantName = snapshot.data!;
                    } else if (snapshot.hasError) {
                      participantName = 'Gagal Memuat Nama';
                    }
                    final dateTime = DateTime.fromMillisecondsSinceEpoch(attendance['attendance_time'] as int);
                    final formattedTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Peserta: $participantName',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text('Waktu Absen: $formattedTime'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}