// models/participant_model.dart
class Participant {
  int? id;
  String? nama;
  int? umur;
  String? kategori;
  String? namaClubSekolah;
  int? eventId; // Tambahkan ini
  int? subCategoryId; // Tambahkan ini

  Participant({
    this.id,
    this.nama,
    this.umur,
    this.kategori,
    this.namaClubSekolah,
    this.eventId, // Inisialisasi
    this.subCategoryId, // Inisialisasi
  });

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'] as int?,
      nama: map['nama'] as String?,
      umur: map['umur'] as int?,
      kategori: map['kategori'] as String?,
      namaClubSekolah: map['nama_club_sekolah'] as String?,
      eventId: map['event_id'] as int?, 
      subCategoryId: map['sub_category_id'] as int?, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'umur': umur,
      'kategori': kategori,
      'nama_club_sekolah': namaClubSekolah,
      'event_id': eventId, 
      'sub_category_id': subCategoryId, 
    };
  }
}