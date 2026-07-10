class AffiliateProfileModel {
  int? id;
  int? customerId;
  String? numeroAnp;
  String? nombreNegocio;
  String? whatsapp;
  String? direccion;
  String? estado;
  String? municipio;
  String? colonia;
  String? fotoNegocio;
  String? estatus;
  String? approvedAt;
  String? approvedBy;
  String? createdAt;
  // R-Afiliación (aditivo, tolerante a backend viejo): estado de activación e
  // invitación a completar los campos vacíos del perfil.
  bool reclamada = false;
  List<String> camposFaltantes = [];

  AffiliateProfileModel({
    this.id,
    this.customerId,
    this.numeroAnp,
    this.nombreNegocio,
    this.whatsapp,
    this.direccion,
    this.estado,
    this.municipio,
    this.colonia,
    this.fotoNegocio,
    this.estatus,
    this.approvedAt,
    this.approvedBy,
    this.createdAt,
    this.reclamada = false,
    this.camposFaltantes = const [],
  });

  AffiliateProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    numeroAnp = json['numero_anp']?.toString();
    nombreNegocio = json['nombre_negocio']?.toString();
    whatsapp = json['whatsapp']?.toString();
    direccion = json['direccion']?.toString();
    estado = json['estado']?.toString();
    municipio = json['municipio']?.toString();
    colonia = json['colonia']?.toString();
    fotoNegocio = json['foto_negocio']?.toString();
    estatus = json['estatus']?.toString();
    approvedAt = json['approved_at']?.toString();
    approvedBy = json['approved_by']?.toString();
    createdAt = json['created_at']?.toString();
    reclamada = json['reclamada'] == true || json['reclamada'] == 1;
    camposFaltantes = json['campos_faltantes'] is List
        ? (json['campos_faltantes'] as List).map((campo) => campo.toString()).toList()
        : [];
  }
}
