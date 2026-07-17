import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/controllers/chat_tiendas_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/conversacion_tienda_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/screens/conversacion_tienda_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/screens/directorio_tiendas_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/conversacion_tienda_tile_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ConversacionesTiendasScreen extends StatefulWidget {
  // R-Nav: como pestaña del dashboard no lleva flecha back y el título es
  // "Chats"; el uso pusheado (menú viejo) queda idéntico con el default.
  final bool fromDashboard;
  const ConversacionesTiendasScreen({super.key, this.fromDashboard = false});

  @override
  State<ConversacionesTiendasScreen> createState() => _ConversacionesTiendasScreenState();
}

class _ConversacionesTiendasScreenState extends State<ConversacionesTiendasScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatTiendasController>(context, listen: false).getInbox();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 200) {
      return;
    }
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    final int cargadas = controller.conversacionesModel?.data?.length ?? 0;
    final int total = controller.conversacionesModel?.totalSize ?? 0;
    if (!controller.isInboxLoading && cargadas < total) {
      controller.getInbox(offset: (cargadas ~/ 20) + 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _abrirConversacion(ConversacionTienda conversacion) {
    if (conversacion.contraparte == null) {
      return;
    }
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    controller.abrirConversacion(contraparte: conversacion.contraparte!, chatId: conversacion.chatId);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversacionTiendaScreen(
      contraparte: conversacion.contraparte!,
      chatId: conversacion.chatId,
    ))).then((_) {
      if (mounted) {
        Provider.of<ChatTiendasController>(context, listen: false).getInbox();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.fromDashboard
            ? (getTranslated('chats', context) ?? 'Chats')
            : (getTranslated('chat_entre_tiendas', context) ?? 'Chat entre tiendas'),
        isBackButtonExist: !widget.fromDashboard,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectorioTiendasScreen())),
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(getTranslated('nueva_conversacion', context) ?? 'Nueva conversación'),
      ),
      body: Consumer<ChatTiendasController>(
        builder: (context, controller, child) {
          final List<ConversacionTienda> conversaciones = controller.conversacionesModel?.data ?? [];

          if (controller.isInboxLoading && conversaciones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (conversaciones.isEmpty) {
            return NoInternetOrDataScreenWidget(
              isNoInternet: false,
              message: getTranslated('sin_conversaciones_aun', context) ??
                  'Aún no tienes conversaciones. Busca a otro afiliado en el directorio.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getInbox(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              itemCount: conversaciones.length,
              itemBuilder: (context, index) => ConversacionTiendaTileWidget(
                conversacion: conversaciones[index],
                onTap: () => _abrirConversacion(conversaciones[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
