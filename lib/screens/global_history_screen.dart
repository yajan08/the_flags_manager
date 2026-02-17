import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/inventory_log.dart';
import '../widgets/my_text_field.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class GlobalHistoryScreen extends StatefulWidget {
  const GlobalHistoryScreen({super.key});

  @override
  State<GlobalHistoryScreen> createState() => _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends State<GlobalHistoryScreen> {
  String searchQuery = "";
  DateTimeRange? selectedDateRange; // ✅ Changed from DateTime? to DateTimeRange?
  
  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  // Filter logic for the UI
  bool _applyFilters(InventoryLog log) {
    final matchesSearch = log.userEmail.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          log.flags.any((f) => f.size.contains(searchQuery));
    
    if (selectedDateRange == null) return matchesSearch;

    // ✅ Check if the log timestamp is within the selected start and end dates
    // We compare dates at 00:00:00 for the start and 23:59:59 for the end
    final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
    final startDate = DateTime(selectedDateRange!.start.year, selectedDateRange!.start.month, selectedDateRange!.start.day);
    final endDate = DateTime(selectedDateRange!.end.year, selectedDateRange!.end.month, selectedDateRange!.end.day);

    final matchesDate = logDate.isAtSameMomentAs(startDate) || 
                        logDate.isAtSameMomentAs(endDate) || 
                        (logDate.isAfter(startDate) && logDate.isBefore(endDate));

    return matchesSearch && matchesDate;
  }

  // ✅ Updated to pick a Range
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryOrange,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDateRange = picked);

      // ✅ ADD THIS POSTHOG TRACKING
      Posthog().capture(
        eventName: 'audit_logs_date_filtered',
        properties: {
          'days_range': picked.end.difference(picked.start).inDays,
          'start_date': picked.start.toIso8601String(),
          'end_date': picked.end.toIso8601String(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Audit Logs",
          style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState();
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryOrange));

                final allLogs = snapshot.data!.docs
                    .map((doc) => InventoryLog.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .where(_applyFilters)
                    .toList();

                if (allLogs.isEmpty) return _buildNoResultsState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: allLogs.length,
                  itemBuilder: (context, index) => _buildLogCard(allLogs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
              child: MyTextField(
                hintText: "Search email or size...",
                obscureText: false,
                prefixIcon: Icons.search_rounded,
                onChanged: (val) {
                  setState(() => searchQuery = val);
                  
                  // ✅ ADD THIS: Track only if search is more than 3 characters
                  if (val.length > 3) {
                    Posthog().capture(
                      eventName: 'audit_logs_searched',
                      properties: {'search_term': val},
                    );
                  }
                },
                controller: TextEditingController()..text = searchQuery..selection = TextSelection.fromPosition(TextPosition(offset: searchQuery.length)),
              ),
            ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickDateRange, // ✅ Updated call
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedDateRange != null ? primaryOrange : bgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.date_range_rounded, // ✅ Changed Icon to reflect range
                    color: selectedDateRange != null ? Colors.white : textMuted,
                  ),
                ),
              ),
              if (selectedDateRange != null)
                IconButton(
                  onPressed: () => setState(() => selectedDateRange = null),
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                )
            ],
          ),
          if (selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                "Range: ${DateFormat('dd MMM').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange!.end)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogCard(InventoryLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withAlpha(5)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getActionColor(log.action).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.action.replaceAll('_', ' '),
                  style: TextStyle(color: _getActionColor(log.action), fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
              Text(
                DateFormat('hh:mm a • dd MMM').format(log.timestamp),
                style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            log.autoDescription,
            style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: textMuted),
              const SizedBox(width: 4),
              Text(
                log.userEmail,
                style: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'ADD': return Colors.blueAccent;
      case 'TRANSFER': return primaryOrange;
      case 'WASH_START': return Colors.blueGrey;
      case 'WASH_RETURN': return Colors.green;
      case 'RECEIVE': return Colors.purpleAccent;
      default: return textMuted;
    }
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_rounded, size: 60, color: textMuted.withAlpha(50)),
          const SizedBox(height: 16),
          const Text("No logs found for these filters", style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text("Error fetching history. Check permissions."));
  }
}