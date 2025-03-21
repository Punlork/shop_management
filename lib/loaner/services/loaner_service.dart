import 'package:my_app/app/app.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerService extends BaseService {
  LoanerService(super.apiService);

  @override
  String get basePath => '/loans';

  Future<ApiResponse<PaginatedResponse<LoanerModel>>> getLoaners({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
  }) =>
      get(
        '',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'name': searchQuery,
          'customer': customer,
        }..removeWhere(
            (key, value) => value.toString().isEmpty || value == null,
          ),
        parser: (value) => value is Map
            ? PaginatedResponse.fromJson(
                value as Map<String, dynamic>,
                LoanerModel.fromJson,
              )
            : PaginatedResponse(
                items: [],
                pagination: Pagination(),
              ),
      );

  Future<ApiResponse<LoanerModel?>> createLoaner(LoanerModel body) => post(
        '',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? LoanerModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<LoanerModel?>> updateLoaner(LoanerModel body) => put(
        '/${body.id}',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? LoanerModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<dynamic>> deleteLoaner(LoanerModel body) => delete(
        '/${body.id}',
      );
}
