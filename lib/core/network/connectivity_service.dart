import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  ConnectivityService(this._checker);
  final InternetConnectionChecker _checker;
  Stream<bool> get changes => _checker.onStatusChange.map((status) => status == InternetConnectionStatus.connected);
}
