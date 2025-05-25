// ignore_for_file: avoid_function_literals_in_foreach_calls, unused_element, unnecessary_to_list_in_spreads, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
// import 'dart:convert'; 
import 'package:collection/collection.dart';
import 'package:wevent3/models/event_model.dart'; 
import 'package:wevent3/models/participant_model.dart'; 
import 'package:wevent3/services/database_helper.dart'; 


class TrianglePointer extends CustomPainter {
  final Color color;

  TrianglePointer({this.color = const Color.fromARGB(255, 230, 223, 223)});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}


class TournamentMatch {
  int? p1Id; 
  int? p2Id; 
  int? winnerId; 
  int round; 
  int matchNumber; 

  TournamentMatch({
    this.p1Id,
    this.p2Id,
    this.winnerId,
    required this.round,
    required this.matchNumber,
  });


  bool get isReady {
    return (p1Id != null) && (p2Id != null);
  }


  bool get isCompleted => winnerId != null;
}


class BracketScreen extends StatefulWidget {
  final Event? event; 
  final List<Participant> initialParticipants; 
  final Map<String, dynamic>? subCategory; 

  const BracketScreen({
    super.key,
    this.event,
    this.initialParticipants = const [],
    this.subCategory,
  });

  @override
  _BracketScreenState createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  late DatabaseHelper _databaseHelper; 
  List<List<TournamentMatch>> _rounds = []; 
  List<Participant> _spinEligibleParticipants = []; 

  late StreamController<int> _selectedIndex; 
  bool _isSpinning = false; 
  Participant? _lastSelectedParticipant; 
  int? _lastSelectedIndex;

  
  static const String currentSelectedMatchFormat = '1 vs 1';
  
  // final List<String> _formatOptions = ['1 vs 1'];

