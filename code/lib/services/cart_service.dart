// lib/services/cart_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;
  String? maKH; // ✅ Mã khách hàng

  CartItem({
    required this.product,
    this.quantity = 1,
    this.maKH,
  });

  int get price => (product['giaBan'] as int? ?? 0);
  String get name => product['tenSP']?.toString() ?? '';

  // ✅ Chuyển CartItem thành JSON để lưu
  Map<String, dynamic> toJson() => {
    'product': product,
    'quantity': quantity,
    'maKH': maKH,
  };

  // ✅ Tạo CartItem từ JSON
  static CartItem fromJson(Map<String, dynamic> json) => CartItem(
    product: json['product'] as Map<String, dynamic>,
    quantity: json['quantity'] as int? ?? 1,
    maKH: json['maKH'] as String?,
  );
}

class CartService {
  CartService._internal();
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  static const String _key = "cart_items"; // ✅ Key để lưu vào SharedPreferences

  final List<CartItem> _items = [];
  String? _maKH; // ✅ Lưu mã khách hàng chung

  List<CartItem> get items => List.unmodifiable(_items);

  String? get maKH => _maKH;
  
  // ✅ Load giỏ hàng từ SharedPreferences
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _items.clear();
        for (final item in decoded) {
          _items.add(CartItem.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      print("❌ Lỗi load cart: $e");
    }
  }

  // ✅ Lưu giỏ hàng vào SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_key, jsonString);
    } catch (e) {
      print("❌ Lỗi lưu cart: $e");
    }
  }
  
  // ✅ Set mã khách hàng
  void setMaKH(String? maKH) {
    _maKH = maKH;
    // Cập nhật toàn bộ items có maKH
    for (var item in _items) {
      item.maKH = maKH;
    }
  }

  void addToCart(Map<String, dynamic> product) {
    final id = product['maSP']?.toString() ?? '';

    // nếu cùng sản phẩm thì tăng số lượng
    final index = _items.indexWhere(
      (e) => e.product['maSP']?.toString() == id,
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, maKH: _maKH));
    }
    _saveCart(); // ✅ Lưu sau khi thêm
  }

  void removeOne(Map<String, dynamic> product) {
    final id = product['maSP']?.toString() ?? '';
    final index = _items.indexWhere(
      (e) => e.product['maSP']?.toString() == id,
    );
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }
    _saveCart(); // ✅ Lưu sau khi xóa
  }

  void removeItem(Map<String, dynamic> product) {
    final id = product['maSP']?.toString() ?? '';
    _items.removeWhere(
      (e) => e.product['maSP']?.toString() == id,
    );
    _saveCart(); // ✅ Lưu sau khi xóa item
  }

  void clear() {
    _items.clear();
    _saveCart(); // ✅ Lưu sau khi xóa hết
  }

  int get total {
    int sum = 0;
    for (final item in _items) {
      sum += item.price * item.quantity;
    }
    return sum;
  }

  bool get isEmpty => _items.isEmpty;
}
