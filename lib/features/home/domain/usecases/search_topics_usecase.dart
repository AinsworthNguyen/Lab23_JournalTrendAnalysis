import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/network/api_client.dart';

@lazySingleton
class SearchTopicsUseCase
    implements UseCase<List<Map<String, String>>, String> {
  final ApiClient _apiClient;

  SearchTopicsUseCase(this._apiClient);

  @override
  Future<Either<Failure, List<Map<String, String>>>> call(String params) async {
    try {
      final response = await _apiClient.get(
        '/topics',
        queryParameters: {'search': params, 'per_page': 10},
      );
      final results = response['results'] as List<dynamic>? ?? [];
      final list = results.map((item) {
        final map = item as Map<String, dynamic>;
        final fullId = map['id'] as String? ?? '';
        final id = fullId.split('/').last;
        return {'id': id, 'name': map['display_name'] as String? ?? ''};
      }).toList();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure('Failed to search topics: $e'));
    }
  }
}
