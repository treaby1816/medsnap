import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async'; 
import '../../core/theme.dart';
import '../../core/utils/seed_data.dart';
import 'pharmacy_inventory_screen.dart'; 

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _showComparison = true;
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _listenToNewOrders(); 
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _listenToNewOrders() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _showNotification(
            title: "New Order Received!",
            body: "A customer ordered ${data['medicationName'] ?? 'Medication'}",
            isAlert: true,
          );
        }
      }
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    // FIXED: Using named parameter 'settings'
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    bool isAlert = false,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vail_meds_orders',
      'Order Updates',
      channelDescription: 'Updates for pharmacy orders',
      importance: isAlert ? Importance.max : Importance.defaultImportance,
      priority: isAlert ? Priority.high : Priority.defaultPriority,
      color: isAlert ? Colors.red : AppTheme.primaryColor,
    );

    // FIXED: Added required 'id' and used named parameters
    await _notifications.show(
      id: isAlert ? 1 : 0,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  // --- ANALYTICS & CHART LOGIC ---
  List<FlSpot> _getSpotsForPeriod(List<QueryDocumentSnapshot> docs, DateTime start, DateTime end) {
    Map<int, double> dailyTotals = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = data['orderDate'] as Timestamp?;
      if (ts != null) {
        final date = ts.toDate();
        if (date.isAfter(start) && date.isBefore(end)) {
          int day = date.day;
          double price = (data['price'] ?? 0.0).toDouble();
          dailyTotals[day] = (dailyTotals[day] ?? 0.0) + price;
        }
      }
    }
    
    if (dailyTotals.isEmpty) return [const FlSpot(0, 0)];
    
    List<int> sortedDays = dailyTotals.keys.toList()..sort();
    return sortedDays.map((day) => FlSpot(day.toDouble(), dailyTotals[day]! / 1000)).toList();
  }

  Widget _buildComparisonChart(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const SizedBox(height: 150, child: Center(child: Text("No Sales Data")));

    final now = DateTime.now();
    final currentStart = DateTime(now.year, now.month, 1);
    final prevStart = DateTime(now.year, now.month - 1, 1);
    final prevEnd = DateTime(now.year, now.month, 0, 23, 59);

    final currentSpots = _getSpotsForPeriod(docs, currentStart, now);
    final prevSpots = _getSpotsForPeriod(docs, prevStart, prevEnd);

    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: currentSpots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                // FIXED: Using withValues instead of deprecated withOpacity
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            if (_showComparison)
              LineChartBarData(
                spots: prevSpots,
                isCurved: true,
                // FIXED: Using withValues instead of deprecated withOpacity
                color: Colors.grey.withValues(alpha: 0.3),
                barWidth: 2,
                dashArray: [5, 5],
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Pharmacy Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: "Manage Inventory",
              icon: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyInventoryScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(_showComparison ? Icons.stacked_line_chart : Icons.show_chart),
              onPressed: () => setState(() => _showComparison = !_showComparison),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            tabs: [Tab(text: "Pending"), Tab(text: "Analytics")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(isHistory: false),
            _buildAnalyticsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        return ListView(
          children: [
            _buildRevenueHeader(docs),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.storage),
                label: const Text("Seed Demo History"),
                onPressed: () => SeedData.seedHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            if (docs.isEmpty) 
               const Padding(
                 padding: EdgeInsets.all(20.0),
                 child: Center(child: Text("No completed orders yet.")),
               )
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['medicationName'] ?? 'Medication'),
                  subtitle: Text("₦${(data['price'] ?? 0.0).toStringAsFixed(2)}"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildRevenueHeader(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['price'] ?? 0.0).toDouble();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // FIXED: Using withValues instead of deprecated withOpacity
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MTD Revenue", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("₦${total.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                if (_showComparison)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _chartLegend(AppTheme.primaryColor, "Current"),
                      _chartLegend(Colors.grey, "Previous"),
                    ],
                  )
              ],
            ),
          ),
          _buildComparisonChart(docs),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildOrderList({required bool isHistory}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: isHistory ? 'Completed' : 'Pending')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("No orders found."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.medication, color: Colors.white, size: 20)
              ),
              title: Text(data['medicationName'] ?? 'Medication'),
              subtitle: Text("₦${(data['price'] ?? 0.0).toStringAsFixed(2)}"),
              trailing: isHistory
                  ? const Icon(Icons.verified, color: Colors.green)
                  : IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(docs[index].id)
                      .update({'status': 'Completed'});
                  
                  await _showNotification(
                    title: "Order Processed",
                    body: "${data['medicationName']} is ready.",
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}