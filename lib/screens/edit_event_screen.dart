// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart'; 

class EditEventScreen extends StatefulWidget {
  final Event event;
  final VoidCallback onEventUpdated;

  const EditEventScreen({
    super.key,
    required this.event,
    required this.onEventUpdated,
  });

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalPelaksanaanController = TextEditingController();
  final _tanggalBerakhirController = TextEditingController(); 
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime? _selectedTanggalPelaksanaan;
  DateTime? _selectedTanggalBerakhir; 

  @override
  void initState() {
    super.initState();
    
    _namaController.text = widget.event.nama!;
    _deskripsiController.text = widget.event.deskripsi ?? '';

    if (widget.event.tanggalPelaksanaan != null) {
      _tanggalPelaksanaanController.text = widget.event.tanggalPelaksanaan!;
      _selectedTanggalPelaksanaan = DateTime.tryParse(widget.event.tanggalPelaksanaan!);
    }

   
    if (widget.event.tanggalBerakhir != null) {
      _tanggalBerakhirController.text = widget.event.tanggalBerakhir!;
      _selectedTanggalBerakhir = DateTime.tryParse(widget.event.tanggalBerakhir!);
    }
  }

  Future<void> _selectTanggalPelaksanaan(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalPelaksanaan ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedTanggalPelaksanaan = picked;
        _tanggalPelaksanaanController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

 
  Future<void> _selectTanggalBerakhir(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalBerakhir ?? _selectedTanggalPelaksanaan ?? DateTime.now(), 
      firstDate: _selectedTanggalPelaksanaan ?? DateTime(2023), 
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedTanggalBerakhir = picked;
        _tanggalBerakhirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      final updatedEvent = Event(
        id: widget.event.id, 
        nama: _namaController.text,
        deskripsi: _deskripsiController.text,
        tanggalPelaksanaan: _tanggalPelaksanaanController.text,
        tanggalBerakhir: _tanggalBerakhirController.text,
        isActive: widget.event.isActive, 
        isFinished: widget.event.isFinished, 
      );

      print('Data event yang akan diupdate: ${updatedEvent.toMap()}');
      int result = await _databaseHelper.updateEvent(updatedEvent);
      print('Hasil updateEvent: $result');

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event berhasil diperbarui!')),
        );
        Navigator.pop(context, true); 
        widget.onEventUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui event. Coba lagi.')),
        );
      }
    } else {
      print('Validasi form gagal.');
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _tanggalPelaksanaanController.dispose();
    _tanggalBerakhirController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A40),
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
                  'Edit Event',
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
                          controller: _tanggalPelaksanaanController,
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
                              onPressed: () => _selectTanggalPelaksanaan(context),
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
                          onTap: () => _selectTanggalPelaksanaan(context),
                        ),
                        const SizedBox(height: 20), 

                       
                        TextFormField(
                          controller: _tanggalBerakhirController,
                          decoration: InputDecoration(
                            labelText: 'Tanggal Berakhir',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.yellow),
                              onPressed: () => _selectTanggalBerakhir(context),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                       
                          readOnly: true,
                          onTap: () => _selectTanggalBerakhir(context),
                        ),
                        const SizedBox(height: 30),
                     

                        SizedBox(
                          width: double.infinity, 
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.deepPurple[700],
                            ),
                            onPressed: _updateEvent, 
                            child: const Text('Perbarui Event'),
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