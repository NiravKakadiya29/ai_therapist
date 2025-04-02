import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _checkConnectivity();
  }

  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool newState = result.contains(ConnectivityResult.none);
      if (newState != _isOffline) {
        _isOffline = newState;
        notifyListeners();
      }
    });
  }
}
