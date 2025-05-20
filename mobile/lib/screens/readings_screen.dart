import 'package:flutter/material.dart';
import 'dart:async';
import '../services/database_helper.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({Key? key}) : super(key: key);

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _readings = [];
  bool _loading = true;
  late final Timer _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchReadings();
    // Poll the database every 2 seconds for new readings
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchReadings(appendOnly: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer.cancel();
    super.dispose();
  }

  Future<void> _fetchReadings({bool appendOnly = false}) async {
    final allReadings = await DatabaseHelper().getReadings();
    List<Map<String, dynamic>> filtered = allReadings;
    if (_startDate != null && _endDate != null) {
      filtered = allReadings.where((r) {
        final ts = DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime(2000);
        return ts.isAfter(_startDate!.subtract(const Duration(days: 1))) && ts.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }
    if (appendOnly && filtered.isNotEmpty && _readings.isNotEmpty) {
      // Only add new readings
      final lastTimestamp = _readings.first['timestamp'];
      final newRows = filtered.takeWhile((r) => r['timestamp'] != lastTimestamp).toList();
      if (newRows.isNotEmpty) {
        setState(() {
          _readings = [...newRows, ..._readings];
        });
      }
    } else {
      setState(() {
        _readings = filtered;
        _loading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReadings();
    }
  }

  void _showAlertsDialog() async {
    DateTime? alertStart = _startDate;
    DateTime? alertEnd = _endDate;
    List<Map<String, dynamic>> alerts = await DatabaseHelper().getAlerts(start: alertStart, end: alertEnd);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Logged Alerts'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    tooltip: 'Filter by date',
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: (alertStart != null && alertEnd != null)
                            ? DateTimeRange(start: alertStart!, end: alertEnd!)
                            : null,
                      );
                      if (picked != null) {
                        alertStart = picked.start;
                        alertEnd = picked.end;
                        final filtered = await DatabaseHelper().getAlerts(start: alertStart, end: alertEnd);
                        setState(() {
                          alerts = filtered;
                        });
                      }
                    },
                  ),
                  if (alertStart != null && alertEnd != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear filter',
                      onPressed: () async {
                        alertStart = null;
                        alertEnd = null;
                        final allAlerts = await DatabaseHelper().getAlerts();
                        setState(() {
                          alerts = allAlerts;
                        });
                      },
                    ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: alerts.isEmpty
                    ? const Text('No alerts found.')
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Timestamp')),
                            DataColumn(label: Expanded(child: Text('Message'))),
                          ],
                          rows: alerts.map((a) => DataRow(cells: [
                            DataCell(Container(width: 140, child: Text(a['timestamp'] ?? ''))),
                            DataCell(Container(width: 220, child: Text(a['message'] ?? '', softWrap: true))),
                          ])).toList(),
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Readings History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _pickDateRange,
            tooltip: 'Filter by date',
          ),
          IconButton(
            icon: const Icon(Icons.warning),
            onPressed: _showAlertsDialog,
            tooltip: 'View Alerts',
          ),
          if (_startDate != null && _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _fetchReadings();
              },
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _readings.isEmpty
              ? const Center(child: Text('No readings found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Timestamp')),
                        DataColumn(label: Text('pH')),
                        DataColumn(label: Text('Turbidity')),
                        DataColumn(label: Text('Water Level')),
                      ],
                      rows: _readings.map((r) => DataRow(cells: [
                        DataCell(Text(r['timestamp'] ?? '')),
                        DataCell(Text(r['ph'].toString())),
                        DataCell(Text(r['turbidity'].toString())),
                        DataCell(Text(r['waterLevelRaw'].toString())),
                      ])).toList(),
                    ),
                  ),
                ),
    );
  }
}
