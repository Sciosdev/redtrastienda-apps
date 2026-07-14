import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/tienda_publica_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/services/mercado_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:image_picker/image_picker.dart';

class MercadoController with ChangeNotifier {
  final MercadoServiceInterface mercadoServiceInterface;
  MercadoController({required this.mercadoServiceInterface});

  PublicacionesMercadoModel? explorarModel;
  bool _isExplorarLoading = false;
  bool get isExplorarLoading => _isExplorarLoading;
  String _search = '';
  String _filtroEstado = '';
  String get filtroEstado => _filtroEstado;
  String _filtroTipo = '';
  String get filtroTipo => _filtroTipo;

  TiendaPublicaModel? tiendaModel;
  bool _isTiendaLoading = false;
  bool get isTiendaLoading => _isTiendaLoading;

  PublicacionesMercadoModel? misPublicacionesModel;
  bool _isMisPublicacionesLoading = false;
  bool get isMisPublicacionesLoading => _isMisPublicacionesLoading;

  bool _isGuardando = false;
  bool get isGuardando => _isGuardando;

  Future<void> getPublicaciones({int offset = 1, String? search, String? estado, String? tipo}) async {
    if (offset == 1) {
      _search = search ?? _search;
      _filtroEstado = estado ?? _filtroEstado;
      _filtroTipo = tipo ?? _filtroTipo;
      _isExplorarLoading = true;
      notifyListeners();
    }

    ApiResponseModel apiResponse = await mercadoServiceInterface.getPublicaciones(
      search: _search,
      estado: _filtroEstado,
      tipo: _filtroTipo,
      offset: offset.toString(),
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final PublicacionesMercadoModel pagina = PublicacionesMercadoModel.fromJson(apiResponse.response?.data);
      if (offset == 1) {
        explorarModel = pagina;
      } else {
        explorarModel!.data!.addAll(pagina.data ?? []);
        explorarModel!.offset = pagina.offset;
        explorarModel!.totalSize = pagina.totalSize;
      }
    }

    _isExplorarLoading = false;
    notifyListeners();
  }

  Future<void> getTienda(int userId, {int offset = 1}) async {
    if (offset == 1) {
      tiendaModel = null;
      _isTiendaLoading = true;
      notifyListeners();
    }

    ApiResponseModel apiResponse = await mercadoServiceInterface.getTienda(userId, offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final TiendaPublicaModel pagina = TiendaPublicaModel.fromJson(apiResponse.response?.data);
      if (offset == 1 || tiendaModel == null) {
        tiendaModel = pagina;
      } else {
        tiendaModel!.publicaciones!.data!.addAll(pagina.publicaciones?.data ?? []);
        tiendaModel!.publicaciones!.offset = pagina.publicaciones?.offset;
        tiendaModel!.publicaciones!.totalSize = pagina.publicaciones?.totalSize;
      }
    }

    _isTiendaLoading = false;
    notifyListeners();
  }

  Future<void> getMisPublicaciones({int offset = 1}) async {
    if (offset == 1) {
      _isMisPublicacionesLoading = true;
      notifyListeners();
    }

    ApiResponseModel apiResponse = await mercadoServiceInterface.getMisPublicaciones(offset.toString());

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final PublicacionesMercadoModel pagina = PublicacionesMercadoModel.fromJson(apiResponse.response?.data);
      if (offset == 1) {
        misPublicacionesModel = pagina;
      } else {
        misPublicacionesModel!.data!.addAll(pagina.data ?? []);
        misPublicacionesModel!.offset = pagina.offset;
        misPublicacionesModel!.totalSize = pagina.totalSize;
      }
    }

    _isMisPublicacionesLoading = false;
    notifyListeners();
  }

  /// Crea o actualiza según [publicacionId]. True si el backend aceptó.
  Future<bool> guardarPublicacion({int? publicacionId, required Map<String, String> campos, XFile? foto}) async {
    _isGuardando = true;
    notifyListeners();

    ApiResponseModel apiResponse = publicacionId == null
        ? await mercadoServiceInterface.crearPublicacion(campos, foto)
        : await mercadoServiceInterface.actualizarPublicacion(publicacionId, campos, foto);

    _isGuardando = false;

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(apiResponse.response?.data['message'], Get.context!, snackBarType: SnackBarType.success);
      await getMisPublicaciones();
      return true;
    }

    notifyListeners();
    showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    return false;
  }

  Future<bool> togglePublicacion(int publicacionId) async {
    ApiResponseModel apiResponse = await mercadoServiceInterface.togglePublicacion(publicacionId);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(apiResponse.response?.data['message'], Get.context!, snackBarType: SnackBarType.success);
      await getMisPublicaciones();
      return true;
    }

    showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    return false;
  }

  Future<bool> reportarPublicacion({required int publicacionId, String? motivo}) async {
    ApiResponseModel apiResponse = await mercadoServiceInterface.reportarPublicacion(publicacionId, motivo);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(
        getTranslated('publicacion_reportada_gracias', Get.context!) ?? 'Publicación reportada. Gracias por avisarnos.',
        Get.context!,
        snackBarType: SnackBarType.success,
      );
      return true;
    }

    showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    return false;
  }

  void limpiarFiltros() {
    _search = '';
    _filtroEstado = '';
    _filtroTipo = '';
  }
}
