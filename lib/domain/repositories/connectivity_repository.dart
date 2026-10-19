/// Pure domain repository contract defining network connectivity monitoring
abstract class ConnectivityRepository {
  Future<bool> checkInternetAccess();
  Stream<bool> get onConnectivityChanged;
  void dispose();
}
