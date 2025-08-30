import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  String? id;
  String title;
  double amount; // total amount (unitPrice * quantity * days)
  String? unit; // e.g., litre, kg, metre, dozen
  double? unitPrice; // price per unit
  int? days; // optional number of days
  String category;
  String type; // "expense" or "income"
  String paymentMethod;
  DateTime date;
  String? notes;
  List<String>? tags;
  bool isRecurring;
  String? recurringFrequency;
  String? receiptUrl;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    this.unit,
    this.unitPrice,
    this.days,
    required this.category,
    required this.type,
    required this.paymentMethod,
    required this.date,
    this.notes,
    this.tags,
    this.isRecurring = false,
    this.recurringFrequency,
    this.receiptUrl,
  });

  /// Create Expense from Firestore document
  factory Expense.fromFirestore(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      unit: data['unit'],
      unitPrice: data['unitPrice'] != null
          ? (data['unitPrice'] as num).toDouble()
          : null,
      days: data['days'] != null ? (data['days'] as num).toInt() : null,
      category: data['category'] ?? 'General',
      type: data['type'] ?? 'expense',
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      isRecurring: data['isRecurring'] ?? false,
      recurringFrequency: data['recurringFrequency'],
      receiptUrl: data['receiptUrl'],
    );
  }

  /// Convert Expense to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'unit': unit,
      'unitPrice': unitPrice,
      'days': days,
      'category': category,
      'type': type,
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'receiptUrl': receiptUrl,
    };
  }

  /// Check if expense is unit-based
  bool get isUnitBased =>
      unit != null && unit!.isNotEmpty && category != 'General';

  /// Calculate total amount automatically (unit * unitPrice * days)
  void calculateAmount({double? qty}) {
    if (isUnitBased && unitPrice != null) {
      final quantity = qty ?? 0;
      final d = days ?? 1;
      amount = quantity * unitPrice! * d;
    }
  }

  /// Display amount with breakdown
  String get displayAmount {
    if (isUnitBased && unitPrice != null && unit != null && unit!.isNotEmpty) {
      final d = days != null && days! > 1 ? " × $days days" : "";
      return "$unit × ₹${unitPrice!.toStringAsFixed(2)}$d = ₹${amount.toStringAsFixed(2)}";
    }
    return "₹${amount.toStringAsFixed(2)}";
  }
}
