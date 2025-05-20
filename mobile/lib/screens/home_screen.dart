import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/device_status.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../widgets/status_tile.dart';
import 'settings_screen.dart';
import 'readings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<DeviceStatus> _statusStream = Stream.empty(); // 👈 Initialize with an empty stream
  String espIp = ''; // 👈 Initialize as empty string
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<String> _lastAlerts = [];
  int _readingSaveCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIpDialog();
    });
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Explicitly create the notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alert_channel',
      'Alerts',
      description: 'Water quality alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showAlertNotification(List<String> alerts) async {
    if (alerts.isEmpty) return;
    await flutterLocalNotificationsPlugin.show(
      0,
      'Water Quality Alert',
      alerts.join('\n'),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_channel',
          'Alerts',
          channelDescription: 'Water quality alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
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
              leading: const Icon(Icons.analytics),
              title: const Text('Readings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadingsScreen(),
                  ),
                );
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
            // Save reading to database every 30th fetch (approx every minute)
            _readingSaveCounter++;
            if (_readingSaveCounter >= 30) {
              DatabaseHelper().insertReading(data);
              _readingSaveCounter = 0;
            }
            final alerts = data.checkAlerts();
            if (alerts.isNotEmpty && alerts.toString() != _lastAlerts.toString()) {
              _showAlertNotification(alerts);
              _lastAlerts = List.from(alerts);
              // Log alerts in the database
              for (final alert in alerts) {
                DatabaseHelper().insertAlert(alert);
              }
            }
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
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Alerts",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (data.checkAlerts().isEmpty)
                              const Text(
                                "No alerts at the moment.",
                                style: TextStyle(fontSize: 16),
                              )
                            else
                              ...data.checkAlerts().map((alert) => ListTile(
                                    leading: const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      alert,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )),
                          ],
                        ),
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
