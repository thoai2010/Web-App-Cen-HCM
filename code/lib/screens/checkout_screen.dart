import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  // ✅ tổng trước KM, tổng sau KM, tiền giảm
  final int tongGoc;
  final int tongSauKM;
  final int tienGiam;

  const CheckoutScreen({
    super.key,
    required this.selectedItems,
    required this.tongGoc,
    required this.tongSauKM,
    required this.tienGiam,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _payMethod = "COD";
  bool _loading = false;

  static const Color _accent = Color(0xFFFF7A00);
  static const Color _bg = Color(0xFFF6F6F6);

  // ✅ phí ship dùng chung (tránh hard-code lặp)
  static const int _phiVanChuyen = 30000;

  int get _tongSauKM => widget.tongSauKM;
  int get _tongGoc => widget.tongGoc;
  int get _tienGiam => widget.tienGiam;

  // ✅ tổng thanh toán đúng logic: sau KM + ship
  int get _tongThanhToan => _tongSauKM + _phiVanChuyen;

  String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
    }
    return "${buf.toString()} đ";
  }

  String _maSPOf(CartItem item) {
    final p = item.product;

    if (p is Map) {
      final ma = p['maSP'] ?? p['MaSP'] ?? p['masp'];
      if (ma != null) return ma.toString();
    }

    try {
      // ignore: avoid_dynamic_calls
      final ma2 = (p as dynamic).maSP;
      if (ma2 != null) return ma2.toString();
    } catch (_) {}

    return "";
  }

  void _removePurchasedItemsFromCart() {
    final cart = CartService();
    for (final it in widget.selectedItems) {
      cart.removeItem(it.product);
    }
  }

  void _showSuccessDialog(String maDH) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    size: 54, color: Colors.green),
              ),
              const SizedBox(height: 12),
              const Text(
                "Thanh toán thành công",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Mã đơn: $maDH",
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // ✅ Tổng thanh toán: sau KM + ship
              Text(
                "Tổng thanh toán: ${_money(_tongThanhToan)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              if (_tienGiam > 0) ...[
                const SizedBox(height: 6),
                Text(
                  "Giá gốc: ${_money(_tongGoc)}",
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Giảm: -${_money(_tienGiam)}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _removePurchasedItemsFromCart();
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    "Tiếp tục mua hàng",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(Map<String, dynamic> res) {
    final code = res["statusCode"]?.toString() ?? "???";
    final msg = res["message"]?.toString() ?? "Lỗi không xác định";
    final err = res["error"]?.toString();
    final inner = res["inner"]?.toString();
    final raw = res["rawBody"]?.toString();

    final detail = [
      "Status: $code",
      "Message: $msg",
      if (err != null && err.isNotEmpty) "Error: $err",
      if (inner != null && inner.isNotEmpty) "Inner: $inner",
      if (raw != null && raw.isNotEmpty) "Raw: $raw",
    ].join("\n");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Không tạo được đơn hàng"),
        content: SingleChildScrollView(child: Text(detail)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _addrCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin người nhận")),
      );
      return;
    }

    final items = widget.selectedItems
        .map((it) => {"maSP": _maSPOf(it), "soLuong": it.quantity})
        .toList();

    if (items.any((e) => (e["maSP"] as String).trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thiếu maSP trong giỏ hàng")),
      );
      return;
    }

    setState(() => _loading = true);

    final res = await ApiService.taoDonHang(
      maKH: CartService().maKH,
      hoTen: _nameCtrl.text.trim(),
      diaChi: _addrCtrl.text.trim(),
      sdt: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phuongThucThanhToan: _payMethod,
      items: items,

      // ✅ gửi để backend lưu/đối soát
      tongSanPham: _tongGoc,
      tienGiam: _tienGiam,
      phiVanChuyen: _phiVanChuyen,
      tongTien: _tongThanhToan, // ✅ chính là sau KM + ship
    );

    setState(() => _loading = false);

    final ok = (res["message"] != null) &&
        res["message"].toString().toLowerCase().contains("thành công");

    if (ok) {
      _showSuccessDialog((res["maDH"] ?? "").toString());
    } else {
      _showErrorDialog(res);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );

  Widget _field({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.selectedItems;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("Thanh toán"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tổng sản phẩm",
                            style: TextStyle(fontSize: 13, color: Colors.black54)),
                        Text(_money(_tongGoc), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_tienGiam > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Giảm khuyến mãi",
                              style: TextStyle(fontSize: 13, color: Colors.black54)),
                          Text(
                            "-${_money(_tienGiam)}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Phí vận chuyển",
                            style: TextStyle(fontSize: 13, color: Colors.black54)),
                        Text(_money(_phiVanChuyen), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(height: 1, color: _accent.withOpacity(0.2)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tổng thanh toán",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(
                          _money(_tongThanhToan),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Thanh toán",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _sectionTitle("THÔNG TIN NGƯỜI NHẬN"),
          _card(
            child: Column(
              children: [
                _field(icon: Icons.person_outline, hint: "Họ tên", controller: _nameCtrl),
                _field(icon: Icons.location_on_outlined, hint: "Địa chỉ giao hàng", controller: _addrCtrl),
                _field(icon: Icons.phone_outlined, hint: "Số điện thoại", controller: _phoneCtrl, keyboardType: TextInputType.phone),
                _field(icon: Icons.email_outlined, hint: "Email", controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
          _sectionTitle("PHƯƠNG THỨC THANH TOÁN"),
          _card(
            child: Column(
              children: [
                _PayRow(
                  title: "Thanh toán khi nhận hàng (COD)",
                  selected: _payMethod == "COD",
                  onTap: () => setState(() => _payMethod = "COD"),
                ),
                const Divider(height: 18),
                _PayRow(
                  title: "Chuyển khoản ngân hàng",
                  selected: _payMethod == "ChuyenKhoan",
                  onTap: () => setState(() => _payMethod = "ChuyenKhoan"),
                ),
              ],
            ),
          ),
          _sectionTitle("SẢN PHẨM ĐÃ CHỌN"),
          _card(
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(items[i].name,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${_money(items[i].price)} x ${items[i].quantity}"),
                    trailing: Text(
                      _money(items[i].price * items[i].quantity),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (i != items.length - 1) const Divider(height: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PayRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFFFF7A00),
            ),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
