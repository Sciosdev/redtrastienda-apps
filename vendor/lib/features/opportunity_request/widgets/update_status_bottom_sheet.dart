import 'package:flutter/material.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_button_widget.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/controllers/opportunity_request_controller.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/domain/models/opportunity_request_model.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:provider/provider.dart';

class UpdateStatusBottomSheet extends StatefulWidget {
  final OpportunityRequest request;
  const UpdateStatusBottomSheet({super.key, required this.request});

  @override
  State<UpdateStatusBottomSheet> createState() => _UpdateStatusBottomSheetState();
}

class _UpdateStatusBottomSheetState extends State<UpdateStatusBottomSheet> {
  static const List<String> statuses = ['new', 'in_review', 'contacted', 'served', 'rejected'];
  late String _selectedStatus;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status ?? 'new';
    _responseController.text = widget.request.providerResponse ?? '';
  }

  @override
  void dispose() {
    _responseController.dispose();
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
          Text(getTranslated('update_status', context) ?? 'Actualizar estatus',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            children: statuses.map((s) {
              final bool selected = s == _selectedStatus;
              return ChoiceChip(
                label: Text(getTranslated('status_$s', context) ?? s),
                selected: selected,
                onSelected: (_) => setState(() => _selectedStatus = s),
              );
            }).toList(),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          TextField(
            controller: _responseController,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: getTranslated('response_optional', context) ?? 'Respuesta (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Consumer<OpportunityRequestController>(
            builder: (context, controller, child) {
              return CustomButtonWidget(
                isLoading: controller.isUpdating,
                btnTxt: getTranslated('save', context) ?? 'Guardar',
                onTap: () async {
                  bool success = await controller.updateStatus(
                    id: widget.request.id!,
                    status: _selectedStatus,
                    providerResponse: _responseController.text.trim().isEmpty ? null : _responseController.text.trim(),
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
