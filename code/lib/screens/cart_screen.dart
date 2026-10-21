import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cart = CartService();

  final Map<String, bool> _selected = {};
  static const Color _accent = Color(0xFFFF7A00);

  // Cache KM theo (maSP|qty|donGia)
  final Map<String, Map<String, dynamic>> _kmCache = {};

  String _keyOf(CartItem item) {
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

    return item.name;
  }

  void _ensureSelectedInit(List<CartItem> items) {
    for (final it in items) {
      _selected.putIfAbsent(_keyOf(it), () => true);
    }
    _selected.removeWhere((k, _) => !items.any((it) => _keyOf(it) == k));
  }

  bool get _isAllSelected {
    final items = _cart.items;
    if (items.isEmpty) return false;
    return items.every((it) => _selected[_keyOf(it)] == true);
  }

  void _toggleSelectAll(bool value) {
    setState(() {
      for (final it in _cart.items) {
        _selected[_keyOf(it)] = value;
      }
    });
  }

  List<CartItem> get _selectedItems =>
      _cart.items.where((it) => _selected[_keyOf(it)] == true).toList();

  // ====== MONEY FORMAT ======
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

  // ====== IMAGE ======
  Widget _buildItemImage(CartItem item) {
    final p = item.product;

    String raw = "";
    if (p is Map && (p['hinh'] ?? p['Hinh']) != null) {
      raw = (p['hinh'] ?? p['Hinh']).toString();
    }

    try {
      // ignore: avoid_dynamic_calls
      raw = raw.isEmpty ? ((p as dynamic).hinh?.toString() ?? "") : raw;
    } catch (_) {}

    raw = raw.trim();
    if (raw.isNotEmpty) {
      final fileName = raw.split('\\').last.split('/').last;

      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          "assets/images/products/$fileName",
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
        ),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  // ====== LOAD KM FOR ITEM ======
  Future<Map<String, dynamic>> _loadKmForItem(CartItem item) async {
    final maSP = _keyOf(item);
    final key = "$maSP|${item.quantity}|${item.price}";
    if (_kmCache.containsKey(key)) return _kmCache[key]!;

    final res = await ApiService.applyKhuyenMai(
      maSP: maSP,
      soLuong: item.quantity,
      donGia: item.price,
    );

    final tongGoc = item.price * item.quantity;
    final thanhTien =
        int.tryParse((res["thanhTien"] ?? res["ThanhTien"] ?? tongGoc).toString()) ??
            tongGoc;
    final giam = int.tryParse((res["giam"] ?? res["Giam"] ?? (tongGoc - thanhTien)).toString()) ??
        (tongGoc - thanhTien);
    final applied = (res["applied"] ??
            res["Applied"] ??
            res["apDung"] ??
            res["ApDung"]) as List<dynamic>? ??
        const [];

    final data = {
      "tongGoc": tongGoc,
      "thanhTien": thanhTien,
      "giam": giam,
      "applied": applied,
    };

    _kmCache[key] = data;
    return data;
  }

  // ====== TOTALS (FOOTER) ======
  int get _totalSelectedOriginal {
    int sum = 0;
    for (final it in _cart.items) {
      if (_selected[_keyOf(it)] == true) {
        sum += it.price * it.quantity;
      }
    }
    return sum;
  }

  int get _totalSelectedAfterDiscount {
    int sum = 0;
    for (final it in _cart.items) {
      if (_selected[_keyOf(it)] != true) continue;

      final maSP = _keyOf(it);
      final cacheKey = "$maSP|${it.quantity}|${it.price}";
      final cached = _kmCache[cacheKey];

      final tongGoc = it.price * it.quantity;
      final thanhTien = cached == null
          ? tongGoc
          : int.tryParse((cached["thanhTien"] ?? tongGoc).toString()) ?? tongGoc;

      sum += thanhTien;
    }
    return sum;
  }

  int get _totalSelectedDiscount =>
      (_totalSelectedOriginal - _totalSelectedAfterDiscount).clamp(0, 1 << 30);

  void _checkout() {
  final chosen = _selectedItems;
  if (chosen.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vui lòng tick chọn sản phẩm để thanh toán")),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        selectedItems: chosen,
        tongGoc: _totalSelectedOriginal,                  // ✅ tổng gốc
        tongSauKM: _totalSelectedAfterDiscount,           // ✅ tổng sau KM
        tienGiam: _totalSelectedDiscount,                 // ✅ tiền giảm
      ),
    ),
  );
}


  Widget _priceBlock(CartItem item) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadKmForItem(item),
      builder: (context, snap) {
        final tongGoc = item.price * item.quantity;

        int thanhTien = tongGoc;
        int giam = 0;
        List<dynamic> applied = const [];

        if (snap.hasData) {
          thanhTien = int.tryParse((snap.data!["thanhTien"] ?? tongGoc).toString()) ?? tongGoc;
          giam = int.tryParse((snap.data!["giam"] ?? 0).toString()) ?? 0;
          applied = (snap.data!["applied"] as List<dynamic>?) ?? const [];
        }

        final hasDiscount = giam > 0 && thanhTien < tongGoc;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // giá sau giảm (cam) - nếu chưa load thì vẫn hiển thị tạm tongGoc
            Text(
              _money(thanhTien),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),

            if (hasDiscount) ...[
              const SizedBox(height: 2),
              // giá gốc gạch xám
              Text(
                _money(tongGoc),
                style: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              // số tiền giảm
              Text(
                "Giảm: ${_money(giam)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              // chip mã KM
              if (applied.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: applied.map((e) {
                    final m = e as Map<String, dynamic>;
                    final maKM = (m["maKM"] ?? m["MaKM"] ?? "").toString();
                    final giamKm =
                        int.tryParse((m["soTienGiam"] ?? m["SoTienGiam"] ?? 0).toString()) ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        "$maKM (-${_money(giamKm)})",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;
    _ensureSelectedInit(items);

    // ✅ Trigger load KM cho các item đang hiển thị để footer tính đúng dần
    for (final it in items) {
      final maSP = _keyOf(it);
      final cacheKey = "$maSP|${it.quantity}|${it.price}";
      if (!_kmCache.containsKey(cacheKey)) {
        _loadKmForItem(it).then((_) {
          if (mounted) setState(() {});
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Giỏ hàng"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: items.isEmpty
          ? const Center(child: Text("Giỏ hàng trống"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAllSelected,
                        activeColor: _accent,
                        onChanged: (v) => _toggleSelectAll(v ?? false),
                      ),
                      const Text(
                        "Chọn tất cả",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final key = _keyOf(item);
                      final tick = _selected[key] == true;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            Checkbox(
                              value: tick,
                              activeColor: _accent,
                              onChanged: (v) => setState(() => _selected[key] = v ?? false),
                            ),
                            _buildItemImage(item),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // ✅ PRICE + KM
                                  _priceBlock(item),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CircleIconButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    setState(() => _cart.removeOne(item.product));
                                  },
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _CircleIconButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    setState(() => _cart.addToCart(item.product));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ===== FOOTER =====
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                      children: [
                        // Chi tiết thanh toán
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
                              // Tổng sản phẩm
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Tổng sản phẩm",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    _money(_totalSelectedOriginal),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Giảm khuyến mãi
                              if (_totalSelectedDiscount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Giảm khuyến mãi",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "-${_money(_totalSelectedDiscount)}",
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

                              // Phí vận chuyển
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Phí vận chuyển",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    _money(30000),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),

                              // Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  height: 1,
                                  color: _accent.withOpacity(0.2),
                                ),
                              ),

                              // Tổng thanh toán
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Tổng thanh toán",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _money(_totalSelectedAfterDiscount + 30000),
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
                            onPressed: _checkout,
                            child: const Text(
                              "Thanh toán",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black45, width: 1),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}
