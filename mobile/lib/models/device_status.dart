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
}
