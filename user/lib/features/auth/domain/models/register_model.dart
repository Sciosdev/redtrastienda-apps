class RegisterModel {
  String? email;
  String? password;
  String? fName;
  String? lName;
  String? phone;
  String? socialId;
  String? loginMedium;
  String? referCode;
  // ANPEC: número de afiliado y nombre de negocio (registro de afiliados).
  String? numeroAnp;
  String? nombreNegocio;
  // R-Afiliación: registro de LEAD (interesado sin número ANP). El backend crea
  // una cuenta pendiente que no puede iniciar sesión hasta que ANPEC lo afilie.
  bool esLead = false;

  RegisterModel({this.email, this.password, this.fName, this.lName, this.socialId,this.loginMedium, this.referCode, this.numeroAnp, this.nombreNegocio, this.esLead = false});

  RegisterModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    password = json['password'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    socialId = json['social_id'];
    loginMedium = json['login_medium'];
    referCode = json['referral_code'];
    numeroAnp = json['numero_anp'];
    nombreNegocio = json['nombre_negocio'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['password'] = password;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['social_id'] = socialId;
    data['login_medium'] = loginMedium;
    data['referral_code'] = referCode;
    // Solo enviamos los campos de afiliado si vienen informados, para no
    // alterar otros flujos de registro (social/OTP) que reutilizan este modelo.
    if (numeroAnp != null && numeroAnp!.isNotEmpty) {
      data['numero_anp'] = numeroAnp;
    }
    if (nombreNegocio != null && nombreNegocio!.isNotEmpty) {
      data['nombre_negocio'] = nombreNegocio;
    }
    if (esLead) {
      data['es_lead'] = true;
    }
    return data;
  }
}
