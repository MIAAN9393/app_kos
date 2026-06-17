class Waktu {
  static String tanggal() {
    var w = DateTime.now();
    return '${w.year}-${w.month.toString().padLeft(2, '0')}-${w.day.toString().padLeft(2, '0')}';
  }

  static String jam() {
    var w = DateTime.now();
    return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  }
}
