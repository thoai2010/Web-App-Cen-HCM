import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String? imageName = product['hinh']; // ví dụ "sp002.png"

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ẢNH SẢN PHẨM
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: (imageName != null && imageName.isNotEmpty)
                      ? Image.asset(
                          "assets/images/products/$imageName",
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          height: 220,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                Text(
                  product['tenSP'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  '${product['giaBan']} đ',
                  style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Số lượng tồn: ${product['slTon']}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  'Mô tả sản phẩm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['moTa']?.toString().trim().isNotEmpty == true
                      ? product['moTa']
                      : 'Không có mô tả',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),

          // FOOTER NÚT GIỎ HÀNG
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                  CartService().addToCart(product);   // 👈 thêm vào giỏ

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm vào giỏ hàng'),
                    ),
                  );
                },

                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text(
                    'Thêm vào giỏ hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
