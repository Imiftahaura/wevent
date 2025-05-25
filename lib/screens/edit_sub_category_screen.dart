import 'package:flutter/material.dart';
import '../services/database_helper.dart';


void showEditSubCategoryScreen({
  required BuildContext context,
  required Map<String, dynamic> subCategory,
  required VoidCallback onSubCategoryUpdated,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: subCategory['nama']);
  final databaseHelper = DatabaseHelper();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor:  const Color(0xFF0D47A1), 
        title: const Text(
          'Edit Subkategori',
          style: TextStyle(color: Colors.yellow),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Subkategori',
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.yellow),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama subkategori tidak boleh kosong.';
              }
              return null;
            },
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
            child: const Text('Simpan'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newName = nameController.text.trim();
                try {
                  final result = await databaseHelper.updateSubCategory(
                    subCategory['id'] as int,
                    newName,
                  );
                  if (result > 0) {
                    onSubCategoryUpdated();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subkategori berhasil diperbarui.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal memperbarui subkategori.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    },
  );
}
