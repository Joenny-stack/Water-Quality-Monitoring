import 'package:flutter/material.dart';
import '../models/device_status.dart';
import '../services/api_service.dart';
import '../widgets/status_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<DeviceStatus> _statusStream;
  final String espIp = '192.168.1.96'; // 👈 Replace with your ESP IP

  @override
  void initState() {
    super.initState();
    _statusStream = ApiService.fetchStatusStream(espIp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Water Quality Monitoring")),
      body: StreamBuilder<DeviceStatus>(
        stream: _statusStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  StatusTile(
                    label: "Connection",
                    value: data.connected ? "Connected" : "Disconnected",
                    icon: Icons.wifi,
                    color: data.connected ? Colors.green : Colors.red,
                  ),
                  StatusTile(
                    label: "Turbidity",
                    value: "${data.turbidity}%",
                    icon: Icons.water_drop,
                    color:
                        double.tryParse(data.turbidity) != null &&
                                double.parse(data.turbidity) >= 75.0
                            ? Colors.red
                            : Colors.blue,
                  ),
                  StatusTile(
                    label: "Tank Level",
                    value: data.waterDetected == "true" ? "95%" : "No",
                    icon: Icons.water,
                    color:
                        data.waterDetected == "true"
                            ? Colors.green
                            : Colors.grey,
                  ),
                  StatusTile(
                    label: "PH",
                    value: "Pending",
                    icon: Icons.science,
                    color: Colors.orange,
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
