import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/surtido/controllers/surtido_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Diálogo no-cancelable que acompaña "Repetir pedido": muestra el avance
/// secuencial "Agregando X / N" (nunca ráfaga paralela).
class RepeatOrderProgressDialog extends StatelessWidget {
  const RepeatOrderProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Consumer<SurtidoController>(
          builder: (context, controller, _) {
            final int total = controller.repeatTotal;
            final int done = controller.repeatDone;
            final String label = total == 0
                ? (getTranslated('surtido_repeat_preparing', context) ?? '')
                : '${getTranslated('surtido_repeat_adding', context)} $done / $total';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Flexible(
                  child: Text(
                    label,
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
