import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../Homepages/model/expensemodel.dart';
import '../Homepages/repository/expenserepository.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final repo = ExpenseRepository();
  String selectedPeriod = "Month";
  List<Expense> expenses = [];

  double totalIncome = 0;
  double totalExpense = 0;
  double netBalance = 0;
  String biggestExpense = "";
  double biggestExpenseAmount = 0;
  double savings = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await repo.getAllExpenses();
    setState(() {
      expenses = data;
      _calculateSummary();
    });
  }

  void _calculateSummary() {
    totalIncome = expenses
        .where((e) => e.type == "income")
        .fold(0.0, (sum, e) => sum + e.amount);

    totalExpense = expenses
        .where((e) => e.type == "expense")
        .fold(0.0, (sum, e) => sum + e.amount);

    netBalance = totalIncome - totalExpense;

    if (expenses.any((e) => e.type == "expense")) {
      final maxExp = expenses
          .where((e) => e.type == "expense")
          .reduce((a, b) => a.amount > b.amount ? a : b);

      biggestExpense = maxExp.title;
      biggestExpenseAmount = maxExp.amount;
    } else {
      biggestExpense = "None";
      biggestExpenseAmount = 0.0;
    }

    // Prevent negative savings
    savings = netBalance < 0 ? 0.0 : netBalance;
  }

  Future<void> _exportReportAsPDF(
    double totalIncome,
    double totalExpense,
    double netBalance,
    double savings,
    List<Expense> expenses,
  ) async {
    final pdf = pw.Document();
    final safeNetBalance = netBalance < 0 ? 0.0 : netBalance;
    final safeSavings = savings < 0 ? 0.0 : savings;

    // Build category totals
    final categoryTotals = <String, double>{};
    for (var e in expenses.where((ex) => ex.type == "expense")) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Expense Report',
                style: pw.TextStyle(fontSize: 24),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Income: ₹${totalIncome.toStringAsFixed(2)}"),
                pw.Text("Total Expense: ₹${totalExpense.toStringAsFixed(2)}"),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Net Balance: ₹${safeNetBalance.toStringAsFixed(2)}"),
                pw.Text("Savings: ₹${safeSavings.toStringAsFixed(2)}"),
              ],
            ),
            pw.SizedBox(height: 14),

            // Category breakdown table
            pw.Text("Category breakdown:", style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 8),
            if (categoryTotals.isNotEmpty)
              pw.Table.fromTextArray(
                headers: ['Category', 'Amount (₹)'],
                data: categoryTotals.entries
                    .map((e) => [e.key, e.value.toStringAsFixed(2)])
                    .toList(),
              )
            else
              pw.Text("No expense categories found."),

            pw.SizedBox(height: 14),
            pw.Text("Detailed Expenses:", style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 8),
            if (expenses.isNotEmpty)
              pw.ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final ex = expenses[index];
                  final date = ex.date is DateTime
                      ? DateFormat.yMMMd().format(ex.date)
                      : '';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              ex.title,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "${ex.category} • $date",
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.Text("₹${ex.amount.toStringAsFixed(2)}"),
                      ],
                    ),
                  );
                },
              )
            else
              pw.Text("No expenses available."),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
  }

  Future<void> _downloadReportAsPdf() async {
    await _exportReportAsPDF(
      totalIncome,
      totalExpense,
      netBalance,
      savings,
      expenses,
    );

    // Show Snackbar confirmation after PDF download/ share
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF Report downloaded / shared successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safe values for UI (prevent negatives)
    final safeNetBalance = netBalance < 0 ? 0.0 : netBalance;
    final safeSavings = savings < 0 ? 0.0 : savings;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Report",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // <-- TEXT BUTTON in app bar so people clearly see "Download PDF"
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: _downloadReportAsPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                "Download PDF",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Select Period",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Period Filter with scrollable chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      {"label": "Day", "icon": Icons.today},
                      {"label": "Week", "icon": Icons.view_week},
                      {"label": "Month", "icon": Icons.calendar_month},
                      {"label": "Year", "icon": Icons.event},
                      {"label": "Custom", "icon": Icons.tune},
                    ].map((item) {
                      final label = item["label"] as String;
                      final icon = item["icon"] as IconData;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          avatar: Icon(icon, size: 18, color: Colors.white),
                          label: Text(
                            label,
                            style: GoogleFonts.poppins(
                              color: selectedPeriod == label
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: selectedPeriod == label,
                          selectedColor: Colors.blueAccent,
                          backgroundColor: Colors.grey[200],
                          onSelected: (val) {
                            setState(() {
                              selectedPeriod = label;
                              _calculateSummary();
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Summary Cards
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard(
                  "Total Income",
                  totalIncome < 0 ? 0 : totalIncome,
                  Colors.green,
                ),
                _summaryCard(
                  "Total Expense",
                  totalExpense < 0 ? 0 : totalExpense,
                  Colors.red,
                ),
                _summaryCard("Net Balance", safeNetBalance, Colors.blue),
                _summaryCard("Savings", safeSavings, Colors.purple),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              "Visual Charts",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _chartCard(_barChart()),
            const SizedBox(height: 20),

            // Pie chart: keep inside chartCard; prevent overflow by constraining internals
            _chartCard(
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 250,
                  maxHeight: 350,
                ),
                child: _pieChart(),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "Insights",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            _insightTile(
              "You saved ₹${safeSavings.toStringAsFixed(2)} this $selectedPeriod",
            ),
            _insightTile(
              "Biggest expense: $biggestExpense (₹${biggestExpenseAmount.toStringAsFixed(2)})",
            ),

            const SizedBox(height: 20),
            Text(
              "Detailed Report",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final e = expenses[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: e.type == "income"
                          ? Colors.green
                          : Colors.red,
                      child: Icon(
                        e.type == "income"
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      e.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "${e.category} • ${DateFormat.yMMMd().format(e.date)}",
                    ),
                    trailing: Text(
                      "₹${e.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: e.type == "income" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(Widget chart) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(height: 200, child: chart),
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width / 2) - 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barChart() {
    final allExpenses = expenses;

    // Unique color per category
    final categoryColors = <String, Color>{};
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];
    for (int i = 0; i < allExpenses.length; i++) {
      categoryColors[allExpenses[i].category] = colors[i % colors.length];
    }

    final barGroups = allExpenses.asMap().entries.map((entry) {
      final index = entry.key;
      final expense = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: expense.amount,
            color: categoryColors[expense.category],
            width: 18,
            borderRadius: BorderRadius.circular(4),
            rodStackItems: [
              BarChartRodStackItem(
                0,
                expense.amount,
                categoryColors[expense.category]!,
              ),
            ],
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    // Dynamic height based on number of categories or max value
    double chartHeight = 200 + (allExpenses.length * 30); // example

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY:
              allExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b) *
              1.2, // add some top padding
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= expenses.length)
                    return const SizedBox();
                  final expense = expenses[index];
                  return RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      expense.category,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x.toInt();
                if (index < 0 || index >= expenses.length) return null;
                final expense = expenses[index];
                return BarTooltipItem(
                  "${expense.category} (₹${expense.amount.toStringAsFixed(0)})",
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _pieChart() {
    // Build category totals
    Map<String, double> categoryTotals = {};
    for (var e in expenses.where((ex) => ex.type == "expense")) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    // Colors for slices (repeat if more categories)
    final sliceColors = <Color>[
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    final sections = categoryTotals.entries.toList().asMap().entries.map((
      entry,
    ) {
      final idx = entry.key;
      final e = entry.value;
      final color = sliceColors[idx % sliceColors.length];
      return PieChartSectionData(
        value: e.value,
        title: "₹${e.value.toStringAsFixed(0)}",
        radius: 60,
        color: color,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    // Legend chips (put in horizontal scroll to avoid vertical overflow)
    final legend = categoryTotals.entries.map((e) {
      final idx = categoryTotals.keys.toList().indexOf(e.key);
      final color = sliceColors[idx % sliceColors.length];
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "${e.key}: ₹${e.value.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pie chart sized to fit
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scroll legend to avoid vertical overflow
        SizedBox(
          height: 36,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: legend),
          ),
        ),
      ],
    );
  }

  Widget _insightTile(String text) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.lightbulb, color: Colors.amber),
        title: Text(
          text,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
