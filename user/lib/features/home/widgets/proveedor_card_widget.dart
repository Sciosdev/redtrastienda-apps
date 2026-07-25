import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

/// R-Inicio: tarjeta de proveedor del hub — grande pero LIMPIA (decisión de
/// Axel): banda visual de la marca (banner del shop; si no hay, logo sobre
/// color del theme) + pill flotante "N productos" + nombre. SIN pedido mínimo,
/// SIN sello de zona, SIN botón: el tap lleva directo a la pantalla de surtido
/// del proveedor (R-Proveedor), con los mismos args que SellerCard.
class ProveedorCardWidget extends StatelessWidget {
  final Seller seller;
  const ProveedorCardWidget({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final String banner = seller.shop?.bannerFullUrl?.path ?? '';
    final String logo = seller.shop?.imageFullUrl?.path ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      onTap: () {
        RouterHelper.getTopSellerRoute(
          action: RouteAction.push,
          slug: seller.shop?.slug,
          sellerId: seller.id,
          temporaryClose: seller.shop?.temporaryClose,
          vacationStatus: seller.shop?.vacationStatus ?? false,
          vacationEndDate: seller.shop?.vacationEndDate,
          vacationStartDate: seller.shop?.vacationStartDate,
          vacationDurationType: seller.shop?.vacationDurationType,
          name: seller.shop?.name,
          banner: seller.shop?.bannerFullUrl?.path,
          image: seller.shop?.imageFullUrl?.path,
          totalProduct: seller.productCount,
          totalReview: seller.ratingCount,
          rating: seller.averageRating?.toString(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.075),
              spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.paddingSizeSmall),
                    topRight: Radius.circular(Dimensions.paddingSizeSmall),
                  ),
                  child: banner.isNotEmpty
                      ? CustomImageWidget(image: banner, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                          child: Center(
                            child: ClipOval(
                              child: CustomImageWidget(image: logo, width: 56, height: 56),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: Dimensions.paddingSizeExtraSmall,
                right: Dimensions.paddingSizeExtraSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeEight,
                    vertical: Dimensions.paddingSizeExtraExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${seller.productCount ?? 0} ${getTranslated('productos', context) ?? 'productos'}',
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Text(
              seller.shop?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
