class Product {
  final int? id;
  final String name;
  final double price;
  final String imageUrl;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'image_url': imageUrl,
    };
  }
}
