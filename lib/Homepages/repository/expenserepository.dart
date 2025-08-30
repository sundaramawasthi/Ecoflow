import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/expensemodel.dart';

class ExpenseRepository {
  final _db = FirebaseFirestore.instance;

  /// Reference to current user's expenses collection
  CollectionReference<Map<String, dynamic>> _userExpenses() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(uid).collection('expenses');
  }

  /// Stream all expenses
  Stream<List<Expense>> getExpenses() {
    return _userExpenses()
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Add a new expense
  Future<void> addExpense(Expense expense) async {
    if (expense.isUnitBased) {
      if (expense.unitPrice == null || expense.unitPrice == 0) {
        throw Exception(
          "Unit price is required for unit-based category '${expense.category}'",
        );
      }
      // Calculate total amount including days
      final qty = double.tryParse(expense.unit ?? '0') ?? 0;
      final d = expense.days ?? 1;
      expense.amount = expense.unitPrice! * qty * d;
    }

    final data = expense.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _userExpenses().add(data);
  }

  /// Update an existing expense
  Future<void> updateExpense(String id, Expense expense) async {
    if (expense.isUnitBased) {
      if (expense.unitPrice == null || expense.unitPrice == 0) {
        throw Exception(
          "Unit price is required for unit-based category '${expense.category}'",
        );
      }
      final qty = double.tryParse(expense.unit ?? '0') ?? 0;
      final d = expense.days ?? 1;
      expense.amount = expense.unitPrice! * qty * d;
    }

    final data = expense.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _userExpenses().doc(id).update(data);
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    await _userExpenses().doc(id).delete();
  }
}
