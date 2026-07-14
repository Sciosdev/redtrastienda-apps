import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

/// Badge de Mi tiendita: visible / pausada / oculta por administración.
class EstadoPublicacionBadgeWidget extends StatelessWidget {
  final PublicacionMercado publicacion;
  const EstadoPublicacionBadgeWidget({super.key, required this.publicacion});

  @override
  Widget build(BuildContext context) {
    final String texto;
    final Color color;
    if (publicacion.motivoNoVisible == 'oculta_por_admin') {
      texto = getTranslated('oculta_por_administracion', context) ?? 'Oculta por administración';
      color = Theme.of(context).colorScheme.error;
    } else if (publicacion.motivoNoVisible == 'pausada') {
      texto = getTranslated('pausada', context) ?? 'Pausada';
      color = Theme.of(context).hintColor;
    } else {
      texto = getTranslated('visible', context) ?? 'Visible';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
      ),
      child: Text(
        texto,
        style: textRegular.copyWith(color: color, fontSize: Dimensions.fontSizeExtraSmall),
      ),
    );
  }
}
