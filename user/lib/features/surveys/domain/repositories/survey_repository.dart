import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/features/surveys/domain/models/survey_model.dart';
import 'package:get_it/get_it.dart';

abstract class SurveyRepository {
  Future<List<Survey>> getSurveys();
  Future<Survey> getSurvey(int id);
  Future<Survey> submit(int id, List<SurveyAnswer> answers);
}

class SurveyApiRepository implements SurveyRepository {
  final DioClient _client;
  static const _basePath = '/api/v1/customer/surveys';

  SurveyApiRepository({DioClient? client})
      : _client = client ?? GetIt.instance<DioClient>();

  @override
  Future<List<Survey>> getSurveys() async {
    try {
      final response = await _client.get(_basePath,
          options: Options(headers: {'Accept': 'application/json'}));
      final json = Map<String, dynamic>.from(response.data as Map);
      return (json['data'] as List)
          .map(
              (item) => Survey.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (error) {
      throw SurveyRequestException.from(error);
    }
  }

  @override
  Future<Survey> getSurvey(int id) async {
    try {
      final response = await _client.get('$_basePath/$id',
          options: Options(headers: {'Accept': 'application/json'}));
      return _parseSurvey(response.data);
    } catch (error) {
      throw SurveyRequestException.from(error);
    }
  }

  @override
  Future<Survey> submit(int id, List<SurveyAnswer> answers) async {
    try {
      final response = await _client.post('$_basePath/$id/responses',
          data: {
            'answers': answers.map((answer) => answer.toJson()).toList(),
          },
          options: Options(headers: {'Accept': 'application/json'}));
      return _parseSurvey(response.data);
    } catch (error) {
      throw SurveyRequestException.from(error);
    }
  }

  Survey _parseSurvey(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    return Survey.fromJson(json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json);
  }
}

class SurveyRequestException implements Exception {
  final String message;
  final int? statusCode;

  const SurveyRequestException(this.message, {this.statusCode});

  factory SurveyRequestException.from(Object error) {
    if (error is SurveyRequestException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 409) {
        final data = error.response?.data;
        final message = data is Map && data['message'] is String
            ? data['message'] as String
            : 'Esta encuesta ya no recibe respuestas.';
        return SurveyRequestException(message, statusCode: 409);
      }
      if (status == 401) {
        return const SurveyRequestException(
            'Tu sesión venció. Vuelve a iniciar sesión.',
            statusCode: 401);
      }
      if (status == 404) {
        return const SurveyRequestException(
            'Esta encuesta ya no está disponible.',
            statusCode: 404);
      }
      if (status == 422) {
        final data = error.response?.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final value = errors.values.first;
            final message =
                value is List && value.isNotEmpty ? value.first : value;
            if (message is String) {
              return SurveyRequestException(message, statusCode: status);
            }
          }
          if (data['message'] is String) {
            return SurveyRequestException(data['message'] as String,
                statusCode: status);
          }
        }
        return SurveyRequestException(
            'Revisa tus respuestas e inténtalo de nuevo.',
            statusCode: status);
      }
      if (error.response == null) {
        return const SurveyRequestException(
            'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.');
      }
      return SurveyRequestException(
          'No se pudo completar la solicitud. Inténtalo de nuevo.',
          statusCode: status);
    }
    return const SurveyRequestException(
        'No se pudo cargar la encuesta. Inténtalo de nuevo.');
  }
}
