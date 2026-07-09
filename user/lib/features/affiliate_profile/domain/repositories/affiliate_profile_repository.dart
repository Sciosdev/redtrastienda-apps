import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/repositories/affiliate_profile_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class AffiliateProfileRepository implements AffiliateProfileRepositoryInterface {
  final DioClient? dioClient;
  AffiliateProfileRepository({required this.dioClient});

  // Marcador que usa el controller para mostrar el estado vacío (usuario sin
  // perfil de afiliado) en lugar de un error.
  static const String noProfileError = 'no_affiliate_profile';

  @override
  Future<ApiResponseModel> getAffiliateProfile() async {
    try {
      final response = await dioClient!.get(AppConstants.affiliateProfileUri);
      return ApiResponseModel.withSuccess(response);
    } on DioException catch (e) {
      // 404 = el usuario no tiene perfil de afiliado todavía (estado vacío amable).
      if (e.response?.statusCode == 404) {
        return ApiResponseModel.withError(noProfileError);
      }
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
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
