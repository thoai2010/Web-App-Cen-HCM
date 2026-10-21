import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  /// ✅ Với Android Emulator: 10.0.2.2 trỏ về máy host
  /// ⚠️ Nếu bạn dùng HTTPS dev cert, thường sẽ lỗi SSL.
  /// Nếu bị lỗi "HandshakeException", hãy dùng HTTP hoặc cấu hình cert.
  static const String baseUrl = "https://10.0.2.2:7072/api";

  static const String productUrl = "$baseUrl/SanPham";
  static const String accountUrl = "$baseUrl/TaiKhoan";
  static const String orderUrl = "$baseUrl/DonHang";
  static const String kmUrl = "$baseUrl/KhuyenMai";
  static const String loaiUrl = "$baseUrl/LoaiSanPham";

  static const _jsonHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  // ============ SẢN PHẨM ============
  static Future<List<dynamic>> fetchProducts() async {
    final res = await http
        .get(Uri.parse(productUrl), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Không lấy được dữ liệu sản phẩm: ${res.statusCode} - ${res.body}");
  }

  // ============ LOẠI SẢN PHẨM ============
  static Future<List<dynamic>> fetchLoaiSanPham() async {
    final res = await http
        .get(Uri.parse(loaiUrl), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Không lấy được loại sản phẩm: ${res.statusCode} - ${res.body}");
  }

  // ============ KHUYẾN MÃI ============
  static Future<List<dynamic>> fetchKhuyenMai() async {
    final res = await http
        .get(Uri.parse(kmUrl), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Không lấy được khuyến mãi: ${res.statusCode} - ${res.body}");
  }

  // ✅ Nếu CartScreen đang gọi applyKhuyenMai thì thêm sẵn để khỏi lỗi build.
  static Future<Map<String, dynamic>> applyKhuyenMai({
    required String maSP,
    required int soLuong,
    required int donGia,
  }) async {
    final url = Uri.parse("$kmUrl/apply");

    final res = await http
        .post(
          url,
          headers: _jsonHeaders,
          body: jsonEncode({
            "maSP": maSP,
            "soLuong": soLuong,
            "donGia": donGia,
          }),
        )
        .timeout(const Duration(seconds: 20));

    debugPrint("applyKhuyenMai STATUS: ${res.statusCode}");
    debugPrint("applyKhuyenMai BODY: ${res.body}");

    return _safeMap(res);
  }

  // ============ ĐĂNG KÝ ============
  static Future<Map<String, dynamic>> register(String username, String password) async {
    final res = await http
        .post(
          Uri.parse("$accountUrl/register"),
          headers: _jsonHeaders,
          body: jsonEncode({
            "tenDangNhap": username.trim(),
            "matKhau": password.trim(),
            "vaiTro": "KhachHang",
            "trangThai": "Hoạt động",
          }),
        )
        .timeout(const Duration(seconds: 20));

    return _safeMap(res);
  }

  // ============ ĐĂNG NHẬP ============
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http
        .post(
          Uri.parse("$accountUrl/login"),
          headers: _jsonHeaders,
          body: jsonEncode({
            "tenDangNhap": username.trim(),
            "matKhau": password.trim(),
            "vaiTro": "KhachHang",
            "trangThai": "Hoạt động",
          }),
        )
        .timeout(const Duration(seconds: 20));

    return _safeMap(res);
  }

  // ============ TẠO ĐƠN HÀNG ============
  /// ✅ Logic: tongTien = tongSauKM + phiVanChuyen (client gửi)
  /// Backend nên đối soát tổng gốc từ DB để chống sửa giá.
  static Future<Map<String, dynamic>> taoDonHang({
    String? maKH,
    required String hoTen,
    required String diaChi,
    required String sdt,
    required String email,
    required String phuongThucThanhToan,
    required List<Map<String, dynamic>> items,

    int? tongSanPham,
    int? tienGiam,
    int? phiVanChuyen,
    int? tongTien,
  }) async {
    final body = <String, dynamic>{
      "maKH": maKH,
      "hoTen": hoTen.trim(),
      "diaChi": diaChi.trim(),
      "sdt": sdt.trim(),
      "email": email.trim(),
      "phuongThucThanhToan": phuongThucThanhToan,
      "items": items,
      if (tongSanPham != null) "tongSanPham": tongSanPham,
      if (tienGiam != null) "tienGiam": tienGiam,
      if (phiVanChuyen != null) "phiVanChuyen": phiVanChuyen,
      if (tongTien != null) "tongTien": tongTien,
    };

    debugPrint("taoDonHang REQ: ${jsonEncode(body)}");

    try {
      final res = await http
          .post(
            Uri.parse(orderUrl),
            headers: _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      debugPrint("taoDonHang STATUS: ${res.statusCode}");
      debugPrint("taoDonHang BODY: ${res.body}");

      return _safeMap(res);
    } on SocketException catch (e) {
      return {
        "statusCode": 0,
        "message": "Không kết nối được server",
        "error": e.toString(),
      };
    } on HandshakeException catch (e) {
      return {
        "statusCode": 0,
        "message": "Lỗi SSL/HTTPS (Handshake). Thử dùng HTTP hoặc cấu hình chứng chỉ.",
        "error": e.toString(),
      };
    } catch (e) {
      return {
        "statusCode": 0,
        "message": "Lỗi gọi API",
        "error": e.toString(),
      };
    }
  }

  // ============ KHÁCH HÀNG ============
  static Future<Map<String, dynamic>> fetchKhachHang(String maKH) async {
    final url = Uri.parse("$baseUrl/KhachHang/$maKH");
    final res = await http.get(url, headers: _jsonHeaders).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getKhachHangByMaKH(String maKH) async {
    final url = Uri.parse("$baseUrl/KhachHang/$maKH");
    final res = await http.get(url, headers: _jsonHeaders).timeout(const Duration(seconds: 20));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception("GET KhachHang lỗi ${res.statusCode}: ${res.body}");
  }

  static Future<void> updateKhachHang(String maKH, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/KhachHang/$maKH");
    final res = await http
        .put(
          url,
          headers: _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception(res.body);
  }

  // ✅ Tạo khách hàng mới (sau đăng ký)
  static Future<Map<String, dynamic>> createKhachHang(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/KhachHang");
    final res = await http
        .post(
          url,
          headers: _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    debugPrint("createKhachHang STATUS: ${res.statusCode}");
    debugPrint("createKhachHang BODY: ${res.body}");

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {"message": "Tạo khách hàng thành công"};
    }
    throw Exception("Tạo khách hàng lỗi ${res.statusCode}: ${res.body}");
  }

  // ============ LỊCH SỬ ĐƠN HÀNG ============
  static Future<List<dynamic>> fetchDonHangByMaKH(String maKH) async {
    maKH = maKH.trim();
    if (maKH.isEmpty) return [];

    final url = Uri.parse("$baseUrl/DonHang/khachhang/$maKH");
    final res = await http.get(url, headers: _jsonHeaders).timeout(const Duration(seconds: 20));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      return decoded is List ? decoded : [];
    }

    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  // Lấy chi tiết đơn hàng theo maDH
  static Future<Map<String, dynamic>> fetchDonHangDetail(String maDH) async {
    maDH = maDH.trim();
    if (maDH.isEmpty) return {};

    final url = Uri.parse("$baseUrl/DonHang/$maDH");
    final res = await http.get(url, headers: _jsonHeaders).timeout(const Duration(seconds: 20));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    }

    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  // ============ HELPER ============
  static Map<String, dynamic> _safeMap(http.Response res) {
    try {
      final data = jsonDecode(res.body);

      if (data is Map<String, dynamic>) {
        data["statusCode"] = res.statusCode;
        data["rawBody"] = res.body; // ✅ luôn giữ rawBody để debug
        return data;
      }

      return {
        "statusCode": res.statusCode,
        "message": data.toString(),
        "rawBody": res.body,
      };
    } catch (_) {
      return {
        "statusCode": res.statusCode,
        "message": "Response không phải JSON",
        "rawBody": res.body,
      };
    }
  }
}
