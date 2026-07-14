import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/repositories/mercado_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class MercadoRepository implements MercadoRepositoryInterface {
  final DioClient? dioClient;
  MercadoRepository({required this.dioClient});

  @override
  Future<ApiResponseModel> getPublicaciones({String? search, String? estado, String? tipo, required String offset}) async {
    try {
      final String filtros = [
        if (search != null && search.isNotEmpty) 'search=${Uri.encodeQueryComponent(search)}',
        if (estado != null && estado.isNotEmpty) 'estado=${Uri.encodeQueryComponent(estado)}',
        if (tipo != null && tipo.isNotEmpty) 'tipo=${Uri.encodeQueryComponent(tipo)}',
      ].map((filtro) => '$filtro&').join();
      final response = await dioClient!.get('${AppConstants.mercadoPublicaciones}?${filtros}limit=15&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getTienda(int userId, String offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.mercadoTienda}$userId?limit=15&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getMisPublicaciones(String offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.mercadoMisPublicaciones}limit=15&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> crearPublicacion(Map<String, String> campos, XFile? foto) async {
    try {
      final response = await dioClient!.postMultipart(
        AppConstants.mercadoPublicaciones,
        data: Map<String, dynamic>.from(campos),
        files: [
          if (foto != null)
            MultipartWithKey(
              key: 'foto',
              multipartFile: MultipartFile.fromBytes(await foto.readAsBytes(), filename: foto.name),
            ),
        ],
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> actualizarPublicacion(int id, Map<String, String> campos, XFile? foto) async {
    try {
      final response = await dioClient!.postMultipart(
        '${AppConstants.mercadoPublicaciones}/$id/actualizar',
        data: Map<String, dynamic>.from(campos),
        files: [
          if (foto != null)
            MultipartWithKey(
              key: 'foto',
              multipartFile: MultipartFile.fromBytes(await foto.readAsBytes(), filename: foto.name),
            ),
        ],
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> togglePublicacion(int id) async {
    try {
      final response = await dioClient!.post('${AppConstants.mercadoPublicaciones}/$id/toggle');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> reportarPublicacion(int id, String? motivo) async {
    try {
      final response = await dioClient!.post(
        '${AppConstants.mercadoPublicaciones}/$id/reportar',
        data: {
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        },
      );
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
