// ignore_for_file: unused_element, prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/event_model.dart';
import '../screens/event_screen.dart';
import '../screens/bracket_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

DateTime? _parseFlexibleDateTime(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;

  final trimmedDateString = dateString.trim();

  final List<String> formatsToTry = [
    'yyyy-MM-ddTHH:mm:ss.SSS',
    'yyyy-MM-ddTHH:mm:ss',
    'yyyy-MM-dd HH:mm:ss',
    'yyyy-M-d HH:mm:ss',
    'yyyy-MM-dd HH:mm',
    'yyyy-M-d HH:mm',
    'yyyy-MM-dd',
    'yyyy-M-d',
  ];

  for (final format in formatsToTry) {
    try {
      return DateFormat(format).parseStrict(trimmedDateString);
    // ignore: empty_catches
    } on FormatException {
    }
  }

  try {
    return DateTime.parse(trimmedDateString);
  } on FormatException {
    print('Failed to parse date string with all known formats: $trimmedDateString');
    return null;
  }
}


class HomeScreen extends StatefulWidget {
  final String? loggedInUserName;
  const HomeScreen({super.key, this.loggedInUserName, required String userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _databaseHelper = DatabaseHelper();
  List<Event> _upcomingEvents = [];
  int _selectedIndex = 0;
  late final Widget _homeBody;
  late final Widget _eventScreen;
  final Widget _bracketScreen = BracketScreen();

  late Widget _currentBody;

  String _upcomingEventsError = '';

  @override
  void initState() {
    super.initState();
    _eventScreen = EventScreen(onEventsChanged: _loadUpcomingEvents);
    _loadUpcomingEvents();
    _homeBody = _HomeBody(
      upcomingEvents: _upcomingEvents,
      onEventsReloaded: _loadUpcomingEvents,
    );
    _currentBody = _homeBody;
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      List<Event> events = await _databaseHelper.getEvents();
      print('Raw events from DB: ${events.length}');

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      _upcomingEvents = events
          .where((event) {
            final eventDate = _parseFlexibleDateTime(event.tanggalPelaksanaan);
            if (eventDate == null) {
              print('Event with unparseable tanggalPelaksanaan found: ${event.nama}');
              return false;
            }
            final normalizedEventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);

            return normalizedEventDate.isAtSameMomentAs(normalizedToday) ||
                normalizedEventDate.isAfter(normalizedToday);
          })
          .toList()
        ..sort((a, b) {
          final dateA = _parseFlexibleDateTime(a.tanggalPelaksanaan);
          final dateB = _parseFlexibleDateTime(b.tanggalPelaksanaan);
          if (dateA == null || dateB == null) return 0;
          return dateA.compareTo(dateB);
        });
      _upcomingEventsError = '';
      print('Filtered upcoming events: ${_upcomingEvents.length}');
    } catch (e) {
      _upcomingEventsError = 'Gagal memuat event mendatang: $e';
      print('Error loading events: $_upcomingEventsError');
    }
    if (mounted) {
      setState(() {
        _homeBody = _HomeBody(
          upcomingEvents: _upcomingEvents,
          onEventsReloaded: _loadUpcomingEvents,
        );
        if (_selectedIndex == 0) {
          _currentBody = _homeBody;
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (_selectedIndex) {
        case 0:
          _currentBody = _homeBody;
          break;
        case 1:
          _currentBody = _eventScreen;
          break;
        case 2:
          _currentBody = _bracketScreen;
          break;
        default:
          _currentBody = _homeBody;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A40),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF142A6B),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF142A6B).withOpacity(0.9),
                        const Color(0xFF0B1A40).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.account_circle,
                            size: 40, color: Colors.amberAccent),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hai, ${FirebaseAuth.instance.currentUser?.displayName ?? (
                                  FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Pengguna')}!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Selamat datang kembali!",
                                style: TextStyle(color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _currentBody,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF142A6B),
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.grey.shade400,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Event',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final List<Event> upcomingEvents;
  final VoidCallback onEventsReloaded;

  const _HomeBody({
    super.key,
    this.upcomingEvents = const [],
    required this.onEventsReloaded,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mainCarouselItems = [
      {
        'imagePath': 'assets/images/login.png',
        'text': 'Buat bracket turnamen Anda dengan mudah dan cepat!',
        'type': 'bracket',
        'gradient': LinearGradient(
          colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'imagePath': 'assets/images/fatahillah.png',
        'text': 'Atur event Anda agar lebih terorganisir dengan Wevent!',
        'type': 'event',
        'gradient': LinearGradient(
          colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'imagePath': 'assets/images/logo.png',
        'text': 'Jelajahi fitur menarik lainnya untuk pengalaman yang lebih baik!',
        'type': 'general',
        'gradient': LinearGradient(
          colors: [Color(0xFF1D976C), Color(0xFF93F9B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Fitur Utama',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
              ),
            ),
          ),
          CarouselSlider.builder(
            itemCount: mainCarouselItems.length,
            options: CarouselOptions(
              height: 160.0,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 5),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              viewportFraction: 0.85,
            ),
            itemBuilder: (BuildContext context, int index, int realIndex) {
              final item = mainCarouselItems[index];

              Widget carouselContent = Container(
                width: MediaQuery.of(context).size.width * 0.85,
                margin: EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                  gradient: item['gradient'],
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      item['imagePath']!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
                      },
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      item['text']!,
                      style: TextStyle(fontSize: 14.0, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );

            if (item['type'] == 'bracket') {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BracketScreen()),
                  );
                },
                child: carouselContent,
              );
            } else {
              return carouselContent;
            }
          },
        ),
        const SizedBox(height: 24.0),

        _CountdownEventsSection(upcomingEvents: upcomingEvents),

        const SizedBox(height: 24.0),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _CalendarSection(
            upcomingEvents: upcomingEvents,
            databaseHelper: DatabaseHelper(),
            onEventsReloaded: onEventsReloaded,
          ),
        ),
        const SizedBox(height: 24.0),
      ],
      ),
    );
  }
}

