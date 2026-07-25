import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/seller_card.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

class TopSellerWidget extends StatelessWidget {
  const TopSellerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ShopController, SellerModel?>(
      selector: (ctx, shopController)=> shopController.topSellerModel,
      builder: (context, sellerModel, child) {
        // R-Proveedor: oculta el proveedor interno "ANPEC Red Trastienda" (id 0)
        // del carrusel "Mejores proveedores" — es la plataforma, no una marca.
        // Solo del carrusel (Decisión #2); sigue alcanzable por otras vías.
        // Flag OFF: lista completa, idéntica a hoy.
        final List<Seller> sellers = AppConstants.anpecProveedorFlow
            ? (sellerModel?.sellers?.where((s) => s.id != 0).toList() ?? [])
            : (sellerModel?.sellers ?? []);
        return sellers.isNotEmpty ? ListView.builder(
          itemCount: sellers.length,
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) => SizedBox(width: MediaQuery.of(context).size.width * .70, child: SellerCard(
            sellerModel: sellers[index],
            isHomePage: true,
            index: index,
            length: sellers.length,
          )),
        ) : const SizedBox();
      },
    );
  }
}



