import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/controllers/chat_tiendas_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/screens/conversacion_tienda_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/afiliado_directorio_tile_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class DirectorioTiendasScreen extends StatefulWidget {
  const DirectorioTiendasScreen({super.key});

  @override
  State<DirectorioTiendasScreen> createState() => _DirectorioTiendasScreenState();
}

class _DirectorioTiendasScreenState extends State<DirectorioTiendasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatTiendasController>(context, listen: false).getDirectorio(search: '');
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 200) {
      return;
    }
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    final int cargados = controller.directorioModel?.data?.length ?? 0;
    final int total = controller.directorioModel?.totalSize ?? 0;
    if (!controller.isDirectorioLoading && cargados < total) {
      controller.getDirectorio(offset: (cargados ~/ 20) + 1);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      Provider.of<ChatTiendasController>(context, listen: false).getDirectorio(search: value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _abrirConversacion(AfiliadoDirectorio afiliado) {
    if (afiliado.userId == null) {
      return;
    }
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    final int? chatExistente = controller.chatIdParaContraparte(afiliado.userId!);
    controller.abrirConversacion(contraparte: afiliado, chatId: chatExistente);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversacionTiendaScreen(
      contraparte: afiliado,
      chatId: chatExistente,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('directorio_de_afiliados', context) ?? 'Directorio de afiliados'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: getTranslated('buscar_por_nombre_negocio_o_estado', context) ??
                    'Busca por nombre, negocio o estado',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: Dimensions.paddingSizeSmall),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatTiendasController>(
              builder: (context, controller, child) {
                final List<AfiliadoDirectorio> afiliados = controller.directorioModel?.data ?? [];

                if (controller.isDirectorioLoading && afiliados.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (afiliados.isEmpty) {
                  return NoInternetOrDataScreenWidget(
                    isNoInternet: false,
                    message: getTranslated('sin_resultados_directorio', context) ?? 'No se encontraron afiliados',
                  );
                }

                final int total = controller.directorioModel?.totalSize ?? 0;
                final bool hayMas = afiliados.length < total;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  itemCount: afiliados.length + (hayMas ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= afiliados.length) {
                      return const Padding(
                        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return AfiliadoDirectorioTileWidget(
                      afiliado: afiliados[index],
                      onTap: () => _abrirConversacion(afiliados[index]),
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
