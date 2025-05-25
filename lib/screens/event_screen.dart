// ignore_for_file: use_build_context_synchronously, avoid_print, unused_element

import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_helper.dart';
import '../screens/add_event_screen.dart';
import '../widgets/event_card.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required Future<void> Function() onEventsChanged});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Event> _events = [];
  late TabController _tabController;
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents(); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true; 
    });
    _events = await _databaseHelper.getAllEvents();
    print('Jumlah event yang dimuat: ${_events.length}');
    setState(() {
      _isLoading = false; 
    });
  }

  void _onEventAdded() {
    _loadEvents(); 
  }

  void _onEventUpdated() {
    _loadEvents(); 
    print('Event di-update, _loadEvents dipanggil. Jumlah event setelah reload: ${_events.length}');
    for (var event in _events) {
      print('${event.nama} - Aktif: ${event.isActive}, Selesai: ${event.isFinished}');
    }
  }

  List<Event> get _activeEvents =>
      _events.where((e) => e.isActive && !e.isFinished).toList();

  List<Event> get _finishedEvents => _events.where((e) => e.isFinished).toList();

  bool get _hasAnyEvents => _events.isNotEmpty;

  Widget _buildEmptyState({
    required String imagePath,
    required String message,
    bool showButton = false, 
    VoidCallback? onButtonPressed, 
    String? buttonText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 200,
            width: 200,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (showButton) ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.add, color: Color(0xFF0D1B52)),
              label: Text(
                buttonText ?? 'Start Buat Event',
                style: const TextStyle(color: Color(0xFF0D1B52)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A40),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF0B1A40),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.amberAccent,
                labelColor: Colors.amberAccent,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Aktif'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.amberAccent,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _activeEvents.isEmpty
                            ? _buildEmptyState(
                                imagePath: 'assets/images/eventscreen.png',
                                message: 'Tidak ada event aktif buat sekarang.',
                                showButton: true,
                                buttonText: 'Start Buat Event',
                                onButtonPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEventScreen(onEventAdded: _onEventAdded),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadEvents();
                                  }
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                itemCount: _activeEvents.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: EventCard(
                                      event: _activeEvents[index],
                                      onEventUpdated: _onEventUpdated,
                                    ),
                                  );
                                },
                              ),
                        _finishedEvents.isEmpty
                            ? _buildEmptyState(
                                imagePath: 'assets/images/login.png',
                                message: 'Tidak ada event selesai saat ini.',
                                showButton: false,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                itemCount: _finishedEvents.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: EventCard(
                                      event: _finishedEvents[index],
                                      onEventUpdated: _onEventUpdated,
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _activeEvents.isEmpty && _tabController.index == 0
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.amberAccent,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEventScreen(onEventAdded: _onEventAdded),
                  ),
                );
                if (result == true) {
                  _loadEvents();
                }
              },
              child: const Icon(Icons.add, color: Color(0xFF0D1B52)),
            ),
    );
  }
}
