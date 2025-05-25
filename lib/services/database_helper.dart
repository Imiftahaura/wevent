// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'wevent.db');
    print('Database path: $path'); // Tambahkan log path database
    return await openDatabase(
      path,
      version: 3, // Naikkan versi database karena ada perubahan skema
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database dari versi $oldVersion ke $newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE subcategories ADD COLUMN IF NOT EXISTS parent_id INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE subcategories ADD COLUMN IF NOT EXISTS parent_id INTEGER');
      await db.execute('ALTER TABLE participants ADD COLUMN IF NOT EXISTS sub_category_id INTEGER');
      await db.execute('ALTER TABLE brackets ADD COLUMN IF NOT EXISTS sub_category_id INTEGER');
       print('Menambahkan kolom tanggal_berakhir ke tabel events di upgradeDb');
      await db.execute('ALTER TABLE events ADD COLUMN IF NOT EXISTS tanggal_berakhir TEXT NOT NULL DEFAULT \'2000-01-01\'');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_subcategories_parent_id ON subcategories (parent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_participants_sub_category_id ON participants (sub_category_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_brackets_sub_category_id ON brackets (sub_category_id)'); 
    }
    // Jika ada perubahan skema lain di masa depan, tambahkan di sini
  }

  Future<void> _createDb(Database db, int version) async {
    print('Mencoba membuat tabel events...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        deskripsi TEXT,
        tanggal_pelaksanaan TEXT NOT NULL,
        tanggal_berakhir TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        is_finished INTEGER DEFAULT 1
      )
    ''');
    print('Tabel events berhasil dibuat/sudah ada.');

    print('Mencoba membuat tabel participants...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        umur INTEGER,
        kategori TEXT,
        nama_club_sekolah TEXT,
        event_id INTEGER NOT NULL,
        sub_category_id INTEGER,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (sub_category_id) REFERENCES subcategories(id) ON DELETE SET NULL
      )
    ''');
    print('Tabel participants berhasil dibuat/sudah ada.');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_participants_event_id ON participants (event_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_participants_sub_category_id ON participants (sub_category_id)');

    print('Mencoba membuat tabel subcategories...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        event_id INTEGER NOT NULL,
        parent_id INTEGER,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES subcategories(id) ON DELETE SET NULL
      )
    ''');
    print('Tabel subcategories berhasil dibuat/sudah ada.');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subcategories_event_id ON subcategories (event_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subcategories_parent_id ON subcategories (parent_id)');

    print('Mencoba membuat tabel attendances...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id INTEGER NOT NULL,
        event_id INTEGER NOT NULL,
        sub_category_id INTEGER NOT NULL,
        is_present INTEGER NOT NULL,
        attendance_time INTEGER NOT NULL,
        FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (sub_category_id) REFERENCES subcategories(id) ON DELETE CASCADE,
        UNIQUE (participant_id, event_id, sub_category_id) ON CONFLICT REPLACE
      )
    ''');
    print('Tabel attendances berhasil dibuat/sudah ada.');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendances_participant_id ON attendances (participant_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendances_event_id ON attendances (event_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendances_sub_category_id ON attendances (sub_category_id)');

    print('Mencoba membuat tabel brackets...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS brackets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        round INTEGER NOT NULL,
        match_number INTEGER NOT NULL,
        participant1_id INTEGER,
        participant2_id INTEGER,
        winner_id INTEGER,
        sub_category_id INTEGER, 
        FOREIGN KEY (event_id) REFERENCES events(id),
        FOREIGN KEY (participant1_id) REFERENCES participants(id) ON DELETE SET NULL,
        FOREIGN KEY (participant2_id) REFERENCES participants(id) ON DELETE SET NULL,
        FOREIGN KEY (winner_id) REFERENCES participants(id) ON DELETE SET NULL,
        FOREIGN KEY (sub_category_id) REFERENCES subcategories(id) ON DELETE SET NULL
      )
    ''');
    print('Tabel brackets berhasil dibuat/sudah ada.');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_brackets_event_id ON brackets (event_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_brackets_participant1_id ON brackets (participant1_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_brackets_participant2_id ON brackets (participant2_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_brackets_winner_id ON brackets (winner_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_brackets_sub_category_id ON brackets (sub_category_id)'); // Tambahkan indeks ini
  }

  //======================================================Event start========================================================
  // Operasi CRUD untuk tabel Events
  // Future<int> insertEvent(Event event) async {
  //   final db = await database;
  //   int result = 0;
  //   try {
  //     result = await db.insert('events', event.toMap());
  //     print('Hasil insertEvent: $result');
  //     return result;
  //   } catch (e) {
  //     print('Error saat insert event: $e');
  //     return 0;
  //   }
  // }

  Future<int> insertEvent(Event event) async {
  final db = await database;
  int result = 0;
  try {
    print('Data yang akan di-insert ke events: ${event.toMap()}'); // Log data
    result = await db.insert('events', event.toMap());
    print('Hasil insertEvent: $result');
    return result;
  } catch (e) {
    print('Error saat insert event: $e'); // Log error
    return 0;
  }
}

  Future<List<Event>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        nama: maps[i]['nama'],
        deskripsi: maps[i]['deskripsi'],
        tanggalPelaksanaan: maps[i]['tanggal_pelaksanaan'],
        tanggalBerakhir: maps[i]['tanggal_berakhir'],
        isActive: maps[i]['is_active'] == 1,
        isFinished: maps[i]['is_finished'] == 0,
      );
    });
  }

  Future<Event?> getEventById(int eventId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
    if (result.isNotEmpty) {
      return Event(
        id: result.first['id'],
        nama: result.first['nama'],
        deskripsi: result.first['deskripsi'],
        tanggalPelaksanaan: result.first['tanggal_pelaksanaan'],
        tanggalBerakhir: result.first['tanggal_berakhir'],
        isActive: result.first['is_active'] == 1,
        isFinished: result.first['is_finished'] == 1,
      );
    }
    return null;
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  // Fungsi untuk menghapus event berdasarkan nama (jika diperlukan)
  Future<int> deleteEventByName(String eventName) async {
    final db = await database;
    return await db.delete(
      'events',
      where: 'nama = ?',
      whereArgs: [eventName],
    );
  }

  Future<int> updateEventStatusByName(String eventName, bool isActive) async {
    final db = await database;
    return await db.update(
      'events',
      {
        'is_active': isActive ? 1 : 0,
        'is_finished': isActive ? 0 : 1, // otomatis kebalikannya
      },
      where: 'nama = ?',
      whereArgs: [eventName],
    );
  }

  //======================================================Event end========================================================

  //======================================================Participant start========================================================
  // Operasi CRUD untuk tabel Participants
  // Modifikasi fungsi insertParticipant agar bisa menerima sub_category_id
  Future<int> insertParticipant(Participant participant) async {
    final db = await database;
    try {
      final result = await db.insert('participants', participant.toMap());
      print('Hasil insertParticipant (sukses): $result');
      return result;
    } catch (e) {
      print('Error saat insert participant: $e');
      return 0;
    }
  }

  // Fungsi untuk mendapatkan semua peserta hanya berdasarkan id partcipant yg spesifik
  Future<Participant?> getParticipant(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'participants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Participant.fromMap(result.first);
    }
    return null;
  }

  // Fungsi untuk mendapatkan semua peserta berdasarkan event ID
  Future<List<Participant>> fetchParticipantsByEvent(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'participants',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return List.generate(maps.length, (i) {
      return Participant.fromMap(maps[i]);
    });
  }

  Future<List<Participant>> getParticipantsBySubCategory(int subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'participants',
      where: 'sub_category_id = ?',
      whereArgs: [subCategoryId],
    );
    return List.generate(maps.length, (i) {
      return Participant.fromMap(maps[i]);
    });
  }

  Future<int> updateParticipant(Participant participant) async {
    final db = await database;
    return await db.update(
      'participants',
      participant.toMap(),
      where: 'id = ?',
      whereArgs: [participant.id],
    );
  }

  Future<int> deleteParticipant(int id) async {
    final db = await database;
    return await db.delete(
      'participants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //======================================================Participant end========================================================

  //======================================================SubCategory start========================================================

  // Operasi CRUD untuk tabel Subcategories
  Future<int> insertSubCategory(String subCategoryName, int eventId, {int? parentId}) async {
    final db = await database;
    try {
      final result = await db.insert(
        'subcategories',
        {
          'nama': subCategoryName,
          'event_id': eventId,
          'parent_id': parentId,
        },
      );
      print('Hasil insertSubCategory (sukses): $result');
      return result;
    } catch (e) {
      print('Error saat insert subcategory: $e');
      return 0;
    }
  }

  // Fungsi untuk mendapatkan semua subkategori berdasarkan event ID
  Future<List<Map<String, dynamic>>> getSubCategoriesByEvent(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return List.generate(maps.length, (i) => {
          'id': maps[i]['id'],
          'nama': maps[i]['nama'],
          'event_id': maps[i]['event_id'],
          'parent_id': maps[i]['parent_id'],
        });
  }

  // Fungsi untuk mendapatkan semua subkategori berdasarkan event ID dan parent ID
  Future<List<int>> getSubCategoryIdsByEvent(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      columns: ['id'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return maps.map((map) => map['id'] as int).toList();
  }

  // Fungsi untuk mendapatkan semua subkategori berdasarkan parent ID di event tertentu
  Future<List<Map<String, dynamic>>> getSubCategoriesByParent(int? parentId, int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subcategories',
      where: 'parent_id = ? AND event_id = ?',
      whereArgs: [parentId, eventId],
    );
    return List.generate(maps.length, (i) => {
          'id': maps[i]['id'],
          'nama': maps[i]['nama'],
          'event_id': maps[i]['event_id'],
          'parent_id': maps[i]['parent_id'],
        });
  }

  // fungsi unutuk edit subcategory
  Future<int> updateSubCategory(int? id, String newName) async {
    final db = await database;
    return await db.update(
      'subcategories',
      {'nama': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubCategory(int id) async {
    final db = await database;
    return await db.delete(
      'subcategories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  //======================================================SubCategory end========================================================

  //======================================================Attendance start========================================================
  // Operasi CRUD untuk tabel Attendances

  Future<int> markAttendance(int participantId, int eventId, int subCategoryId,
      {required bool present}) async {
    final db = await database;
    try {
      return await db.insert(
        'attendances',
        {
          'participant_id': participantId,
          'event_id': eventId,
          'sub_category_id': subCategoryId,
          'is_present': present ? 1 : 0,
          'attendance_time': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saat menyimpan absensi: $e');
      return 0;
    }
  }

  // Fungsi untuk mendapatkan semua absensi berdasarkan event ID
  Future<List<Map<String, dynamic>>> getAttendanceByEvent(int eventId) async {
    final db = await database;
    return await db.query(
      'attendances',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'attendance_time DESC',
    );
  }

  // Fungsi untuk mendapatkan semua absensi berdasarkan event ID dan subkategori
  Future<List<Map<String, dynamic>>> getAttendanceBySubCategory(
      int eventId, int subCategoryId) async {
    final db = await database;
    return await db.query(
      'attendances',
      where: 'event_id = ? AND sub_category_id = ?',
      whereArgs: [eventId, subCategoryId],
    );
  }

  //======================================================Attendance end========================================================

  // Operasi CRUD untuk tabel Brackets
  // insertBracketMatchBasic (sudah ada)
  Future<int> insertBracketMatchBasic(int eventId, int round, int matchNumber,
      int? participant1Id, int? participant2Id, int? winnerId, [int? selectedSubCategoryId]) async {
    final db = await database;
    return await db.insert(
      'brackets',
      {
        'event_id': eventId,
        'round': round,
        'match_number': matchNumber,
        'participant1_id': participant1Id,
        'participant2_id': participant2Id,
        'sub_category_id': selectedSubCategoryId,
      },
    );
  }

  // getBracketsByEvent (sudah ada)
  Future<List<Map<String, dynamic>>> getBracketsByEvent(int eventId) async {
    final db = await database;
    return await db.query(
      'brackets',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'round, match_number',
    );
  }

  // deleteBracketsByEvent (sudah ada)
  Future<int> deleteBracketsByEvent(int eventId) async {
    final db = await database;
    return await db.delete(
      'brackets',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  // updateBracketResult (sudah ada)
  Future<int> updateBracketResult(int bracketId, int? winnerId) async {
    final db = await database;
    return await db.update(
      'brackets',
      {'winner_id': winnerId},
      where: 'id = ?',
      whereArgs: [bracketId],
    );
  }

  // updateBracketParticipants (sudah ada)
  Future<int> updateBracketParticipants(
      int bracketId, int? participant1Id, int? participant2Id) async {
    final db = await database;
    return await db.update(
      'brackets',
      {
        'participant1_id': participant1Id,
        'participant2_id': participant2Id,
      },
      where: 'id = ?',
      whereArgs: [bracketId],
    );
  }

  // getAllEvents (sudah ada)
  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        nama: maps[i]['nama'],
        deskripsi: maps[i]['deskripsi'],
        tanggalPelaksanaan: maps[i]['tanggal_pelaksanaan'],
        tanggalBerakhir: maps[i]['tanggal_berakhir'],
        isActive: maps[i]['is_active'] == 1,
        isFinished: maps[i]['is_finished'] == 1,
      );
    });
  }

  // getSubCategoriesAndParticipantsByParent (sudah ada)
  Future<List<Map<String, dynamic>>> getSubCategoriesAndParticipantsByParent(
      int? parentId, int eventId) async {
    final db = await database;
    List<Map<String, dynamic>> results = [];

    // Ambil subkategori dengan parent_id dan event_id yang sesuai
    List<Map<String, dynamic>> subCategories = await db.query(
      'subcategories',
      where: 'parent_id = ? AND event_id = ?',
      whereArgs: [parentId, eventId],
    );

    for (var subCategory in subCategories) {
      results.add({
        ...subCategory,
        'is_category': 1, // Tandai sebagai kategori
      });

      // Ambil peserta yang berada langsung di bawah subkategori ini
      List<Map<String, dynamic>> participants = await db.query(
        'participants',
        where: 'sub_category_id = ? AND event_id = ?',
        whereArgs: [subCategory['id'], eventId],
      );
      results.addAll(participants.map((participant) => {
            ...participant,
            'is_category': 0, // Tandai sebagai peserta
          }));
    }

    // Jika parentId null, ambil juga peserta level teratas (tidak berada di dalam subkategori)
    if (parentId == null) {
      List<Map<String, dynamic>> topLevelParticipants = await db.query(
        'participants',
        where: 'sub_category_id IS NULL AND event_id = ?',
        whereArgs: [eventId],
      );
      results.addAll(topLevelParticipants.map((participant) => {
            ...participant,
            'is_category': 0, // Tandai sebagai peserta
          }));
    }

    return results;
  }

  // getParticipantsByEvent (sudah ada)
  Future<List<Participant>> getParticipantsByEvent(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'participants',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return List.generate(maps.length, (i) {
      return Participant.fromMap(maps[i]);
    });
  }

  // getParticipantsByEventAndSubCategory (sudah ada)
  Future<List<Participant>> getParticipantsByEventAndSubCategory(
      int eventId, int? subCategoryId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (subCategoryId != null) {
      maps = await db.query(
        'participants',
        where: 'event_id = ? AND sub_category_id = ?',
        whereArgs: [eventId, subCategoryId],
      );
    } else {
      maps = await db.query(
        'participants',
        where: 'event_id = ? AND sub_category_id IS NULL',
        whereArgs: [eventId],
      );
    }
    return List.generate(maps.length, (i) {
      return Participant.fromMap(maps[i]);
    });
  }

  // getBracketsByEventAndSubCategory (sudah ada)
  Future<List<Map<String, dynamic>>> getBracketsByEventAndSubCategory(
      int eventId, int? subCategoryId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (subCategoryId != null) {
      maps = await db.query(
        'brackets',
        where: 'event_id = ? AND sub_category_id = ?',
        whereArgs: [eventId, subCategoryId],
        orderBy: 'round ASC, match_number ASC',
      );
    } else {
      // Menangani kasus jika subCategoryId adalah NULL di database
      maps = await db.query(
        'brackets',
        where: 'event_id = ? AND sub_category_id IS NULL',
        whereArgs: [eventId],
        orderBy: 'round ASC, match_number ASC',
      );
    }
    return maps; // Mengembalikan maps secara langsung
  }

  // deleteBracketsByEventAndSubCategory (sudah ada)
  Future<int> deleteBracketsByEventAndSubCategory(
      int eventId, int? subCategoryId) async {
    final db = await database;
    if (subCategoryId != null) {
      return await db.delete(
        'brackets',
        where: 'event_id = ? AND sub_category_id = ?',
        whereArgs: [eventId, subCategoryId],
      );
    } else {
      // Menangani kasus jika subCategoryId adalah NULL di database
      return await db.delete(
        'brackets',
        where: 'event_id = ? AND sub_category_id IS NULL',
        whereArgs: [eventId],
      );
    }
  }

  // insertManualBracketMatch (sudah ada)
  // Tidak ada perubahan di sini, karena sudah menerima winnerId dan subCategoryId
  Future<int> insertManualBracketMatch(
    int eventId,
    int round,
    int matchNumber,
    int? participant1Id,
    int? participant2Id,
    int? winnerId,
    int? subCategoryId,
  ) async {
    final db = await database;
    // Tambahkan log untuk debugging
    print('Inserting bracket match: EventID=$eventId, Round=$round, Match=$matchNumber, P1=$participant1Id, P2=$participant2Id, Winner=$winnerId, SubCat=$subCategoryId');
    return await db.insert(
      'brackets',
      {
        'event_id': eventId,
        'round': round,
        'match_number': matchNumber,
        'participant1_id': participant1Id,
        'participant2_id': participant2Id,
        'winner_id': winnerId,
        'sub_category_id': subCategoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Penting agar data lama di-overwrite
    );
  }

  getUpcomingEvents() {}

  // getSubCategoriesAndParticipantsByParent(int? parentId, int eventId) {}

}