import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/repositories/mercado_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/services/mercado_service_interface.dart';
import 'package:image_picker/image_picker.dart';

class MercadoService implements MercadoServiceInterface {
  final MercadoRepositoryInterface mercadoRepositoryInterface;
  MercadoService({required this.mercadoRepositoryInterface});

  @override
  Future getPublicaciones({String? search, String? estado, String? tipo, required String offset}) async {
    return await mercadoRepositoryInterface.getPublicaciones(search: search, estado: estado, tipo: tipo, offset: offset);
  }

  @override
  Future getTienda(int userId, String offset) async {
    return await mercadoRepositoryInterface.getTienda(userId, offset);
  }

  @override
  Future getMisPublicaciones(String offset) async {
    return await mercadoRepositoryInterface.getMisPublicaciones(offset);
  }

  @override
  Future crearPublicacion(Map<String, String> campos, XFile? foto) async {
    return await mercadoRepositoryInterface.crearPublicacion(campos, foto);
  }

  @override
  Future actualizarPublicacion(int id, Map<String, String> campos, XFile? foto) async {
    return await mercadoRepositoryInterface.actualizarPublicacion(id, campos, foto);
  }

  @override
  Future togglePublicacion(int id) async {
    return await mercadoRepositoryInterface.togglePublicacion(id);
  }

  @override
  Future reportarPublicacion(int id, String? motivo) async {
    return await mercadoRepositoryInterface.reportarPublicacion(id, motivo);
  }
}
