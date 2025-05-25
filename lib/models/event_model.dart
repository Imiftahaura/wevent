class Event {
  int? id; 
  String? nama;
  String? deskripsi;
  String? tanggalPelaksanaan;
  String? tanggalBerakhir;
  bool isActive;
  bool isFinished;

  Event({
    this.id, 
    this.nama,
    this.deskripsi,
    this.tanggalPelaksanaan,
    this.tanggalBerakhir,
    this.isActive = true,
    this.isFinished = false,
  });

  get date => null;

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'nama': nama,
      'deskripsi': deskripsi,
      'tanggal_pelaksanaan': tanggalPelaksanaan,
      'tanggal_berakhir' : tanggalBerakhir,
      'is_active': isActive ? 1 : 0,
      'is_finished': isFinished ? 1 : 0,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'], 
      nama: map['nama'],
      deskripsi: map['deskripsi'],
      tanggalPelaksanaan: map['tanggal_pelaksanaan'],
      tanggalBerakhir: map['tanggal_berakhir'],
      isActive: map['is_active'] == 1,
      isFinished: map['is_finished'] ?? false,
    );
  }
}