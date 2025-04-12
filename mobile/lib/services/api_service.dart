import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_status.dart';

class ApiService {
  static Stream<DeviceStatus> fetchStatusStream(String espIp) async* {
    while (true) {
      try {
        // final response = await http.get(Uri.parse('http://\$espIp/status'));
        final response = await http.get(
          Uri.parse('http://' + espIp + '/status'),
        );

        if (response.statusCode == 200) {
          yield DeviceStatus.fromJson(json.decode(response.body));
        } else {
          throw Exception('Failed to load status');
        }
      } catch (e) {
        yield* Stream.error(e);
      }

      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
