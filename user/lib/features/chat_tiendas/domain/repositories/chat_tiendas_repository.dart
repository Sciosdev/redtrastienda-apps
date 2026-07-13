import 'dart:async';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/repositories/chat_tiendas_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ChatTiendasRepository implements ChatTiendasRepositoryInterface {
  final DioClient? dioClient;
  ChatTiendasRepository({required this.dioClient});

  @override
  Future<ApiResponseModel> getInbox(String offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.chatTiendasInbox}limit=20&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getDirectorio(String? search, String offset) async {
    try {
      final String busqueda = (search == null || search.isEmpty) ? '' : 'search=${Uri.encodeQueryComponent(search)}&';
      final response = await dioClient!.get('${AppConstants.chatTiendasDirectorio}${busqueda}limit=20&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getMensajes(int chatId, String offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.chatTiendasBase}/$chatId/mensajes?limit=30&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> enviarMensaje(int destinatarioId, String mensaje) async {
    try {
      final response = await dioClient!.post(
        AppConstants.chatTiendasEnviar,
        data: {
          'destinatario_id': destinatarioId,
          'mensaje': mensaje,
        },
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> bloquear(int userId, String? motivo) async {
    try {
      final response = await dioClient!.post(
        AppConstants.chatTiendasBloquear,
        data: {
          'user_id': userId,
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        },
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> desbloquear(int userId) async {
    try {
      final response = await dioClient!.post(
        AppConstants.chatTiendasDesbloquear,
        data: {'user_id': userId},
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
