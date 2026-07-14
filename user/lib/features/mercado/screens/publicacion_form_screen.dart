import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/controllers/mercado_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/image_size_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Alta/edición de publicación. Con [publicacion] es edición (form prellenado).
class PublicacionFormScreen extends StatefulWidget {
  final PublicacionMercado? publicacion;
  const PublicacionFormScreen({super.key, this.publicacion});

  @override
  State<PublicacionFormScreen> createState() => _PublicacionFormScreenState();
}

class _PublicacionFormScreenState extends State<PublicacionFormScreen> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();

  String _tipo = 'producto';
  bool _esOferta = false;
  DateTime? _vigenciaHasta;
  XFile? _foto;

  bool get _esEdicion => widget.publicacion != null;

  @override
  void initState() {
    super.initState();
    final publicacion = widget.publicacion;
    if (publicacion != null) {
      _tipo = publicacion.tipo ?? 'producto';
      _tituloController.text = publicacion.titulo ?? '';
      _descripcionController.text = publicacion.descripcion ?? '';
      _precioController.text = publicacion.precio ?? '';
      _unidadController.text = publicacion.unidad ?? '';
      _esOferta = publicacion.esOferta ?? false;
      _vigenciaHasta = DateTime.tryParse(publicacion.vigenciaHasta ?? '');
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto(ImageSource source) async {
    final XFile? foto = await ImageValidationHelper.validateAndPickImage(
      context: context,
      source: source,
      imageQuality: 60,
      maxHeight: 1000,
      maxWidth: 1000,
    );
    if (foto != null && mounted) {
      setState(() => _foto = foto);
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(getTranslated('camara', context) ?? 'Cámara'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _elegirFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(getTranslated('galeria', context) ?? 'Galería'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _elegirFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _elegirVigencia() async {
    final DateTime hoy = DateTime.now();
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _vigenciaHasta ?? hoy.add(const Duration(days: 7)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (seleccionada != null && mounted) {
      setState(() => _vigenciaHasta = seleccionada);
    }
  }

  String _formatFecha(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    final String titulo = _tituloController.text.trim();
    final String precio = _precioController.text.trim();

    if (titulo.isEmpty) {
      showCustomSnackBarWidget(
        getTranslated('el_titulo_es_obligatorio', context) ?? 'El título es obligatorio',
        context, snackBarType: SnackBarType.error,
      );
      return;
    }
    if (_tipo == 'producto' && precio.isEmpty) {
      showCustomSnackBarWidget(
        getTranslated('el_precio_es_obligatorio_para_productos', context) ?? 'El precio es obligatorio para productos',
        context, snackBarType: SnackBarType.error,
      );
      return;
    }

    final Map<String, String> campos = {
      'tipo': _tipo,
      'titulo': titulo,
      'descripcion': _descripcionController.text.trim(),
      if (precio.isNotEmpty) 'precio': precio,
      'unidad': _unidadController.text.trim(),
      'es_oferta': _esOferta ? '1' : '0',
      if (_esOferta && _vigenciaHasta != null) 'vigencia_hasta': _formatFecha(_vigenciaHasta!),
    };

    final bool ok = await Provider.of<MercadoController>(context, listen: false).guardarPublicacion(
      publicacionId: widget.publicacion?.id,
      campos: campos,
      foto: _foto,
    );

    if (ok && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _chipTipo(String valor, String etiqueta) {
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
      child: ChoiceChip(
        label: Text(etiqueta, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
        selected: _tipo == valor,
        onSelected: (_) => setState(() => _tipo = valor),
      ),
    );
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _esEdicion
            ? (getTranslated('editar_publicacion', context) ?? 'Editar publicación')
            : (getTranslated('publicar', context) ?? 'Publicar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chipTipo('producto', getTranslated('producto', context) ?? 'Producto'),
                _chipTipo('aviso', getTranslated('aviso', context) ?? 'Aviso'),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            TextField(
              controller: _tituloController,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracion(getTranslated('titulo_publicacion', context) ?? 'Título'),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            TextField(
              controller: _descripcionController,
              maxLength: 1000,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracion(getTranslated('descripcion_publicacion', context) ?? 'Descripción (opcional)'),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    decoration: _decoracion(_tipo == 'producto'
                        ? (getTranslated('precio', context) ?? 'Precio')
                        : (getTranslated('precio_opcional', context) ?? 'Precio (opcional)')),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: TextField(
                    controller: _unidadController,
                    maxLength: 30,
                    decoration: _decoracion(getTranslated('unidad_medida', context) ?? 'Unidad (kg, caja...)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(getTranslated('marcar_como_oferta', context) ?? 'Marcar como oferta',
                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
              value: _esOferta,
              onChanged: (valor) => setState(() => _esOferta = valor),
            ),
            if (_esOferta)
              InkWell(
                onTap: _elegirVigencia,
                child: InputDecorator(
                  decoration: _decoracion(getTranslated('vigencia_de_la_oferta', context) ?? 'Vigencia de la oferta (opcional)'),
                  child: Text(
                    _vigenciaHasta != null
                        ? _formatFecha(_vigenciaHasta!)
                        : (getTranslated('elegir_fecha', context) ?? 'Elegir fecha'),
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),
                ),
              ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text(getTranslated('foto_publicacion', context) ?? 'Foto (opcional)',
                style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            InkWell(
              onTap: _mostrarOpcionesFoto,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                  child: _foto != null
                      ? FutureBuilder(
                          future: _foto!.readAsBytes(),
                          builder: (context, snapshot) => snapshot.hasData
                              ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                              : const Center(child: CircularProgressIndicator()),
                        )
                      : (widget.publicacion?.fotoUrl != null
                          ? CustomImageWidget(image: widget.publicacion!.fotoUrl!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: Theme.of(context).hintColor),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                Text(
                                  getTranslated('agregar_foto', context) ?? 'Agregar foto',
                                  style: textRegular.copyWith(color: Theme.of(context).hintColor),
                                ),
                              ],
                            )),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Consumer<MercadoController>(
              builder: (context, controller, child) => CustomButton(
                buttonText: _esEdicion
                    ? (getTranslated('guardar_cambios', context) ?? 'Guardar cambios')
                    : (getTranslated('publicar', context) ?? 'Publicar'),
                isLoading: controller.isGuardando,
                onTap: controller.isGuardando ? null : _guardar,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
      ),
    );
  }
}
