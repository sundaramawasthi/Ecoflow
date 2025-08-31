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

  // -----------------------------
  // 🔹 CRUD
  // -----------------------------

  /// Stream all expenses (real-time updates)
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

  /// Stream expenses by date range (for reports, auto-updating)
  Stream<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) {
    return _userExpenses()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
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

    // Ensure Firestore stores proper Timestamp for date
    if (expense.date == null) {
      data['date'] = Timestamp.now();
    } else {
      data['date'] = Timestamp.fromDate(expense.date!);
    }

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

    if (expense.date != null) {
      data['date'] = Timestamp.fromDate(expense.date!);
    }

    data['updatedAt'] = FieldValue.serverTimestamp();

    await _userExpenses().doc(id).update(data);
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    await _userExpenses().doc(id).delete();
  }

  // -----------------------------
  // 🔹 REPORTING HELPERS
  // -----------------------------

  /// Stream total expenses (all time, auto-updating)
  Stream<double> getTotalExpenses() {
    return getExpenses().map(
      (list) => list.fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0)),
    );
  }

  /// Stream total expenses within a date range (auto-updating)
  Stream<double> getTotalExpensesByRange(DateTime start, DateTime end) {
    return getExpensesByDateRange(start, end).map(
      (list) => list.fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0)),
    );
  }

  /// One-time fetch: all expenses
  Future<List<Expense>> getAllExpenses() async {
    final snapshot = await _userExpenses()
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Expense.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// One-time total expenses (all time)
  Future<double> getTotalExpensesOnce() async {
    final expenses = await getAllExpenses();
    return expenses.fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
  }

  /// One-time total expenses within a date range
  Future<double> getTotalExpensesByRangeOnce(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _userExpenses()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final expenses = snapshot.docs
        .map((doc) => Expense.fromFirestore(doc.id, doc.data()))
        .toList();

    return expenses.fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0.0));
  }
}
