class DeviceStatus {
  final bool connected;
  final bool ledOn;
  final bool buzzerOn;
  final bool solenoidClosed;
  final double ph;
  final double turbidity;
  final int waterLevelRaw;


  DeviceStatus({
    required this.connected,
    required this.ledOn,
    required this.buzzerOn,
    required this.solenoidClosed,
    required this.ph,
    required this.turbidity,
    required this.waterLevelRaw,

  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      connected: json['connected'],
      ledOn: json['led_on'],
      buzzerOn: json['buzzer_on'],
      solenoidClosed: json['solenoid_closed'],
      ph: json['ph'].toDouble(),
      turbidity: json['turbidity'].toDouble(),
      waterLevelRaw: json['water_level_raw'],
    );
  }

  List<String> checkAlerts() {
    List<String> alerts = [];
    // Reasonable thresholds for water quality
    if (ph < 6.5 || ph > 8.5) {
      alerts.add("pH is out of range (6.5-8.5). Safe range for drinking water.");
    }
    if (turbidity > 1000.0) {
      alerts.add("Turbidity is high (>1000 NTU). Water may be unsafe.");
    }
    if (waterLevelRaw > 150) {
      alerts.add("Tank is full, Supply is closed.");
    }
    // Add more checks as needed
    return alerts;
  }
}
