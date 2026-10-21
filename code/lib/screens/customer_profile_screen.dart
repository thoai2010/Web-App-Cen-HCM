import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final bool isRegistration;

  const CustomerProfileScreen({
    super.key,
    this.isRegistration = false,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _bg = Color(0xFFFFF4F8);

  final _tenCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  final _diaChiCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _selectedAvatarPath = ""; // ✅ Lưu đường dẫn ảnh đã chọn

  Map<String, dynamic>? _raw;

  String get _maKH => (UserSession.maKH ?? "").trim();

  String _val(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k].toString();
    }
    return "";
  }

  String? _avatarAssetFromText(String raw) {
    final r = raw.trim();
    if (r.isEmpty) return null;
    final file = r.split('\\').last.split('/').last.trim();
    if (file.isEmpty) return null;
    return "assets/khachhang/$file";
  }

  Future<void> _load() async {
    // Nếu là mode đăng ký, không cần tải từ API
    if (widget.isRegistration) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (_maKH.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa có MaKH (chưa đăng nhập?)")),
        );
      }
      return;
    }

    try {
      final res = await ApiService.getKhachHangByMaKH(_maKH);

      final m = Map<String, dynamic>.from(res);

      _raw = m;

      _tenCtrl.text = _val(m, ["tenKH", "TenKH"]);
      _emailCtrl.text = _val(m, ["email", "Email"]);
      _sdtCtrl.text = _val(m, ["sdt", "SDT", "soDienThoai", "SoDienThoai"]);
      _diaChiCtrl.text = _val(m, ["diaChi", "DiaChi"]);
      _selectedAvatarPath = _val(m, ["anhDaiDien", "AnhDaiDien", "hinh", "Hinh"]);

      // đồng bộ header Home (nếu muốn)
      UserSession.tenKH = _tenCtrl.text.trim();
      UserSession.anhDaiDien = _selectedAvatarPath.trim().isEmpty ? null : _selectedAvatarPath.trim();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi load thông tin: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    // ✅ Validation: Kiểm tra thông tin bắt buộc
    final tenKH = _tenCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final sdt = _sdtCtrl.text.trim();
    final diaChi = _diaChiCtrl.text.trim();

    if (tenKH.isEmpty || email.isEmpty || sdt.isEmpty || diaChi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ thông tin: Họ tên, Email, SĐT, Địa chỉ"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Validation: Kiểm tra định dạng email
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email không hợp lệ. Vui lòng kiểm tra lại"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Validation: Kiểm tra SĐT (chỉ chứa số)
    if (!RegExp(r'^[0-9]{9,11}$').hasMatch(sdt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Số điện thoại không hợp lệ (phải 9-11 chữ số)"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String finalMaKH = _maKH; // ✅ Lưu maKH (cũ hoặc mới)

      // ✅ Nếu là mode đăng ký (maKH trống), tạo khách hàng mới
      if (_maKH.isEmpty && widget.isRegistration) {
        // Khi tạo mới, KHÔNG gửi maKH (backend sẽ sinh tự động)
        final body = {
          "tenKH": tenKH,
          "email": email,
          "sdt": sdt,
          "diaChi": diaChi,
          "anhDaiDien": _selectedAvatarPath.trim(),
          "tenDangNhap": UserSession.tenDangNhap ?? "", // ✅ Link với TaiKhoan
        };
        
        final response = await ApiService.createKhachHang(body);
        
        // ✅ Lấy maKH mới từ response
        finalMaKH = (response["maKH"] ?? "").toString().trim();
        if (finalMaKH.isEmpty) {
          throw Exception("Backend không trả về maKH");
        }
        
        debugPrint("✅ Tạo khách hàng thành công. MaKH: $finalMaKH");
      } else {
        // Nếu maKH có rồi, cập nhật thông tin
        if (_maKH.isEmpty) return;
        
        // Khi cập nhật, gửi maKH để xác định khách hàng
        final body = {
          "maKH": _maKH,
          "tenKH": tenKH,
          "email": email,
          "sdt": sdt,
          "diaChi": diaChi,
          "anhDaiDien": _selectedAvatarPath.trim(),
        };
        
        await ApiService.updateKhachHang(_maKH, body);
      }

      // cập nhật session với maKH đúng (mới được tạo hoặc cũ)
      await UserSession.save(
        tenDangNhap: UserSession.tenDangNhap ?? "",
        maKH: finalMaKH,
        tenKH: tenKH,
        anhDaiDien: _selectedAvatarPath.trim().isEmpty ? null : _selectedAvatarPath.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thành công")),
      );

      // Nếu là mode đăng ký, chuyển về trang đăng nhập
      if (widget.isRegistration) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi cập nhật: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ✅ Hàm chọn ảnh từ thư viện
  Future<void> _pickAvatar() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Chọn ảnh đại diện"),
        content: const Text("Bạn muốn chọn ảnh từ đâu?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Integrate image_picker here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cần cài image_picker package")),
              );
            },
            child: const Text("Thư viện"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Integrate camera here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cần cài image_picker package")),
              );
            },
            child: const Text("Camera"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _emailCtrl.dispose();
    _sdtCtrl.dispose();
    _diaChiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarAsset = _avatarAssetFromText(_selectedAvatarPath);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          widget.isRegistration ? "Hoàn tất đăng ký" : "Thông tin cá nhân",
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: !widget.isRegistration, // Không cho phép quay lại khi đang đăng ký
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 14,
                        color: Colors.black.withOpacity(0.06),
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // ✅ Avatar có thể click để chọn ảnh
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: avatarAsset != null ? AssetImage(avatarAsset) : null,
                          child: avatarAsset == null
                              ? const Icon(Icons.person, size: 30, color: Colors.black87)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tenCtrl.text.trim().isEmpty ? "Khách hàng" : _tenCtrl.text.trim(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            if (widget.isRegistration)
                              const Text(
                                "Vui lòng hoàn tất thông tin",
                                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                              )
                            else
                              Text(
                                "Mã KH: ${_maKH.isEmpty ? "---" : _maKH}",
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                      if (!widget.isRegistration)
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _field(label: "Họ tên", controller: _tenCtrl, hint: "Nhập tên khách hàng"),
                _field(
                  label: "Email",
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  hint: "example@gmail.com",
                ),
                _field(
                  label: "Số điện thoại",
                  controller: _sdtCtrl,
                  keyboardType: TextInputType.phone,
                  hint: "0xxxxxxxxx",
                ),
                _field(label: "Địa chỉ", controller: _diaChiCtrl, hint: "Nhập địa chỉ giao hàng"),

                // ✅ Thay vì textfield, dùng button để chọn ảnh
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ảnh đại diện (Tùy chọn)",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera, size: 36, color: _accent),
                            const SizedBox(height: 8),
                            Text(
                              _selectedAvatarPath.isEmpty ? "Chọn ảnh đại diện" : "Đổi ảnh",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                              ),
                            ),
                            if (_selectedAvatarPath.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedAvatarPath.split('/').last,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),

                if (_raw != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Dữ liệu server: ${_raw.toString()}",
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, -6),
              )
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.isRegistration ? "Hoàn tất đăng ký" : "Lưu thông tin",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
