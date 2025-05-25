// ignore_for_file: use_build_context_synchronously, avoid_print, unused_element, unused_import, unnecessary_cast, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, avoid_types_as_parameter_names, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wevent3/screens/edit_sub_category_screen.dart';
import '../services/database_helper.dart';
import '../widgets/add_participant_form.dart';
import '../models/participant_model.dart';
import '../widgets/sub_category_list.dart';
import '../widgets/participants_list.dart';
import '../widgets/manage_event_fab.dart';
import 'sub_sub_category_detail_screen.dart';
import 'attendance_list_screen.dart';
import 'bracket_screen.dart';
import 'edit_participant_screen.dart';
// import '../services/share_helper.dart';
import '../models/event_model.dart';

class SubCategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subCategoryData;
  final Event event;
  const SubCategoryDetailScreen({
    super.key,
    required this.subCategoryData,
    required this.event, 
  });

  @override
  _SubCategoryDetailScreenState createState() => _SubCategoryDetailScreenState();
}

class _SubCategoryDetailScreenState extends State<SubCategoryDetailScreen> {
  final _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _subCategoriesLevel3 = [];
  List<Participant> _participantsInSubCategory = [];
  List<Map<String, dynamic>> _filteredSubCategoriesLevel3 = [];
  List<Participant> _filteredParticipantsInSubCategory = [];
  Set<int> _absencedParticipantIdsInSubCategory = {};
  bool _isLoadingAttendanceSubCategory = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _loadInitialData();
    print('Data diterima di SubCategoryDetailScreen: ${widget.subCategoryData}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    query = query.toLowerCase();
    setState(() {
      _filteredSubCategoriesLevel3 = _subCategoriesLevel3
          .where((sub) => sub['nama']?.toLowerCase().contains(query) ?? false)
          .toList();
      _filteredParticipantsInSubCategory = _participantsInSubCategory
          .where((participant) => participant.nama?.toLowerCase().contains(query) ?? false)
          .toList();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingAttendanceSubCategory = true;
    });
    try {
      final subCategoryId = widget.subCategoryData['id'];
      final eventId = widget.subCategoryData['event_id'];
      print('_loadInitialData: subCategoryId = $subCategoryId, eventId = $eventId');
      if (subCategoryId == null || eventId == null) {
        _showErrorSnackBar('ID Subkategori atau Event tidak valid saat memuat data awal.');
        return;
      }
      await _loadSubCategoriesLevel3(subCategoryId as int, eventId as int);
      await _loadParticipantsInSubCategory(subCategoryId as int);
      await _loadAbsencedParticipantsInSubCategory(subCategoryId as int);
      setState(() {
        _initialLoadDone = true;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data awal: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingAttendanceSubCategory = false;
      });
    }
  }

  Future<void> _loadAbsencedParticipantsInSubCategory(int subCategoryId) async {
    setState(() {
      _isLoadingAttendanceSubCategory = true;
    });
    try {
      final List<Map<String, dynamic>> attendanceData =
          await _databaseHelper.getAttendanceBySubCategory(widget.subCategoryData['event_id'] as int, subCategoryId);
      setState(() {
        _absencedParticipantIdsInSubCategory = attendanceData
            .where((item) => item['is_present'] == 0)
            .map((item) => item['participant_id'] as int)
            .toSet();
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data absensi: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingAttendanceSubCategory = false;
      });
    }
  }

  Future<void> _loadSubCategoriesLevel3(int parentId, int eventId) async {
    print('_loadSubCategoriesLevel3 dimulai dengan parentId: $parentId, eventId: $eventId');
    try {
      final subCategories = await _databaseHelper.getSubCategoriesByParent(parentId, eventId);
      setState(() {
        _subCategoriesLevel3 = subCategories;
        _filteredSubCategoriesLevel3 = List.from(_subCategoriesLevel3);
      });
      print('_loadSubCategoriesLevel3 selesai, jumlah data: ${_subCategoriesLevel3.length}');
    } catch (e) {
      _showErrorSnackBar('Gagal memuat subkategori level 3: ${e.toString()}');
    }
  }

