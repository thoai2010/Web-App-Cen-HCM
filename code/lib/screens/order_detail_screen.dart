import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;
  
  @override
  void initState() {
    super.initState();
    final maDH = (widget.order["maDH"] ?? widget.order["MaDH"] ?? "").toString().trim();
    // Tải chi tiết đơn hàng nếu backend hỗ trợ
    _detailFuture = maDH.isNotEmpty 
      ? ApiService.fetchDonHangDetail(maDH)
      : Future.value(widget.order);
  }

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

  String _val(dynamic value, [String defaultVal = ""]) {
    if (value == null) return defaultVal;
    return value.toString().trim().isEmpty ? defaultVal : value.toString().trim();
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailFuture,
      builder: (context, snap) {
        final orderData = snap.data ?? widget.order;
        
        // Lấy thông tin từ object đơn hàng
        final maDH = _val(orderData["maDH"] ?? orderData["MaDH"], "N/A");
        final trangThai = _val(orderData["trangThai"] ?? orderData["TrangThai"], "Chờ xử lý");
        final ngayDat = _val(orderData["ngayDat"] ?? orderData["NgayDat"], "");
        final ngayGiao = _val(orderData["ngayGiao"] ?? orderData["NgayGiao"], "");
        
        // Các giá tiền
        final tongSanPham = int.tryParse((orderData["tongSanPham"] ?? orderData["TongSanPham"] ?? 0).toString()) ?? 0;
        final phiVanChuyen = int.tryParse((orderData["phiVanChuyen"] ?? orderData["PhiVanChuyen"] ?? 30000).toString()) ?? 30000;
        final tienGiam = int.tryParse((orderData["tienGiam"] ?? orderData["TienGiam"] ?? 0).toString()) ?? 0;
        final tongTien = int.tryParse((orderData["tongTien"] ?? orderData["TongTien"] ?? 0).toString()) ?? 0;
        
        final hoTen = _val(orderData["hoTen"] ?? orderData["HoTen"], "");
        final sdt = _val(orderData["sdt"] ?? orderData["SDT"] ?? orderData["soDienThoai"], "");
        final email = _val(orderData["email"] ?? orderData["Email"], "");
        final diaChi = _val(orderData["diaChi"] ?? orderData["DiaChi"], "");
        final ghiChu = _val(orderData["ghiChu"] ?? orderData["GhiChu"], "");
        final phuongThucThanhToan = _val(orderData["phuongThucThanhToan"] ?? orderData["PhuongThucThanhToan"], "");

        // Chi tiết sản phẩm (nếu có)
        final chiTiet = orderData["chiTiet"] ?? orderData["chiTietDonHang"] ?? orderData["ChiTietDonHang"] ?? orderData["items"] ?? [];
        final items = chiTiet is List ? chiTiet : [];

    // Status color
    Color _statusColor() {
      final st = trangThai.toLowerCase();
      if (st.contains("hoàn thành")) return Colors.green;
      if (st.contains("đang giao") || st.contains("shipping")) return Colors.blue;
      if (st.contains("hủy") || st.contains("cancel")) return Colors.red;
      return Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết đơn hàng"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER: MÃ ĐƠN + TRẠNG THÁI =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mã đơn hàng",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      Text(
                        maDH,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Trạng thái",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trangThai,
                          style: TextStyle(
                            color: _statusColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== NGÀY ĐẶT + NGÀY GIAO =====
            if (ngayDat.isNotEmpty || ngayGiao.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ngayDat.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Ngày đặt hàng",
                              style: TextStyle(fontSize: 13, color: Colors.black54)),
                          Text(ngayDat,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (ngayGiao.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Ngày giao hàng",
                              style: TextStyle(fontSize: 13, color: Colors.black54)),
                          Text(ngayGiao,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== THÔNG TIN KHÁCH HÀNG =====
            if (hoTen.isNotEmpty ||
                sdt.isNotEmpty ||
                email.isNotEmpty ||
                diaChi.isNotEmpty ||
                phuongThucThanhToan.isNotEmpty ||
                ghiChu.isNotEmpty) ...[
              const Text(
                "Thông tin nhận hàng",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.06),
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Họ tên", hoTen),
                    _buildInfoRow("Số điện thoại", sdt),
                    _buildInfoRow("Email", email),
                    _buildInfoRow("Địa chỉ", diaChi),
                    _buildInfoRow("Phương thức thanh toán", phuongThucThanhToan),
                    _buildInfoRow("Ghi chú", ghiChu),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== CHI TIẾT SẢN PHẨM =====
            if (items.isNotEmpty) ...[
              const Text(
                "Chi tiết sản phẩm",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = Map<String, dynamic>.from(entry.value);

                final tenSP = _val(item["tenSP"] ?? item["TenSP"], "Sản phẩm");
                final giaBan = int.tryParse(
                  (item["donGia"] ?? item["giaBan"] ?? item["GiaBan"] ?? 0).toString(),
                ) ?? 0;
                final soLuong = int.tryParse(
                  (item["soLuong"] ?? item["SoLuong"] ?? 1).toString(),
                ) ?? 1;
                
                // Tính thành tiền = (số lượng × đơn giá) - (khuyến mãi ÷ số sản phẩm)
                final giamMoiSanPham = items.isNotEmpty ? tienGiam ~/ items.length : 0;
                final thanhTien = (giaBan * soLuong) - giamMoiSanPham;

                return Container(
                  margin: EdgeInsets.only(bottom: idx < items.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.06),
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenSP,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Giá: ${_money(giaBan)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Số lượng: $soLuong",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _money(thanhTien),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF7A00),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // ===== TỔNG TIỀN & THANH TOÁN =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF7A00).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tổng sản phẩm
                  if (tongSanPham > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tổng sản phẩm",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            _money(tongSanPham),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                  // Tiền giảm khuyến mãi
                  if (tienGiam > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Giảm khuyến mãi",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            "-${_money(tienGiam)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Phí vận chuyển
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Phí vận chuyển",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          _money(phiVanChuyen),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 1,
                      color: Colors.orange.withOpacity(0.2),
                    ),
                  ),

                  // Tổng tiền thanh toán
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tổng thanh toán",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _money(tongTien),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF7A00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
        );
      },
    );
  }
}
