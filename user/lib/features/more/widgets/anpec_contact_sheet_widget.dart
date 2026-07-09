import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:url_launcher/url_launcher.dart';

/// Canal de contacto directo del afiliado con ANPEC (F5).
/// Toma el número desde el config del backend (company_phone). No hardcodea nada.
class AnpecContactSheetWidget extends StatelessWidget {
  /// Número tal cual viene del config (company_phone).
  final String rawPhone;

  const AnpecContactSheetWidget({super.key, required this.rawPhone});

  /// Deja solo dígitos. Si no trae código de país (10 dígitos), asume México (52).
  static String sanitizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '52$digits';
    return digits;
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final number = sanitizePhone(rawPhone);
    if (number.isEmpty) return;
    final message = Uri.encodeComponent(
      getTranslated('anpec_whatsapp_prefill', context) ?? 'Hola, soy afiliado de Red Trastienda.',
    );
    final uri = Uri.parse('https://wa.me/$number?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call() async {
    final number = sanitizePhone(rawPhone);
    if (number.isEmpty) return;
    await launchUrl(Uri.parse('tel:$number'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslated('anpec_contact_title', context) ?? 'Contacto ANPEC',
              style: titilliumBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            _ContactAction(
              icon: Icons.chat,
              iconColor: const Color(0xFF25D366), // verde WhatsApp
              label: getTranslated('whatsapp_anpec', context) ?? 'WhatsApp ANPEC',
              onTap: () {
                Navigator.of(context).pop();
                _openWhatsApp(context);
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            _ContactAction(
              icon: Icons.call,
              iconColor: const Color(0xFFA1262B), // acento ANPEC
              label: getTranslated('call_anpec', context) ?? 'Llamar',
              onTap: () {
                Navigator.of(context).pop();
                _call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ContactAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: Dimensions.iconSizeDefault),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text(
                label,
                style: titilliumRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: Dimensions.iconSizeSmall, color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}
