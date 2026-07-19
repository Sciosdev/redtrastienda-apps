import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class HomeTitleWidget extends StatelessWidget {
  final String title;
  final bool isShowViewAll;
  final VoidCallback? onViewAllTap;
  // R-Inicio: etiqueta propia del enlace ("Ver todos"/"Ver todas" según la
  // sección del hub); null = el "Ver todo" de siempre.
  final String? viewAllLabel;

  const HomeTitleWidget({super.key, required this.title, this.isShowViewAll = true, this.onViewAllTap, this.viewAllLabel});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: Dimensions.homePagePadding),
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titilliumBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
        ),
      ),

      isShowViewAll ? InkWell(
        onTap: onViewAllTap,
        child: Text(viewAllLabel ?? getTranslated('VIEW_ALL', context) ?? '', style: titilliumRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        )),
      ): const SizedBox.shrink(),
    ]);
  }
}