  final List<Color> _wheelColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
  ];

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _selectedIndex = StreamController<int>.broadcast();
    _spinEligibleParticipants = List.from(widget.initialParticipants);
    _spinEligibleParticipants.shuffle(Random());
    _loadExistingBracket(); 
  }

  @override
  void dispose() {
    _selectedIndex.close();
    super.dispose();
  }

 
  Future<void> _loadExistingBracket() async {
    if (widget.event?.id == null) return; 

    try {
      final bracketData = await _databaseHelper.getBracketsByEventAndSubCategory(
        widget.event!.id!,
        widget.subCategory?['id'],
      );

      if (bracketData.isNotEmpty) {
        int maxRound = 0;
        Map<int, List<Map<String, dynamic>>> matchesByRound = {};

      
        for (var matchData in bracketData) {
          final roundNum = (matchData['babak'] as int);
          maxRound = max(maxRound, roundNum);
          matchesByRound.putIfAbsent(roundNum, () => []).add(matchData);
        }

      
        _rounds = List.generate(maxRound, (index) => []);

        Set<int> placedParticipantIds = {}; 
        for (int r = 1; r <= maxRound; r++) {
          final currentRoundMatchesData = matchesByRound[r] ?? [];
          currentRoundMatchesData.sort((a, b) => (a['match_number'] as int).compareTo(b['match_number'] as int));

          final roundIndex = r - 1;

          for (var matchData in currentRoundMatchesData) {
            final matchNumber = (matchData['match_number'] as int);

            int? p1Id = (matchData['participant1_id'] as int?);
            int? p2Id = (matchData['participant2_id'] as int?);
            int? winnerId = (matchData['winner_id'] as int?);
           

           
            if (p1Id != null) placedParticipantIds.add(p1Id);
            if (p2Id != null) placedParticipantIds.add(p2Id);

           
            while (_rounds[roundIndex].length < matchNumber) {
              _rounds[roundIndex].add(TournamentMatch(
                round: r,
                matchNumber: _rounds[roundIndex].length + 1,
              ));
            }

        
            _rounds[roundIndex][matchNumber - 1] = TournamentMatch(
              p1Id: p1Id,
              p2Id: p2Id,
              winnerId: winnerId,
              round: r,
              matchNumber: matchNumber,
            );
          }
        }

      
        setState(() {
          _spinEligibleParticipants.removeWhere((p) => placedParticipantIds.contains(p.id));
        });
      } else {
      
        setState(() {
          _rounds = [];
          _spinEligibleParticipants = List.from(widget.initialParticipants);
          _spinEligibleParticipants.shuffle(Random());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat bracket: ${e.toString()}')),
      );
    }
  }

 
  Participant? _getParticipantById(int? id) {
    if (id == null) return null;
    return widget.initialParticipants.firstWhereOrNull((p) => p.id == id);
  }

  
  (int, int) _findNextEmptyMatchSlot() {
    if (_rounds.isEmpty) {
      _rounds.add([]); 
    }

  
    for (int i = 0; i < _rounds[0].length; i++) {
      final match = _rounds[0][i];
      if (match.p1Id == null) {
        return (0, i);
      }
      if (match.p2Id == null) {
        return (0, i); 
      }
    }
    
    int newMatchIndex = _rounds[0].length;
    _rounds[0].add(TournamentMatch(
      round: 1,
      matchNumber: newMatchIndex + 1,
    ));
    return (0, newMatchIndex);
  }

 
  Future<void> _spinAndPlaceParticipantsForMatch() async {
    if (_isSpinning) return; 
    if (_spinEligibleParticipants.isEmpty) {
      _showDialog('Selesai!', 'Semua peserta sudha masuk ke bracket.');
      return;
    }

    setState(() {
      _isSpinning = true; 
    });

    final Random random = Random();
    int selectedIndex = random.nextInt(_spinEligibleParticipants.length);
    _lastSelectedIndex = selectedIndex; 
    _selectedIndex.add(selectedIndex); 

  }

 
  Future<void> _placeSelectedParticipant() async {
    if (_lastSelectedIndex == null || _lastSelectedIndex! >= _spinEligibleParticipants.length) {
      return; 
    }

    final (roundIdx, matchIdx) = _findNextEmptyMatchSlot();
    final targetMatch = _rounds[roundIdx][matchIdx];
    final Participant selectedParticipant = _spinEligibleParticipants[_lastSelectedIndex!];

    setState(() {
      if (targetMatch.p1Id == null) {
        targetMatch.p1Id = selectedParticipant.id!;
      } else if (targetMatch.p2Id == null) {
        targetMatch.p2Id = selectedParticipant.id!;
      } else {
        print('Error: Slot 1 vs 1 sudah penuh .');
        return;
      }
      _spinEligibleParticipants.removeAt(_lastSelectedIndex!); 
      _lastSelectedIndex = null; 
    });

    await _saveManualBracket(showSnackbar: false); 
  }


  
  void _showMatchReadyDialog(TournamentMatch match) {
    String p1Name = _getParticipantById(match.p1Id)?.nama ?? 'TBD';
    String p2Name = _getParticipantById(match.p2Id)?.nama ?? 'TBD';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pertandingan baru!'),
          content: Text(
            'Babak ${match.round}, Pertandingan ${match.matchNumber}'
            '$p1Name VS $p2Name',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

 
  void _showSetWinnerDialog(int roundIndex, int matchIndex, int? participantId1, int? participantId2) {
    List<Participant> participantsInMatch = [];
    if (participantId1 != null) participantsInMatch.add(_getParticipantById(participantId1)!);
    if (participantId2 != null) participantsInMatch.add(_getParticipantById(participantId2)!);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih pemenang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: participantsInMatch.map((player) => ListTile(
                title: Text(player.nama ?? 'Unknown'),
                onTap: () {
                  Navigator.pop(context); 
                  _setMatchWinner(roundIndex, matchIndex, player.id!); 
                },
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('batal'),
            ),
          ],
        );
      },
    );
  }

 
  void _setMatchWinner(int roundIndex, int matchIndex, int winnerId) async {
    if (roundIndex >= _rounds.length || matchIndex >= _rounds[roundIndex].length) return;

    final currentMatch = _rounds[roundIndex][matchIndex];

   
    if (currentMatch.winnerId != null) {
      if (currentMatch.winnerId == winnerId) {
     
        return;
      } else {
    
        bool? confirmChange = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(' Ubah Pemenang?'),
            content: Text('Pemenang yang maju adalah  ${_getParticipantById(currentMatch.winnerId)?.nama}. Anda ingin mengubahnya? ini akan mempengaruhi babak berikutnya'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya Ubah'),
              ),
            ],
          ),
        );

        if (confirmChange != true) {
          return;
        }
        
        _undoNextRoundWinner(roundIndex + 1, (matchIndex ~/ 2) + 1, currentMatch.winnerId);
      }
    }

 
    setState(() {
      currentMatch.winnerId = winnerId;
    });

   
    final int nextRoundIndex = roundIndex + 1;
    final int nextMatchNumber = (matchIndex ~/ 2) + 1;

 
    while (_rounds.length <= nextRoundIndex) {
      _rounds.add([]);
    }

    while (_rounds[nextRoundIndex].length < nextMatchNumber) {
      _rounds[nextRoundIndex].add(
        TournamentMatch(
          round: nextRoundIndex + 1,
          matchNumber: _rounds[nextRoundIndex].length + 1,
        ),
      );
    }

    final nextRoundMatch = _rounds[nextRoundIndex][nextMatchNumber - 1];

 
    setState(() {
      final bool isFirstPlayerInNextMatch = matchIndex % 2 == 0;

      if (isFirstPlayerInNextMatch) {
        nextRoundMatch.p1Id = winnerId;
      } else {
        nextRoundMatch.p2Id = winnerId;
      }
    });

   
    if (nextRoundIndex == _rounds.length - 1 && nextRoundMatch.isCompleted) {
      _showDialog('SELAMAT!', 'Pemenang bracket: ${_getParticipantById(nextRoundMatch.winnerId)?.nama ?? 'N/A'}!');
    }

    await _saveManualBracket(); 
  }


  void _undoNextRoundWinner(int roundIndex, int matchNumber, int? participantIdToRemove) {
    if (roundIndex >= _rounds.length) return;

    final int matchIdxInNextRound = matchNumber - 1;
    if (matchIdxInNextRound >= _rounds[roundIndex].length) return;

    final nextRoundMatch = _rounds[roundIndex][matchIdxInNextRound];

    bool changed = false;
    setState(() {
      
      if (nextRoundMatch.p1Id == participantIdToRemove) {
        nextRoundMatch.p1Id = null;
        changed = true;
      } else if (nextRoundMatch.p2Id == participantIdToRemove) {
        nextRoundMatch.p2Id = null;
        changed = true;
      }
    
      if (nextRoundMatch.winnerId == participantIdToRemove) {
        nextRoundMatch.winnerId = null;
        changed = true;
      }
    });

    
    if (changed && (nextRoundMatch.p1Id == null || nextRoundMatch.p2Id == null || nextRoundMatch.winnerId == null)) {
      _undoNextRoundWinner(roundIndex + 1, (matchIdxInNextRound ~/ 2) + 1, participantIdToRemove);
    }
  }


  void _formMatches() async { 
    if (widget.initialParticipants.isEmpty) {
      _showDialog('Peringatan', 'Tidak ada peserta yang terdaftar.');
      return;
    }

    List<Participant> tempParticipants = List.from(widget.initialParticipants); 
    tempParticipants.shuffle(Random()); 

    _rounds = []; 
    _rounds.add([]); 

   
    for (int i = 0; i < tempParticipants.length; i += 2) {
      int? p1Id = tempParticipants[i].id;
      int? p2Id;
      if (i + 1 < tempParticipants.length) {
        p2Id = tempParticipants[i + 1].id;
      }

      TournamentMatch match = TournamentMatch(
        round: 1,
        matchNumber: (_rounds[0].length) + 1,
        p1Id: p1Id,
        p2Id: p2Id,
      );
      _rounds[0].add(match);
    }


    setState(() {
      _spinEligibleParticipants.clear(); 
    });

    await _saveManualBracket(); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bracket 1 vs 1 dibuat secara otomatis.')),
    );
  }

 
  void _resetBracket() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Bracket?'),
        content: const Text('Semua data bracket akan terhapus. Lanjut?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _rounds = []; 
        _spinEligibleParticipants = List.from(widget.initialParticipants); 
        _spinEligibleParticipants.shuffle(Random()); 
      });
      
      await _databaseHelper.deleteBracketsByEventAndSubCategory(
          widget.event!.id!, widget.subCategory?['id']); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bracket berhasil di Reset.')),
      );
    }
  }

  
  Future<void> _saveManualBracket({bool showSnackbar = true}) async { 
    if (widget.event?.id == null) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID tidak valid.')),
        );
      }
      return;
    }

    try {
      await _databaseHelper.deleteBracketsByEventAndSubCategory(
        widget.event!.id!,
        widget.subCategory?['id'],
      );

      
      for (int i = 0; i < _rounds.length; i++) {
        final roundMatches = _rounds[i];
        for (int j = 0; j < roundMatches.length; j++) {
          final match = roundMatches[j];

         
          if ((match.p1Id != null) || (match.p2Id != null) || match.winnerId != null) {
         
            await _databaseHelper.insertBracketMatchBasic(
              widget.event!.id!,
              match.round,
              match.matchNumber,
              match.p1Id,
              match.p2Id,
              match.winnerId,
              widget.subCategory?['id'],
            );
          }
        }
      }

     

      if (showSnackbar) { 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bracket berhasil disimpan.')),
        );
      }
    } catch (e) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bracket gagal disimpan: ${e.toString()}')),
        );
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildRound(List<TournamentMatch> matches, int roundIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Round ${roundIndex + 1}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
    
        ...matches.map((match) => _buildMatchCard(match, roundIndex)).toList(),
        const SizedBox(height: 32),
      ],
    );
  }

  
  Widget _buildMatchCard(TournamentMatch match, int roundIndex) {
    final Participant? p1Participant = _getParticipantById(match.p1Id);
    final Participant? p2Participant = _getParticipantById(match.p2Id);

    return Column(
      children: [
        Container(
          width: 250, 
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D57), 
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: _buildParticipantDisplay(
            p1Participant,
            onTap: () => _showSetWinnerDialog(roundIndex, match.matchNumber - 1, match.p1Id, match.p2Id),
            isWinner: p1Participant?.id == match.winnerId, 
          ),
        ),
        
        const SizedBox(height: 4), 

        
        Container(
          width: 250, 
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D57),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: _buildParticipantDisplay(
            p2Participant,
            onTap: () => _showSetWinnerDialog(roundIndex, match.matchNumber - 1, match.p1Id, match.p2Id),
            isWinner: p2Participant?.id == match.winnerId, 
          ),
        ),


        if (roundIndex < _rounds.length - 1 && match.isCompleted)
          Container(
            height: 24,
            width: 1,
            color: Colors.white,
          ),
        const SizedBox(height: 16), 
      ],
    );
  }

  Widget _buildParticipantDisplay(
    Participant? participant, {
    VoidCallback? onTap,
    bool isWinner = false, 
  }) {
  
    if (participant == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SizedBox(
            width: double.infinity,
            child: Text(
              'TBD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
 
   
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isWinner ? const Color.fromARGB(255, 65, 249, 132) : Colors.transparent, 
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            // White circle
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(right: 8),
            ),
            Expanded( 
              child: Text(
                participant.nama ?? 'Unknown',
                textAlign: TextAlign.center, 
                style: TextStyle(
                  color: isWinner ? Colors.black : Colors.white,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWinner) 
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.star, color: Colors.amberAccent, size: 18),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  
    double getSpinnerFontSize(int participantCount) {
      if (participantCount <= 10) return 24;
      if (participantCount <= 20) return 20;
      if (participantCount <= 40) return 16;
      if (participantCount <= 70) return 14;
      return 12;
    }

    List<Participant> displayParticipants = List.from(_spinEligibleParticipants);
  
    if (displayParticipants.isEmpty) {
      displayParticipants.add(Participant(nama: 'Tambah peserta', id: -1));
      displayParticipants.add(Participant(nama: 'Tambah Peserta', id: -2));
    } else if (displayParticipants.length == 1) {
      displayParticipants.add(Participant(nama: 'Tidak ada peserta lagi', id: -3));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1A40),
      appBar: AppBar(
        title: Text(
          'Bracket',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B1A40),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
         
          IconButton(
            icon: const Icon(Icons.save, color: Colors.amberAccent),
            tooltip: 'Simpan Bracket',
            onPressed: () => _saveManualBracket(showSnackbar: true), 
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amberAccent),
            tooltip: 'Reset Bracket',
            onPressed: _resetBracket,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                color: const Color(0xFF1E2D57),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
               
                      Text(
                        'Spin the wheel (1 vs 1)', 
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Stack( 
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100, 
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(
                            height: 350, 
                            width: 350,
                            child: FortuneWheel(
                              selected: _selectedIndex.stream,
                              duration: const Duration(milliseconds: 3000), 
                              animateFirst: false,
                              items: [
                                for (int i = 0; i < displayParticipants.length; i++)
                                  FortuneItem(
                                    child: Text(
                                      displayParticipants[i].nama ?? 'N/A',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white, 
                                        fontSize: getSpinnerFontSize(displayParticipants.length),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: FortuneItemStyle(
                                   
                                      color: displayParticipants[i].id! < 0 ? Colors.grey[700]! : _wheelColors[i % _wheelColors.length],
                                      borderColor: Colors.transparent, 
                                      borderWidth: 0, 
                                    ),
                                  ),
                              ],
                              indicators: <FortuneIndicator>[
                                FortuneIndicator(
                                  alignment: Alignment.topCenter, 
                                  child: Transform.rotate(
                                    angle: pi / 2, 
                                    child: SizedBox(
                                      width: 50, 
                                      height: 30, 
                                      child: CustomPaint(painter: TrianglePointer(color: Colors.amberAccent)),
                                    ),
                                  ),
                                ),
                              ],
                              onAnimationEnd: () async {
                                setState(() {
                                  _isSpinning = false; 
                                });
                            
                                if (_lastSelectedIndex != null && _lastSelectedIndex! < _spinEligibleParticipants.length) {
                                  _lastSelectedParticipant = _spinEligibleParticipants[_lastSelectedIndex!];
                                  if (_lastSelectedParticipant!.id! >= 0) { 
                                    bool? confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Memilih peserta!'),
                                        content: Text(
                                          'Peserta Terpilih: ${_lastSelectedParticipant!.nama ?? 'N/A'}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Ya'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await _placeSelectedParticipant(); 
                                    }
                                  }
                                }
                                _lastSelectedParticipant = null; 
                                _lastSelectedIndex = null; 
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Peserta yang tersisa: ${_spinEligibleParticipants.length}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isSpinning || _spinEligibleParticipants.isEmpty
                            ? null
                            : _spinAndPlaceParticipantsForMatch,
                        icon: const Icon(Icons.casino),
                        label: Text(_isSpinning ? 'Putar Roda' : 'Putar Roda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: const Color(0xFF0B1A40),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          textStyle: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Tampilan Bracket:',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              if (_rounds.isEmpty || _rounds[0].isEmpty || (_rounds.length == 1 && _rounds[0].every((match) => match.p1Id == null && match.p2Id == null)))
                Center(
                  child: Text(
                    'Bracket kosong! Putar roda unutk mendapatkan peserta',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _rounds.asMap().entries.map((entry) {
                      int roundIndex = entry.key;
                      List<TournamentMatch> matches = entry.value;

                      final filteredMatches = matches.where((match) =>
                          (match.p1Id != null) || (match.p2Id != null) || match.winnerId != null || roundIndex == 0).toList();

                      if (filteredMatches.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildRound(filteredMatches, roundIndex),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
