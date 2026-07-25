import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/screens/digital_card_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:provider/provider.dart';

/// R-Inicio: pestaña Tarjeta del dashboard — la Tarjeta Digital (F3) sube al
/// footer. Mismo patrón de sesión que ChatsTabScreen (loginNotifier +
/// NotLoggedInWidget); con sesión monta la pantalla existente en modo pestaña
/// (sin flecha de regreso). Su uso pusheado desde el Menú queda intacto.
class TarjetaTabScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final ValueNotifier<bool>? loginNotifier;
  const TarjetaTabScreen({super.key, this.onLoginSuccess, this.loginNotifier});

  @override
  State<TarjetaTabScreen> createState() => _TarjetaTabScreenState();
}

class _TarjetaTabScreenState extends State<TarjetaTabScreen> {
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
          title: getTranslated('my_digital_card', context) ?? 'Mi Tarjeta Digital',
          isBackButtonExist: false,
        ),
        body: NotLoggedInWidget(
          message: getTranslated('inicia_sesion_para_ver_tu_tarjeta', context),
          fromPage: '${RouterHelper.dashboardScreen}?page=tarjeta',
          onLoginSuccess: () {
            if (mounted) {
              setState(() => isGuestMode = false);
            }
            widget.onLoginSuccess?.call();
          },
        ),
      );
    }

    return const DigitalCardScreen(fromDashboard: true);
  }
}
