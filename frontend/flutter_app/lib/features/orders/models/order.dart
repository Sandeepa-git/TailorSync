class Order {
  final int? id;
  final int customerId;
  final String garmentType;
  final String? occasion;
  final String? status;
  final String? priority;
  final String? dueDate;
  final String? completedAt;
  final String? createdAt;
  final String? tailorRemarks;
  final String? customerInstructions;
  final String? customerName;
  final String? customerPhone;
  final List<dynamic>? measurements;

  Order({
    this.id,
    required this.customerId,
    required this.garmentType,
    this.occasion,
    this.status,
    this.priority,
    this.dueDate,
    this.completedAt,
    this.createdAt,
    this.tailorRemarks,
    this.customerInstructions,
    this.customerName,
    this.customerPhone,
    this.measurements,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        customerId: json['customer_id'] ?? 0,
        garmentType: json['garment_type'] ?? '',
        occasion: json['occasion'],
        status: json['status'],
        priority: json['priority'],
        dueDate: json['due_date'],
        completedAt: json['completed_at'],
        createdAt: json['created_at'],
        tailorRemarks: json['tailor_remarks'],
        customerInstructions: json['customer_instructions'],
        customerName: json['customer_name'],
        customerPhone: json['customer_phone'],
        measurements: json['measurements'],
      );
}
