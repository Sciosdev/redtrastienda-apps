import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';

/// R-Mercado: publicación de la vitrina entre tenderos. El bloque `dueno` trae
/// EXACTAMENTE los 4 campos del directorio del chat, por eso se parsea con
/// [AfiliadoDirectorio] (reuso directo; nunca viajan datos sensibles).
class PublicacionMercado {
  int? id;
  String? tipo;
  String? titulo;
  String? descripcion;
  String? precio;
  String? unidad;
  bool? esOferta;
  bool? ofertaVigente;
  String? vigenciaHasta;
  String? fotoUrl;
  String? fecha;
  AfiliadoDirectorio? dueno;

  // Solo en mis-publicaciones (Mi tiendita).
  bool? activo;
  bool? ocultoPorAdmin;
  String? motivoNoVisible;

  PublicacionMercado({
    this.id,
    this.tipo,
    this.titulo,
    this.descripcion,
    this.precio,
    this.unidad,
    this.esOferta,
    this.ofertaVigente,
    this.vigenciaHasta,
    this.fotoUrl,
    this.fecha,
    this.dueno,
    this.activo,
    this.ocultoPorAdmin,
    this.motivoNoVisible,
  });

  PublicacionMercado.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipo = json['tipo']?.toString();
    titulo = json['titulo']?.toString();
    descripcion = json['descripcion']?.toString();
    precio = json['precio']?.toString();
    unidad = json['unidad']?.toString();
    esOferta = json['es_oferta'] == true;
    ofertaVigente = json['oferta_vigente'] == true;
    vigenciaHasta = json['vigencia_hasta']?.toString();
    fotoUrl = json['foto_url']?.toString();
    fecha = json['fecha']?.toString();
    dueno = json['dueno'] != null ? AfiliadoDirectorio.fromJson(json['dueno']) : null;
    activo = json['activo'] is bool ? json['activo'] : null;
    ocultoPorAdmin = json['oculto_por_admin'] is bool ? json['oculto_por_admin'] : null;
    motivoNoVisible = json['motivo_no_visible']?.toString();
  }

  bool get esProducto => tipo == 'producto';
}

class PublicacionesMercadoModel {
  List<PublicacionMercado>? data;
  int? totalSize;
  String? limit;
  String? offset;

  PublicacionesMercadoModel({this.data, this.totalSize, this.limit, this.offset});

  PublicacionesMercadoModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <PublicacionMercado>[];
      json['data'].forEach((v) {
        data!.add(PublicacionMercado.fromJson(v));
      });
    }
    totalSize = json['total_size'];
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
  }
}
