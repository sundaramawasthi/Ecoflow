import 'package:ecoflown/Homepages/repository/expenserepository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'expenseform.dart';
import 'model/expensemodel.dart';

class RevenuHomePage extends StatefulWidget {
  const RevenuHomePage({super.key});

  @override
  State<RevenuHomePage> createState() => _RevenuHomePageState();
}

class _RevenuHomePageState extends State<RevenuHomePage> {
  final repo = ExpenseRepository();
  String filterRange = "This Month";
  bool sortAscending = true;
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  List<Expense> expenses = [];

  final Map<String, IconData> categoryIcons = {
    'General': Icons.category,
    'Milk': Icons.local_drink,
    'Fruits': Icons.apple,
    'Fabric': Icons.checkroom,
    'Eggs': Icons.egg,
  };

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

  void _sortExpenses() {
    expenses.sort(
      (a, b) => sortAscending
          ? a.amount.compareTo(b.amount)
          : b.amount.compareTo(a.amount),
    );
  }

  Map<String, List<Expense>> _groupByCategory(List<Expense> expList) {
    Map<String, List<Expense>> map = {};
    for (var e in expList) {
      String key = (e.category.isNotEmpty) ? e.category : 'General';
      if (!map.containsKey(key)) map[key] = [];
      map[key]!.add(e);
    }
    return map;
  }

