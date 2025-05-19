import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String currentIp;
  final void Function(String) onIpChanged;
  const SettingsScreen({Key? key, required this.currentIp, required this.onIpChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.currentIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current ESP IP Address:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.currentIp, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Change ESP IP Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Show Notifications', style: TextStyle(fontSize: 16)),
                Switch(
                  value: _showNotifications,
                  onChanged: (val) {
                    setState(() {
                      _showNotifications = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onIpChanged(_ipController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
