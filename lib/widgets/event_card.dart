import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_helper.dart';
import '../screens/edit_event_screen.dart';
import '../screens/manage_event_screen.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Function() onEventUpdated;

  const EventCard({
    super.key,
    required this.event,
    required this.onEventUpdated,
  });

  Future<void> _updateEventStatus(BuildContext context, bool newIsActive) async {
    final dbHelper = DatabaseHelper();
    int result = await dbHelper.updateEventStatusByName(event.nama!, newIsActive);
    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event "${event.nama}" marked as ${newIsActive ? 'active' : 'completed'}.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      onEventUpdated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update event status.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete', style: TextStyle(color: Colors.amberAccent)),
          backgroundColor:  const Color(0xFF142A6B).withOpacity(0.9),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete event "${event.nama}"?', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                const Text('All related data (participants, subcategories) will also be deleted.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.amberAccent)),
              onPressed: () async {
                final dbHelper = DatabaseHelper();
                int result = await dbHelper.deleteEventByName(event.nama!);
                if (result > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Event "${event.nama}" deleted successfully.', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  onEventUpdated();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete event.', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF142A6B).withOpacity(0.9),
            const Color(0xFF0B1A40).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent, width: 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.nama ?? 'Event Name',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: const Color(0xFF2A2A2A),
                  onSelected: (value) async {
                    if (value == 'finish' && event.isActive) {
                      await _updateEventStatus(context, false);
                    } else if (value == 'activate' && !event.isActive) {
                      await _updateEventStatus(context, true);
                    } else if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditEventScreen(event: event, onEventUpdated: () {  },),
                        ),
                      ).then((value) {
                        if (value == true) {
                          onEventUpdated();
                        }
                      });
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    if (event.isActive)
                      const PopupMenuItem<String>(
                        value: 'finish',
                        child: Text('Finished', style: TextStyle(color: Colors.white)),
                      ),
                    if (!event.isActive)
                      const PopupMenuItem<String>(
                        value: 'activate',
                        child: Text('Move to active', style: TextStyle(color: Colors.white)),
                      ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: event.deskripsi != null ? 8.0 : 0.0), 
            if (event.deskripsi != null)
              Padding(
                padding: const EdgeInsets.only(top: 0.0), 
                child: Text(
                  event.deskripsi!,
                  style: const TextStyle(fontSize: 14.0, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (event.deskripsi == null)
              const Padding(
                padding: EdgeInsets.only(top: 0.0), 
                child: Text(
                  "No description",
                  style: TextStyle(fontSize: 14.0, color: Colors.white70),
                ),
              ),
            const SizedBox(height: 9.0),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.yellow),
                const SizedBox(width: 5),
                if (event.tanggalPelaksanaan != null && event.tanggalBerakhir != null)
                  if (event.tanggalPelaksanaan == event.tanggalBerakhir)
                    Text(
                      event.tanggalPelaksanaan!,
                      style: const TextStyle(fontSize: 13.0, color: Colors.white),
                    )
                  else
                    Text(
                      '${event.tanggalPelaksanaan} to ${event.tanggalBerakhir}',
                      style: const TextStyle(fontSize: 13.0, color: Colors.white),
                    )
                else if (event.tanggalPelaksanaan != null)
                  Text(
                    event.tanggalPelaksanaan!,
                    style: const TextStyle(fontSize: 13.0, color: Colors.white),
                  )
                else
                  const Text(
                    'Date not specified',
                    style: TextStyle(fontSize: 13.0, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 9.0),
            SizedBox(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00C9FF),
                      Color(0xFF92FE9D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    elevation: 0,
                  ),
                  onPressed: event.isActive
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageEventScreen(event: event),
                            ),
                          ).then((value) {
                            if (value == true) {
                              onEventUpdated();
                            }
                          });
                        }
                      : () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Event Inactive'),
                                content: const Text('This event has been archived. Reactivate to view details.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                  child: Text(event.isActive ? 'Manage' : 'Event Completed'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}