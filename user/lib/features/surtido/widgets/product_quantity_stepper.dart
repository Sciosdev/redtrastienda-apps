import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/surtido/controllers/surtido_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Stepper de cantidad para la card de producto en la lista del proveedor.
/// - Producto sin variantes: [+ Agregar] (o "Sin existencias" si stock 0) →
///   [ − n + ] sincronizado con el carrito real.
/// - Cantidad inicial = minimum_order_qty; el "−" en el mínimo elimina; el "+"
///   respeta current_stock.
/// Solo se muestra para productos simples; la decisión de mostrarlo la toma la
/// card (ver [ProductCardWidget.showQuantityStepper]).
class ProductQuantityStepper extends StatelessWidget {
  final Product product;
  const ProductQuantityStepper({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final int stock = product.currentStock ?? 0;
    return Consumer<SurtidoController>(
      builder: (context, controller, _) {
        final int qty = controller.quantityFor(product.id);
        final bool busy = controller.isBusy(product.id);

        if (qty == 0) {
          return _AddButton(
            enabled: stock > 0 && !busy,
            outOfStock: stock <= 0,
            busy: busy,
            onTap: () => controller.addProduct(context, product),
          );
        }

        final int min = product.minimumOrderQuantity ?? 1;
        final bool atMin = qty <= min;
        final bool canIncrease = qty < stock;

        return Container(
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: atMin ? Icons.delete_outline : Icons.remove,
                onTap: busy ? null : () => controller.decrement(context, product),
                color: atMin ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
              ),
              Expanded(
                child: Center(
                  child: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          ),
                        )
                      : Text(
                          '$qty',
                          style: titilliumBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onTap: (busy || !canIncrease) ? null : () => controller.increment(context, product),
                color: canIncrease ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool enabled;
  final bool outOfStock;
  final bool busy;
  final VoidCallback onTap;
  const _AddButton({required this.enabled, required this.outOfStock, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final bool disabled = !enabled;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? Theme.of(context).hintColor.withValues(alpha: 0.12) : primary.withValues(alpha: 0.1),
          border: Border.all(color: disabled ? Theme.of(context).hintColor.withValues(alpha: 0.35) : primary.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primary)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    outOfStock ? Icons.block : Icons.add,
                    size: Dimensions.iconSizeSmall,
                    color: outOfStock ? Theme.of(context).hintColor : primary,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Flexible(
                    child: Text(
                      getTranslated(outOfStock ? 'surtido_out_of_stock' : 'surtido_add', context) ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titilliumBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: outOfStock ? Theme.of(context).hintColor : primary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _StepButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: SizedBox(
        width: 38,
        height: 34,
        child: Icon(icon, size: Dimensions.iconSizeSmall, color: color),
      ),
    );
  }
}
