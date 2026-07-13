import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/avatar_inicial_tienda_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class AfiliadoDirectorioTileWidget extends StatelessWidget {
  final AfiliadoDirectorio afiliado;
  final VoidCallback onTap;
  const AfiliadoDirectorioTileWidget({super.key, required this.afiliado, required this.onTap});

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
          children: [
            AvatarInicialTiendaWidget(nombre: afiliado.nombre),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    afiliado.nombre ?? '',
                    style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((afiliado.nombreNegocio ?? '').isNotEmpty)
                    Text(
                      afiliado.nombreNegocio!,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if ((afiliado.estado ?? '').isNotEmpty) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  afiliado.estado!,
                  style: textRegular.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
