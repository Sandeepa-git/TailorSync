class Customer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;

  Customer({this.id, required this.name, this.email, this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) =>
      Customer(id: json['id'], name: json['name'], email: json['email'], phone: json['phone']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone};
}
