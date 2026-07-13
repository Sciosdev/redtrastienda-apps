import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/conversacion_tienda_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/mensaje_tienda_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/services/chat_tiendas_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

class ChatTiendasController with ChangeNotifier {
  final ChatTiendasServiceInterface chatTiendasServiceInterface;
  ChatTiendasController({required this.chatTiendasServiceInterface});

  ConversacionesTiendaModel? conversacionesModel;
  bool _isInboxLoading = false;
  bool get isInboxLoading => _isInboxLoading;

  DirectorioTiendasModel? directorioModel;
  bool _isDirectorioLoading = false;
  bool get isDirectorioLoading => _isDirectorioLoading;
  String _searchDirectorio = '';

  MensajesTiendaModel? mensajesModel;
  bool _isMensajesLoading = false;
  bool get isMensajesLoading => _isMensajesLoading;
  bool _isEnviando = false;
  bool get isEnviando => _isEnviando;

  Future<void> getInbox({int offset = 1}) async {
    _isInboxLoading = true;
    if (offset == 1) {
      notifyListeners();
    }

    ApiResponseModel apiResponse = await chatTiendasServiceInterface.getInbox(offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final ConversacionesTiendaModel pagina = ConversacionesTiendaModel.fromJson(apiResponse.response?.data);
      if (offset == 1) {
        conversacionesModel = pagina;
      } else {
        conversacionesModel!.data!.addAll(pagina.data ?? []);
        conversacionesModel!.offset = pagina.offset;
        conversacionesModel!.totalSize = pagina.totalSize;
      }
    }

    _isInboxLoading = false;
    notifyListeners();
  }

  Future<void> getDirectorio({int offset = 1, String? search}) async {
    if (offset == 1) {
      _searchDirectorio = search ?? '';
      _isDirectorioLoading = true;
      notifyListeners();
    }

    ApiResponseModel apiResponse = await chatTiendasServiceInterface.getDirectorio(_searchDirectorio, offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final DirectorioTiendasModel pagina = DirectorioTiendasModel.fromJson(apiResponse.response?.data);
      if (offset == 1) {
        directorioModel = pagina;
      } else {
        directorioModel!.data!.addAll(pagina.data ?? []);
        directorioModel!.offset = pagina.offset;
        directorioModel!.totalSize = pagina.totalSize;
      }
    }

    _isDirectorioLoading = false;
    notifyListeners();
  }

  /// Prepara la pantalla de conversación antes de tener mensajes cargados
  /// (desde el directorio la conversación puede aún no existir).
  void abrirConversacion({required AfiliadoDirectorio contraparte, int? chatId}) {
    mensajesModel = MensajesTiendaModel(
      chatId: chatId,
      contraparte: contraparte,
      bloqueadoPorMi: false,
      data: [],
      totalSize: 0,
    );
  }

  /// offset 1 con [silencioso] = polling: agrega al frente solo los mensajes
  /// nuevos, sin perder las páginas viejas ya cargadas ni mostrar loader.
  Future<void> getMensajes(int chatId, {int offset = 1, bool silencioso = false}) async {
    if (offset == 1 && !silencioso) {
      _isMensajesLoading = true;
      notifyListeners();
    }

    ApiResponseModel apiResponse = await chatTiendasServiceInterface.getMensajes(chatId, offset.toString());

    // Respuesta tardía de otra conversación (el usuario ya abrió otro chat):
    // se descarta para no pisar el modelo activo.
    final bool respuestaDeOtraConversacion =
        mensajesModel != null && mensajesModel!.chatId != null && mensajesModel!.chatId != chatId;

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200 && !respuestaDeOtraConversacion) {
      final MensajesTiendaModel pagina = MensajesTiendaModel.fromJson(apiResponse.response?.data);
      if (offset > 1 && mensajesModel != null && mensajesModel!.chatId == chatId) {
        // Los mensajes nuevos del polling desplazan las páginas del backend:
        // se agregan solo los ids más viejos que lo ya cargado (sin duplicar).
        final int minIdCargado =
            (mensajesModel!.data?.isNotEmpty ?? false) ? (mensajesModel!.data!.last.id ?? 0) : 0;
        final List<MensajeTienda> viejos =
            (pagina.data ?? []).where((mensaje) => (mensaje.id ?? 0) < minIdCargado).toList();
        mensajesModel!.data!.addAll(viejos);
        mensajesModel!.totalSize = pagina.totalSize;
        mensajesModel!.bloqueadoPorMi = pagina.bloqueadoPorMi;
      } else if (silencioso &&
          mensajesModel != null &&
          mensajesModel!.chatId == chatId &&
          (mensajesModel!.data?.isNotEmpty ?? false)) {
        final int maxIdCargado = mensajesModel!.data!.first.id ?? 0;
        final List<MensajeTienda> nuevos =
            (pagina.data ?? []).where((mensaje) => (mensaje.id ?? 0) > maxIdCargado).toList();
        mensajesModel!.data!.insertAll(0, nuevos);
        mensajesModel!.totalSize = pagina.totalSize;
        mensajesModel!.bloqueadoPorMi = pagina.bloqueadoPorMi;
      } else {
        mensajesModel = pagina;
      }
    }

    _isMensajesLoading = false;
    notifyListeners();
  }

  /// Devuelve el chat_id (nuevo o existente) al enviar con éxito; null si falló.
  Future<int?> enviarMensaje({required int destinatarioId, required String mensaje}) async {
    _isEnviando = true;
    notifyListeners();

    ApiResponseModel apiResponse = await chatTiendasServiceInterface.enviarMensaje(destinatarioId, mensaje);

    int? chatId;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      chatId = apiResponse.response?.data['chat_id'];
      final MensajeTienda enviado = MensajeTienda.fromJson(apiResponse.response?.data['mensaje']);
      if (mensajesModel != null) {
        mensajesModel!.chatId = chatId;
        mensajesModel!.data ??= [];
        mensajesModel!.data!.insert(0, enviado);
        mensajesModel!.totalSize = (mensajesModel!.totalSize ?? 0) + 1;
      }
    } else {
      showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    }

    _isEnviando = false;
    notifyListeners();
    return chatId;
  }

  Future<bool> bloquear({required int userId, String? motivo}) async {
    ApiResponseModel apiResponse = await chatTiendasServiceInterface.bloquear(userId, motivo);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(apiResponse.response?.data['message'], Get.context!, snackBarType: SnackBarType.success);
      if (mensajesModel?.contraparte?.userId == userId) {
        mensajesModel!.bloqueadoPorMi = true;
      }
      notifyListeners();
      return true;
    }

    showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    return false;
  }

  Future<bool> desbloquear({required int userId}) async {
    ApiResponseModel apiResponse = await chatTiendasServiceInterface.desbloquear(userId);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(apiResponse.response?.data['message'], Get.context!, snackBarType: SnackBarType.success);
      if (mensajesModel?.contraparte?.userId == userId) {
        mensajesModel!.bloqueadoPorMi = false;
      }
      notifyListeners();
      return true;
    }

    showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    return false;
  }

  /// Si el inbox ya trae conversación con ese afiliado, reusa su chat_id al
  /// abrir desde el directorio (evita "duplicar" la vista de conversación).
  int? chatIdParaContraparte(int userId) {
    final conversaciones = conversacionesModel?.data ?? [];
    for (final conversacion in conversaciones) {
      if (conversacion.contraparte?.userId == userId) {
        return conversacion.chatId;
      }
    }
    return null;
  }
}
