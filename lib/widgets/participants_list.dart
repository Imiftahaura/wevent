// ignore_for_file: unnecessary_this, prefer_const_constructors

import 'package:flutter/material.dart';
import '../models/participant_model.dart';

class ParticipantsList extends StatelessWidget {
  final List<Participant> participants;
  final bool isDeleteModeActive;
  final Set<int> selectedParticipantIds;
  final Function(int participantId, bool isSelected)? onParticipantCheckboxChanged;
  final Set<int> absencedParticipantIds;
  final Function(Participant participant)? onAbsenParticipant;
  final Function(Participant participant)? onEditParticipant;
  final Function(Participant participant)? onDeleteParticipant;

  const ParticipantsList({
    super.key,
    required this.participants,
    this.isDeleteModeActive = false,
    this.selectedParticipantIds = const {},
    this.onParticipantCheckboxChanged,
    this.absencedParticipantIds = const {},
    this.onAbsenParticipant,
    this.onEditParticipant,
    this.onDeleteParticipant,
  });


  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        final isAbsenced = absencedParticipantIds.contains(participant.id);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ClipRRect( 
            borderRadius: BorderRadius.circular(8.0), 
            child: Container(
              
              decoration: isAbsenced
                  ? BoxDecoration(
                      color: Colors.grey[700], 
                    )
                  : const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 160, 57, 102), 
                          Color(0xFF7366ff), 
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            participant.nama ?? 'Nama Peserta',
                            style: TextStyle(

                              color: isAbsenced ? Colors.white70 : Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (participant.umur != null)
                            Text(
                              'Umur: ${participant.umur}',
                              style: TextStyle(color: isAbsenced ? Colors.grey[300] : const Color.fromARGB(221, 245, 241, 241)), 
                            ),
                          if (participant.kategori != null && participant.kategori!.isNotEmpty)
                            Text(
                              'Kategori: ${participant.kategori}',
                              style: TextStyle(color: isAbsenced ? Colors.grey[300] : Color.fromARGB(221, 255, 253, 253)), 
                            ),
                          if (participant.namaClubSekolah != null && participant.namaClubSekolah!.isNotEmpty)
                            Text(
                              'Club/Sekolah: ${participant.namaClubSekolah}',
                              style: TextStyle(color: isAbsenced ? Colors.grey[300] : Color.fromARGB(221, 254, 254, 254)), 
                            ),
                        ],
                      ),
                    ),
                    if (isAbsenced)
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (isDeleteModeActive)
                      Checkbox(
                        value: selectedParticipantIds.contains(participant.id),
                        onChanged: (bool? value) {
                          if (value != null && onParticipantCheckboxChanged != null) {
                            onParticipantCheckboxChanged!(participant.id!, value);
                          }
                        },
                        activeColor: Colors.yellow,
                        checkColor: Colors.black, 
                      ),
                    PopupMenuButton<String>(
                
                      color: const Color(0xFF0B1A40), 
                      onSelected: (String value) {
                        final participant = participants[index];
                        if (value == 'absen' && onAbsenParticipant != null) {
                          onAbsenParticipant!(participant);
                        } else if (value == 'edit' && onEditParticipant != null) {
                          onEditParticipant!(participant);
                        } else if (value == 'hapus' && onDeleteParticipant != null) {
                          onDeleteParticipant!(participant);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (onAbsenParticipant != null)
                          const PopupMenuItem<String>(
                            value: 'absen',
                            child: Text('Absenkan', style: TextStyle(color: Colors.white)), 
                          ),
                        if (onEditParticipant != null)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit', style: TextStyle(color: Colors.white)), 
                          ),
                        if (onDeleteParticipant != null)
                          const PopupMenuItem<String>(
                            value: 'hapus',
                            child: Text('Hapus', style: TextStyle(color: Colors.white)), 
                          ),
                      ],
                      child: const Icon(Icons.more_vert, color: Color.fromARGB(255, 255, 255, 255)), 
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}