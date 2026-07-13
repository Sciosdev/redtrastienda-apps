import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';

class MensajeTienda {
  int? id;
  bool? mia;
  String? mensaje;
  String? fecha;
  bool? leido;

  MensajeTienda({this.id, this.mia, this.mensaje, this.fecha, this.leido});

  MensajeTienda.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mia = json['mia'];
    mensaje = json['mensaje'];
    fecha = json['fecha'];
    leido = json['leido'];
  }
}

/// Página de mensajes de una conversación: llega del más reciente al más
/// viejo, tal como la pinta el ListView con reverse: true.
class MensajesTiendaModel {
  int? chatId;
  AfiliadoDirectorio? contraparte;
  bool? bloqueadoPorMi;
  List<MensajeTienda>? data;
  int? totalSize;

  MensajesTiendaModel({this.chatId, this.contraparte, this.bloqueadoPorMi, this.data, this.totalSize});

  MensajesTiendaModel.fromJson(Map<String, dynamic> json) {
    chatId = json['chat_id'];
    contraparte = json['contraparte'] != null ? AfiliadoDirectorio.fromJson(json['contraparte']) : null;
    bloqueadoPorMi = json['bloqueado_por_mi'];
    if (json['data'] != null) {
      data = <MensajeTienda>[];
      json['data'].forEach((v) {
        data!.add(MensajeTienda.fromJson(v));
      });
    }
    totalSize = json['total_size'];
  }
}
