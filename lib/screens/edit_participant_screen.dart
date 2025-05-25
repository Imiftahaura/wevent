// lib/screens/edit_participant_screen.dart
// ignore_for_file: prefer_final_fields, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';
import '../services/database_helper.dart';

class EditParticipantScreen extends StatefulWidget {
  final Event event;
  final Participant participant;
  final VoidCallback onParticipantUpdated;

  const EditParticipantScreen({
    super.key,
    required this.event,
    required this.participant,
    required this.onParticipantUpdated,
  });

  @override
  _EditParticipantScreenState createState() => _EditParticipantScreenState();
}

class _EditParticipantScreenState extends State<EditParticipantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _umurController;
  late TextEditingController _kategoriController; 
  late TextEditingController _namaClubSekolahController; 
  String? _selectedSubCategory; 
  final _databaseHelper = DatabaseHelper.instance;
  bool _isLoading = false;

 
  late FocusNode _namaFocusNode;
  late FocusNode _deskripsiFocusNode; 
  late FocusNode _umurFocusNode;
  late FocusNode _alamatFocusNode; 

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.participant.nama ?? '');
    _umurController = TextEditingController(text: widget.participant.umur?.toString() ?? '');
    _kategoriController = TextEditingController(text: widget.participant.kategori ?? ''); 
    _namaClubSekolahController = TextEditingController(text: widget.participant.namaClubSekolah ?? ''); 

    _namaFocusNode = FocusNode();
    _deskripsiFocusNode = FocusNode();
    _umurFocusNode = FocusNode();
    _alamatFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _umurController.dispose();
    _kategoriController.dispose();
    _namaClubSekolahController.dispose();
    _namaFocusNode.dispose();
    _deskripsiFocusNode.dispose();
    _umurFocusNode.dispose();
    _alamatFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateParticipant() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; 
      });
      try {
        final updatedParticipant = Participant(
          id: widget.participant.id,
          nama: _namaController.text.trim(),
          umur: _umurController.text.isNotEmpty ? int.tryParse(_umurController.text) : null,
          kategori: _kategoriController.text.trim(), 
          namaClubSekolah: _namaClubSekolahController.text.trim(), 
          eventId: widget.event.id,
          subCategoryId: widget.participant.subCategoryId,
        );

        final result = await _databaseHelper.updateParticipant(updatedParticipant);
        if (result > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data peserta berhasil diperbarui.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
          widget.onParticipantUpdated();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui data peserta.', style: TextStyle(color: Colors.white)),
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
  }

  @override
  Widget build(BuildContext context) {
    final yellowColor = Colors.yellow[700];
    return AlertDialog(
      backgroundColor: const Color(0xFF0D47A1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      title: Text(
        'Edit Peserta',
        style: const TextStyle(color: Colors.yellow),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 50,
              child: Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _namaController,
                      focusNode: _namaFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (value) {
                        _namaFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_deskripsiFocusNode); 
                      },
                      style: TextStyle(color: yellowColor),
                      decoration: InputDecoration(
                        labelText: 'Nama Peserta / Club', 
                        labelStyle: TextStyle(color: yellowColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor!)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama peserta / club tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _kategoriController, 
                      focusNode: _deskripsiFocusNode,
                      textInputAction: TextInputAction.newline, 
                      keyboardType: TextInputType.multiline,
                      maxLines: null, 
                      style: TextStyle(color: yellowColor),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (Opsional)', 
                        labelStyle: TextStyle(color: yellowColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                      ),
                
                    ),
                    TextFormField(
                      controller: _umurController,
                      focusNode: _umurFocusNode,
                      textInputAction: TextInputAction.next, 
                      onFieldSubmitted: (value) {
                        _umurFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_alamatFocusNode); 
                      },
                      style: TextStyle(color: yellowColor),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Umur (Opsional)',
                        labelStyle: TextStyle(color: yellowColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                      ),
                    ),
                    TextFormField(
                      controller: _namaClubSekolahController, 
                      focusNode: _alamatFocusNode,
                      textInputAction: TextInputAction.done, 
                      onFieldSubmitted: (value) {
                        _alamatFocusNode.unfocus();
                        _updateParticipant(); 
                      },
                      style: TextStyle(color: yellowColor),
                      decoration: InputDecoration(
                        labelText: 'Alamat (Opsional)', 
                        labelStyle: TextStyle(color: yellowColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
                      ),
                  
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Batal', style: TextStyle(color: yellowColor)),
        ),
        const SizedBox(width: 16.0),
        GestureDetector(
          onTap: _isLoading ? null : _updateParticipant,
          child: Text(
            'Simpan Perubahan',
            style: TextStyle(
              color: _isLoading ? Colors.grey : yellowColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}