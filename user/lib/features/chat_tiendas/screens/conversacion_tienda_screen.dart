import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/controllers/chat_tiendas_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/afiliado_directorio_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/domain/models/mensaje_tienda_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/bloquear_reportar_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/widgets/burbuja_mensaje_tienda_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ConversacionTiendaScreen extends StatefulWidget {
  final AfiliadoDirectorio contraparte;
  final int? chatId;
  const ConversacionTiendaScreen({super.key, required this.contraparte, this.chatId});

  @override
  State<ConversacionTiendaScreen> createState() => _ConversacionTiendaScreenState();
}

class _ConversacionTiendaScreenState extends State<ConversacionTiendaScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // No hay websockets en el stack: polling cada ~10s mientras la pantalla
  // está visible (Timer cancelado en dispose). Push real llega con F8.
  static const Duration _intervaloPolling = Duration(seconds: 10);
  Timer? _pollingTimer;
  int? _chatId;
  int _paginaCargada = 1;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatId != null) {
        Provider.of<ChatTiendasController>(context, listen: false).getMensajes(_chatId!);
        _iniciarPolling();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _iniciarPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_intervaloPolling, (_) {
      if (mounted && _chatId != null) {
        Provider.of<ChatTiendasController>(context, listen: false).getMensajes(_chatId!, silencioso: true);
      }
    });
  }

  void _onScroll() {
    // reverse: true → el final de la lista son los mensajes más viejos.
    if (_scrollController.position.extentAfter > 200 || _chatId == null) {
      return;
    }
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    final int cargados = controller.mensajesModel?.data?.length ?? 0;
    final int total = controller.mensajesModel?.totalSize ?? 0;
    if (!controller.isMensajesLoading && cargados < total) {
      _paginaCargada++;
      controller.getMensajes(_chatId!, offset: _paginaCargada);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final String texto = _inputController.text.trim();
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    if (texto.isEmpty || controller.isEnviando || widget.contraparte.userId == null) {
      return;
    }

    final int? chatId = await controller.enviarMensaje(
      destinatarioId: widget.contraparte.userId!,
      mensaje: texto,
    );

    if (chatId != null) {
      _inputController.clear();
      if (_chatId == null) {
        // Primer mensaje desde el directorio: ya existe conversación — se
        // carga el historial completo (por si el par ya se había escrito).
        _chatId = chatId;
        _paginaCargada = 1;
        controller.getMensajes(chatId, silencioso: true);
        _iniciarPolling();
      }
    }
  }

  void _onAccionMenu(String accion) {
    final controller = Provider.of<ChatTiendasController>(context, listen: false);
    switch (accion) {
      case 'bloquear':
        showDialog(
          context: context,
          builder: (_) => BloquearReportarDialogWidget(contraparte: widget.contraparte, esReporte: false),
        );
        break;
      case 'reportar':
        showDialog(
          context: context,
          builder: (_) => BloquearReportarDialogWidget(contraparte: widget.contraparte, esReporte: true),
        );
        break;
      case 'desbloquear':
        controller.desbloquear(userId: widget.contraparte.userId!);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.contraparte.nombre ?? '',
        actions: [
          Consumer<ChatTiendasController>(
            builder: (context, controller, child) {
              final bool bloqueadoPorMi = controller.mensajesModel?.bloqueadoPorMi ?? false;
              return PopupMenuButton<String>(
                onSelected: _onAccionMenu,
                itemBuilder: (context) => [
                  if (bloqueadoPorMi)
                    PopupMenuItem(
                      value: 'desbloquear',
                      child: Text(getTranslated('desbloquear_usuario', context) ?? 'Desbloquear'),
                    )
                  else
                    PopupMenuItem(
                      value: 'bloquear',
                      child: Text(getTranslated('bloquear_usuario', context) ?? 'Bloquear'),
                    ),
                  PopupMenuItem(
                    value: 'reportar',
                    child: Text(getTranslated('reportar_usuario', context) ?? 'Reportar'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatTiendasController>(
              builder: (context, controller, child) {
                final List<MensajeTienda> mensajes = controller.mensajesModel?.data ?? [];

                if (controller.isMensajesLoading && mensajes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (mensajes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: Text(
                        getTranslated('inicia_la_conversacion', context) ??
                            'Este es el inicio de su conversación. ¡Salúdalo!',
                        style: textRegular.copyWith(color: Theme.of(context).hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) => BurbujaMensajeTiendaWidget(mensaje: mensajes[index]),
                );
              },
            ),
          ),
          Consumer<ChatTiendasController>(
            builder: (context, controller, child) {
              final bool bloqueadoPorMi = controller.mensajesModel?.bloqueadoPorMi ?? false;

              if (bloqueadoPorMi) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  color: Theme.of(context).cardColor,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            getTranslated('bloqueaste_a_este_usuario_banner', context) ??
                                'Bloqueaste a este usuario',
                            style: textRegular.copyWith(color: Theme.of(context).hintColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _onAccionMenu('desbloquear'),
                          child: Text(getTranslated('desbloquear_usuario', context) ?? 'Desbloquear'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeExtraSmall,
                ),
                color: Theme.of(context).cardColor,
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          maxLength: 1000,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: getTranslated('escribe_un_mensaje', context) ?? 'Escribe un mensaje',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).scaffoldBackgroundColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      controller.isEnviando
                          ? const Padding(
                              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              onPressed: _enviar,
                              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
