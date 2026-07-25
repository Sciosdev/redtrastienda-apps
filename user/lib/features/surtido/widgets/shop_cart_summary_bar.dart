import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/surtido/controllers/surtido_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Barra fija inferior de la pantalla del proveedor: mientras haya productos de
/// esta tienda en el carrito, muestra "N productos · $total" y "Ver pedido" →
/// carrito (de ahí sigue el flujo F6 de "Solicitar pedido"). Cuando el carrito
/// de este proveedor está vacío, se colapsa a nada.
class ShopCartSummaryBar extends StatelessWidget {
  const ShopCartSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SurtidoController>(
      builder: (context, controller, _) {
        final int count = controller.shopItemCount;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(color: Theme.of(context).hintColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count ${getTranslated('products', context)}',
                          style: textMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                        Text(
                          PriceConverter.convertPrice(context, controller.shopSubtotal),
                          style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () => RouterHelper.getCartScreenRoute(action: RouteAction.push),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated('surtido_view_order', context) ?? '',
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).colorScheme.secondaryContainer,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Icon(Icons.arrow_forward, size: Dimensions.iconSizeSmall, color: Theme.of(context).colorScheme.secondaryContainer),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
