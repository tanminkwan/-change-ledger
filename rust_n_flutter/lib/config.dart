import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';

class Config {
  static late List<String> dhtServers;
  static late String dbConnection;

  // Load configuration from a specified file
  static Future<void> loadConfig(String configName) async {
    try {
      // Construct the file path based on the name
      final fileName = 'assets/config/config-$configName.json';
      print("Config Filename : $fileName");
      final configData = await rootBundle.loadString(fileName);
      final config = json.decode(configData);

      // Parse the config values
      dhtServers = List<String>.from(config['dhtServers']);
      dbConnection = config['dbConnection'];
    } catch (e) {
      log('Error loading configuration: $e');
      rethrow;
    }
  }
}