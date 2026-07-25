import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// R-Proveedor: chips de categoría bajo el buscador (look BEES/Juntos+). Acceso
/// rápido para filtrar la grilla de surtido por categoría; reusa EXACTAMENTE el
/// mismo camino que el filtro ⚙ (`getSellerProductList` con `categoryIds`).
/// Selección única con resaltado local. Estilo custom con colores del theme (no
/// `ChoiceChip` M3 crudo, que se sale del theme — lección de R-Mercado).
///
/// Se alimenta de `CategoryController.sellerWiseCategoryList` (ya poblado por el
/// `_load()` del shop screen); si el proveedor no trae categorías, no renderiza
/// nada (`SizedBox.shrink`) y el header no reserva la franja.
class SellerCategoryChips extends StatefulWidget {
  final String slug;
  const SellerCategoryChips({super.key, required this.slug});

  @override
  State<SellerCategoryChips> createState() => _SellerCategoryChipsState();
}

class _SellerCategoryChipsState extends State<SellerCategoryChips> {
  // -1 = chip "Todos"; en otro caso, el id de la categoría seleccionada.
  int _selectedCategoryId = -1;

  Future<void> _onSelect(int categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    final productController = Provider.of<SellerProductController>(context, listen: false);
    if (categoryId == -1) {
      await productController.getSellerProductList(widget.slug, 1, "", categoryIds: '[]');
      productController.setFilterApply(false);
    } else {
      await productController.getSellerProductList(widget.slug, 1, "", categoryIds: jsonEncode([categoryId]));
      productController.setFilterApply(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(
      builder: (context, categoryController, _) {
        final categories = categoryController.sellerWiseCategoryList;
        if (categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _chip(context, label: getTranslated('all_categories', context) ?? 'Todos', id: -1);
              }
              final category = categories[index - 1];
              return _chip(context, label: category.name ?? '', id: category.id ?? -1);
            },
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, {required String label, required int id}) {
    final bool selected = _selectedCategoryId == id;
    final Color primary = Theme.of(context).primaryColor;
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
        onTap: () => _onSelect(id),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: selected ? primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
            border: Border.all(
                color: selected ? primary : Theme.of(context).hintColor.withValues(alpha: .3)),
          ),
          child: Text(
            label,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}
