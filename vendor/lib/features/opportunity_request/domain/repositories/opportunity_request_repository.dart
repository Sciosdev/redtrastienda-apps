import 'dart:async';
import 'package:sixvalley_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:sixvalley_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/domain/repositories/opportunity_request_repository_interface.dart';
import 'package:sixvalley_vendor_app/utill/app_constants.dart';

class OpportunityRequestRepository implements OpportunityRequestRepositoryInterface {
  final DioClient? dioClient;
  OpportunityRequestRepository({required this.dioClient});

  @override
  Future<ApiResponse> getReceivedRequests(String offset, {String? status}) async {
    try {
      final String statusQuery = (status != null && status.isNotEmpty) ? 'status=$status&' : '';
      final response = await dioClient!.get('${AppConstants.opportunityRequestListUri}${statusQuery}limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateStatus(int id, String status, String? providerResponse) async {
    try {
      final response = await dioClient!.post(
        AppConstants.opportunityRequestUpdateStatusUri,
        data: {
          'id': id,
          'status': status,
          'provider_response': providerResponse,
        },
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    throw UnimplementedError();
  }
}
