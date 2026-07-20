import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/controllers/affiliate_profile_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/models/affiliate_profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class DigitalCardScreen extends StatefulWidget {
  // R-Inicio: como pestaña del dashboard no debe pintar flecha de regreso
  // (no hay a dónde regresar). Default false = uso pusheado de siempre.
  final bool fromDashboard;
  const DigitalCardScreen({super.key, this.fromDashboard = false});

  @override
  State<DigitalCardScreen> createState() => _DigitalCardScreenState();
}

class _DigitalCardScreenState extends State<DigitalCardScreen> {
  // Rojo institucional ANPEC.
  static const Color _anpecRed = Color(0xFFA1262B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AffiliateProfileController>(context, listen: false).getAffiliateProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _anpecRed,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.fromDashboard,
        title: Text(getTranslated('my_digital_card', context) ?? '',
            style: textMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
      ),
      body: Consumer<AffiliateProfileController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _anpecRed));
          }

          if (controller.hasNoProfile) {
            return _buildEmptyState(context);
          }

          if (controller.profile == null) {
            return _buildErrorState(context, controller);
          }

          return _buildCard(context, controller.profile!);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, AffiliateProfileModel profile) {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    final String affiliateName =
        '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'.trim();
    final String anp = profile.numeroAnp ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(children: [
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(children: [
            // Cabecera roja con logo.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              decoration: const BoxDecoration(
                color: _anpecRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.paddingSizeLarge),
                  topRight: Radius.circular(Dimensions.paddingSizeLarge),
                ),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Image.asset(Images.logo, height: 56, width: 56),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(getTranslated('digital_card', context) ?? '',
                    style: textMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(children: [
                // Nombre del afiliado.
                Text(affiliateName.isEmpty ? (getTranslated('affiliate', context) ?? '') : affiliateName,
                    textAlign: TextAlign.center,
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // Nombre del negocio.
                if ((profile.nombreNegocio ?? '').isNotEmpty)
                  Text(profile.nombreNegocio!,
                      textAlign: TextAlign.center,
                      style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),

                const SizedBox(height: Dimensions.paddingSizeDefault),
                _statusBadge(context, profile.estatus),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // QR con el número ANP.
                if (anp.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                      border: Border.all(color: _anpecRed.withValues(alpha: 0.2)),
                    ),
                    child: QrImageView(
                      data: anp,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _anpecRed),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A1A)),
                    ),
                  ),

                const SizedBox(height: Dimensions.paddingSizeLarge),
                const Divider(),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                // Número ANP.
                _infoRow(context, getTranslated('numero_anp', context) ?? '', anp),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                // Fecha de afiliación.
                _infoRow(context, getTranslated('affiliation_date', context) ?? '', _formatDate(profile.createdAt)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: Dimensions.paddingSizeLarge),

        // Botón compartir.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _anpecRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
            ),
            onPressed: () => _shareCard(context, affiliateName, profile),
            icon: const Icon(Icons.share),
            label: Text(getTranslated('share_card', context) ?? '',
                style: textMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
      const SizedBox(width: Dimensions.paddingSizeDefault),
      Flexible(
        child: Text(value.isEmpty ? '-' : value,
            textAlign: TextAlign.end,
            style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
      ),
    ]);
  }

  Widget _statusBadge(BuildContext context, String? estatus) {
    final String key = (estatus ?? '').toLowerCase();
    Color color;
    String labelKey;
    switch (key) {
      case 'activo':
      case 'active':
      case 'aprobado':
        color = const Color(0xFF2E7D32);
        labelKey = 'affiliate_status_active';
        break;
      case 'rechazado':
      case 'rejected':
        color = const Color(0xFFC62828);
        labelKey = 'affiliate_status_rejected';
        break;
      case 'bloqueado':
      case 'blocked':
        color = const Color(0xFF424242);
        labelKey = 'affiliate_status_blocked';
        break;
      case 'pendiente':
      case 'pending':
      default:
        color = const Color(0xFFEF6C00);
        labelKey = 'affiliate_status_pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(getTranslated(labelKey, context) ?? (estatus ?? ''),
            style: textMedium.copyWith(color: color, fontSize: Dimensions.fontSizeSmall)),
      ]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.badge_outlined, size: 72, color: Theme.of(context).hintColor),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(getTranslated('no_digital_card_title', context) ?? '',
              textAlign: TextAlign.center, style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(getTranslated('no_digital_card_subtitle', context) ?? '',
              textAlign: TextAlign.center,
              style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
        ]),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AffiliateProfileController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(controller.errorMessage?.isNotEmpty == true
              ? controller.errorMessage!
              : (getTranslated('could_not_load_card', context) ?? ''),
              textAlign: TextAlign.center,
              style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _anpecRed, foregroundColor: Colors.white),
            onPressed: () => controller.getAffiliateProfile(),
            child: Text(getTranslated('try_again', context) ?? 'Retry'),
          ),
        ]),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  void _shareCard(BuildContext context, String affiliateName, AffiliateProfileModel profile) {
    final buffer = StringBuffer();
    buffer.writeln(getTranslated('digital_card', context) ?? 'ANPEC Red Trastienda');
    if (affiliateName.isNotEmpty) buffer.writeln(affiliateName);
    if ((profile.nombreNegocio ?? '').isNotEmpty) buffer.writeln(profile.nombreNegocio);
    buffer.writeln('${getTranslated('numero_anp', context) ?? 'ANP'}: ${profile.numeroAnp ?? ''}');
    SharePlus.instance.share(ShareParams(text: buffer.toString().trim()));
  }
}
