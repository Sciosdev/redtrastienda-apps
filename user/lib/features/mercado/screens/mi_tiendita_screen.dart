import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/controllers/mercado_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/publicacion_form_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/widgets/estado_publicacion_badge_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/widgets/publicacion_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class MiTienditaScreen extends StatefulWidget {
  const MiTienditaScreen({super.key});

  @override
  State<MiTienditaScreen> createState() => _MiTienditaScreenState();
}

class _MiTienditaScreenState extends State<MiTienditaScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MercadoController>(context, listen: false).getMisPublicaciones();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 200) {
      return;
    }
    final controller = Provider.of<MercadoController>(context, listen: false);
    final int cargadas = controller.misPublicacionesModel?.data?.length ?? 0;
    final int total = controller.misPublicacionesModel?.totalSize ?? 0;
    if (!controller.isMisPublicacionesLoading && cargadas < total) {
      controller.getMisPublicaciones(offset: (cargadas ~/ 15) + 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onAccion(String accion, PublicacionMercado publicacion) {
    final controller = Provider.of<MercadoController>(context, listen: false);
    switch (accion) {
      case 'editar':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PublicacionFormScreen(publicacion: publicacion)));
        break;
      case 'toggle':
        controller.togglePublicacion(publicacion.id!);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('mi_tiendita', context) ?? 'Mi tiendita'),
      // Colores explícitos: el default M3 del theme pintaba el FAB verdoso,
      // fuera del patrón de botón primario de la app.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicacionFormScreen())),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(getTranslated('publicar', context) ?? 'Publicar'),
      ),
      body: Consumer<MercadoController>(
        builder: (context, controller, child) {
          final List<PublicacionMercado> publicaciones = controller.misPublicacionesModel?.data ?? [];

          if (controller.isMisPublicacionesLoading && publicaciones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (publicaciones.isEmpty) {
            return NoInternetOrDataScreenWidget(
              isNoInternet: false,
              message: getTranslated('sin_publicaciones_mi_tiendita', context) ??
                  'Aún no tienes publicaciones. ¡Publica tu primer producto o aviso!',
            );
          }

          final int total = controller.misPublicacionesModel?.totalSize ?? 0;
          final bool hayMas = publicaciones.length < total;

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            itemCount: publicaciones.length + (hayMas ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= publicaciones.length) {
                return const Padding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final publicacion = publicaciones[index];
              return PublicacionCardWidget(
                publicacion: publicacion,
                onTap: () => _onAccion('editar', publicacion),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    EstadoPublicacionBadgeWidget(publicacion: publicacion),
                    PopupMenuButton<String>(
                      onSelected: (accion) => _onAccion(accion, publicacion),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'editar',
                          child: Text(getTranslated('editar_publicacion', context) ?? 'Editar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(publicacion.activo == true
                              ? (getTranslated('pausar_publicacion', context) ?? 'Pausar')
                              : (getTranslated('reactivar_publicacion', context) ?? 'Reactivar')),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
