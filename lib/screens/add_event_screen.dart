// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_helper.dart';

class AddEventScreen extends StatefulWidget {
  final VoidCallback onEventAdded;

  const AddEventScreen({super.key, required this.onEventAdded});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _tanggalBerakhirController= TextEditingController();
  DateTime? _tanggalBerakhir;

  Future<void> _selectDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {

      setState(() {
        _tanggalController.text = "${picked.year}-${picked.month}-${picked.day}";
      });

    }
  }


  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _tanggalBerakhir = picked;
        _tanggalBerakhirController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }


  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final newEvent = Event(
        nama: _namaController.text,
        deskripsi: _deskripsiController.text,
        tanggalPelaksanaan: _tanggalController.text,
        tanggalBerakhir: _tanggalBerakhirController.text,
        isActive: true,
        isFinished: false,
      );

      print('Data event yang akan disimpan: ${newEvent.toMap()}');
      int result = await _databaseHelper.insertEvent(newEvent);
      print('Hasil insertEvent: $result');

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event berhasil disimpan!')),
        );
        Navigator.pop(context, true);
        widget.onEventAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan event. Coba lagi.')),
        );
      }
    } else {
      print('Validasi form gagal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFF0B1A40),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF142A6B),
              Color(0xFF0B1A40),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text(
                  'Tambah Event',
                  style: TextStyle(color: Colors.yellow),
                ),
                backgroundColor: const Color(0xFF142A6B),
                elevation: 0,
                automaticallyImplyLeading: true,
                iconTheme: const IconThemeData(color: Colors.yellow),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Event',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama event tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _deskripsiController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _tanggalController,
                          decoration: InputDecoration(
                            labelText: 'Tanggal Pelaksanaan',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.yellow),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tanggal pelaksanaan harus diisi';
                            }
                            return null;
                          },
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 20), 

                       
                        TextFormField(
                          controller: _tanggalBerakhirController,
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          decoration: InputDecoration(
                            labelText: 'Tanggal Berakhir', // Label disesuaikan
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.yellow),
                              onPressed: () => _selectEndDate(context),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                       

                        const SizedBox(height: 30), 
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.deepPurple[700],
                            ),
                            onPressed: _saveEvent,
                            child: const Text('Simpan Event'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}