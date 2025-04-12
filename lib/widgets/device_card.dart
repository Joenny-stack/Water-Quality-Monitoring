import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool status;

  const DeviceCard({
    super.key,
    required this.label,
    required this.icon,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: status ? Colors.green : Colors.grey),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(status ? "On" : "Off"),
          ],
        ),
      ),
    );
  }
}
