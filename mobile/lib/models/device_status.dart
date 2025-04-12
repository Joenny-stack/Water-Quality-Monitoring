class DeviceStatus {
  final bool connected;
  final bool ledOn;
  final bool buzzerOn;
  final String turbidity;
  final String waterDetected; // Change to String

  DeviceStatus({
    required this.connected,
    required this.ledOn,
    required this.buzzerOn,
    required this.turbidity,
    required this.waterDetected, // Change to String
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      connected: json['connected'],
      ledOn: json['led_on'],
      buzzerOn: json['buzzer_on'],
      turbidity: json['turbidity'].toString(),
      waterDetected: json['water_detected'].toString(), // Parse as String
    );
  }
}
