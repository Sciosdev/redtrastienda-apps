import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/widgets/category_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/home_shell_header.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/proveedor_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/redesign/home_title_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/search_home_page_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// R-Inicio: el HUB de surtido — la pestaña Inicio deja de ser el home de
/// consumo de 6valley y aterriza al tendero listo para pedir. Orden cerrado
/// por Axel: Buscar → Mis pedidos recientes → Categorías → Mis proveedores.
/// Todo reusa lo existente: búsqueda global, detalle/lista de pedidos,
/// pantalla de categoría "como antes" y la pantalla de surtido de R-Proveedor.
class HomeHubScreen extends StatefulWidget {
  final ValueNotifier<bool>? loginNotifier;
  const HomeHubScreen({super.key, this.loginNotifier});

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  bool get _isLoggedIn => Provider.of<AuthController>(context, listen: false).isLoggedIn();

  @override
  void initState() {
    super.initState();
    widget.loginNotifier?.addListener(_onLoginChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isLoggedIn) {
        Provider.of<OrderController>(context, listen: false).getHubRecentOrders();
      }
      final ShopController shopController = Provider.of<ShopController>(context, listen: false);
      if (shopController.allSellerModel == null) {
        shopController.getAllSellerList(offset: 1);
      }
    });
  }

  void _onLoginChanged() {
    if (!mounted) return;
    final OrderController orderController = Provider.of<OrderController>(context, listen: false);
    if (_isLoggedIn) {
      orderController.getHubRecentOrders();
    } else {
      orderController.clearHubOrders();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.loginNotifier?.removeListener(_onLoginChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    final categoryController = Provider.of<CategoryController>(context, listen: false);
    final orderController = Provider.of<OrderController>(context, listen: false);
    final shopController = Provider.of<ShopController>(context, listen: false);
    final bool isLoggedIn = _isLoggedIn;

    await profileController.getUserInfo(context, isLoggedIn: isLoggedIn);
    await categoryController.getCategoryList(true);
    if (isLoggedIn) {
      await orderController.getHubRecentOrders();
    }
    await shopController.getAllSellerList(offset: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: Theme.of(context).primaryColor,
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                      child: HomeShellHeader(),
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HubSearchBarDelegate(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: InkWell(
                        onTap: () => RouterHelper.getSearchRoute(action: RouteAction.push),
                        child: const SearchHomePageWidget(
                          isCompact: true,
                          hintKey: 'buscar_en_todos_tus_proveedores',
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // ── Mis pedidos recientes ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                      child: HomeTitleWidget(
                        title: getTranslated('mis_pedidos_recientes', context) ?? 'Mis pedidos recientes',
                        viewAllLabel: getTranslated('ver_todos', context) ?? 'Ver todos',
                        onViewAllTap: () => RouterHelper.getOrderScreenRoute(action: RouteAction.push),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    _pedidosRecientes(context),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ── Categorías ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                      child: HomeTitleWidget(
                        title: getTranslated('categorias', context) ?? 'Categorías',
                        viewAllLabel: getTranslated('ver_todas', context) ?? 'Ver todas',
                        onViewAllTap: () => RouterHelper.getCategoryScreenRoute(action: RouteAction.push),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    _categorias(context),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ── Mis proveedores ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                      child: HomeTitleWidget(
                        title: getTranslated('mis_proveedores', context) ?? 'Mis proveedores',
                        viewAllLabel: getTranslated('ver_todos', context) ?? 'Ver todos',
                        onViewAllTap: () => RouterHelper.getAllTopSellerRoute(
                            action: RouteAction.push, title: 'all_seller'),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    _proveedores(context),

                    // La barra flotante del dashboard (extendBody) tapa el
                    // final del scroll — mismo colchón que el Menú de R-Nav.
                    const SizedBox(height: 96),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pedidos ────────────────────────────────────────────────────────────

  Widget _pedidosRecientes(BuildContext context) {
    if (!_isLoggedIn) {
      return _tarjetaInvitacion(
        context,
        icon: Icons.receipt_long_outlined,
        titulo: getTranslated('inicia_sesion_para_ver_tus_pedidos', context) ?? 'Inicia sesión para ver tus pedidos',
        subtitulo: getTranslated('surte_con_tus_proveedores', context) ?? 'Surte tu tienda con tus proveedores',
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => NotLoggedInBottomSheetWidget(
              fromPage: '${RouterHelper.dashboardScreen}?page=home'),
        ),
      );
    }

    return Consumer<OrderController>(
      builder: (context, orderController, _) {
        if (orderController.isHubOrdersLoading && orderController.hubOrdersModel == null) {
          return _shimmerFilas(context);
        }
        final List<Orders> pedidos =
            (orderController.hubOrdersModel?.orders ?? []).take(3).toList();
        if (pedidos.isEmpty) {
          return _tarjetaInvitacion(
            context,
            icon: Icons.storefront_outlined,
            titulo: getTranslated('aun_no_tienes_pedidos', context) ?? 'Aún no tienes pedidos',
            subtitulo: getTranslated('surte_con_tus_proveedores', context) ?? 'Surte tu tienda con tus proveedores',
          );
        }
        return Column(
          children: pedidos.map((pedido) => _HubOrderRow(pedido: pedido)).toList(),
        );
      },
    );
  }

  // ── Categorías ─────────────────────────────────────────────────────────

  Widget _categorias(BuildContext context) {
    return Consumer<CategoryController>(
      builder: (context, categoryController, _) {
        final categorias = categoryController.categoryList;
        if (categorias.isEmpty) {
          return _shimmerFilas(context, alto: 70);
        }
        return SizedBox(
          height: 105,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: categorias.length,
            itemBuilder: (context, index) => InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              // Tap → productos de la categoría (cruza proveedores) y se pide
              // "como antes" (palabras de Axel): mismo flujo que el listado
              // de categorías de siempre.
              onTap: () => RouterHelper.getBrandCategoryRoute(
                action: RouteAction.push,
                isBrand: false,
                id: categorias[index].id,
                name: categorias[index].name,
              ),
              child: CategoryWidget(
                category: categorias[index],
                index: index,
                length: categorias.length,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Proveedores ────────────────────────────────────────────────────────

  Widget _proveedores(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shopController, _) {
        if (shopController.allSellerModel == null) {
          return _shimmerFilas(context, alto: 140);
        }
        // Excluye el proveedor interno "ANPEC Red Trastienda" (seller id 0) —
        // es la plataforma, no una marca (mismo filtro que el carrusel de
        // R-Proveedor). Todos los demás son "Mis proveedores": sin alta
        // manual (la zona llegará a futuro por API).
        final List<Seller> proveedores =
            (shopController.allSellerModel?.sellers ?? []).where((s) => s.id != 0).toList();
        if (proveedores.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.homePagePadding,
              vertical: Dimensions.paddingSizeLarge,
            ),
            child: Center(
              child: Text(
                getTranslated('sin_proveedores_disponibles', context) ?? 'Aún no hay proveedores disponibles',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              mainAxisExtent: 150,
            ),
            itemCount: proveedores.length,
            itemBuilder: (context, index) => ProveedorCardWidget(seller: proveedores[index]),
          ),
        );
      },
    );
  }

  // ── Piezas comunes ─────────────────────────────────────────────────────

  Widget _tarjetaInvitacion(BuildContext context,
      {required IconData icon, required String titulo, required String subtitulo, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          ),
          child: Row(children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo,
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    )),
                const SizedBox(height: Dimensions.paddingSizeExtraExtraSmall),
                Text(subtitulo,
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerFilas(BuildContext context, {double alto = 48}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).cardColor,
        highlightColor: Colors.grey[300]!,
        child: Container(
          height: alto,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          ),
        ),
      ),
    );
  }
}

/// Fila compacta de pedido del hub: #id · proveedor · chip de estado.
/// El chip reusa las claves de traducción del estatus y el mapeo de colores
/// del OrderWidget de la lista completa.
class _HubOrderRow extends StatelessWidget {
  final Orders pedido;
  const _HubOrderRow({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final String proveedor = pedido.sellerIs == 'admin'
        ? (Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.name ?? '')
        : (pedido.seller?.shop?.name ?? '');

    return InkWell(
      onTap: () => RouterHelper.getOrderDetailsScreenRoute(
        action: RouteAction.push,
        orderId: pedido.id!,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.homePagePadding,
          vertical: Dimensions.paddingSizeEight,
        ),
        child: Row(children: [
          Text('#${pedido.id}',
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(proveedor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                )),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeEight,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: _colorFondoEstatus(context, pedido.orderStatus),
            ),
            child: Text(
              getTranslated(pedido.orderStatus, context) ?? pedido.orderStatus ?? '',
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: _colorTextoEstatus(context, pedido.orderStatus),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Color _colorFondoEstatus(BuildContext context, String? status) {
    switch (status) {
      case 'delivered':
      case 'confirmed':
        return Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: .1);
      case 'pending':
        return Theme.of(context).primaryColor.withValues(alpha: .1);
      case 'processing':
        return Theme.of(context).colorScheme.outline.withValues(alpha: .1);
      case 'canceled':
      case 'failed':
        return Theme.of(context).colorScheme.error.withValues(alpha: .1);
      default:
        return Theme.of(context).colorScheme.secondary.withValues(alpha: .1);
    }
  }

  Color _colorTextoEstatus(BuildContext context, String? status) {
    switch (status) {
      case 'delivered':
      case 'confirmed':
        return Theme.of(context).colorScheme.onTertiaryContainer;
      case 'pending':
        return Theme.of(context).primaryColor;
      case 'processing':
        return Theme.of(context).colorScheme.outline;
      case 'canceled':
      case 'failed':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}

class _HubSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _HubSearchBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(_HubSearchBarDelegate oldDelegate) => oldDelegate.child != child;
}
