import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/controllers/affiliate_profile_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/controllers/chat_tiendas_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/screens/conversacion_tienda_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/avatar_inicial_tienda_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/mi_tiendita_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/tienda_publica_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/widgets/reportar_publicacion_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class PublicacionDetalleScreen extends StatelessWidget {
  final PublicacionMercado publicacion;
  const PublicacionDetalleScreen({super.key, required this.publicacion});

  /// Ajuste de auditoría: en publicación propia se ocultan "Me interesa" y
  /// "Reportar" (el 403 del backend queda como red de seguridad, no como UX).
  bool _esMia(BuildContext context) {
    final int? miUserId = Provider.of<AffiliateProfileController>(context, listen: false).profile?.customerId;
    return miUserId != null && publicacion.dueno?.userId == miUserId;
  }

  void _meInteresa(BuildContext context) {
    final dueno = publicacion.dueno;
    if (dueno?.userId == null) {
      return;
    }
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    final int? chatExistente = controller.chatIdParaContraparte(dueno!.userId!);
    controller.abrirConversacion(contraparte: dueno, chatId: chatExistente);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversacionTiendaScreen(
      contraparte: dueno,
      chatId: chatExistente,
      textoInicial: '${getTranslated('me_interesa', context) ?? 'Me interesa'}: ${publicacion.titulo ?? ''}',
    )));
  }

  @override
  Widget build(BuildContext context) {
    final bool esMia = _esMia(context);
    final dueno = publicacion.dueno;

    return Scaffold(
      appBar: CustomAppBar(
        title: getTranslated('publicacion', context) ?? 'Publicación',
        actions: [
          if (!esMia)
            PopupMenuButton<String>(
              onSelected: (_) => showDialog(
                context: context,
                builder: (_) => ReportarPublicacionDialogWidget(publicacion: publicacion),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'reportar',
                  child: Text(getTranslated('reportar_publicacion', context) ?? 'Reportar publicación'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (publicacion.fotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: CustomImageWidget(image: publicacion.fotoUrl!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    publicacion.titulo ?? '',
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),
                if (publicacion.ofertaVigente == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    ),
                    child: Text(
                      getTranslated('oferta', context) ?? 'OFERTA',
                      style: textBold.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeSmall),
                    ),
                  ),
              ],
            ),
            if (publicacion.precio != null) ...[
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                '\$${publicacion.precio}${(publicacion.unidad ?? '').isNotEmpty ? ' / ${publicacion.unidad}' : ''}',
                style: textBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor),
              ),
            ],
            if (publicacion.ofertaVigente == true && publicacion.vigenciaHasta != null) ...[
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                '${getTranslated('oferta_vigente_hasta', context) ?? 'Oferta vigente hasta'}: ${publicacion.vigenciaHasta}',
                style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
              ),
            ],
            if ((publicacion.descripcion ?? '').isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(publicacion.descripcion!, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
            ],
            const SizedBox(height: Dimensions.paddingSizeDefault),

            if (dueno != null)
              InkWell(
                onTap: dueno.userId == null
                    ? null
                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        TiendaPublicaScreen(userId: dueno.userId!, nombre: dueno.nombre))),
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      AvatarInicialTiendaWidget(nombre: dueno.nombre),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dueno.nombre ?? '', style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              [
                                if ((dueno.nombreNegocio ?? '').isNotEmpty) dueno.nombreNegocio!,
                                if ((dueno.estado ?? '').isNotEmpty) dueno.estado!,
                              ].join(' · '),
                              style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            esMia
                ? CustomButton(
                    buttonText: getTranslated('ver_en_mi_tiendita', context) ?? 'Ver en Mi tiendita',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiTienditaScreen())),
                  )
                : CustomButton(
                    buttonText: getTranslated('me_interesa', context) ?? 'Me interesa',
                    onTap: () => _meInteresa(context),
                  ),
          ],
        ),
      ),
    );
  }
}
