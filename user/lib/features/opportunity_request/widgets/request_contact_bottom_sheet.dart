import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/controllers/opportunity_request_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class RequestContactBottomSheet extends StatefulWidget {
  final int productId;
  final String? opportunityTitle;
  const RequestContactBottomSheet({super.key, required this.productId, this.opportunityTitle});

  @override
  State<RequestContactBottomSheet> createState() => _RequestContactBottomSheetState();
}

class _RequestContactBottomSheetState extends State<RequestContactBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        top: Dimensions.paddingSizeDefault,
        bottom: MediaQuery.of(context).viewInsets.bottom + Dimensions.paddingSizeDefault,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(color: Theme.of(context).hintColor.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text(getTranslated('request_contact', context) ?? 'Solicitar contacto', style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (widget.opportunityTitle != null)
            Text(widget.opportunityTitle!, style: textRegular.copyWith(color: Theme.of(context).hintColor), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: getTranslated('add_a_comment_optional', context) ?? 'Comentario (opcional)',
              hintStyle: textRegular.copyWith(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Consumer<OpportunityRequestController>(
            builder: (context, controller, child) {
              return CustomButton(
                isLoading: controller.isSubmitting,
                buttonText: getTranslated('send_request', context) ?? 'Enviar solicitud',
                onTap: () async {
                  bool success = await controller.sendContactRequest(
                    productId: widget.productId,
                    comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
                  );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
