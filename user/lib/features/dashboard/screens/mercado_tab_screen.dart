import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/mercado_explorar_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:provider/provider.dart';

/// R-Inicio: pestaña Mercado del dashboard, gobernada por el gate combinado
/// (kill-switch de código && remoto del panel). Con el gate apagado pinta
/// SizedBox (el NavItem ni se muestra: este es el cinturón). Con sesión monta
/// la vitrina existente en modo pestaña; sin sesión, guard de login — el
/// explorar del Mercado es auth:api y sin guard daría 401 + toast.
class MercadoTabScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final ValueNotifier<bool>? loginNotifier;
  const MercadoTabScreen({super.key, this.onLoginSuccess, this.loginNotifier});

  @override
  State<MercadoTabScreen> createState() => _MercadoTabScreenState();
}

class _MercadoTabScreenState extends State<MercadoTabScreen> {
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
    if (!Provider.of<SplashController>(context).mercadoVisible) {
      return const SizedBox.shrink();
    }

    if (isGuestMode) {
      return Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('mercado', context) ?? 'Mercado',
          isBackButtonExist: false,
        ),
        body: NotLoggedInWidget(
          message: getTranslated('inicia_sesion_para_ver_el_mercado', context),
          fromPage: '${RouterHelper.dashboardScreen}?page=mercado',
          onLoginSuccess: () {
            if (mounted) {
              setState(() => isGuestMode = false);
            }
            widget.onLoginSuccess?.call();
          },
        ),
      );
    }

    return const MercadoExplorarScreen(fromDashboard: true);
  }
}