class _CountdownEventsSection extends StatefulWidget {
  final List<Event> upcomingEvents;

  const _CountdownEventsSection({Key? key, required this.upcomingEvents}) : super(key: key);

  @override
  State<_CountdownEventsSection> createState() => _CountdownEventsSectionState();
}

class _CountdownEventsSectionState extends State<_CountdownEventsSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getCountdown(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      return 'Event telah berakhir';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${days.toString().padLeft(2, '0')}h '
           '${hours.toString().padLeft(2, '0')}j '
           '${minutes.toString().padLeft(2, '0')}m '
           '${seconds.toString().padLeft(2, '0')}d';
  }

  @override
  Widget build(BuildContext context) {
    final activeUpcomingEvents = widget.upcomingEvents.where((event) {
      final eventStartDate = _parseFlexibleDateTime(event.tanggalPelaksanaan);
      if (eventStartDate == null) return false;

      final now = DateTime.now();
      return eventStartDate.isAfter(now) ||
             (eventStartDate.year == now.year &&
              eventStartDate.month == now.month &&
              eventStartDate.day == now.day &&
              eventStartDate.isAfter(now));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Hitungan Mundur Event',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 150.0,
          child: activeUpcomingEvents.isEmpty
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: const Color(0xFF142A6B),
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tidak ada event yang akan datang.',
                          style: TextStyle(color: Colors.grey.shade300),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '00h 00j 00m 00d',
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeUpcomingEvents.length,
                  itemBuilder: (context, index) {
                    final event = activeUpcomingEvents.elementAt(index);
                    final eventDate = _parseFlexibleDateTime(event.tanggalPelaksanaan) ?? DateTime.now();
                    final countdownText = _getCountdown(eventDate);
                    bool useGradient = index % 2 == 0;

                    return Container(
                      width: 200.0,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 16.0 : 0.0,
                        right: 16.0,
                      ),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: useGradient ? null : const Color(0xFF142A6B),
                        gradient: useGradient
                            ? LinearGradient(
                                colors: [
                                  Color(0xFF7B2FF7),
                                  Color(0xFFf107a3),
                                  Color(0xFF00d2ff),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            event.nama ?? 'Nama Acara',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Dimulai: ${DateFormat('dd MMMyy, HH:mm').format(eventDate)}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            'Sisa Waktu:',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            countdownText,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CalendarSection extends StatefulWidget {
  final List<Event> upcomingEvents;
  final DatabaseHelper databaseHelper;
  final VoidCallback onEventsReloaded;

  const _CalendarSection({
    Key? key,
    required this.upcomingEvents,
    required this.databaseHelper,
    required this.onEventsReloaded,
  }) : super(key: key);

  @override
  __CalendarSectionState createState() => __CalendarSectionState();
}

class __CalendarSectionState extends State<_CalendarSection> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  // ignore: prefer_final_fields
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  List<Event> _localCalendarEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initCalendarData();
    _selectedEvents = ValueNotifier(_getAllEventsForDay(_selectedDay!));
  }

  Future<void> _initCalendarData() async {
    await _loadLocalCalendarEvents();
    if (mounted) {
      _selectedEvents.value = _getAllEventsForDay(_selectedDay!);
    }
  }

  Future<void> _loadLocalCalendarEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? eventsJson = prefs.getString('localCalendarEvents');
      if (eventsJson != null) {
        final List<dynamic> decodedData = json.decode(eventsJson);
        setState(() {
          _localCalendarEvents = decodedData.map((e) => Event.fromMap(e)).toList();
        });
      }
    } catch (e) {
      print('Error loading local calendar events from SharedPreferences: $e');
    }
  }

  Future<void> _saveLocalCalendarEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(_localCalendarEvents.map((e) => e.toMap()).toList());
      await prefs.setString('localCalendarEvents', encodedData);
    } catch (e) {
      print('Error saving local calendar events to SharedPreferences: $e');
    }
  }

  @override
  void didUpdateWidget(covariant _CalendarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.upcomingEvents != oldWidget.upcomingEvents) {
      _selectedEvents.value = _getAllEventsForDay(_selectedDay!);
    }
  }

  List<Event> _getAllEventsForDay(DateTime day) {
    List<Event> allEvents = [...widget.upcomingEvents, ..._localCalendarEvents];
    return allEvents.where((event) {
      final startDate = _parseFlexibleDateTime(event.tanggalPelaksanaan);
      final endDate = _parseFlexibleDateTime(event.tanggalBerakhir);

      if (startDate == null || endDate == null) {
        print('Skipping event due to unparseable date: ${event.nama}');
        return false;
      }

      final normalizedDay = DateTime(day.year, day.month, day.day);
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);

      return (normalizedDay.isAfter(normalizedStartDate) || normalizedDay.isAtSameMomentAs(normalizedStartDate)) &&
             (normalizedDay.isBefore(normalizedEndDate) || normalizedDay.isAtSameMomentAs(normalizedEndDate));
    }).toList();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.amberAccent,
              onPrimary: Colors.black,
              surface: const Color(0xFF142A6B),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amberAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        _startTimeController.text = _startTime!.format(context);
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.amberAccent,
              onPrimary: Colors.black,
              surface: const Color(0xFF142A6B),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amberAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
        _endTimeController.text = _endTime!.format(context);
      });
    }
  }

  Future<void> _addManualEvent() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih tanggal di kalender terlebih dahulu!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_eventTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Judul event tidak boleh kosong!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime finalStartDate = _selectedDay!;
    if (_startTime != null) {
      finalStartDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
    } else {
      finalStartDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        0, 0, 0,
      );
    }

    DateTime finalEndDate = _selectedDay!;
    if (_endTime != null) {
      finalEndDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _endTime!.hour,
        _endTime!.minute,
      );
    } else {
      finalEndDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        23, 59, 59,
      );
    }

    if (finalEndDate.isBefore(finalStartDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Waktu berakhir harus setelah waktu mulai!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newEvent = Event(
      nama: _eventTitleController.text,
      deskripsi: _eventDescriptionController.text.isNotEmpty ? _eventDescriptionController.text : null,
      tanggalPelaksanaan: finalStartDate.toIso8601String(),
      tanggalBerakhir: finalEndDate.toIso8601String(),
      isActive: true,
    );

    try {
      setState(() {
        _localCalendarEvents.add(newEvent);
      });
      await _saveLocalCalendarEvents();

      _eventTitleController.clear();
      _eventDescriptionController.clear();
      _startTimeController.clear();
      _endTimeController.clear();
      _startTime = null;
      _endTime = null;

      _selectedEvents.value = _getAllEventsForDay(_selectedDay!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kegiatan "${newEvent.nama}" berhasil ditambahkan!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan kegiatan: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      print('Error adding manual event to SharedPreferences: $e');
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Event> getEventsForMarkers(DateTime day) {
      List<Event> allEvents = [...widget.upcomingEvents, ..._localCalendarEvents];
      return allEvents.where((event) {
        final startDate = _parseFlexibleDateTime(event.tanggalPelaksanaan);
        final endDate = _parseFlexibleDateTime(event.tanggalBerakhir);

        if (startDate == null || endDate == null) {
          print('Skipping marker for event due to unparseable date: ${event.nama}');
          return false;
        }

        final normalizedDay = DateTime(day.year, day.month, day.day);
        final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
        final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);

        return (normalizedDay.isAfter(normalizedStartDate) || normalizedDay.isAtSameMomentAs(normalizedStartDate)) &&
               (normalizedDay.isBefore(normalizedEndDate) || normalizedDay.isAtSameMomentAs(normalizedEndDate));
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jadwal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Colors.amberAccent,
          ),
        ),
        TableCalendar<Event>(
          firstDay: DateTime.utc(2022, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: getEventsForMarkers,
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents.value = _getAllEventsForDay(selectedDay);
                _startTime = null;
                _endTime = null;
                _startTimeController.clear();
                _endTimeController.clear();
              });
            }
          },
          onFormatChanged: (_) {},

          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.amberAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: Colors.white70),
            weekendTextStyle: TextStyle(color: Colors.redAccent),
            holidayTextStyle: TextStyle(color: Colors.greenAccent),
          ),

          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              color: Colors.amberAccent,
              fontSize: 14,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.amberAccent, size: 20),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.amberAccent, size: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF142A6B),
              borderRadius: BorderRadius.circular(8),
            ),
            headerPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0.5),
            titleCentered: true,
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white),
            weekendStyle: TextStyle(color: Colors.redAccent),
          ),
        ),

        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Kegiatan/Event',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Catatan: Kegiatan yang ditambahkan di sini hanya akan terlihat di kalender ini.',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _eventTitleController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Judul Kegiatan',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF142A6B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _eventDescriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Deskripsi (opsional)',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF142A6B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      readOnly: true,
                      onTap: () => _selectStartTime(context),
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Waktu Mulai (HH:MM)',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFF142A6B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
                        ),
                        suffixIcon: Icon(Icons.access_time, color: Colors.amberAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: _endTimeController,
                      readOnly: true,
                      onTap: () => _selectEndTime(context),
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Waktu Berakhir (HH:MM)',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFF142A6B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
                        ),
                        suffixIcon: Icon(Icons.access_time, color: Colors.amberAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addManualEvent,
                  icon: Icon(Icons.add_box_outlined, color: Colors.black),
                  label: Text(
                    'Tambahkan Kegiatan',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Daftar Kegiatan pada Tanggal Ini:',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        ValueListenableBuilder<List<Event>>(
          valueListenable: _selectedEvents,
          builder: (context, value, _) {
            if (value.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Tidak ada kegiatan pada tanggal ini.',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: value.length,
              itemBuilder: (context, index) {
                final event = value[index];
                String eventTime = '';
                try {
                  final startDateTime = _parseFlexibleDateTime(event.tanggalPelaksanaan);
                  final endDateTime = _parseFlexibleDateTime(event.tanggalBerakhir);

                  if (startDateTime != null) {
                    eventTime += DateFormat('HH:mm').format(startDateTime);
                  }
                  if (endDateTime != null) {
                    eventTime += ' - ${DateFormat('HH:mm').format(endDateTime)}';
                  }
                } catch (e) {
                  print('Error parsing event time for display: ${event.nama}, $e');
                  eventTime = 'Waktu tidak valid';
                }

                return Card(
                  color: const Color(0xFF142A6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      event.nama ?? 'Acara',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.deskripsi ?? '',
                          style: TextStyle(color: Colors.white60),
                        ),
                        if (eventTime.isNotEmpty)
                          Text(
                            eventTime,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
