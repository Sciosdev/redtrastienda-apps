import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

/// Chip seleccionable del módulo Mercado (patrón del design system, espejo de
/// buttons_tab_bar): seleccionado = fondo primario + texto blanco; no
/// seleccionado = borde + texto normal. El ChoiceChip de Material dejaba el
/// texto blanco sobre fondo claro (ilegible).
class MercadoChipWidget extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;
  const MercadoChipWidget({super.key, required this.etiqueta, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: seleccionado ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: seleccionado ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            etiqueta,
            style: seleccionado
                ? titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)
                : titilliumRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
          ),
        ),
      ),
    );
  }
}
