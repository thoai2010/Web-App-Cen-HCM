import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<dynamic>> _future;

@override
void initState() {
  super.initState();
  final maKH = (UserSession.maKH ?? "").trim();
  _future = maKH.isEmpty ? Future.value([]) : ApiService.fetchDonHangByMaKH(maKH);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trạng thái đơn hàng"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Lỗi: ${snap.error}"));
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text("Chưa có đơn hàng nào"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(list[i]);

              final maDH = (m["maDH"] ?? m["MaDH"] ?? "").toString();
              final trangThai = (m["trangThai"] ?? m["TrangThai"] ?? "Chờ xử lý").toString();
              final ngay = (m["ngayDat"] ?? m["NgayDat"] ?? "").toString();
              final tong = int.tryParse((m["tongTien"] ?? m["TongTien"] ?? 0).toString()) ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: m),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black.withOpacity(0.06),
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mã đơn: $maDH",
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text("Trạng thái: $trangThai",
                                style: const TextStyle(color: Colors.black54)),
                            if (ngay.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text("Ngày: $ngay", style: const TextStyle(color: Colors.black54)),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _money(tong),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
