import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auction_dashboard_summary/controllers/auction_dashboard_summary_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/mercado_explorar_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/mercado/screens/mi_tiendita_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/screens/anpec_webview_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/screens/more_screen_view_new.dart' show MenuItem, SectionHeader, TrailingBadge;
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/anpec_contact_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/logout_confirm_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/screens/my_opportunity_requests_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/business_pages_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// R-Nav: el menú principal como pestaña del dashboard, en 4 secciones
/// (Mi tienda / Proveedores / Mis cosas / Ayuda y soporte). Reemplaza al
/// MoreScreenView + rail con flag ON; el menú viejo queda intacto para flag
/// OFF. Reusa MenuItem/SectionHeader/TrailingBadge (tinte uniforme de
/// R-Limpieza).
class MenuAnpecScreen extends StatefulWidget {
  const MenuAnpecScreen({super.key});

  @override
  State<MenuAnpecScreen> createState() => _MenuAnpecScreenState();
}

class _MenuAnpecScreenState extends State<MenuAnpecScreen> {
  bool _wasLoggedIn = false;
  late AuthController _authController;

  static const String _fromPage = '${RouterHelper.dashboardScreen}?page=menu';

  bool get _walletEnabled =>
      Provider.of<SplashController>(context, listen: false).configModel?.walletStatus == 1;

  bool get _auctionEnabled =>
      (Provider.of<SplashController>(context, listen: false).configModel?.isAuctionFeatureEnabled == true) ||
      (Provider.of<ProfileController>(context, listen: false).userInfoModel?.showAuctionMenuForUser == true);

