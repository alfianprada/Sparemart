class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final String imageUrl;

  Product({required this.id, required this.name, required this.price, required this.stock, required this.imageUrl});

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: (m['id'] ?? 0) as int,
    name: (m['name'] ?? '') as String,
    price: (m['price'] ?? 0).toDouble(),
    stock: (m['stock'] ?? 0) as int,
    imageUrl: (m['image_url'] ?? '') as String,
  );
}
