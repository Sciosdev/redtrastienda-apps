import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class ChatTiendasRepositoryInterface<T> extends RepositoryInterface {

  Future<dynamic> getInbox(String offset);

  Future<dynamic> getDirectorio(String? search, String offset);

  Future<dynamic> getMensajes(int chatId, String offset);

  Future<dynamic> enviarMensaje(int destinatarioId, String mensaje);

  Future<dynamic> bloquear(int userId, String? motivo);

  Future<dynamic> desbloquear(int userId);
}
