import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/controllers/affiliate_profile_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/controllers/chat_tiendas_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/screens/conversacion_tienda_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/avatar_inicial_tienda_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/controllers/mercado_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/publicacion_detalle_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/widgets/publicacion_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class TiendaPublicaScreen extends StatefulWidget {
  final int userId;
  final String? nombre;
  const TiendaPublicaScreen({super.key, required this.userId, this.nombre});

  @override
  State<TiendaPublicaScreen> createState() => _TiendaPublicaScreenState();
}

class _TiendaPublicaScreenState extends State<TiendaPublicaScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MercadoController>(context, listen: false).getTienda(widget.userId);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 200) {
      return;
    }
    final controller = Provider.of<MercadoController>(context, listen: false);
    final int cargadas = controller.tiendaModel?.publicaciones?.data?.length ?? 0;
    final int total = controller.tiendaModel?.publicaciones?.totalSize ?? 0;
    if (!controller.isTiendaLoading && cargadas < total) {
      controller.getTienda(widget.userId, offset: (cargadas ~/ 15) + 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _esMiTienda =>
      Provider.of<AffiliateProfileController>(context, listen: false).profile?.customerId == widget.userId;

  void _enviarMensaje(AfiliadoDirectorio contraparte) {
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    final int? chatExistente = controller.chatIdParaContraparte(widget.userId);
    controller.abrirConversacion(contraparte: contraparte, chatId: chatExistente);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversacionTiendaScreen(
      contraparte: contraparte,
      chatId: chatExistente,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.nombre ?? (getTranslated('tienda', context) ?? 'Tienda')),
      body: Consumer<MercadoController>(
        builder: (context, controller, child) {
          if (controller.isTiendaLoading && controller.tiendaModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final tienda = controller.tiendaModel;
          if (tienda == null) {
            return NoInternetOrDataScreenWidget(
              isNoInternet: false,
              message: getTranslated('tienda_no_disponible', context) ?? 'Esta tienda no está disponible en este momento',
            );
          }

          final List<PublicacionMercado> publicaciones = tienda.publicaciones?.data ?? [];
          final int total = tienda.publicaciones?.totalSize ?? 0;
          final bool hayMas = publicaciones.length < total;
          // Los items del perfil no traen bloque dueno: se arma con el
          // encabezado para que el detalle conserve "Me interesa"/tarjeta.
          final AfiliadoDirectorio dueno = AfiliadoDirectorio(
            userId: tienda.userId,
            nombre: tienda.nombre,
            nombreNegocio: tienda.nombreNegocio,
            estado: tienda.estado,
          );

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            itemCount: 1 + publicaciones.length + (hayMas ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tienda.fotoNegocioUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: CustomImageWidget(image: tienda.fotoNegocioUrl!, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(
                      children: [
                        AvatarInicialTiendaWidget(nombre: tienda.nombre),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tienda.nombre ?? '', style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                              Text(
                                [
                                  if ((tienda.nombreNegocio ?? '').isNotEmpty) tienda.nombreNegocio!,
                                  if ((tienda.estado ?? '').isNotEmpty) tienda.estado!,
                                ].join(' · '),
                                style: textRegular.copyWith(color: Theme.of(context).hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    if (!_esMiTienda)
                      CustomButton(
                        buttonText: getTranslated('enviar_mensaje', context) ?? 'Enviar mensaje',
                        onTap: () => _enviarMensaje(dueno),
                      ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      '${getTranslated('publicaciones', context) ?? 'Publicaciones'} ($total)',
                      style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    if (publicaciones.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: Center(
                          child: Text(
                            getTranslated('sin_publicaciones_mercado', context) ?? 'Aún no hay publicaciones',
                            style: textRegular.copyWith(color: Theme.of(context).hintColor),
                          ),
                        ),
                      ),
                  ],
                );
              }

              if (index > publicaciones.length) {
                return const Padding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final publicacion = publicaciones[index - 1];
              return PublicacionCardWidget(
                publicacion: publicacion,
                onTap: () {
                  publicacion.dueno ??= dueno;
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      PublicacionDetalleScreen(publicacion: publicacion)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
