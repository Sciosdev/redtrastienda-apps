/// R-Chat-Tiendas: entrada del directorio abierto de afiliados. El API expone
/// ÚNICAMENTE estos campos (nunca teléfono, correo, dirección ni número ANP).
class AfiliadoDirectorio {
  int? userId;
  String? nombre;
  String? nombreNegocio;
  String? estado;

  AfiliadoDirectorio({this.userId, this.nombre, this.nombreNegocio, this.estado});

  AfiliadoDirectorio.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    nombre = json['nombre'];
    nombreNegocio = json['nombre_negocio'];
    estado = json['estado'];
  }
}

class DirectorioTiendasModel {
  List<AfiliadoDirectorio>? data;
  int? totalSize;
  String? limit;
  String? offset;

  DirectorioTiendasModel({this.data, this.totalSize, this.limit, this.offset});

  DirectorioTiendasModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <AfiliadoDirectorio>[];
      json['data'].forEach((v) {
        data!.add(AfiliadoDirectorio.fromJson(v));
      });
    }
    totalSize = json['total_size'];
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
  }
}
