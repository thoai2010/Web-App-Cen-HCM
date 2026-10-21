import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/cart_service.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import 'customer_profile_screen.dart';
import 'order_history_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeFuture;

  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _categories = [];

  final TextEditingController _searchCtrl = TextEditingController();

  final PageController _bannerController = PageController(viewportFraction: 0.9);
  int _currentBanner = 0;

  String _selectedMaLoai = "ALL";

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHome();

    // ✅ load session để có tên + avatar
    _loadSessionForHeader();

    // auto slide banner
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      _currentBanner = (_currentBanner + 1) % bannerImages.length;
      _bannerController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      return true;
    });
  }

  Future<void> _loadSessionForHeader() async {
    await UserSession.load();
    // ✅ Set maKH vào CartService
    CartService().setMaKH(UserSession.maKH);
    if (mounted) setState(() {}); // refresh header/avatar
  }

  Future<Map<String, dynamic>> _loadHome() async {
    final results = await Future.wait([
      ApiService.fetchProducts(),
      ApiService.fetchLoaiSanPham(),
    ]);

    return {
      "products": results[0],
      "categories": results[1],
    };
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // USER (NAME + AVATAR)
  String _displayName() {
    final ten = (UserSession.tenKH ?? "").trim();
    if (ten.isNotEmpty) return ten;

    final tk = (UserSession.tenDangNhap ?? "").trim();
    return tk.isNotEmpty ? tk : "Người dùng";
  }

  /// Avatar KH nằm trong assets/khachhang/
  /// backend có thể trả: "kh001.png" hoặc "/Content/khachhang/kh001.png"
  String? _assetAvatarPath() {
    final raw = (UserSession.anhDaiDien ?? "").trim();
    if (raw.isEmpty) return null;

    final fileName = raw.split('\\').last.split('/').last.trim();
    if (fileName.isEmpty) return null;

    return "assets/khachhang/$fileName";
  }

  // CATEGORY + FILTER HELPERS
  String _getMaLoaiFromCategory(Map<String, dynamic> c) {
    return (c["maLoai"] ?? c["MaLoai"] ?? c["maLOAI"] ?? "").toString().trim();
  }

  String _getMaLoaiFromProduct(Map<String, dynamic> p) {
    final direct = (p["maLoai"] ??
            p["MaLoai"] ??
            p["maLoaiSP"] ??
            p["MaLoaiSP"] ??
            p["maLoaiSanPham"] ??
            p["MaLoaiSanPham"])
        ?.toString()
        .trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final nested = (p["loaiSanPham"] ?? p["LoaiSanPham"] ?? p["loai"] ?? p["Loai"]);
    if (nested is Map) {
      final m = Map<String, dynamic>.from(nested);
      final v = (m["maLoai"] ?? m["MaLoai"] ?? m["maLoaiSP"] ?? m["MaLoaiSP"])
          ?.toString()
          .trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return "";
  }

  void _applyFilters() {
    final kw = _searchCtrl.text.trim().toLowerCase();
    List<dynamic> list = _allProducts;

    if (_selectedMaLoai != "ALL") {
      list = list.where((p) {
        final mp = _getMaLoaiFromProduct(Map<String, dynamic>.from(p));
        return mp == _selectedMaLoai;
      }).toList();
    }

    if (kw.isNotEmpty) {
      list = list.where((p) {
        final ten = (p["tenSP"] ?? p["TenSP"] ?? "").toString().toLowerCase();
        return ten.contains(kw);
      }).toList();
    }

    setState(() => _filteredProducts = list);
  }

  void _runFilter(String _) => _applyFilters();

  void _setCategory(String maLoai) {
    setState(() => _selectedMaLoai = maLoai);
    _applyFilters();
  }

  void _showUserMenu() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) {
      final avatar = _assetAvatarPath();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tài khoản",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatar != null ? AssetImage(avatar) : null,
                    child: avatar == null
                        ? const Icon(Icons.person, color: Colors.black87)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayName(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // ✅ Xem thông tin cá nhân
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: const Text(
                  "Xem thông tin cá nhân",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text("Xem và chỉnh sửa thông tin khách hàng"),
                onTap: () {
                  Navigator.pop(context); // đóng sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                  );
                },
              ),

              // ✅ Trạng thái đơn hàng
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text(
                  "Trạng thái đơn hàng",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text("Lịch sử mua hàng và trạng thái đơn"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                  );
                },
              ),

              const SizedBox(height: 8),

              // ✅ Đăng xuất
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await UserSession.clear();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    "Đăng xuất",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}


  IconData _iconForCategory(String tenLoai) {
    final t = tenLoai.toLowerCase();
    if (t.contains("dung môi") || t.contains("dung moi")) return Icons.opacity_rounded;
    if (t.contains("axit") || t.contains("acid")) return Icons.local_fire_department_rounded;
    if (t.contains("bazo") || t.contains("base")) return Icons.science_rounded;
    if (t.contains("chuẩn") || t.contains("chuan") || t.contains("standard")) {
      return Icons.hub_rounded;
    }
    return Icons.category_rounded;
  }

  Color _chipBg(bool selected) => selected ? const Color(0xFFFF7A00) : Colors.white;
  Color _chipFg(bool selected) => selected ? Colors.white : Colors.black87;
  Color _chipBorder(bool selected) => selected ? const Color(0xFFFF7A00) : Colors.black12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F8),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _homeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("Không có dữ liệu"));
            }

            final products = (snapshot.data!["products"] as List<dynamic>);
            final categories = (snapshot.data!["categories"] as List<dynamic>);

            if (products.isEmpty) return const Center(child: Text("Không có sản phẩm"));

            if (_allProducts.isEmpty) {
              _allProducts = products;
              _categories = categories;
              _filteredProducts = products;
            }

            final width = MediaQuery.of(context).size.width;
            final avatar = _assetAvatarPath();

            return CustomScrollView(
              slivers: [
                // HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Chào mừng trở lại,",
                                style: TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Text(
                              _displayName(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _showUserMenu,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.06))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: avatar != null ? AssetImage(avatar) : null,
                              child: avatar == null
                                  ? const Icon(Icons.person, color: Colors.black87)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // SEARCH
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.05),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _runFilter,
                        decoration: const InputDecoration(
                          hintText: 'Tìm hóa chất, CAS, công thức...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // BANNER
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _bannerController,
                          itemCount: bannerImages.length,
                          onPageChanged: (i) => setState(() => _currentBanner = i),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(bannerImages[index], fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          child: Row(
                            children: List.generate(
                              bannerImages.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: i == _currentBanner ? 16 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _currentBanner ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // DANH MỤC + Xem tất cả
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text("Danh mục",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _setCategory("ALL"),
                          child: const Text(
                            "Xem tất cả",
                            style: TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CHIP ROW
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _CategoryChip(
                          title: "Tất cả",
                          icon: Icons.apps_rounded,
                          selected: _selectedMaLoai == "ALL",
                          bg: _chipBg(_selectedMaLoai == "ALL"),
                          fg: _chipFg(_selectedMaLoai == "ALL"),
                          border: _chipBorder(_selectedMaLoai == "ALL"),
                          onTap: () => _setCategory("ALL"),
                        ),
                        const SizedBox(width: 10),
                        for (final c in _categories)
                          Builder(builder: (_) {
                            final m = c as Map<String, dynamic>;
                            final maLoai = _getMaLoaiFromCategory(m);
                            final tenLoai = (m["tenLoai"] ?? m["TenLoai"] ?? "Danh mục").toString();
                            final selected = _selectedMaLoai == maLoai;

                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _CategoryChip(
                                title: tenLoai,
                                icon: _iconForCategory(tenLoai),
                                selected: selected,
                                bg: _chipBg(selected),
                                fg: _chipFg(selected),
                                border: _chipBorder(selected),
                                onTap: () => _setCategory(maLoai),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // TITLE SP
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text("Danh sách sản phẩm",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                // GRID
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width >= 430 ? 2 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = _filteredProducts[index] as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.05))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                    child: _buildProductImage(p),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (p["tenSP"] ?? p["TenSP"] ?? "").toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${p['giaBan']} đ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _filteredProducts.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ảnh sản phẩm từ assets/images/products/
  Widget _buildProductImage(Map<String, dynamic> p) {
    String raw = (p['hinh'] ?? '').toString().trim();
    if (raw.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 50),
      );
    }
    final fileName = raw.split('\\').last.split('/').last;
    return Image.asset(
      'assets/images/products/$fileName',
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image, size: 50),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.title,
    required this.icon,
    required this.selected,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

final List<String> bannerImages = [
  "assets/banners/banner1.jpg",
  "assets/banners/banner2.jpg",
  "assets/banners/banner3.jpg",
];
