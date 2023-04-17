
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../database/database_manager.dart';
import '../../web_socket/web_socket_channel.dart';

logout(context) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('jwt');
  await prefs.remove('uuid');

  DatabaseManager().closeDatabase();
  WebSocketChannel().closeChannel();

  Navigator.pushNamedAndRemoveUntil(context, '/account', (route) => false);
}
