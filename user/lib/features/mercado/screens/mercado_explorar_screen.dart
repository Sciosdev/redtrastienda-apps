import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/controllers/affiliate_profile_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/controllers/mercado_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/domain/models/publicacion_mercado_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/mi_tiendita_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/publicacion_detalle_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/widgets/mercado_chip_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/widgets/publicacion_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class MercadoExplorarScreen extends StatefulWidget {
  const MercadoExplorarScreen({super.key});

  @override
  State<MercadoExplorarScreen> createState() => _MercadoExplorarScreenState();
}

class _MercadoExplorarScreenState extends State<MercadoExplorarScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<MercadoController>(context, listen: false);
      controller.limpiarFiltros();
      controller.getPublicaciones();
      // El perfil propio alimenta el chip "Mi estado" y la detección de
      // publicaciones propias en el detalle.
      final perfilController = Provider.of<AffiliateProfileController>(context, listen: false);
      if (perfilController.profile == null) {
        perfilController.getAffiliateProfile();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 200) {
      return;
    }
    final controller = Provider.of<MercadoController>(context, listen: false);
    final int cargadas = controller.explorarModel?.data?.length ?? 0;
    final int total = controller.explorarModel?.totalSize ?? 0;
    if (!controller.isExplorarLoading && cargadas < total) {
      controller.getPublicaciones(offset: (cargadas ~/ 15) + 1);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      Provider.of<MercadoController>(context, listen: false).getPublicaciones(search: value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _chipTipo(MercadoController controller, String valor, String etiqueta) {
    final bool seleccionado = controller.filtroTipo == valor;
    return MercadoChipWidget(
      etiqueta: etiqueta,
      seleccionado: seleccionado,
      onTap: () => controller.getPublicaciones(tipo: seleccionado ? '' : valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: getTranslated('mercado', context) ?? 'Mercado',
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiTienditaScreen())),
            icon: Icon(Icons.storefront_outlined, color: Theme.of(context).textTheme.bodyLarge?.color),
            label: Text(
              getTranslated('mi_tiendita', context) ?? 'Mi tiendita',
              style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: getTranslated('buscar_en_el_mercado', context) ?? 'Busca productos, avisos o estados',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: Dimensions.paddingSizeSmall),
              ),
            ),
          ),
          Consumer<MercadoController>(
            builder: (context, controller, child) {
              final String? miEstado = Provider.of<AffiliateProfileController>(context).profile?.estado;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: Row(
                  children: [
                    _chipTipo(controller, '', getTranslated('todos', context) ?? 'Todos'),
                    _chipTipo(controller, 'producto', getTranslated('productos', context) ?? 'Productos'),
                    _chipTipo(controller, 'aviso', getTranslated('avisos', context) ?? 'Avisos'),
                    if ((miEstado ?? '').isNotEmpty)
                      MercadoChipWidget(
                        etiqueta: '${getTranslated('mi_estado', context) ?? 'Mi estado'} ($miEstado)',
                        seleccionado: controller.filtroEstado.isNotEmpty,
                        onTap: () => controller.getPublicaciones(
                          estado: controller.filtroEstado.isNotEmpty ? '' : miEstado,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: Consumer<MercadoController>(
              builder: (context, controller, child) {
                final List<PublicacionMercado> publicaciones = controller.explorarModel?.data ?? [];

                if (controller.isExplorarLoading && publicaciones.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (publicaciones.isEmpty) {
                  return NoInternetOrDataScreenWidget(
                    isNoInternet: false,
                    message: getTranslated('sin_resultados_mercado', context) ?? 'No se encontraron publicaciones',
                  );
                }

                final int total = controller.explorarModel?.totalSize ?? 0;
                final bool hayMas = publicaciones.length < total;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  itemCount: publicaciones.length + (hayMas ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= publicaciones.length) {
                      return const Padding(
                        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return PublicacionCardWidget(
                      publicacion: publicaciones[index],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                          PublicacionDetalleScreen(publicacion: publicaciones[index]))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
