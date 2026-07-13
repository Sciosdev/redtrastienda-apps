import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/conversacion_tienda_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/avatar_inicial_tienda_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:intl/intl.dart';

class ConversacionTiendaTileWidget extends StatelessWidget {
  final ConversacionTienda conversacion;
  final VoidCallback onTap;
  const ConversacionTiendaTileWidget({super.key, required this.conversacion, required this.onTap});

  String _hora(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return '';
    }
    try {
      final DateTime local = DateConverter.isoUtcStringToLocalDate(fecha);
      final DateTime ahora = DateTime.now();
      final bool esHoy = local.year == ahora.year && local.month == ahora.month && local.day == ahora.day;
      return esHoy ? DateFormat('HH:mm').format(local) : DateFormat('dd MMM').format(local);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int noLeidos = conversacion.noLeidos ?? 0;
    final bool ultimoEsMio = conversacion.ultimoMensaje?.mia ?? false;
    final String ultimoTexto = conversacion.ultimoMensaje?.texto ?? '';

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            AvatarInicialTiendaWidget(nombre: conversacion.contraparte?.nombre),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversacion.contraparte?.nombre ?? '',
                    style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((conversacion.contraparte?.nombreNegocio ?? '').isNotEmpty)
                    Text(
                      conversacion.contraparte!.nombreNegocio!,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (ultimoTexto.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ultimoEsMio ? '${getTranslated('tu_prefijo_mensaje', context) ?? 'Tú'}: $ultimoTexto' : ultimoTexto,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _hora(conversacion.ultimoMensaje?.fecha),
                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                if (noLeidos > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      noLeidos > 99 ? '99+' : '$noLeidos',
                      style: textMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