  Future<void> _deleteSubCategoryLevel3(int? subCategoryId) async {
    if (subCategoryId == null) {
      _showErrorSnackBar('ID Subkategori Level 3 tidak valid.');
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple[700],
          title: const Text('Konfirmasi Hapus', style: TextStyle(color: Colors.yellow)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus subkategori ini?', style: TextStyle(color: Colors.white)),
                Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.white70)),
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
                setState(() {
                  _isLoadingAttendanceSubCategory = true;
                });
                try {
                  final result = await _databaseHelper.deleteSubCategory(subCategoryId);
                  if (result > 0) {
                    _showSnackBar('Subkategori berhasil dihapus.');
                    _loadSubCategoriesLevel3(
                      widget.subCategoryData['id'] as int,
                      widget.subCategoryData['event_id'] as int,
                    );
                  } else {
                    _showErrorSnackBar('Gagal menghapus subkategori.');
                  }
                } catch (e) {
                  _showErrorSnackBar('Terjadi kesalahan saat menghapus: ${e.toString()}');
                } finally {
                  setState(() {
                    _isLoadingAttendanceSubCategory = false;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadParticipantsInSubCategory(int subCategoryId) async {
    print('_loadParticipantsInSubCategory dimulai dengan subCategoryId: $subCategoryId');
    try {
      final participants = await _databaseHelper.getParticipantsBySubCategory(subCategoryId);
      setState(() {
        _participantsInSubCategory = participants;
        _filteredParticipantsInSubCategory = List.from(_participantsInSubCategory);
      });
      print('_loadParticipantsInSubCategory selesai, jumlah data peserta: ${_participantsInSubCategory.length}');
    } catch (e) {
      _showErrorSnackBar('Gagal memuat peserta untuk subkategori: ${e.toString()}');
    }
  }

  Future<Event?> _getEventData(int eventId) async {
    try {
      final eventData = await _databaseHelper.getEventById(eventId);
      return eventData;
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil data Event: ${e.toString()}');
      return null;
    }
  }

  Future<void> _markParticipantAttendanceInSubCategory(Participant participant) async {
    if (participant.id == null || widget.subCategoryData['event_id'] == null || widget.subCategoryData['id'] == null) {
      _showErrorSnackBar('Data peserta, event, atau subkategori tidak valid.');
      return;
    }
    setState(() {
      _isLoadingAttendanceSubCategory = true;
    });
    try {
      final isCurrentlyAbsent = _absencedParticipantIdsInSubCategory.contains(participant.id);
      final result = await _databaseHelper.markAttendance(
        participant.id!,
        widget.subCategoryData['event_id'] as int,
        widget.subCategoryData['id'] as int,
        present: !isCurrentlyAbsent,
      );
      if (result > 0) {
        setState(() {
          if (!isCurrentlyAbsent) {
            _absencedParticipantIdsInSubCategory.add(participant.id!);
            print('Absen: ID ${participant.id} ditambahkan ke _absencedParticipantIdInSubCategory');
          } else {
            _absencedParticipantIdsInSubCategory.remove(participant.id!);
            print('Hapus Absen: ID ${participant.id} dihapus dari _absencedParticipantIdInSubCategory');
          }
        });
        _showSnackBar('${participant.nama} berhasil ${!isCurrentlyAbsent ? 'diabsenkan' : 'dihapus dari absen'}.');
      } else {
        _showErrorSnackBar('Gagal memperbarui absensi ${participant.nama}.');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingAttendanceSubCategory = false;
      });
    }
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

  //==========================share helper start=========================
  
  
  //=========================== share helper end ==========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subCategoryData['nama']}', style: const TextStyle(color: Colors.yellow)),
      backgroundColor:  const Color(0xFF142A6B), 
    
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.share, color: Colors.white),
        //     onPressed: _showShareOptions,
        //   ),
        // ],
      ),
      body: Container(
        // color: Colors.deepPurple[800],
        color:  const Color(0xFF0D1B52),
        child: _isLoadingAttendanceSubCategory && !_initialLoadDone
            ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
            : Column(
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
                  fillColor:   Color(0xFF0D47A1), 
                ),
                onChanged: (value) => _onSearchChanged(value),
              ),
            ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (_filteredSubCategoriesLevel3.isNotEmpty)
                            const Text('Subkategori',
                                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.yellow)),
                          SubCategoryList(
                            subCategories: _filteredSubCategoriesLevel3,
                            onSubCategoryTap: (sub) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubSubCategoryDetailScreen(
                                    subCategoryData: sub,
                                    event: widget.event,
                                    ),
                                ),
                              );
                            },
                            onDeleteSubCategory: _deleteSubCategoryLevel3,
                            onEditSubCategory: (Map<String, dynamic> subCategory) {
                              showEditSubCategoryScreen(
                              context: context,
                              subCategory: subCategory,
                              onSubCategoryUpdated: () => _loadSubCategoriesLevel3(
                                  widget.subCategoryData['id'] as int,
                                  widget.subCategoryData['event_id'] as int,
                                    ),
                            ); 
                            },
                          ),
                          if (_filteredParticipantsInSubCategory.isNotEmpty)
                            const SizedBox(height: 16.0),
                          if (_filteredParticipantsInSubCategory.isNotEmpty)
                            const Text('Peserta',
                                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.yellow)),
                          ParticipantsList(
                            participants: _filteredParticipantsInSubCategory,
                            absencedParticipantIds: _absencedParticipantIdsInSubCategory,
                            onAbsenParticipant: _markParticipantAttendanceInSubCategory,
                            onEditParticipant: (participant) async {
                              final eventId = widget.subCategoryData['event_id'] as int?;
                              if (eventId == null) {
                                _showErrorSnackBar('ID Event tidak valid.');
                                return;
                              }
                              final eventData = await _getEventData(eventId);
                              if (eventData != null) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) { 
                                    return EditParticipantScreen(
                                      participant: participant,
                                      event: eventData,
                                      onParticipantUpdated: () => _loadParticipantsInSubCategory(widget.subCategoryData['id'] as int),
                                    );
                                  },
                                );
                              } else {
                                _showErrorSnackBar('Data Event tidak ditemukan, tidak dapat mengedit peserta.');
                              }
                            },
                            onDeleteParticipant: _deleteParticipant3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: ManageEventFab(
        onAddParticipant: () => _addParticipant(context, participant: null),
        onAddSubCategory: () => _addSubCategoryLevel3Dialog(context),
        onViewAttendance: () async {
          final eventData = await _databaseHelper.getEventById(widget.subCategoryData['event_id'] as int);
          if (eventData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceListScreen(
                  subCategory: widget.subCategoryData,
                  event: eventData,
                ),
              ),
            );
          } else {
            _showErrorSnackBar('Data Event tidak ditemukan.');
          }
        },
        onManageBracket: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BracketScreen(
                      event: widget.event, 
                      initialParticipants: _participantsInSubCategory,
                      subCategory: widget.subCategoryData,
                  ),
              ),
          );
      },
         onShare: () {  },

