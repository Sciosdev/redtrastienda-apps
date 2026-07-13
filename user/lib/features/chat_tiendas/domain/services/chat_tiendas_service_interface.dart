abstract class ChatTiendasServiceInterface {

  Future<dynamic> getInbox(String offset);

  Future<dynamic> getDirectorio(String? search, String offset);

  Future<dynamic> getMensajes(int chatId, String offset);

  Future<dynamic> enviarMensaje(int destinatarioId, String mensaje);

  Future<dynamic> bloquear(int userId, String? motivo);

  Future<dynamic> desbloquear(int userId);
}
