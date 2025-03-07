part of 'api_service.dart';

ApiResponse<T> handleResponse<T>(
  http.Response response,
  T Function(dynamic) parser,
) {
  final statusCode = response.statusCode;
  final rawBody = response.body.isEmpty || response.body == 'null' ? null : response.body;

  dynamic responseBody;
  if (rawBody != null) {
    try {
      responseBody = jsonDecode(rawBody);
    } catch (e) {
      throw ApiException(
        'Failed to parse response: $e',
        statusCode: statusCode,
      );
    }
  }

  if (statusCode >= 200 && statusCode < 300) {
    try {
      return ApiResponse<T>(
        success: true,
        data: parser(responseBody),
        message: responseBody is Map ? responseBody['message']?.toString() : null,
      );
    } catch (e) {
      throw ApiException(
        'Failed to parse response data: $e',
        statusCode: statusCode,
      );
    }
  } else {
    throw ApiException(
      responseBody is Map<String, dynamic> && responseBody['message'] != null
          ? responseBody['message'].toString()
          : 'Error: $statusCode',
      statusCode: statusCode,
    );
  }
}

Future<http.Response> interceptRequest(
  String endpoint,
  Future<http.Response> Function() request,
) async {
  final logger = LoggerFactory.createLogger(
    methodCount: 0,
    printTime: false,
  );
  final startTime = DateTime.now();
  final endTime = DateTime.now();
  final timeFormatter = DateFormat('MMMM d, yyyy h:mm:ss a');

  logger.i('Request $endpoint started: ${timeFormatter.format(startTime.toLocal())}');

  final response = await request();

  logger.i('Response $endpoint  received: ${response.statusCode} at ${timeFormatter.format(endTime.toLocal())}');
  return response;
}

Map<String, String> getHeaders() {
  return {
    'Content-Type': 'application/json;charset=UTF-8',
    'Connection': 'keep-alive',
  };
}
