import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/mensaje_tienda_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:intl/intl.dart';

class BurbujaMensajeTiendaWidget extends StatelessWidget {
  final MensajeTienda mensaje;
  const BurbujaMensajeTiendaWidget({super.key, required this.mensaje});

  String _hora() {
    if (mensaje.fecha == null || mensaje.fecha!.isEmpty) {
      return '';
    }
    try {
      return DateFormat('HH:mm').format(DateConverter.isoUtcStringToLocalDate(mensaje.fecha!));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esMio = mensaje.mia ?? false;

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: Dimensions.paddingSizeExtraSmall,
          left: esMio ? 50 : 0,
          right: esMio ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: esMio ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Dimensions.paddingSizeDefault),
            topRight: const Radius.circular(Dimensions.paddingSizeDefault),
            bottomLeft: Radius.circular(esMio ? Dimensions.paddingSizeDefault : 2),
            bottomRight: Radius.circular(esMio ? 2 : Dimensions.paddingSizeDefault),
          ),
          border: esMio ? null : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje.mensaje ?? '',
              style: textRegular.copyWith(
                color: esMio ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _hora(),
              style: textRegular.copyWith(
                color: esMio ? Colors.white70 : Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeExtraSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
