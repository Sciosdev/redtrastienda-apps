import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_filter_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/search_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/anpec_contact_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/seller_category_chips.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart' show Get;
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// R-Pulido-AAB: header del proveedor SIN espacios muertos (smoke B1) + card
/// de contacto (decisión de Axel). Un solo SliverPersistentHeader colapsable:
/// banner + card de contacto se van con el scroll; buscador + ⚙ + chips quedan
/// fijos bajo el status bar. El delegate mide EXACTAMENTE su contenido, así el
/// hueco del layout viejo (que reservaba topPadding + altura de sobra en
/// reposo) desaparece de raíz. La franja de chips no reserva altura mientras
/// las categorías del proveedor no hayan cargado (smoke B2/B3).
class ProveedorHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double bannerHeight = 120;
  static const double bannerHeightTab = 250;
  static const double cardHeight = 130;
  static const double bannerCardGap = Dimensions.paddingSizeEight;
  static const double searchHeight = 70; // SearchWidget: campo 50 + 10 vertical x2
  static const double chipsHeight = 50; // fila ⚙+chips: 40 + 5 vertical x2

  final double topPadding;
  final double bannerH;
  final bool hasChips;
  final Widget collapsibleChild;
  final Widget pinnedChild;

  ProveedorHeaderDelegate({
    required this.topPadding,
    required this.bannerH,
    required this.hasChips,
    required this.collapsibleChild,
    required this.pinnedChild,
  });

  double get _collapsibleH => bannerH + bannerCardGap + cardHeight;
  double get _pinnedH => searchHeight + (hasChips ? chipsHeight : 0);

  @override
  double get maxExtent => _collapsibleH + _pinnedH;

  @override
  double get minExtent => topPadding + _pinnedH;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Franja del status bar: mientras el banner sigue detrás del reloj se ve la
    // marca; en el último tramo del colapso entra el rojo del theme (mismo
    // lenguaje que el header del hub).
    final double statusCover =
        (shrinkOffset - _collapsibleH + (2 * topPadding)).clamp(0.0, topPadding);

    return Container(
      color: Theme.of(context).canvasColor,
      child: ClipRect(
        child: Stack(children: [
          Positioned(
            top: -shrinkOffset,
            left: 0,
            right: 0,
            height: _collapsibleH,
            child: collapsibleChild,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _pinnedH,
            child: Container(
              color: Theme.of(context).canvasColor,
              child: pinnedChild,
            ),
          ),
          if (statusCover > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusCover,
              child: ColoredBox(color: Theme.of(context).primaryColor),
            ),
        ]),
      ),
    );
  }

  @override
  bool shouldRebuild(ProveedorHeaderDelegate oldDelegate) {
    return oldDelegate.maxExtent != maxExtent ||
        oldDelegate.minExtent != minExtent ||
        oldDelegate.collapsibleChild != collapsibleChild ||
        oldDelegate.pinnedChild != pinnedChild;
  }
}

/// Capa colapsable: banner de marca (con sangrado detrás del status bar, como
/// siempre) + card de contacto del proveedor.
class ProveedorBannerCard extends StatelessWidget {
  final String slug;
  final int? sellerId;
  final String sellerName;
  final String banner;
  final String shopImage;
  final int totalProduct;
  final String? contact;
  final bool vacationIsOn;
  final bool temporaryClose;
  final double topPadding;
  final double bannerH;

  const ProveedorBannerCard({
    super.key,
    required this.slug,
    required this.sellerId,
    required this.sellerName,
    required this.banner,
    required this.shopImage,
    required this.totalProduct,
    required this.contact,
    required this.vacationIsOn,
    required this.temporaryClose,
    required this.topPadding,
    required this.bannerH,
  });

