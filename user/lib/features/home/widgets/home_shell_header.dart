import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/controllers/notification_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/domain/models/notification_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// R-Inicio: header del shell del home (saludo + campana de R-Nav + avatar),
/// extraído VERBATIM de home_explore_screen para que el hub de surtido
/// (anpecInicioFlow ON) y el home de consumo (flag OFF) monten exactamente el
/// mismo widget — una sola fuente de verdad para el saludo.
class HomeShellHeader extends StatelessWidget {
  const HomeShellHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // bottom: false — el dashboard usa extendBody, así que el Scaffold inyecta
    // la altura del footer como padding.bottom del MediaQuery; con el SafeArea
    // completo ese colchón se pintaba como franja roja vacía bajo el saludo
    // (smoke A1). El header solo necesita respetar el status bar.
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding, vertical: Dimensions.paddingSizeSmall),
        child: Consumer<ProfileController>(
          builder: (context, profileController, _) {
            final bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
            final String firstLine = isLoggedIn
                ? getTranslated('hello_welcome', context)!
                : getTranslated('hello', context)!;
            final String secondLine = isLoggedIn
                ? (profileController.userInfoModel?.fName ?? '')
                : getTranslated('welcome', context)!;
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        firstLine,
                        style: titilliumRegular.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraExtraSmall),
                      Text(secondLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titilliumBold.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                // R-Nav: campana de notificaciones (el rail del
                // menú viejo muere y este es su nuevo lugar) y el
                // avatar pasa a abrir Mi perfil — el menú ya tiene
                // su pestaña. Flag OFF: avatar → menú viejo, igual.
                if (AppConstants.anpecNavFlow) ...[
                  const NotificationBellWidget(),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                ],
                GestureDetector(
                  onTap: () {
                    if (!AppConstants.anpecNavFlow) {
                      RouterHelper.getMoreScreenRoute(action: RouteAction.push);
                    } else if (isLoggedIn) {
                      context.push(RouterHelper.profileScreen1);
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => NotLoggedInBottomSheetWidget(
                            fromPage: '${RouterHelper.dashboardScreen}?page=home'),
                      );
                    }
                  },
                  child: ClipOval(
                    child: CustomImageWidget(
                        image: profileController.userInfoModel?.imageFullUrl?.path ?? '',
                        width: 40, height: 40, placeholder: Images.guestProfile),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// R-Nav: campana de notificaciones en el AppBar del home — heredera del
/// ícono del rail del menú viejo (mismo conteo `totalNewNotification`).
/// R-Inicio: se muda aquí junto con el header que la monta.
class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => RouterHelper.getNotificationRoute(action: RouteAction.push),
      child: Stack(clipBehavior: Clip.none, children: [
        const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
        Positioned(
          top: -4,
          right: -4,
          child: Consumer2<AuthController, NotificationController>(
            builder: (context, authController, notificationController, _) {
              if (!authController.isLoggedIn()) return const SizedBox.shrink();
              final int count = totalNewNotification(
                notificationController.notificationModel,
                notificationController.auctionNotificationModel,
                isAuctionEnabled: (Provider.of<SplashController>(context, listen: false).configModel?.isAuctionFeatureEnabled == true) ||
                    (Provider.of<ProfileController>(context, listen: false).userInfoModel?.showAuctionMenuForUser == true),
              );
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: textBold.copyWith(fontSize: 9, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
