import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/redesign/home_title_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/controllers/mercado_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/mercado_explorar_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/tienda_publica_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// R-Nav (C1): tiendas con publicaciones activas en el Mercado, bajo "Mejores
/// proveedores". Se deriva agrupando la página 1 de `mercado/publicaciones`
/// por dueño (el bloque `dueno` trae solo los 4 campos del directorio — P14
/// intacto). Cubre a los dueños de las ~15 publicaciones más recientes: para
/// un riel de home es el comportamiento deseable (actividad reciente primero);
/// el endpoint dedicado queda como mejora post-expo. Solo con sesión (la API
/// del Mercado exige token).
class TiendasRedWidget extends StatefulWidget {
  const TiendasRedWidget({super.key});

  @override
  State<TiendasRedWidget> createState() => _TiendasRedWidgetState();
}

class _TiendasRedWidgetState extends State<TiendasRedWidget> {
  bool _solicitado = false;

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = Provider.of<AuthController>(context).isLoggedIn();
    if (!isLoggedIn) {
      _solicitado = false;
      return const SizedBox.shrink();
    }

    return Consumer<MercadoController>(
      builder: (context, controller, _) {
        if (!_solicitado && controller.tiendasRedModel == null && !controller.isTiendasRedLoading) {
          _solicitado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Provider.of<MercadoController>(context, listen: false).getTiendasRed();
            }
          });
        }

        final List<AfiliadoDirectorio> tiendas = [];
        final Set<int> vistos = {};
        for (final PublicacionMercado publicacion in controller.tiendasRedModel?.data ?? []) {
          final AfiliadoDirectorio? dueno = publicacion.dueno;
          if (dueno?.userId != null && vistos.add(dueno!.userId!)) {
            tiendas.add(dueno);
          }
        }

        if (tiendas.isEmpty) return const SizedBox.shrink();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
            child: HomeTitleWidget(
              title: getTranslated('tiendas_de_la_red', context) ?? 'Tiendas de la red',
              onViewAllTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MercadoExplorarScreen())),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: Dimensions.homePagePadding, right: 15),
              itemCount: tiendas.length,
              separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
              itemBuilder: (context, index) => _TiendaCard(tienda: tiendas[index]),
            ),
          ),
          const SizedBox(height: Dimensions.homePagePadding),
        ]);
      },
    );
  }
}

class _TiendaCard extends StatelessWidget {
  final AfiliadoDirectorio tienda;
  const _TiendaCard({required this.tienda});

  @override
  Widget build(BuildContext context) {
    final String nombre = (tienda.nombreNegocio?.trim().isNotEmpty ?? false)
        ? tienda.nombreNegocio!.trim()
        : (tienda.nombre ?? '');
    final String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return InkWell(
      onTap: () {
        if (tienda.userId == null) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) =>
            TiendaPublicaScreen(userId: tienda.userId!, nombre: nombre)));
      },
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            child: Text(inicial, style: textBold.copyWith(
              color: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeLarge,
            )),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
          if ((tienda.estado ?? '').isNotEmpty)
            Text(tienda.estado!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ]),
      ),
    );
  }
}
