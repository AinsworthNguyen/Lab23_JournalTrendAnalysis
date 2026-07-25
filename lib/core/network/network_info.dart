import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    try {
      final ConnectivityResult result = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      return result != ConnectivityResult.none;
    } on Exception catch (_) {
      return false;
    }
  }
}
