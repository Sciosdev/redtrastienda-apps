import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/controllers/mercado_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Reporte de publicación (requisito Google Play para UGC): disponible en
/// toda publicación ajena; el motivo es obligatorio (patrón del reporte del
/// chat tienda↔tienda).
class ReportarPublicacionDialogWidget extends StatefulWidget {
  final PublicacionMercado publicacion;
  const ReportarPublicacionDialogWidget({super.key, required this.publicacion});

  @override
  State<ReportarPublicacionDialogWidget> createState() => _ReportarPublicacionDialogWidgetState();
}

class _ReportarPublicacionDialogWidgetState extends State<ReportarPublicacionDialogWidget> {
  final TextEditingController _motivoController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final String motivo = _motivoController.text.trim();
    if (motivo.isEmpty) {
      return;
    }
    setState(() => _enviando = true);

    final bool ok = await Provider.of<MercadoController>(context, listen: false).reportarPublicacion(
      publicacionId: widget.publicacion.id!,
      motivo: motivo,
    );

    if (mounted) {
      setState(() => _enviando = false);
      if (ok) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = getTranslated('reportar_publicacion', context) ?? 'Reportar publicación';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
      title: Text(titulo, style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.publicacion.titulo ?? '',
            style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          TextField(
            controller: _motivoController,
            maxLength: 255,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: getTranslated('motivo_reporte_publicacion', context) ?? 'Cuéntanos qué está mal con esta publicación',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: Text(getTranslated('cancel', context) ?? 'Cancelar',
              style: textRegular.copyWith(color: Theme.of(context).hintColor)),
        ),
        TextButton(
          onPressed: _enviando ? null : _confirmar,
          child: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(getTranslated('reportar_usuario', context) ?? 'Reportar',
                  style: textMedium.copyWith(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }
}