  @override
  void initState() {
    super.initState();
    _authController = Provider.of<AuthController>(context, listen: false);
    _wasLoggedIn = _authController.isLoggedIn();
    _authController.addListener(_onAuthStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authController.isLoggedIn() && _auctionEnabled) {
        Provider.of<AuctionDashboardSummaryController>(context, listen: false).getAuctionDashboardSummary(context);
      }
    });
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final isNowLoggedIn = _authController.isLoggedIn();
    if (isNowLoggedIn && !_wasLoggedIn) {
      _wasLoggedIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onLoginSuccess();
      });
    } else if (!isNowLoggedIn) {
      _wasLoggedIn = false;
    }
  }

  void _onLoginSuccess() {
    if (!mounted) return;
    setState(() {});
    Provider.of<ProfileController>(context, listen: false).getUserInfo(context, isLoggedIn: true);
    if (_walletEnabled) {
      Provider.of<WalletController>(context, listen: false).getTransactionList(1);
    }
    if (_auctionEnabled) {
      Provider.of<AuctionDashboardSummaryController>(context, listen: false).getAuctionDashboardSummary(context);
    }
  }

  /// Corre [accion] con sesión; sin sesión abre el sheet de login.
  void _conSesion(VoidCallback accion) {
    if (!Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NotLoggedInBottomSheetWidget(fromPage: _fromPage, onLoginSuccess: _onLoginSuccess),
      );
    } else {
      accion();
    }
  }

  BusinessPageModel? _getPageBySlug(String slug, List<BusinessPageModel>? pagesList) {
    if (pagesList == null || pagesList.isEmpty) return null;
    for (final page in pagesList) {
      if (page.slug == slug) return page;
    }
    return null;
  }

  Widget _headerUsuario(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, profileController, _) {
        final user = profileController.userInfoModel;
        final bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          child: GestureDetector(
            onTap: () => _conSesion(() => context.push(RouterHelper.profileScreen1)),
            child: Row(
              children: [
                ClipOval(
                  child: CustomImageWidget(
                    image: isLoggedIn ? (user?.imageFullUrl?.path ?? '') : '',
                    width: 44, height: 44,
                    placeholder: Images.guestProfile,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn
                            ? '${user?.fName ?? ''} ${user?.lName ?? ''}'
                            : (getTranslated('login', context) ?? 'Iniciar sesión'),
                        style: titilliumBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isLoggedIn)
                        Text(
                          user?.phone ?? '',
                          style: titilliumRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final splashController = Provider.of<SplashController>(context, listen: false);
    final authController = Provider.of<AuthController>(context);
    final isLoggedIn = authController.isLoggedIn();

    return Scaffold(
      appBar: CustomAppBar(
        title: getTranslated('menu', context) ?? 'Menú',
        isBackButtonExist: false,
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerUsuario(context),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // ── Mi tienda ────────────────────────────────────────────────
            SectionHeader(title: getTranslated('mi_tienda', context) ?? 'Mi tienda'),

            if (isLoggedIn)
              MenuItem(
                iconImage: Images.walletIcon,
                label: getTranslated('my_digital_card', context) ?? 'Mi Tarjeta Digital',
                onTap: () => RouterHelper.getDigitalCardRoute(action: RouteAction.push),
              ),

            MenuItem(
              iconImage: Images.userSvg,
              label: getTranslated('mi_perfil', context) ?? 'Mi perfil',
              onTap: () => _conSesion(() => context.push(RouterHelper.profileScreen1)),
            ),

            MenuItem(
              iconImage: Images.address,
              label: getTranslated('mis_direcciones', context) ?? 'Mis direcciones',
              onTap: () => _conSesion(() => context.push(RouterHelper.addressScreen)),
            ),

            MenuItem(
              iconImage: Images.settings,
              label: getTranslated('configuracion', context) ?? 'Configuración',
              onTap: () => context.push(RouterHelper.settingsScreen),
            ),

            if (AppConstants.anpecMercadoFlow) ...[
              MenuItem(
                iconImage: Images.storeIcon,
                label: getTranslated('mi_tiendita', context) ?? 'Mi tiendita',
                onTap: () => _conSesion(() => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MiTienditaScreen()))),
              ),
              MenuItem(
                iconImage: Images.storeIcon,
                label: getTranslated('mercado', context) ?? 'Mercado',
                onTap: () => _conSesion(() => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MercadoExplorarScreen()))),
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // ── Proveedores ──────────────────────────────────────────────
            SectionHeader(title: getTranslated('proveedores', context) ?? 'Proveedores'),

            MenuItem(
              iconImage: Images.navOrderIcon,
              label: getTranslated('order_history', context) ?? 'Historial de pedidos',
              onTap: () => _conSesion(() => RouterHelper.getOrderScreenRoute(action: RouteAction.push)),
            ),

            if (isLoggedIn)
              MenuItem(
                iconImage: Images.restockRequestSvg,
                label: getTranslated('my_requests', context) ?? 'Mis solicitudes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOpportunityRequestsScreen())),
              ),

            // C2: con Mercado ON, Ofertas apunta al Mercado filtrado por
            // ofertas; con Mercado OFF, a la lista de ofertas de proveedores.
            MenuItem(
              iconImage: Images.offerSvg,
              label: getTranslated('offers', context) ?? 'Ofertas',
              onTap: () {
                if (AppConstants.anpecMercadoFlow) {
                  _conSesion(() => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MercadoExplorarScreen(soloOfertas: true))));
                } else {
                  RouterHelper.getOfferProductListScreenRoute(action: RouteAction.push);
                }
              },
            ),

            MenuItem(
              iconImage: Images.messageImage,
              label: getTranslated('chat_con_proveedores', context) ?? 'Chat con proveedores',
              onTap: () => _conSesion(() => RouterHelper.getInboxScreenRoute(action: RouteAction.push, isBackButtonExist: true)),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // ── Mis cosas ────────────────────────────────────────────────
            SectionHeader(title: getTranslated('mis_cosas', context) ?? 'Mis cosas'),

            MenuItem(
              iconImage: Images.cartSvg,
              label: getTranslated('cart', context) ?? 'Carrito',
              onTap: () => RouterHelper.getCartScreenRoute(action: RouteAction.push),
            ),

            MenuItem(
              iconImage: Images.wishlistSvg,
              label: getTranslated('wishlist', context) ?? 'Lista de deseos',
              onTap: () => _conSesion(() => RouterHelper.getWishListRoute(action: RouteAction.push)),
            ),

            MenuItem(
              iconImage: Images.couponsIcon,
              label: getTranslated('coupons', context) ?? 'Cupones',
              onTap: () => _conSesion(() => RouterHelper.getCouponListScreenRoute()),
            ),

            // Gateados por config (hoy apagados en el server: ocultos, no borrados).
            if (splashController.configModel?.walletStatus == 1)
              MenuItem(
                iconImage: Images.walletIcon,
                label: getTranslated('wallet', context) ?? 'Monedero',
                trailing: Consumer2<AuthController, WalletController>(
                  builder: (context, authController, walletController, _) {
                    if (!authController.isLoggedIn()) return const SizedBox.shrink();
                    final balance = walletController.walletTransactionModel?.totalWalletBalance ?? 0.0;
                    return TrailingBadge(
                      label: PriceConverter.convertPrice(context, balance),
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      textColor: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
                onTap: () => _conSesion(() => RouterHelper.getWalletRoute(action: RouteAction.push)),
              ),

            if (splashController.configModel?.loyaltyPointStatus == 1)
              MenuItem(
                iconImage: Images.loyaltyPointsIcon,
                label: getTranslated('loyalty_points', context) ?? 'Puntos de lealtad',
                trailing: Consumer2<AuthController, ProfileController>(
                  builder: (context, authController, profileController, _) {
                    if (!authController.isLoggedIn()) return const SizedBox.shrink();
                    final points = profileController.userInfoModel?.loyaltyPoint ?? 0;
                    return TrailingBadge(
                      label: '$points ${getTranslated('points', context) ?? 'puntos'}',
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.35),
                      textColor: Theme.of(context).colorScheme.tertiary,
                    );
                  },
                ),
                onTap: () => _conSesion(() => RouterHelper.getLoyaltyPointScreenRoute(action: RouteAction.push)),
              ),

            if (splashController.configModel?.refEarningStatus == '1')
              MenuItem(
                iconImage: Images.referEarnIcon,
                label: getTranslated('refer_and_earn', context) ?? 'Recomienda y gana',
                onTap: () => _conSesion(() => RouterHelper.getReferAndEarnRoute(action: RouteAction.push)),
              ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // ── Ayuda y soporte ──────────────────────────────────────────
            SectionHeader(title: getTranslated('help_and_support', context) ?? 'Ayuda y soporte'),

            // F5: canal directo con ANPEC; oculto si el config no trae teléfono.
            if ((splashController.configModel?.companyPhone ?? '').trim().isNotEmpty &&
                (splashController.configModel?.companyPhone ?? '').trim().toLowerCase() != 'null')
              MenuItem(
                iconImage: Images.chats,
                label: getTranslated('whatsapp_anpec', context) ?? 'WhatsApp ANPEC',
                onTap: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).cardColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
                  ),
                  builder: (_) => AnpecContactSheetWidget(
                    rawPhone: splashController.configModel!.companyPhone!,
                  ),
                ),
              ),

            MenuItem(
              iconImage: Images.aboutUsSvg,
              label: getTranslated('conectate_con_anpec', context) ?? 'Conéctate con ANPEC',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnpecWebviewScreen(
                url: '${AppConstants.baseUrl}/conectate',
                title: getTranslated('conectate_con_anpec', context) ?? 'Conéctate con ANPEC',
              ))),
            ),

            MenuItem(
              iconImage: Images.contactUs,
              label: getTranslated('contact_us', context) ?? 'Contáctanos',
              onTap: () => context.push(RouterHelper.contactUsScreen),
            ),

            MenuItem(
              iconImage: Images.supportTicketSvg,
              label: getTranslated('soporte', context) ?? 'Soporte',
              onTap: () => RouterHelper.getSupportTicketRoute(action: RouteAction.push),
            ),

            MenuItem(
              iconImage: Images.faqSvg,
              label: getTranslated('faq', context) ?? 'Preguntas frecuentes',
              onTap: () => RouterHelper.getFaqRoute(action: RouteAction.push),
            ),

            if (splashController.defaultBusinessPages != null && splashController.defaultBusinessPages!.isNotEmpty) ...[
              if (_getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages) != null)
                MenuItem(
                  iconImage: Images.tremsConditionSvg,
                  label: getTranslated('terms_condition', context) ?? 'Términos y condiciones',
                  onTap: () => RouterHelper.getHtmlViewRoute(
                    page: _getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages)!,
                  ),
                ),

              if (_getPageBySlug('privacy-policy', splashController.defaultBusinessPages) != null)
                MenuItem(
                  iconImage: Images.policySvg,
                  label: getTranslated('privacy_policy', context) ?? 'Política de privacidad',
                  onTap: () => RouterHelper.getHtmlViewRoute(
                    page: _getPageBySlug('privacy-policy', splashController.defaultBusinessPages)!,
                  ),
                ),

              if (_getPageBySlug('refund-policy', splashController.defaultBusinessPages) != null)
                MenuItem(
                  iconImage: Images.policySvg,
                  label: getTranslated('refund_policy', context) ?? 'Política de reembolso',
                  onTap: () => RouterHelper.getHtmlViewRoute(
                    page: _getPageBySlug('refund-policy', splashController.defaultBusinessPages)!,
                  ),
                ),

              if (_getPageBySlug('return-policy', splashController.defaultBusinessPages) != null)
                MenuItem(
                  iconImage: Images.policySvg,
                  label: getTranslated('return_policy', context) ?? 'Política de devoluciones',
                  onTap: () => RouterHelper.getHtmlViewRoute(
                    page: _getPageBySlug('return-policy', splashController.defaultBusinessPages)!,
                  ),
                ),

              if (_getPageBySlug('cancellation-policy', splashController.defaultBusinessPages) != null)
                MenuItem(
                  iconImage: Images.policySvg,
                  label: getTranslated('cancellation_policy', context) ?? 'Política de cancelación',
                  onTap: () => RouterHelper.getHtmlViewRoute(
                    page: _getPageBySlug('cancellation-policy', splashController.defaultBusinessPages)!,
                  ),
                ),

              if (_getPageBySlug('shipping-policy', splashController.defaultBusinessPages) != null)
                MenuItem(
                  iconImage: Images.policySvg,
                  label: getTranslated('shipping_policy', context) ?? 'Política de envío',
                  onTap: () => RouterHelper.getHtmlViewRoute(
                    page: _getPageBySlug('shipping-policy', splashController.defaultBusinessPages)!,
                  ),
                ),
            ],

            if (_getPageBySlug('about-us', splashController.defaultBusinessPages) != null)
              MenuItem(
                iconImage: Images.aboutUsSvg,
                label: getTranslated('about_us', context) ?? 'Sobre nosotros',
                onTap: () => RouterHelper.getHtmlViewRoute(
                  page: _getPageBySlug('about-us', splashController.defaultBusinessPages)!,
                ),
              ),

            if (splashController.configModel?.blogUrl?.isNotEmpty ?? false)
              MenuItem(
                iconImage: Images.blogSvg,
                label: getTranslated('blog', context) ?? 'Blog',
                onTap: () => RouterHelper.getBlogScreenRoute(
                  action: RouteAction.push,
                  url: splashController.configModel?.blogUrl ?? '',
                ),
              ),

            if (splashController.businessPages != null && splashController.businessPages!.isNotEmpty)
              ...splashController.businessPages!.map((page) => MenuItem(
                iconImage: Images.loyaltyPointsIcon,
                label: page.title ?? '',
                onTap: () => RouterHelper.getHtmlViewRoute(page: page),
              )),

            // ── Subastas (condicional por config; hoy apagadas: invisible) ──
            if (_auctionEnabled) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              SectionHeader(title: getTranslated('bidding_activity', context) ?? 'Subastas'),

              Consumer<AuctionDashboardSummaryController>(
                builder: (context, summaryController, _) {
                  final summaryModel = summaryController.summaryModel;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MenuItem(
                      iconImage: Images.navBidIcon,
                      label: getTranslated('my_bids', context) ?? 'Mis pujas',
                      badgeCount: isLoggedIn ? summaryModel?.totalMyBids : null,
                      onTap: () => _conSesion(() => RouterHelper.getMyBidsScreen(action: RouteAction.push)),
                    ),
                    MenuItem(
                      iconImage: Images.saveIcon,
                      label: getTranslated('saved_auction', context) ?? 'Subastas guardadas',
                      badgeCount: isLoggedIn ? summaryModel?.totalMySavedAuctions : null,
                      onTap: () => _conSesion(() => RouterHelper.getSavedAuctionListScreen(action: RouteAction.push)),
                    ),
                    if ((splashController.configModel?.isAuctionFeatureEnabled == true) &&
                        (splashController.configModel?.isActiveAuctionForCustomer == true))
                      MenuItem(
                        iconImage: Images.navAuctionIcon,
                        label: getTranslated('create_auction', context) ?? 'Crear subasta',
                        onTap: () => _conSesion(() => RouterHelper.getAddEditAuctionProductRoute(action: RouteAction.push, fromDetails: false)),
                      ),
                    MenuItem(
                      iconImage: Images.allAuctionIcon,
                      label: getTranslated('all_auctions', context) ?? 'Todas mis subastas',
                      badgeCount: isLoggedIn ? summaryModel?.totalMyAuctions : null,
                      onTap: () => _conSesion(() => RouterHelper.getUserCreatedAuctionListScreenRoute(action: RouteAction.push)),
                    ),
                    MenuItem(
                      iconImage: Images.navActivityIcon,
                      label: getTranslated('auction_request_list', context) ?? 'Solicitudes de subasta',
                      badgeCount: isLoggedIn ? summaryModel?.totalMyAuctionPending : null,
                      onTap: () => _conSesion(() => RouterHelper.getAuctionQueueListRoute(action: RouteAction.push)),
                    ),
                    MenuItem(
                      iconImage: Images.auctionReportIcon,
                      label: getTranslated('auction_sales_report', context) ?? 'Reporte de ventas',
                      onTap: () => _conSesion(() => RouterHelper.getAuctionSalesReportRoute(action: RouteAction.push)),
                    ),
                    MenuItem(
                      iconImage: Images.transactionSvg,
                      label: getTranslated('auction_transaction_history', context) ?? 'Historial de transacciones',
                      onTap: () => _conSesion(() => RouterHelper.getAuctionTransactionListScreenRoute(action: RouteAction.push)),
                    ),
                  ]);
                },
              ),
            ],

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // ── Cerrar sesión (al final, como hoy) ───────────────────────
            MenuItem(
              iconImage: Images.logOut,
              label: isLoggedIn
                  ? (getTranslated('cerrar_sesion', context) ?? 'Cerrar sesión')
                  : (getTranslated('login', context) ?? 'Iniciar sesión'),
              onTap: () {
                if (!isLoggedIn) {
                  RouterHelper.getLoginRoute(action: RouteAction.push, fromPage: _fromPage);
                } else {
                  showModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (_) => const LogoutCustomBottomSheetWidget(),
                  );
                }
              },
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Row(
                children: [
                  Consumer<ThemeController>(
                    builder: (context, themeController, _) => Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined,
                            size: Dimensions.iconSizeSmall,
                            color: Theme.of(context).hintColor),
                        Switch(
                          value: themeController.darkTheme,
                          onChanged: (_) => themeController.toggleTheme(),
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Icon(Icons.nightlight_round, size: Dimensions.iconSizeSmall, color: Theme.of(context).hintColor),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Consumer<SplashController>(
                    builder: (context, splashController, _) =>
                        Text('${getTranslated('version', context) ?? 'Versión'} ${splashController.configModel?.softwareVersion ?? ''}',
                          style: titilliumRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
      ),
    );
  }
}
