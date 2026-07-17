import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat_tiendas/screens/conversaciones_tiendas_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:provider/provider.dart';

/// R-Nav: pestaña Chats del dashboard. Envuelve el chat entre tiendas con el
/// mismo patrón de sesión que usa la pestaña Pedidos (loginNotifier +
/// NotLoggedInWidget); con sesión monta la pantalla existente, cuyo initState
/// ya carga el inbox.
class ChatsTabScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final ValueNotifier<bool>? loginNotifier;
  const ChatsTabScreen({super.key, this.onLoginSuccess, this.loginNotifier});

  @override
  State<ChatsTabScreen> createState() => _ChatsTabScreenState();
}

class _ChatsTabScreenState extends State<ChatsTabScreen> {
  bool isGuestMode = !Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();

  @override
  void initState() {
    super.initState();
    widget.loginNotifier?.addListener(_onLoginChanged);
  }

  void _onLoginChanged() {
    if (!mounted) return;
    final bool loggedIn = widget.loginNotifier?.value ?? false;

    if (loggedIn && isGuestMode) {
      setState(() => isGuestMode = false);
    } else if (!loggedIn && !isGuestMode) {
      setState(() => isGuestMode = true);
    }
  }

  @override
  void dispose() {
    widget.loginNotifier?.removeListener(_onLoginChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isGuestMode) {
      return Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('chats', context) ?? 'Chats',
          isBackButtonExist: false,
        ),
        body: NotLoggedInWidget(
          message: getTranslated('inicia_sesion_para_chatear', context),
          fromPage: '${RouterHelper.dashboardScreen}?page=chats',
          onLoginSuccess: () {
            if (mounted) {
              setState(() => isGuestMode = false);
            }
            widget.onLoginSuccess?.call();
          },
        ),
      );
    }

    return const ConversacionesTiendasScreen(fromDashboard: true);
  }
}
