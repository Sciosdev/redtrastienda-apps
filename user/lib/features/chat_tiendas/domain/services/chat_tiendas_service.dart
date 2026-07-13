import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/repositories/chat_tiendas_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/services/chat_tiendas_service_interface.dart';

class ChatTiendasService implements ChatTiendasServiceInterface {
  final ChatTiendasRepositoryInterface chatTiendasRepositoryInterface;
  ChatTiendasService({required this.chatTiendasRepositoryInterface});

  @override
  Future getInbox(String offset) async {
    return await chatTiendasRepositoryInterface.getInbox(offset);
  }

  @override
  Future getDirectorio(String? search, String offset) async {
    return await chatTiendasRepositoryInterface.getDirectorio(search, offset);
  }

  @override
  Future getMensajes(int chatId, String offset) async {
    return await chatTiendasRepositoryInterface.getMensajes(chatId, offset);
  }

  @override
  Future enviarMensaje(int destinatarioId, String mensaje) async {
    return await chatTiendasRepositoryInterface.enviarMensaje(destinatarioId, mensaje);
  }

  @override
  Future bloquear(int userId, String? motivo) async {
    return await chatTiendasRepositoryInterface.bloquear(userId, motivo);
  }

  @override
  Future desbloquear(int userId) async {
    return await chatTiendasRepositoryInterface.desbloquear(userId);
  }
}
