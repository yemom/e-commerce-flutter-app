class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String licenseNumber;
  final bool isOnline;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.vehicleType = '',
    this.licenseNumber = '',
    this.isOnline = false,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        vehicleType: json['vehicleType'] ?? '',
        licenseNumber: json['licenseNumber'] ?? '',
        isOnline: json['isOnline'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'vehicleType': vehicleType,
        'licenseNumber': licenseNumber,
        'isOnline': isOnline,
      };
}
