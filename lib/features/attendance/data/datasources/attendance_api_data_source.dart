import 'package:c360/core/error/error_codes.dart';
import 'package:c360/core/network/api_client.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:c360/features/attendance/data/models/attendance_record_model.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:dio/dio.dart';

class AttendanceApiDataSource implements AttendanceRemoteDataSource {
  AttendanceApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<String> submit(AttendanceRecord record, String selfiePath) => guardRequest(() async {
        final form = FormData.fromMap({
          'clientId': record.clientId,
          'type': record.type.api,
          'capturedAt': isoWithOffset(record.capturedAt),
          'bssid': record.bssid,
          'selfie': await MultipartFile.fromFile(
            selfiePath,
            filename: '${record.clientId}.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        });
        final data = (await _dio.post<Map<String, dynamic>>('/attendance', data: form)).data!;
        if ((data['status'] as String?)?.toUpperCase() != 'VERIFIED') {
          throw httpFailure(422, 'Face didn’t match', code: ErrorCodes.faceNotMatched);
        }
        return data['id'] as String;
      });

  @override
  Future<List<AttendanceRecord>> history(String employeeId, DateTime from, DateTime to) => guardRequest(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/attendance',
          queryParameters: {'from': formatApiDate(from), 'to': formatApiDate(to)},
        );
        final items = res.data?['items'] as List? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map((e) => AttendanceRecordModel.fromServer(e, employeeId))
            .toList();
      });
}
