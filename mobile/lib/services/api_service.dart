import 'dart:async';
import 'dart:convert';
import 'dart:developer'; // For logging
import 'package:http/http.dart' as http;
import '../models/device_status.dart';

class ApiService {
  static Stream<DeviceStatus> fetchStatusStream(String espIp) async* {
    while (true) {
      try {
        log('Attempting to fetch status from http://$espIp/status'); // Log the request
        final response = await http
            .get(Uri.parse('http://10.40.147.177/status'))
            .timeout(const Duration(seconds: 10)); // Add timeout

        log('Response status: ${response.statusCode}'); // Log response status
        log('Response body: ${response.body}'); // Log response body

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          yield DeviceStatus.fromJson(json); // Yield valid data
        } else {
          log('Error: Received status code ${response.statusCode}');
          yield* Stream.error('Error: Received status code ${response.statusCode}');
        }
      } catch (e) {
        log('Connection error: $e', error: e); // Log the error
        yield* Stream.error('Failed to connect to the board. Please check the IP address.');
      }

      await Future.delayed(const Duration(seconds: 1)); // Continue fetching
    }
  }
}
