class ServerException implements Exception {
  ServerException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'ServerException';
}

class CacheException implements Exception {
  CacheException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'CacheException';
}

class NetworkException implements Exception {
  NetworkException([this.message]);
  final String? message;

  @override
  String toString() => message ?? 'NetworkException';
}
