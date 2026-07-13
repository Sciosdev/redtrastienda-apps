import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/controllers/chat_tiendas_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Bloquear (confirmación simple) o Reportar (motivo obligatorio). Reportar
/// también bloquea: es el mecanismo de bloqueo+reporte que exige Google Play
/// para contenido generado por usuarios.
class BloquearReportarDialogWidget extends StatefulWidget {
  final AfiliadoDirectorio contraparte;
  final bool esReporte;
  const BloquearReportarDialogWidget({super.key, required this.contraparte, required this.esReporte});

  @override
  State<BloquearReportarDialogWidget> createState() => _BloquearReportarDialogWidgetState();
}

class _BloquearReportarDialogWidgetState extends State<BloquearReportarDialogWidget> {
  final TextEditingController _motivoController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final String motivo = _motivoController.text.trim();
    if (widget.esReporte && motivo.isEmpty) {
      return;
    }
    setState(() => _enviando = true);

    final bool ok = await Provider.of<ChatTiendasController>(context, listen: false).bloquear(
      userId: widget.contraparte.userId!,
      motivo: widget.esReporte ? motivo : null,
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
    final String titulo = widget.esReporte
        ? (getTranslated('reportar_usuario', context) ?? 'Reportar')
        : (getTranslated('bloquear_usuario', context) ?? 'Bloquear');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
      title: Text('$titulo · ${widget.contraparte.nombre ?? ''}',
          style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.esReporte
                ? (getTranslated('reportar_tambien_bloquea', context) ??
                    'Al reportar también se bloquea a este usuario y ANPEC revisará el caso.')
                : (getTranslated('confirmar_bloqueo_pregunta', context) ??
                    '¿Bloquear a este afiliado? Ya no podrán enviarse mensajes.'),
            style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
          if (widget.esReporte) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextField(
              controller: _motivoController,
              maxLength: 255,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: getTranslated('motivo_del_reporte', context) ?? 'Motivo del reporte',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
              ),
            ),
          ],
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
              : Text(titulo, style: textMedium.copyWith(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }
}
