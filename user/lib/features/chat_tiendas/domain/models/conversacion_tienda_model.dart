import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';

class ConversacionTienda {
  int? chatId;
  AfiliadoDirectorio? contraparte;
  UltimoMensajeTienda? ultimoMensaje;
  int? noLeidos;

  ConversacionTienda({this.chatId, this.contraparte, this.ultimoMensaje, this.noLeidos});

  ConversacionTienda.fromJson(Map<String, dynamic> json) {
    chatId = json['chat_id'];
    contraparte = json['contraparte'] != null ? AfiliadoDirectorio.fromJson(json['contraparte']) : null;
    ultimoMensaje = json['ultimo_mensaje'] != null ? UltimoMensajeTienda.fromJson(json['ultimo_mensaje']) : null;
    noLeidos = json['no_leidos'];
  }
}

class UltimoMensajeTienda {
  String? texto;
  bool? mia;
  String? fecha;

  UltimoMensajeTienda({this.texto, this.mia, this.fecha});

  UltimoMensajeTienda.fromJson(Map<String, dynamic> json) {
    texto = json['texto'];
    mia = json['mia'];
    fecha = json['fecha'];
  }
}

class ConversacionesTiendaModel {
  List<ConversacionTienda>? data;
  int? totalSize;
  String? limit;
  String? offset;

  ConversacionesTiendaModel({this.data, this.totalSize, this.limit, this.offset});

  ConversacionesTiendaModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <ConversacionTienda>[];
      json['data'].forEach((v) {
        data!.add(ConversacionTienda.fromJson(v));
      });
    }
    totalSize = json['total_size'];
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
  }
}
