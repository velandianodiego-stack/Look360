class UserModel {
  String id;
  String name;
  String email;
  String role; // 'user' o 'admin'
  String phone;
  String address;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.phone = '',
    this.address = '',
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['nombre'] ?? '',
        email: json['email'] ?? '',
        role: json['rol'] ?? 'user',
        phone: json['telefono'] ?? '',
        address: json['direccion'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nombre': name,
        'telefono': phone,
        'direccion': address,
        'rol': role,
      };
}