// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; 
import '../services/database_helper.dart';
import '../widgets/add_participant_form.dart';
import '../models/participant_model.dart';
import '../widgets/participants_list.dart';
import '../widgets/manage_event_fab.dart';
import 'attendance_list_screen.dart';
import 'bracket_screen.dart';
import 'edit_participant_screen.dart';
import '../models/event_model.dart';

class SubSubCategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subCategoryData;
  final Event event;
  // final int eventId;

  const SubSubCategoryDetailScreen({super.key, 
  required this.subCategoryData, 
  required this.event});

  @override
  _SubSubCategoryDetailScreenState createState() => _SubSubCategoryDetailScreenState();
}

class _SubSubCategoryDetailScreenState extends State<SubSubCategoryDetailScreen> {
  final _searchController = TextEditingController();
  final _databaseHelper = DatabaseHelper();
  List<Participant> _participantsInSubSubCategory = [];
  List<Participant> _filteredParticipantsInSubSubCategory = [];
  Set<int> _absencedParticipantIdsInSubSubCategory = {};
  bool _isLoadingAttendanceSubSubCategory = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadParticipantsInSubSubCategory().then((_) {
      _loadAbsencedParticipantsInSubSubCategory(widget.subCategoryData['id'] as int);
      setState(() { _initialLoadDone = true; });
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      final searchText = _searchController.text.toLowerCase().trim();
      _filteredParticipantsInSubSubCategory = _participantsInSubSubCategory
          .where((participant) => participant.nama!.toLowerCase().contains(searchText))
          .toList();
    });
  }

  void _showSnackBar(String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _showErrorSnackBar(String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    });
  }

  Future<void> _loadParticipantsInSubSubCategory() async {
    final participants = await _databaseHelper.getParticipantsBySubCategory(widget.subCategoryData['id'] as int);
    setState(() {
      _participantsInSubSubCategory = participants;
      _filteredParticipantsInSubSubCategory = List.from(_participantsInSubSubCategory);
    });
    print('Reloaded participants for sub-subcategory "${widget.subCategoryData['nama']}": ${_participantsInSubSubCategory.length} found');
  }

  void _showAddParticipantFormDialog(BuildContext context, {int? subCategoryId}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
             backgroundColor:  const Color(0xFF0D47A1), 
          title: const Text('Tambah Peserta', style: TextStyle(color: Colors.yellow)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              child: AddParticipantForm(
                eventId: widget.subCategoryData['event_id'].toString(),
                subCategoryId: widget.subCategoryData['id'].toString(),
                onParticipantAdded: _loadParticipantsInSubSubCategory,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAbsencedParticipantsInSubSubCategory(int subSubCategoryId) async {
    setState(() { _isLoadingAttendanceSubSubCategory = true; });
    try {
      final List<Map<String, dynamic>> attendanceData =
          await _databaseHelper.getAttendanceBySubCategory(widget.subCategoryData['event_id'] as int, subSubCategoryId);
      setState(() {
        _absencedParticipantIdsInSubSubCategory = attendanceData
            .where((item) => item['is_present'] == 0)
            .map((item) => item['participant_id'] as int)
            .toSet();
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data absensi: ${e.toString()}');
    } finally {
      setState(() { _isLoadingAttendanceSubSubCategory = false; });
    }
  }

  Future<void> _markParticipantAttendanceInSubSubCategory(Participant participant) async {
    if (participant.id == null || widget.subCategoryData['event_id'] == null || widget.subCategoryData['id'] == null) {
      _showErrorSnackBar('Data peserta, event, atau sub-subkategori tidak valid.');
      return;
    }
    setState(() { _isLoadingAttendanceSubSubCategory = true; });
    try {
      final isCurrentlyAbsent = _absencedParticipantIdsInSubSubCategory.contains(participant.id);
      final result = await _databaseHelper.markAttendance(
        participant.id!,
        widget.subCategoryData['event_id'] as int,
        widget.subCategoryData['id'] as int,
        present: !isCurrentlyAbsent,
      );
      if (result > 0) {
        setState(() {
          if (!isCurrentlyAbsent) {
            _absencedParticipantIdsInSubSubCategory.add(participant.id!);
            print('Absen (Sub-sub): ID ${participant.id} ditambahkan ke _absencedParticipantIdsInSubSubCategory');
          } else {
            _absencedParticipantIdsInSubSubCategory.remove(participant.id!);
            print('Hapus Absen (Sub-sub): ID ${participant.id} dihapus dari _absencedParticipantIdsInSubSubCategory');
          }
        });
        _showSnackBar('${participant.nama} berhasil ${!isCurrentlyAbsent ? 'diabsenkan' : 'dihapus dari absen'}.');
      } else {
        _showErrorSnackBar('Gagal memperbarui absensi ${participant.nama}.');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() { _isLoadingAttendanceSubSubCategory = false; });
    }
  }

  // Fungsi untuk menghapus peserta
  Future<void> _deleteParticipant(Participant participant) async {
    if (participant.id == null) {
      _showErrorSnackBar('ID Peserta tidak valid.');
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple[700],
          title: const Text('Konfirmasi Hapus Peserta', style: TextStyle(color: Colors.yellow)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus peserta "${participant.nama}"?', style: TextStyle(color: Colors.white)),
                const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.yellow),
              child: const Text('Hapus'),
              onPressed: () async {
                setState(() { _isLoadingAttendanceSubSubCategory = true; });
                try {
                  final result = await _databaseHelper.deleteParticipant(participant.id!);
                  if (result > 0) {
                    _showSnackBar('Peserta "${participant.nama}" berhasil dihapus.');
                    _loadParticipantsInSubSubCategory(); 
                  } else {
                    _showErrorSnackBar('Gagal menghapus peserta "${participant.nama}".');
                  }
                } catch (e) {
                  _showErrorSnackBar('Terjadi kesalahan saat menghapus: ${e.toString()}');
                } finally {
                  setState(() { _isLoadingAttendanceSubSubCategory = false; });
                  Navigator.of(context).pop(); 
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subCategoryData['nama']}', style: const TextStyle(color: Colors.yellow)),
        backgroundColor: const Color(0xFF142A6B),
      ),
      body: Container(
        color: const Color(0xFF142A6B),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari Peserta',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(
                   
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:  Color(0xFF0D47A1), 
                ),
                onChanged: (value) => _onSearchChanged(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_filteredParticipantsInSubSubCategory.isNotEmpty)
                      const Text('Peserta', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.yellow)),
                    ParticipantsList(
                      participants: _filteredParticipantsInSubSubCategory,
                      absencedParticipantIds: _absencedParticipantIdsInSubSubCategory,
                      onAbsenParticipant: _markParticipantAttendanceInSubSubCategory,
                                            onEditParticipant: (participant) async {
                        final eventId = widget.subCategoryData['event_id'] as int?;
                        if (eventId == null) {
                          _showErrorSnackBar('ID Event tidak valid.');
                          return;
                        }

                        final eventData = await _databaseHelper.getEventById(eventId);
                        if (eventData != null) {
                         showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) { // Gunakan dialogContext untuk AlertDialog
                              return EditParticipantScreen(
                                participant: participant,
                                event: eventData, // Gunakan data event yang benar
                                onParticipantUpdated: _loadParticipantsInSubSubCategory, // Callback Anda tetap sama
                              );
                            },
                          );
                        } else {
                          _showErrorSnackBar('Data Event tidak ditemukan, tidak dapat mengedit peserta.');
                        }
                      },
                      onDeleteParticipant: _deleteParticipant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ManageEventFab(
        onAddParticipant: () => _showAddParticipantFormDialog(context, subCategoryId: widget.subCategoryData['id'] as int?),
        onAddSubCategory: () {}, // Tidak ada penambahan sub-kategori di level ini
        onViewAttendance: () async {
          final eventId = widget.subCategoryData['event_id'] as int?;
          if (eventId != null) {
            final eventData = await _databaseHelper.getEventById(eventId);
            if (eventData != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceListScreen(
                      subCategory: widget.subCategoryData, event: eventData),
                ),
              );
            } else {
              _showErrorSnackBar('Data Event tidak ditemukan.');
            }
          } else {
            print('Error: event_id tidak ditemukan pada subCategoryData');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak dapat melihat data absensi.')),
            );
          }
        },
        onManageBracket: () {
          Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BracketScreen(
                event: widget.event, // Lewatkan objek Event yang benar
                initialParticipants: _participantsInSubSubCategory,
                subCategory: widget.subCategoryData,
            ),
        ),
    );

        }, onShare: () {  },
      ),
    );
  }
}