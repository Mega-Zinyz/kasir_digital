class StoreProfile {
  final String name;
  final String phone;
  final String address;

  StoreProfile({
    required this.name,
    required this.phone,
    required this.address,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  /// Create from JSON
  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      name: json['name'] as String? ?? 'Toko Kasir Digital',
      phone: json['phone'] as String? ?? '08xxxxxxxxxx',
      address: json['address'] as String? ?? 'Jl. Contoh No. 123',
    );
  }

  /// Create a copy with modifications
  StoreProfile copyWith({
    String? name,
    String? phone,
    String? address,
  }) {
    return StoreProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
