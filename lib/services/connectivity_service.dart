import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _controller.stream;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((result) {
      final hasConnection = result != ConnectivityResult.none;
      _controller.add(hasConnection);
    });
  }

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _controller.close();
  }
}
