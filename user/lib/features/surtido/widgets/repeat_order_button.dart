import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/surtido/controllers/surtido_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/surtido/widgets/repeat_order_progress_dialog.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Botón "Repetir pedido": reconstruye un pedido pasado con las APIs de carrito,
/// secuencial, con diálogo de progreso y reporte honesto de faltantes; al final
/// navega al carrito para confirmar con "Solicitar pedido" (F6 intacto).
/// - [compact] true: pastilla pequeña para la card del historial.
/// - [compact] false: botón ancho para el detalle del pedido.
class RepeatOrderButton extends StatelessWidget {
  final String orderId;
  final bool compact;
  const RepeatOrderButton({super.key, required this.orderId, this.compact = false});

  Future<void> _onTap(BuildContext context) async {
    final controller = Provider.of<SurtidoController>(context, listen: false);
    if (controller.repeating) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const RepeatOrderProgressDialog(),
    );

    final result = await controller.repeatOrder(orderId: orderId);

    // Cerrar el diálogo de progreso (repeatOrder ya no navega, así el pop es
    // siempre sobre el diálogo).
    Navigator.of(Get.context!, rootNavigator: true).pop();

    if (result.added == 0) {
      showCustomSnackBarWidget(getTranslated('surtido_repeat_none', Get.context!), Get.context!, snackBarType: SnackBarType.error);
      return;
    }

    final String message = result.missing == 0
        ? '${getTranslated('surtido_repeat_added', Get.context!)} ${result.added} ${getTranslated('products', Get.context!)}'
        : '${getTranslated('surtido_repeat_added', Get.context!)} ${result.added} ${getTranslated('surtido_repeat_of', Get.context!)} ${result.total} ${getTranslated('products', Get.context!)} (${result.missing} ${getTranslated('surtido_repeat_unavailable', Get.context!)})';
    showCustomSnackBarWidget(message, Get.context!, snackBarType: SnackBarType.success);

    RouterHelper.getCartScreenRoute(action: RouteAction.push);
  }

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return CustomButton(
        buttonText: getTranslated('surtido_repeat_order', context),
        onTap: () => _onTap(context),
        textColor: Theme.of(context).colorScheme.secondaryContainer,
        backgroundColor: Theme.of(context).primaryColor,
      );
    }

    final Color primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          border: Border.all(color: primary.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay, size: Dimensions.iconSizeSmall, color: primary),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Text(
              getTranslated('surtido_repeat_order', context) ?? '',
              style: textBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
