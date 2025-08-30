import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Homepages/model/expensemodel.dart';
import '../Homepages/repository/expenserepository.dart';

class ExpenseForm extends StatefulWidget {
  final Expense? expense;
  const ExpenseForm({super.key, this.expense});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late double amount;
  late String category;
  late String type;
  late String paymentMethod;
  late DateTime date;
  String? notes;
  String? unit;
  double? unitPrice;
  int? days;

  final Map<String, double> lastUnitPrice = {};

  final List<Map<String, String>> categories = [
    {'name': 'General', 'unit': ''},
    {'name': 'Milk', 'unit': 'litre'},
    {'name': 'Fruits', 'unit': 'kg'},
    {'name': 'Fabric', 'unit': 'metre'},
    {'name': 'Eggs', 'unit': 'dozen'},
  ];

  final List<String> types = ['expense', 'income'];
  final List<String> paymentMethods = ['Cash', 'Card', 'UPI'];

  final TextEditingController unitController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    title = e?.title ?? '';
    amount = e?.amount ?? 0;
    category = e?.category ?? categories.first['name']!;
    type = e?.type ?? types.first;
    paymentMethod = e?.paymentMethod ?? paymentMethods.first;
    date = e?.date ?? DateTime.now();
    notes = e?.notes;
    unit = e?.unit;
    unitPrice = e is Expense && e.isUnitBased ? e.unitPrice : null;
    days = e?.days;

    unitController.text = unit ?? '';
    unitPriceController.text = unitPrice?.toString() ?? '';
    daysController.text = days?.toString() ?? '';

    _loadSavedUnitPrices();

    unitController.addListener(_updateAmount);
    unitPriceController.addListener(_updateAmount);
    daysController.addListener(_updateAmount);
  }

  @override
  void dispose() {
    unitController.dispose();
    unitPriceController.dispose();
    daysController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final qty = double.tryParse(unitController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0;
    final d = int.tryParse(daysController.text) ?? 1; // default 1
    setState(() {
      amount = qty * price * d;
    });
  }

  Future<void> _loadSavedUnitPrices() async {
    final prefs = await SharedPreferences.getInstance();
    for (var cat in categories) {
      if (cat['unit']!.isEmpty) continue; // skip General
      final price = prefs.getDouble("unitPrice_${cat['name']}");
      if (price != null) lastUnitPrice[cat['name']!] = price;
    }
    if (unitPrice == null && lastUnitPrice.containsKey(category)) {
      unitPrice = lastUnitPrice[category];
      unitPriceController.text = unitPrice.toString();
    }
    setState(() {});
  }

  Future<void> _saveUnitPrice(String category, double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("unitPrice_$category", price);
    lastUnitPrice[category] = price;
    unitPrice = price;
    unitPriceController.text = price.toString();
    _updateAmount();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.green),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ExpenseRepository();

    final selectedCategory = categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => categories.first,
    );
    final bool isUnitCategory = selectedCategory['unit']!.isNotEmpty;
    final String categoryUnit = selectedCategory['unit']!;

    final isWeb = MediaQuery.of(context).size.width > 600;
    final padding = isWeb ? 40.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? 'Edit Expense' : 'Add Expense'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: categories.any((c) => c['name'] == category)
                    ? category
                    : null,
                decoration: _inputDecoration('Category'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['name'],
                        child: Text(c['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  category = val!;
                  unit = '';
                  unitController.text = '';
                  daysController.text = '';
                  amount = 0;
                  if (lastUnitPrice.containsKey(category)) {
                    unitPrice = lastUnitPrice[category];
                    unitPriceController.text = unitPrice.toString();
                  } else {
                    unitPrice = null;
                    unitPriceController.text = '';
                  }
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: title,
                decoration: _inputDecoration('Title'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter title' : null,
                onSaved: (val) => title = val!,
              ),
              const SizedBox(height: 16),

              if (isUnitCategory)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enter $categoryUnit purchased'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: unitController,
                            decoration: _inputDecoration(
                              'Quantity ($categoryUnit)',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Enter quantity';
                              final number = double.tryParse(val);
                              if (number == null || number <= 0)
                                return 'Enter a valid positive number';
                              return null;
                            },
                            onSaved: (val) => unit = unitController.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            unitPrice == null ? Icons.add : Icons.edit,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            final result = await showDialog<double>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Enter price per $categoryUnit'),
                                content: TextField(
                                  controller: unitPriceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Amount per $categoryUnit (₹)',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final val = double.tryParse(
                                        unitPriceController.text.trim(),
                                      );
                                      if (val != null)
                                        Navigator.pop(context, val);
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null) {
                              await _saveUnitPrice(category, result);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: daysController,
                      decoration: _inputDecoration('Days (Optional)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
                      ],
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final number = int.tryParse(val);
                          if (number == null || number < 1)
                            return 'Enter a valid positive number';
                        }
                        return null;
                      },
                      onSaved: (val) => days = int.tryParse(val ?? '') ?? 1,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Total: ₹${amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              if (!isUnitCategory)
                TextFormField(
                  initialValue: amount != 0 ? amount.toString() : '',
                  decoration: _inputDecoration('Amount (₹)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter amount';
                    final number = double.tryParse(val);
                    if (number == null || number <= 0)
                      return 'Enter a valid positive number';
                    return null;
                  },
                  onSaved: (val) => amount = double.tryParse(val ?? '0') ?? 0,
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: types.contains(type) ? type : types.first,
                decoration: _inputDecoration('Type'),
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => type = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: _inputDecoration('Payment Method'),
                items: paymentMethods
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => paymentMethod = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat.yMMMd().format(date)),
                trailing: const Icon(Icons.calendar_today, color: Colors.green),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: notes,
                decoration: _inputDecoration('Notes (Optional)'),
                onSaved: (val) => notes = val,
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.expense != null ? 'Update' : 'Add',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();

                    if (isUnitCategory) {
                      if (unitPrice == null || unitPrice == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid unit price'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (unit == null || unit!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter quantity'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (days == null || days! < 1) days = 1;
                      amount =
                          (double.tryParse(unitController.text) ?? 0) *
                          (unitPrice ?? 0) *
                          days!;
                    }

                    final exp = Expense(
                      title: title,
                      amount: amount,
                      unit: unit,
                      unitPrice: unitPrice,
                      days: days,
                      category: category,
                      type: type,
                      paymentMethod: paymentMethod,
                      date: date,
                      notes: notes,
                    );

                    try {
                      if (widget.expense != null) {
                        await repo.updateExpense(widget.expense!.id!, exp);
                      } else {
                        await repo.addExpense(exp);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense saved successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, exp);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to save expense. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
