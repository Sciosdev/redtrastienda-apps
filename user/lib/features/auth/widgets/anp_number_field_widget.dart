import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/anpec_contact_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

/// R-Afiliación: campo de número ANP con el prefijo "ANP" fijo (el afiliado
/// teclea solo dígitos y la letra final si su número la tiene) + el aviso
/// "¿No conoces tu número ANPEC?" que abre el canal de contacto de F5.
/// Extraído del registro (r-anp-prefijo) para reusarse en el wizard de activación.
class AnpNumberFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final Function(String)? onChanged;
  final TextInputAction inputAction;

  const AnpNumberFieldWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.nextFocus,
    this.onChanged,
    this.inputAction = TextInputAction.next,
  });

  /// Número completo con el prefijo fijo antepuesto ("12268" → "ANP12268").
  static String fullNumero(String typed) {
    final String value = typed.trim();
    return value.isEmpty ? '' : 'ANP$value';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault, right: Dimensions.marginSizeDefault),
          child: CustomTextFieldWidget(
              hintText: getTranslated('enter_numero_anp', context),
              labelText: getTranslated('numero_anp', context),
              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
              focusNode: focusNode,
              nextFocus: nextFocus,
              required: true,
              inputType: TextInputType.text,
              inputAction: inputAction,
              controller: controller,
              capitalization: TextCapitalization.characters,
              prefixIcon: Images.username,
              prefixText: 'ANP',
              inputFormatters: [NumeroAnpInputFormatter()],
              onChanged: onChanged,
              validator: (value) => ValidateCheck.validateEmptyText(value, "numero_anp_field_is_required"))),

      _buildAnpHelp(context),
    ]);
  }

  // Aviso "¿No conoces tu número ANPEC?": abre el canal de contacto de F5
  // (WhatsApp/Llamar con company_phone del config). Oculto si no hay número.
  Widget _buildAnpHelp(BuildContext context) {
    final String phone = (Provider.of<SplashController>(context, listen: false).configModel?.companyPhone ?? '').trim();
    if (phone.isEmpty || phone.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault, right: Dimensions.marginSizeDefault, top: Dimensions.paddingSizeExtraSmall),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
          ),
          builder: (_) => AnpecContactSheetWidget(rawPhone: phone),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
          child: Row(children: [
            Icon(Icons.help_outline, size: 16, color: Theme.of(context).hintColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Text.rich(TextSpan(children: [
              TextSpan(text: '${getTranslated('anp_help_question', context) ?? '¿No conoces tu número ANPEC?'} '),
              TextSpan(
                text: getTranslated('anp_help_action', context) ?? 'Llámanos o escríbenos',
                style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
              ),
            ]), style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color))),
          ]),
        ),
      ),
    );
  }
}

/// R-ANP: estructura de lo que teclea el afiliado SIN el prefijo fijo "ANP":
/// dígitos y opcionalmente UNA letra al final. Es el formato real de la base
/// ANPEC (ej. 12268, 0102, 14873A). Cualquier otra edición se rechaza.
class NumeroAnpInputFormatter extends TextInputFormatter {
  static final RegExp _pattern = RegExp(r'^\d*[a-zA-Z]?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
