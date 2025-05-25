import 'package:flutter/material.dart';

class ManageEventFab extends StatelessWidget {
  final VoidCallback onAddParticipant;
  final VoidCallback onAddSubCategory;
  // final VoidCallback onManualAttendance;
  final VoidCallback onViewAttendance;
  final VoidCallback onManageBracket;

  const ManageEventFab({
    super.key,
    required this.onAddParticipant,
    required this.onAddSubCategory,
    // required this.onManualAttendance,
    required this.onViewAttendance,
    required this.onManageBracket, required Null Function() onShare,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.yellow[700],
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF142A6B),
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.orange),
                  title: const Text('Tambah Peserta', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                  onTap: onAddParticipant,
                ),
                ListTile(
                  leading: const Icon(Icons.category, color: Colors.orange),
                  title: const Text('Tambah Subkategori', style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1))),
                  onTap: onAddSubCategory,
                ),
                ListTile(
                  leading: const Icon(Icons.settings_applications, color: Colors.orange),
                  title: const Text('Kelola Bracket', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                  onTap: onManageBracket,
                ),
              ],
            );
          },
        );
      },
      child: const Icon(Icons.add, color: Colors.deepPurple),
    );
  }
}