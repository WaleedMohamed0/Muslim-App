import 'package:flutter/material.dart';

class AppState {
  const AppState({this.isConnected = false, this.themeMode = ThemeMode.light});
  final bool isConnected;
  final ThemeMode themeMode;
}