  @override
  Widget build(BuildContext context) {
    final splashController = Provider.of<SplashController>(context, listen: false);
    final bool isInHouse = sellerId == 0 || sellerId == null;
    final String bannerImage =
        isInHouse ? splashController.configModel?.inHouseShop?.bannerFullUrl?.path ?? '' : banner;
    final String logoImage =
        isInHouse ? splashController.configModel?.inHouseShop?.imageFullUrl?.path ?? '' : shopImage;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: bannerH,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          CustomImageWidget(image: bannerImage, placeholder: Images.placeholder_3x1, fit: BoxFit.cover),
          Positioned(
            top: topPadding + Dimensions.paddingSizeExtraSmall,
            left: Dimensions.paddingSizeDefault,
            child: InkWell(
              onTap: () {
                Provider.of<SellerProductController>(context, listen: false).clearSellerProducts();
                Provider.of<CategoryController>(Get.context!, listen: false).onUpdateFilteredCategoryList(isSeller: false);
                Provider.of<BrandController>(Get.context!, listen: false).onUpdateFiltererBrandList(isSeller: false);
                Provider.of<ShopController>(Get.context!, listen: false).nullShopInfoModel();
                Provider.of<CategoryController>(Get.context!, listen: false).uncheckSellerCategoryList();
                Provider.of<BrandController>(Get.context!, listen: false).uncheckSellerBrandList();
                if (sellerId == null) {
                  RouterHelper.getDashboardRoute(action: RouteAction.pushNamedAndRemoveUntil);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
                height: 36,
                width: 36,
                child: Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeEight),
                  child: const Icon(Icons.arrow_back_ios, size: 18),
                ),
              ),
            ),
          ),
          if (temporaryClose || vacationIsOn)
            Positioned(
              bottom: Dimensions.paddingSizeExtraSmall,
              left: Dimensions.paddingSizeDefault,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeEight,
                  vertical: Dimensions.paddingSizeExtraExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  getTranslated(temporaryClose ? 'temporary_closed' : 'close_for_now', context) ?? '',
                  style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: ProveedorHeaderDelegate.bannerCardGap),
      SizedBox(
        height: ProveedorHeaderDelegate.cardHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeTwelve),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeTwelve),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: Provider.of<ThemeController>(context, listen: false).darkTheme
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.25),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeEight),
                  child: CustomImageWidget(image: logoImage, width: 52, height: 52, fit: BoxFit.cover),
                ),
                const SizedBox(width: Dimensions.paddingSizeTwelve),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraExtraSmall),
                    Text(
                      '$totalProduct ${getTranslated('productos', context) ?? 'productos'}',
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ]),
                ),
              ]),
              const Spacer(),
              _ContactActionsRow(
                slug: slug,
                sellerId: sellerId,
                sellerName: sellerName,
                shopImage: logoImage,
                contact: contact,
                vacationIsOn: vacationIsOn,
                temporaryClose: temporaryClose,
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// Fila [💬 Chat] [📞 Llamar] [WhatsApp]. Chat siempre (es el chat de la
/// plataforma); Llamar/WhatsApp SOLO si el shop trae teléfono utilizable —
/// sin huecos ni botones muertos. Reusa el saneo de teléfono del canal
/// WhatsApp ANPEC (F5).
class _ContactActionsRow extends StatelessWidget {
  final String slug;
  final int? sellerId;
  final String sellerName;
  final String shopImage;
  final String? contact;
  final bool vacationIsOn;
  final bool temporaryClose;

  const _ContactActionsRow({
    required this.slug,
    required this.sellerId,
    required this.sellerName,
    required this.shopImage,
    required this.contact,
    required this.vacationIsOn,
    required this.temporaryClose,
  });

  String get _phoneDigits {
    final String digits = AnpecContactSheetWidget.sanitizePhone(contact ?? '');
    // Datos de relleno tipo "000000000" no son un teléfono real.
    if (digits.length < 8 || digits.replaceAll('0', '').isEmpty) return '';
    return digits;
  }

  void _openChat(BuildContext context) {
    if (temporaryClose) {
      showCustomSnackBarWidget('${getTranslated("this_shop_is_close_now", context)}', context, snackBarType: SnackBarType.warning);
      return;
    }
    if (!Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      showModalBottomSheet(
        context: context,
        builder: (_) => NotLoggedInBottomSheetWidget(fromPage: RouterHelper.topSellerScreen),
      );
      return;
    }
    Provider.of<ChatController>(context, listen: false).setUserTypeIndex(context, 1);
    RouterHelper.getChatScreenRoute(
      action: RouteAction.push,
      id: sellerId ?? 0,
      name: sellerName,
      userType: 1,
      isShopOnVacation: vacationIsOn,
      image: shopImage,
    );
  }

  Future<void> _call() async {
    final String digits = _phoneDigits;
    if (digits.isEmpty) return;
    await launchUrl(Uri.parse('tel:$digits'), mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final String digits = _phoneDigits;
    if (digits.isEmpty) return;
    final String message = Uri.encodeComponent(
      getTranslated('anpec_whatsapp_prefill', context) ?? 'Hola, soy afiliado de Red Trastienda.',
    );
    await launchUrl(Uri.parse('https://wa.me/$digits?text=$message'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    const Color whatsappGreen = Color(0xFF25D366); // mismo verde que F5
    final bool hasPhone = _phoneDigits.isNotEmpty;

    return Row(children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: getTranslated('chat_accion', context) ?? 'Chat',
          color: primary,
          onTap: () => _openChat(context),
        ),
      ),
      if (hasPhone) ...[
        const SizedBox(width: Dimensions.paddingSizeEight),
        Expanded(
          child: _ActionButton(
            icon: Icons.call_outlined,
            label: getTranslated('llamar_accion', context) ?? 'Llamar',
            color: primary,
            onTap: _call,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeEight),
        Expanded(
          child: _ActionButton(
            icon: Icons.chat,
            label: getTranslated('whatsapp', context) ?? 'WhatsApp',
            color: whatsappGreen,
            onTap: () => _openWhatsApp(context),
          ),
        ),
      ],
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: color),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Capa fija: buscador + fila ⚙/chips. La fila entera solo existe cuando ya
/// hay categorías del proveedor cargadas (el delegate tampoco le reserva
/// altura antes de eso).
class ProveedorPinnedTools extends StatelessWidget {
  final String slug;
  final bool hasChips;

  const ProveedorPinnedTools({super.key, required this.slug, required this.hasChips});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SearchWidget(hintText: '${getTranslated('search_hint', context)}', slug: slug),
      if (hasChips)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
              child: Stack(children: [
                InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => ProductFilterDialog(slug: slug),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: .5)),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    ),
                    width: 30,
                    height: 30,
                    child: Center(
                      child: CustomAssetImageWidget(
                        Images.filterIcon,
                        width: 15,
                        height: 15,
                        color: Provider.of<ThemeController>(context, listen: false).darkTheme
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Consumer<SellerProductController>(
                  builder: (context, sellerProductController, _) {
                    return sellerProductController.isFilterApply
                        ? CircleAvatar(radius: 5, backgroundColor: Theme.of(context).primaryColor)
                        : const SizedBox();
                  },
                ),
              ]),
            ),
            Expanded(child: SellerCategoryChips(slug: slug)),
          ]),
        ),
    ]);
  }
}
