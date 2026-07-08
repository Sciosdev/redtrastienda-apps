import 'dart:async';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/domain/repositories/opportunity_request_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class OpportunityRequestRepository implements OpportunityRequestRepositoryInterface {
  final DioClient? dioClient;
  OpportunityRequestRepository({required this.dioClient});

  @override
  Future<ApiResponseModel> sendContactRequest(int productId, String? comment) async {
    try {
      final response = await dioClient!.post(
        AppConstants.opportunityRequestStore,
        data: {
          'product_id': productId,
          'comment': comment,
        },
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getMyRequests(String offset, bool getAll) async {
    try {
      final response = await dioClient!.get('${AppConstants.opportunityRequestList}${getAll ? '' : 'limit=10&'}offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
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