// ... onShare: () {  },
      ),
    );
  }

  Future<void> _addSubCategoryLevel3Dialog(BuildContext context) async {
    final subCategoryLevel3Controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
             backgroundColor: const Color(0xFF0D47A1),
          title: const Text('Tambah Subkategori', style: TextStyle(color: Colors.yellow)),
          content: TextField(
            controller: subCategoryLevel3Controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nama Subkategori',
              labelStyle: TextStyle(color: Colors.yellow),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.yellow),
              child: const Text('Tambah'),
              onPressed: () async {
                final subCategoryName = subCategoryLevel3Controller.text.trim();
                if (subCategoryName.isNotEmpty) {
                  final result = await _databaseHelper.insertSubCategory(
                    subCategoryName,
                    widget.subCategoryData['event_id'] as int,
                    parentId: widget.subCategoryData['id'] as int,
                  );
                  if (result > 0) {
                    _loadSubCategoriesLevel3(
                      widget.subCategoryData['id'] as int,
                      widget.subCategoryData['event_id'] as int,
                    );
                    Navigator.of(context).pop();
                  } else {
                    _showErrorSnackBar('Gagal menambahkan subkategori level 3.');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteParticipant3(Participant participant) async {
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
                Text('Apakah Anda yakin ingin menghapus peserta "${participant.nama}"?',
                    style: TextStyle(color: Colors.white)),
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
                setState(() {
                  _isLoadingAttendanceSubCategory = true;
                });
                try {
                  final result = await _databaseHelper.deleteParticipant(participant.id!);
                  if (result > 0) {
                    _showSnackBar('Peserta "${participant.nama}" berhasil dihapus.');
                    _loadParticipantsInSubCategory(widget.subCategoryData['id'] as int);
                  } else {
                    _showErrorSnackBar('Gagal menghapus peserta "${participant.nama}".');
                  }
                } catch (e) {
                  _showErrorSnackBar('Terjadi kesalahan saat menghapus: ${e.toString()}');
                } finally {
                  setState(() {
                    _isLoadingAttendanceSubCategory = false;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addParticipant(BuildContext context, {Participant? participant}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
             backgroundColor:  const Color(0xFF0D47A1), 
          title: Text(participant == null ? 'Tambah Peserta' : 'Edit Peserta',
              style: const TextStyle(color: Colors.yellow)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              child: AddParticipantForm(
                eventId: widget.subCategoryData['event_id'].toString(),
                subCategoryId: widget.subCategoryData['id'].toString(),
                onParticipantAdded: () =>
                    _loadParticipantsInSubCategory(widget.subCategoryData['id'] as int),
                participant: participant,
              ),
            ),
          ),
        );
      },
    );
  }
}