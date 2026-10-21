import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _kTenDangNhap = "tenDangNhap";
  static const String _kMaKH = "maKH";
  static const String _kTenKH = "tenKH";
  static const String _kAnhDaiDien = "anhDaiDien";

  static String? tenDangNhap;
  static String? maKH;
  static String? tenKH;
  static String? anhDaiDien;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tenDangNhap = prefs.getString(_kTenDangNhap);
    maKH = prefs.getString(_kMaKH);
    tenKH = prefs.getString(_kTenKH);
    anhDaiDien = prefs.getString(_kAnhDaiDien);
  }

  static Future<void> save({
    required String tenDangNhap,
    required String maKH,
    required String tenKH,
    String? anhDaiDien,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTenDangNhap, tenDangNhap);
    await prefs.setString(_kMaKH, maKH);
    await prefs.setString(_kTenKH, tenKH);

    if (anhDaiDien != null && anhDaiDien.trim().isNotEmpty) {
      await prefs.setString(_kAnhDaiDien, anhDaiDien.trim());
    } else {
      await prefs.remove(_kAnhDaiDien);
    }

    UserSession.tenDangNhap = tenDangNhap;
    UserSession.maKH = maKH;
    UserSession.tenKH = tenKH;
    UserSession.anhDaiDien = anhDaiDien;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTenDangNhap);
    await prefs.remove(_kMaKH);
    await prefs.remove(_kTenKH);
    await prefs.remove(_kAnhDaiDien);

    tenDangNhap = null;
    maKH = null;
    tenKH = null;
    anhDaiDien = null;
  }

  static bool get isLoggedIn => (maKH ?? "").trim().isNotEmpty;
}
