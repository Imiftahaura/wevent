// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:wevent3/screens/edit_sub_category_screen.dart';
import '../models/event_model.dart';
import '../services/database_helper.dart';
// import '../services/share_helper.dart';
import '../widgets/add_participant_form.dart';
import '../models/participant_model.dart';
import '../screens/attendance_list_screen.dart';
import '../screens/bracket_screen.dart';
import '../screens/sub_category_detail_screen.dart';
import '../widgets/sub_category_list.dart' as widgets;
import '../widgets/participants_list.dart';
import '../widgets/manage_event_fab.dart';
import '../screens/edit_participant_screen.dart';


class ManageEventScreen extends StatefulWidget {
  final Event event;

  const ManageEventScreen({super.key, required this.event});

  @override
  _ManageEventScreenState createState() => _ManageEventScreenState();
}

class _ManageEventScreenState extends State<ManageEventScreen> {
  final _searchController = TextEditingController();
  final _databaseHelper = DatabaseHelper();

  List<Map<String, dynamic>> _subCategories = [];
  List<Participant> _participants = [];
  List<Map<String, dynamic>> _filteredSubCategories = [];
  List<Participant> _filteredParticipants = [];
  Set<int> _absencedParticipantIds = {};
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
    _loadAbsencedParticipants();
  }

  Future<void> _loadAbsencedParticipants() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Map<String, dynamic>> attendanceData =
          await _databaseHelper.getAttendanceByEvent(widget.event.id!);
      setState(() {
        _absencedParticipantIds = attendanceData
            .where((item) => item['is_present'] == 0)
            .map((item) => item['participant_id'] as int)
            .toSet();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data absensi: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _loadSubCategories();
      await _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data awal: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      final searchText = _searchController.text.toLowerCase().trim();
      _filteredSubCategories = _subCategories
          .where((sub) => sub['nama']!.toLowerCase().contains(searchText))
          .toList();
      _filteredParticipants = _participants
          .where((participant) =>
              participant.nama!.toLowerCase().contains(searchText))
          .toList();
    });
  }

  Future<void> _loadSubCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'subcategories',
        where: 'event_id = ? AND parent_id IS NULL',
        whereArgs: [widget.event.id!],
      );
      setState(() {
        _subCategories = List.generate(
        maps.length, (i) => {
          'id': maps[i]['id'], 
          'nama': maps[i]['nama'] as String,
          'event_id': widget.event.id!,
          });
        _filteredSubCategories = List.from(_subCategories);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat subkategori: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

//=================  Start   ====  sub category level 2 =========================================================== 
//========* add sub category  *========
  Future<void> _addSubCategory(BuildContext context) async {
  final subCategoryController = TextEditingController();
  final formKey = GlobalKey<FormState>(); 
  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) { 
      return AlertDialog(
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
        title: const Text(
          'Tambah Subkategori', 
          style: TextStyle(color: Colors.yellow, fontSize: 16),
        ),
        content: Form( 
          key: formKey, 
          child: TextFormField(
            controller: subCategoryController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration( 
                labelText: 'nama subkategori ', labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder( borderSide: BorderSide(color: Colors.yellow),),
                focusedBorder: OutlineInputBorder( borderSide: BorderSide(color: Colors.yellow),),
              ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama subkategori wajib diisi'; 
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Batal'),
            onPressed: () => Navigator.of(dialogContext).pop(), 
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.yellow), 
            child: const Text('Tambah'),
            onPressed: () async {
              if (formKey.currentState!.validate()) { 
                final subCategoryName = subCategoryController.text.trim();
                setState(() {
                  _isLoading = true;
                });
              
              try {
                final result = await _databaseHelper.insertSubCategory(subCategoryName, widget.event.id!);
                  if (result > 0) {
                    await _loadSubCategories();
                    Navigator.of(dialogContext).pop(); 
                    ScaffoldMessenger.of(context).showSnackBar( 
                      const SnackBar(
                        content: Text('Subkategori berhasil ditambahkan.', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar( 
                      const SnackBar(
                        content: Text('Gagal menambahkan subkategori.', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar( 
                    SnackBar(
                      content: Text('Terjadi kesalahan: ${e.toString()}', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        ],
      );
    },
  );
}

//=========== delete sub category   =======
  Future<void> _deleteSubCategory2(int? subCategoryId) async {
  if (subCategoryId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID Subkategori tidak valid.')),
    );
    return;
  }
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.deepPurple[700],
        title: const Text('Konfirmasi Hapus Subkategori', style: TextStyle(color: Colors.yellow)),
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
              Navigator.of(context).pop(); // Tutup dialog sebelum eksekusi
              setState(() {
                _isLoading = true;
              });
              try {
                final result = await _databaseHelper.deleteSubCategory(subCategoryId);
                if (result > 0) {
                  await _loadSubCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subkategori berhasil dihapus.', style: TextStyle(color: Colors.yellow)),
                      backgroundColor: Colors.deepOrangeAccent,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus subkategori.', style: TextStyle(color: Colors.yellow)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        ],
      );
    },
  );
}

//================================End part sub catgeory ==========================
//
//
//================================ Start  Participant ============================

// ini cradnya si add particicpnat nanti dipindahin 
  void _showAddParticipantFormDialog(BuildContext context,
      {Participant? participant}) async {
        
    await showDialog(
      context: context,
      
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:  const Color(0xFF0D47A1), 
          title: Text(participant == null ? 'Tambah Peserta' : 'Edit Peserta',
              style: const TextStyle(color: Colors.yellow)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.2),
              child: AddParticipantForm(
                eventId: widget.event.id.toString(),
                onParticipantAdded: _loadParticipants,
                participant: participant, subCategoryId: null, 
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final participants =
          await _databaseHelper.getParticipantsByEvent(widget.event.id!);
          print('Data peserta dari database (sebelum filter):');
          for (var p in participants) {
            print('ID: ${p.id}, Nama: ${p.nama}, SubCategoryId: ${p.subCategoryId}');
          }
      setState(() {
        _participants = participants.where((p) => p.subCategoryId == null).toList();
        _filteredParticipants = List.from(_participants);
      });
      print(
          'Reloaded participants for ${widget.event.nama}: ${_participants.length} found');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat peserta: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _markParticipantAttendance(Participant participant) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await _databaseHelper.markAttendance(
          participant.id!,
           widget.event.id!, 0, 
           present: true); 
      if (result > 0) {
        setState(() {
          _absencedParticipantIds.add(participant.id!);
          _participants.removeWhere((p) => p.id == participant.id);
          _participants.add(participant);
          _filteredParticipants.removeWhere((p) => p.id == participant.id);
          _filteredParticipants.add(participant);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${participant.nama} telah diabsenkan.',
                  style: const TextStyle(color: Colors.yellow)),
              backgroundColor: Colors.grey[700]),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengabsenkan ${participant.nama}.',
                  style: const TextStyle(color: Colors.yellow)),
              backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _deleteparticipant2(Participant participant) async {
  if (participant.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID Peserta tidak valid.')),
    );
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
                  style: const TextStyle(color: Colors.white)),
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
              Navigator.of(context).pop(); 
              setState(() {
                _isLoading = true;
              });

              try {
                final result = await _databaseHelper.deleteParticipant(participant.id!);
                if (result > 0) {
                  setState(() {
                    _participants.removeWhere((p) => p.id == participant.id);
                    _filteredParticipants.removeWhere((p) => p.id == participant.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${participant.nama} berhasil dihapus.',
                          style: const TextStyle(color: Colors.yellow)),
                      backgroundColor: Colors.deepOrangeAccent,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus ${participant.nama}.',
                          style: const TextStyle(color: Colors.yellow)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
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
        title: Text('${widget.event.nama}', style: const TextStyle(color: Colors.yellow)),
         backgroundColor:  const Color(0xFF142A6B),
      ),
      body: Container(
        color:  const Color(0xFF0D1B52),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Colors
                        .yellow), 
              )
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
                onChanged: (value) => _onSearchChanged(),
              ),
            ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (_filteredSubCategories.isNotEmpty)
                            const Text('Subkategori',
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow)),
                                    widgets.SubCategoryList(
                                      subCategories: _filteredSubCategories,
                                      onSubCategoryTap: (sub) {
                                        print('Subkategori "${sub['nama']}" diklik!');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SubCategoryDetailScreen(
                                                  subCategoryData: sub,
                                                  event: widget.event, 
                                                  ),
                                          ),
                                        );
                                      },
                            onDeleteSubCategory: _deleteSubCategory2, 
                            onEditSubCategory: (subCategory) {
                              showEditSubCategoryScreen(
                                context: context,
                                subCategory: subCategory,
                                onSubCategoryUpdated: _loadSubCategories,
                              );
                            },

                                       
                          ),
                          if (_filteredParticipants.isNotEmpty)
                            const SizedBox(height: 16.0),
                          if (_filteredParticipants.isNotEmpty)
                            const Text('Peserta',
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow)),
                                    ParticipantsList(
                                      participants: _filteredParticipants,
                                      absencedParticipantIds: _absencedParticipantIds,
                                      onAbsenParticipant: _markParticipantAttendance,
                                      onEditParticipant: (participant) {
                                        showDialog( 
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return EditParticipantScreen(
                                            participant: participant,
                                            event: widget.event,
                                            onParticipantUpdated: _loadParticipants,
                                          );
                                        },
                                      );
                                    },
                                      onDeleteParticipant: _deleteparticipant2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: ManageEventFab(
        onAddParticipant: () => _showAddParticipantFormDialog(context),
        onAddSubCategory: () => _addSubCategory(context),
        // onManualAttendance: () => _showManualAttendanceDialog(context),
        onViewAttendance: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceListScreen(
                  event: widget.event, subCategory: const {}),
            ),
          );
        },
    
       onManageBracket: () async {// Tambahkan ini
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BracketScreen(
                event: widget.event,
                initialParticipants: _participants,
                subCategory: null, 
              ),
            ),
          );
        }, onShare: () {  },
      
      ),
    );
  }
}

