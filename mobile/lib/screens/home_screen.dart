import 'package:flutter/material.dart';
import '../models/device_status.dart';
import '../services/api_service.dart';
import '../widgets/status_tile.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<DeviceStatus> _statusStream = Stream.empty(); // 👈 Initialize with an empty stream
  String espIp = ''; // 👈 Initialize as empty string

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIpDialog();
    });
  }

  void _showIpDialog() async {
    final ipController = TextEditingController();
    final enteredIp = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter ESP IP Address"),
          content: TextField(
            controller: ipController,
            decoration: const InputDecoration(
              hintText: "e.g., 192.168.1.100",
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ipController.text),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (enteredIp != null && enteredIp.isNotEmpty) {
      setState(() {
        espIp = enteredIp;
        _statusStream = ApiService.fetchStatusStream(espIp); // 👈 Update the stream
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Quality"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      currentIp: espIp,
                      onIpChanged: (newIp) {
                        setState(() {
                          espIp = newIp;
                          _statusStream = ApiService.fetchStatusStream(espIp);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showIpDialog, // 👈 Allow retry by showing the IP dialog again
        child: const Icon(Icons.edit),
      ),
      body: StreamBuilder<DeviceStatus>(
        stream: _statusStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Status",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StatusTile(
                            label: "Connection",
                            value: data.connected ? "Connected" : "Disconnected",
                            icon: Icons.wifi,
                            color: data.connected ? Colors.green : Colors.red,
                          ),
                          StatusTile(
                            label: "LED",
                            value: data.ledOn ? "On" : "Off",
                            icon: Icons.lightbulb,
                            color: data.ledOn ? Colors.yellow : Colors.grey,
                          ),
                          StatusTile(
                            label: "Buzzer",
                            value: data.buzzerOn ? "On" : "Off",
                            icon: Icons.notifications,
                            color: data.buzzerOn ? Colors.red : Colors.grey,
                          ),
                          StatusTile(
                            label: "Solenoid",
                            value: data.solenoidClosed ? "Closed" : "Open",
                            icon: Icons.lock,
                            color: data.solenoidClosed ? Colors.green : Colors.red,
                          ),
                          StatusTile(
                            label: "PH",
                            value: data.ph.toStringAsFixed(2),
                            icon: Icons.science,
                            color: Colors.orange,
                          ),
                          StatusTile(
                            label: "Turbidity",
                            value: "${data.turbidity.toStringAsFixed(2)} NTU",
                            icon: Icons.water_drop,
                            color: data.turbidity >= 1000.0 ? Colors.red : Colors.blue,
                          ),
                          StatusTile(
                            label: "Water Level (Raw)",
                            value: data.waterLevelRaw.toString(),
                            icon: Icons.straighten,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    "Connection Error",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Failed to connect to the board.\n"
                    "This could be due to:\n"
                    "- An incorrect IP address\n"
                    "- The board and device not being on the same network\n\n"
                    "Please check and try again.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showIpDialog, // 👈 Allow retry by showing the IP dialog again
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text("No data available")); // 👈 Handle no data case
        },
      ),
    );
  }
}
