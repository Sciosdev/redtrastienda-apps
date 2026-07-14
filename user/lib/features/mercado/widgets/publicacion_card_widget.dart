import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

/// Card de publicación para explorar/tienda/mi tiendita (patrón visual del
/// tile del directorio del chat). El bloque del dueño solo aparece cuando la
/// publicación lo trae (explorar).
class PublicacionCardWidget extends StatelessWidget {
  final PublicacionMercado publicacion;
  final VoidCallback onTap;
  final Widget? trailing;
  const PublicacionCardWidget({super.key, required this.publicacion, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              child: SizedBox(
                width: 64,
                height: 64,
                child: publicacion.fotoUrl != null
                    ? CustomImageWidget(image: publicacion.fotoUrl!, width: 64, height: 64)
                    : Container(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        child: Icon(
                          publicacion.esProducto ? Icons.shopping_basket_outlined : Icons.campaign_outlined,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          publicacion.titulo ?? '',
                          style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (publicacion.ofertaVigente == true) ...[
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                          ),
                          child: Text(
                            getTranslated('oferta', context) ?? 'OFERTA',
                            style: textBold.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: Dimensions.fontSizeExtraSmall,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (publicacion.precio != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '\$${publicacion.precio}${(publicacion.unidad ?? '').isNotEmpty ? ' / ${publicacion.unidad}' : ''}',
                        style: textBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  if (publicacion.dueno != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if ((publicacion.dueno!.nombreNegocio ?? '').isNotEmpty) publicacion.dueno!.nombreNegocio!,
                          if ((publicacion.dueno!.estado ?? '').isNotEmpty) publicacion.dueno!.estado!,
                        ].join(' · '),
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
