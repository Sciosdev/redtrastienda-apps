import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';
import 'package:image_picker/image_picker.dart';

abstract class MercadoRepositoryInterface<T> extends RepositoryInterface {

  Future<dynamic> getPublicaciones({String? search, String? estado, String? tipo, required String offset});

  Future<dynamic> getTienda(int userId, String offset);

  Future<dynamic> getMisPublicaciones(String offset);

  Future<dynamic> crearPublicacion(Map<String, String> campos, XFile? foto);

  Future<dynamic> actualizarPublicacion(int id, Map<String, String> campos, XFile? foto);

  Future<dynamic> togglePublicacion(int id);

  Future<dynamic> reportarPublicacion(int id, String? motivo);
}
