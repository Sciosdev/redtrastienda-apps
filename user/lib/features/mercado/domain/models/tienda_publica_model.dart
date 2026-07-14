import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';

/// R-Mercado: perfil público de tienda. El API expone ÚNICAMENTE nombre,
/// nombre del negocio, estado y foto del negocio (nunca teléfono, correo,
/// dirección ni número ANP) más sus publicaciones visibles.
class TiendaPublicaModel {
  int? userId;
  String? nombre;
  String? nombreNegocio;
  String? estado;
  String? fotoNegocioUrl;
  PublicacionesMercadoModel? publicaciones;

  TiendaPublicaModel({
    this.userId,
    this.nombre,
    this.nombreNegocio,
    this.estado,
    this.fotoNegocioUrl,
    this.publicaciones,
  });

  TiendaPublicaModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    nombre = json['nombre']?.toString();
    nombreNegocio = json['nombre_negocio']?.toString();
    estado = json['estado']?.toString();
    fotoNegocioUrl = json['foto_negocio_url']?.toString();
    publicaciones = json['publicaciones'] != null
        ? PublicacionesMercadoModel.fromJson(json['publicaciones'])
        : null;
  }
}
