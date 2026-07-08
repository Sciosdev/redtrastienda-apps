import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/widgets/request_contact_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class RequestContactButtonWidget extends StatelessWidget {
  final int productId;
  final String? opportunityTitle;
  const RequestContactButtonWidget({super.key, required this.productId, this.opportunityTitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: CustomButton(
        buttonText: getTranslated('request_contact', context) ?? 'Solicitar contacto',
        onTap: () {
          if (!Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
            RouterHelper.getLoginRoute();
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeDefault)),
            ),
            builder: (_) => RequestContactBottomSheet(productId: productId, opportunityTitle: opportunityTitle),
          );
        },
      ),
    );
  }
}
