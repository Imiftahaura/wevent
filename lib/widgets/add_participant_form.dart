// lib/widgets/add_participant_form.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/participant_model.dart';

class AddParticipantForm extends StatefulWidget {
  final String eventId;
  final VoidCallback onParticipantAdded;
  final String? subCategoryId;

  const AddParticipantForm({
    super.key,
    required this.eventId,
    required this.onParticipantAdded,
    this.subCategoryId,
    Participant? participant,
  });

  @override
  _AddParticipantFormState createState() => _AddParticipantFormState();
}

class _AddParticipantFormState extends State<AddParticipantForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kategoriController = TextEditingController(); 
  final _umurController = TextEditingController();
  final _namaClubSekolahController = TextEditingController(); 
  final DatabaseHelper _databaseHelper = DatabaseHelper();

 
  late FocusNode _namaFocusNode;
  late FocusNode _kategoriFocusNode; 
  late FocusNode _umurFocusNode;
  late FocusNode _namaClubSekolahFocusNode; 

  @override
  void initState() {
    super.initState();
    _namaFocusNode = FocusNode();
    _kategoriFocusNode = FocusNode();
    _umurFocusNode = FocusNode();
    _namaClubSekolahFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _umurController.dispose();
    _namaClubSekolahController.dispose();
    _namaFocusNode.dispose();
    _kategoriFocusNode.dispose();
    _umurFocusNode.dispose();
    _namaClubSekolahFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addParticipant() async {
    print('Nilai widget.eventId sebelum parsing: ${widget.eventId}');
    int? parsedEventId = int.tryParse(widget.eventId);
    if (parsedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID Event tidak valid.')),
      );
      return;
    }
    print('Event ID yang di-parse: $parsedEventId');
    if (_formKey.currentState!.validate()) {
      final newParticipant = Participant(
        nama: _namaController.text.trim(),
        kategori: _kategoriController.text.trim(), 
        umur: _umurController.text.isNotEmpty ? int.tryParse(_umurController.text) : null,
        namaClubSekolah: _namaClubSekolahController.text.trim(), 
        eventId: parsedEventId,
        subCategoryId: widget.subCategoryId != null ? int.parse(widget.subCategoryId!) : null,
      );

      final existingParticipants = await _databaseHelper.getParticipantsByEvent(parsedEventId);

      final isDuplicate = existingParticipants.any((p) =>
          p.nama?.toLowerCase() == newParticipant.nama?.toLowerCase() &&
          p.subCategoryId == newParticipant.subCategoryId);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peserta dengan nama ini sudah ada dalam kategori ini.')),
        );
        return;
      }

      int result = await _databaseHelper.insertParticipant(newParticipant);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peserta berhasil ditambahkan!')),
        );
        widget.onParticipantAdded();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan peserta. Coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellowColor = Colors.yellow[700];
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _namaController,
            focusNode: _namaFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              _namaFocusNode.unfocus();
              FocusScope.of(context).requestFocus(_kategoriFocusNode);
            },
            style: TextStyle(color: yellowColor),
            decoration: InputDecoration(
              labelText: 'Nama Peserta / Club', 
              labelStyle: TextStyle(color: yellowColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor!)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor))),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama peserta / club tidak boleh kosong';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _kategoriController, 
            focusNode: _kategoriFocusNode,
            textInputAction: TextInputAction.newline, 
            keyboardType: TextInputType.multiline, 
            maxLines: null, 
            style: TextStyle(color: yellowColor),
            decoration: InputDecoration(
              labelText: 'Deskripsi (Opsional)', 
              labelStyle: TextStyle(color: yellowColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor))),
         
          ),
          TextFormField(
            controller: _umurController,
            focusNode: _umurFocusNode,
            textInputAction: TextInputAction.next, 
            onFieldSubmitted: (value) {
              _umurFocusNode.unfocus();
              FocusScope.of(context).requestFocus(_namaClubSekolahFocusNode); 
            },
            style: TextStyle(color: yellowColor),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Umur (Opsional)',
              labelStyle: TextStyle(color: yellowColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor))),
          ),
          TextFormField(
            controller: _namaClubSekolahController, 
            focusNode: _namaClubSekolahFocusNode,
            textInputAction: TextInputAction.done, 
            onFieldSubmitted: (value) {
              _namaClubSekolahFocusNode.unfocus();
              _addParticipant(); 
            },
            style: TextStyle(color: yellowColor),
            decoration: InputDecoration(
              labelText: 'Alamat/Asal (Opsional)', 
              labelStyle: TextStyle(color: yellowColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: yellowColor))),
          
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Batal', style: TextStyle(color: yellowColor)),
              ),
              const SizedBox(width: 16.0),
              GestureDetector(
                onTap: _addParticipant,
                child: Text(
                  'Simpan Peserta',
                  style: TextStyle(color: yellowColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}