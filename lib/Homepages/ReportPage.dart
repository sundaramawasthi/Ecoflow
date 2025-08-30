import 'package:ecoflown/Homepages/repository/expenserepository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'model/expensemodel.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String filterRange = "This Month";

  List<Expense> _filterExpenses(List<Expense> all) {
    DateTime now = DateTime.now();
    if (filterRange == "Today") {
      return all
          .where(
            (e) =>
                e.date.day == now.day &&
                e.date.month == now.month &&
                e.date.year == now.year,
          )
          .toList();
    } else if (filterRange == "This Week") {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return all
          .where(
            (e) =>
                e.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                e.date.isBefore(endOfWeek.add(const Duration(days: 1))),
          )
          .toList();
    } else if (filterRange == "This Year") {
      return all.where((e) => e.date.year == now.year).toList();
    } else {
      return all
          .where((e) => e.date.month == now.month && e.date.year == now.year)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ExpenseRepository();
    return StreamBuilder<List<Expense>>(
      stream: repo.getExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var allExpenses = snapshot.data ?? [];
        var expenses = _filterExpenses(allExpenses);

        Map<String, double> dailySpend = {};
        for (var e in expenses.where((e) => e.type == 'expense')) {
          String key = DateFormat('dd MMM').format(e.date);
          dailySpend[key] = (dailySpend[key] ?? 0) + e.amount;
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Report")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Filter Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Filter: "),
                    DropdownButton<String>(
                      value: filterRange,
                      items: const [
                        DropdownMenuItem(value: "Today", child: Text("Today")),
                        DropdownMenuItem(
                          value: "This Week",
                          child: Text("This Week"),
                        ),
                        DropdownMenuItem(
                          value: "This Month",
                          child: Text("This Month"),
                        ),
                        DropdownMenuItem(
                          value: "This Year",
                          child: Text("This Year"),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => filterRange = v ?? "This Month"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Expense Chart
                Card(
                  child: SizedBox(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  int index = value.toInt();
                                  if (index < 0 || index >= dailySpend.length)
                                    return const Text('');
                                  return RotatedBox(
                                    quarterTurns: 1,
                                    child: Text(
                                      dailySpend.keys.elementAt(index),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              spots: List.generate(
                                dailySpend.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  dailySpend.values.elementAt(i),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Comparison & History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // You can add more charts here for comparison
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("Future comparison chart placeholder"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