  void _showCategorySnackbar(Expense exp) {
    String category = (exp.category.isNotEmpty) ? exp.category : 'General';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to $category'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.eco, size: 48, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "ShopFlow ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text("", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(Map<String, double> categoryTotals) {
    double totalExpenditure = categoryTotals.values.fold(
      0,
      (sum, val) => sum + val,
    );

    final isWeb = MediaQuery.of(context).size.width > 600;
    final fontSizeHeader = isWeb ? 22.0 : 18.0;
    final fontSizeSubHeader = isWeb ? 18.0 : 16.0;
    final fontSizeItem = isWeb ? 16.0 : 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Financial Overview",
                      style: TextStyle(
                        fontSize: fontSizeHeader,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: filterRange,
                      items: const [
                        DropdownMenuItem(value: "Today", child: Text("Today")),
                        DropdownMenuItem(
                          value: "This Week",
                          child: Text("Week Wise"),
                        ),
                        DropdownMenuItem(
                          value: "This Month",
                          child: Text("Month Wise"),
                        ),
                        DropdownMenuItem(
                          value: "This Year",
                          child: Text("Year Wise"),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          filterRange = v ?? "This Month";
                          expenses = _filterExpenses(expenses);
                          _sortExpenses();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total expenditure row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Expenditure",
                      style: TextStyle(
                        fontSize: fontSizeSubHeader,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹${totalExpenditure.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: fontSizeSubHeader,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Scrollable category list
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isWeb
                        ? constraints.maxHeight * 0.9
                        : constraints.maxHeight * 0.95,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: categoryTotals.entries.map((entry) {
                      final category = entry.key;
                      final categoryTotal = entry.value;
                      final items = expenses
                          .where(
                            (e) =>
                                (e.category.isEmpty ? 'General' : e.category) ==
                                category,
                          )
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        categoryIcons[category] ??
                                            Icons.category,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: fontSizeSubHeader,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "₹${categoryTotal.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: fontSizeSubHeader,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            children: items.map((e) {
                              // Parse quantity safely; default to 1.0 if parsing fails
                              final quantity =
                                  double.tryParse(e.unit ?? '1') ?? 1.0;
                              final days = e.days ?? 1;
                              final amount = e.amount ?? 0;

                              // Calculate unit price per quantity per day
                              final unitPrice = (quantity * days) > 0
                                  ? amount / (quantity * days)
                                  : amount;

                              // Determine unit name based on category
                              String unitName = '';
                              switch (category.toLowerCase()) {
                                case 'milk':
                                  unitName = 'L';
                                  break;
                                case 'fruits':
                                  unitName = 'kg';
                                  break;
                                case 'eggs':
                                  unitName = 'pcs';
                                  break;
                                case 'fabric':
                                  unitName = 'm';
                                  break;
                                default:
                                  unitName = e.unit?.trim() ?? '';
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    category.toLowerCase() == 'general'
                                        ? "• ${e.title} - ₹${amount.toStringAsFixed(2)}"
                                        : "${quantity.toStringAsFixed(2)} $unitName ${e.title} in $days day${days > 1 ? 's' : ''} = ₹${amount.toStringAsFixed(2)} "
                                              "(${unitPrice.toStringAsFixed(2)}/$unitName)",
                                    style: TextStyle(
                                      fontSize: fontSizeItem,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(
    Map<String, double> chartData,
    Map<String, String> chartLabels,
    String filterRange,
    Map<String, DateTime> chartDates,
    Map<String, double> chartQuantities, // for showing units like 5L
    Map<String, String> chartUnits, // unit name for each category
  ) {
    final maxItems = 10;

    // Sort categories by value descending
    final sortedEntries = chartData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top maxItems
    final topEntries = sortedEntries.take(maxItems).toList();

    final keys = topEntries.map((e) => e.key).toList();
    final values = topEntries.map((e) => e.value).toList();

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    double maxY = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b) * 1.4
        : 100;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top title
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: const Text(
              "Chart Analysis",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Bar chart
          SizedBox(
            height: 280,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final amount = rod.toY;
                        final quantity = chartQuantities[keys[groupIndex]] ?? 0;
                        final unit = chartUnits[keys[groupIndex]] ?? '';
                        return BarTooltipItem(
                          "${keys[groupIndex]}\n₹${amount.toStringAsFixed(2)} (${quantity.toStringAsFixed(2)}$unit)",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index < 0 || index >= keys.length)
                            return const SizedBox.shrink();

                          DateTime date =
                              chartDates[keys[index]] ?? DateTime.now();
                          String label = '';

                          switch (filterRange) {
                            case 'Today':
                              label = DateFormat('HH:mm').format(date);
                              break;
                            case 'This Week':
                              label = DateFormat('E').format(date);
                              break;
                            case 'This Month':
                              label = DateFormat('dd MMM').format(date);
                              break;
                            case 'This Year':
                              label =
                                  "${DateFormat('MMM').format(date)} (${date.year})";
                              break;
                            default:
                              label = keys[index];
                          }

                          return RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  barGroups: List.generate(values.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: colors[i % colors.length],
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }),
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOut,
              ),
            ),
          ),

          // Top of bars: category + amount + quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: keys.map((key) {
                final amount = chartData[key] ?? 0;
                final quantity = chartQuantities[key] ?? 0;
                final unit = chartUnits[key] ?? '';
                return Flexible(
                  child: Column(
                    children: [
                      Text(
                        "$key\n₹${amount.toStringAsFixed(2)} (${quantity.toStringAsFixed(2)}$unit)",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildHomePage(),
      _buildShopPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: "addBtn",
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExpenseForm()),
                );
                if (result is Expense) {
                  _sortExpenses();
                  setState(() {});
                  _showCategorySnackbar(result);
                }
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.green,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  @override
  Widget _buildHomePage() {
    return StreamBuilder<List<Expense>>(
      stream: repo.getExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var allExpenses = snapshot.data ?? [];
        expenses = _filterExpenses(allExpenses);
        _sortExpenses();

        Map<String, double> categoryTotals = {};
        Map<String, double> chartData = {};
        Map<String, String> chartLabels = {};
        Map<String, DateTime> chartDates = {};
        Map<String, double> chartQuantities = {};
        Map<String, String> chartUnits = {};

        // ✅ Aggregate by category
        for (var e in expenses.where((e) => e.type == 'expense')) {
          String catKey = e.category.isNotEmpty ? e.category : 'General';

          // Total amount
          categoryTotals[catKey] = (categoryTotals[catKey] ?? 0) + e.amount;
          chartData[catKey] = (chartData[catKey] ?? 0) + e.amount;

          // First date for bottom axis
          chartDates.putIfAbsent(catKey, () => e.date);

          // Quantity and unit
          chartQuantities[catKey] =
              (chartQuantities[catKey] ?? 0) +
              (double.tryParse(e.unit ?? '1') ?? 1);
          chartUnits[catKey] = (e.category.toLowerCase() == 'milk')
              ? 'L'
              : (e.category.toLowerCase() == 'fruits')
              ? 'kg'
              : (e.category.toLowerCase() == 'eggs')
              ? 'pcs'
              : '';
        }

        // Sort chart data and take top 6 categories
        var sortedChart = chartData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        sortedChart = sortedChart.take(6).toList();

        // Rebuild chart data and labels for top 6 items
        chartData = {};
        chartLabels = {};
        chartQuantities = {};
        chartUnits = {};
        chartDates = {};
        for (var entry in sortedChart) {
          chartData[entry.key] = entry.value;
          chartLabels[entry.key] = "₹${entry.value.toStringAsFixed(0)}";
          chartQuantities[entry.key] = chartQuantities[entry.key] ?? 0;
          chartUnits[entry.key] = chartUnits[entry.key] ?? '';
          chartDates[entry.key] = chartDates[entry.key] ?? DateTime.now();
        }

        var categoryMap = _groupByCategory(expenses);

        return Column(
          children: [
            Container(
              color: Colors.green.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: const [
                  Text(
                    "ShopFlow ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.eco, size: 28, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // ✅ Pass all chart data to _buildChart
                    _buildChart(
                      chartData,
                      chartLabels,
                      filterRange,
                      chartDates,
                      chartQuantities,
                      chartUnits,
                    ),
                    const SizedBox(height: 20),

                    // Financial overview
                    _buildFinancialOverview(categoryTotals),
                    const SizedBox(height: 20),

                    // Sorting recent transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton<bool>(
                          icon: const Icon(Icons.sort, color: Colors.green),
                          tooltip: "Sort",
                          onSelected: (value) {
                            setState(() {
                              sortAscending = value;
                              _sortExpenses();
                            });
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: true,
                              child: Text("Less → More"),
                            ),
                            PopupMenuItem(
                              value: false,
                              child: Text("More → Less"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Display category sections with swipe-to-delete functionality
                    ...categoryMap.entries.map(
                      (entry) => Dismissible(
                        key: ValueKey(entry.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          for (var exp in entry.value) {
                            await repo.deleteExpense(
                              exp.id!,
                            ); // Delete the expense
                          }
                          setState(() {}); // Trigger UI update after delete
                        },
                        child: _buildCategorySection(entry.key, entry.value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(String category, List<Expense> items) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final fontSize = isWeb ? 16.0 : 14.0;
    final rowSpacing = isWeb ? 12.0 : 6.0;

    return ExpansionTile(
      title: Text(
        "$category (${items.length})",
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      leading: Icon(
        categoryIcons[category] ?? Icons.category,
        color: Colors.green,
        size: 28, // smaller cute icon
      ),
      children: items.map((exp) {
        double quantity = 1;
        String unitName = '';

        if (exp.unit != null && exp.unit!.isNotEmpty) {
          final parts = exp.unit!.split(' ');
          quantity = double.tryParse(parts.first) ?? 1;

          switch (category.toLowerCase()) {
            case 'milk':
              unitName = 'L';
              break;
            case 'fruits':
              unitName = 'kg';
              break;
            case 'eggs':
              unitName = 'pcs';
              break;
            case 'fabric':
              unitName = 'm';
              break;
            default:
              unitName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
        }

        final unitPrice = (quantity > 0) ? exp.amount / quantity : exp.amount;

        return Dismissible(
          key: ValueKey(exp.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await repo.deleteExpense(exp.id!);
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50, // highlight item
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: rowSpacing),
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(
                  categoryIcons[exp.category] ?? Icons.money_off,
                  color: Colors.white,
                  size: 14, // smaller icon
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp.title, style: TextStyle(fontSize: fontSize)),
                  if (category.toLowerCase() != 'general')
                    Text(
                      "${quantity.toStringAsFixed(2)} $unitName • ₹${unitPrice.toStringAsFixed(2)}/$unitName",
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black87,
                      ),
                    ),
                  if (category.toLowerCase() == 'general')
                    Text(
                      "₹${exp.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
              trailing: GestureDetector(
                onTap: () {
                  // Open ExpenseForm in edit mode
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseForm(expense: exp),
                    ),
                  ).then((value) {
                    if (value != null) setState(() {}); // refresh list
                  });
                },
                child: const Icon(Icons.edit, size: 18, color: Colors.blue),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShopPage() =>
      const Center(child: Text("Shop Page - Coming Soon!"));
  Widget _buildProfilePage() =>
      const Center(child: Text("Profile Page - Coming Soon!"));
}
