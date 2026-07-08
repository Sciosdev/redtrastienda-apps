import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/controllers/opportunity_request_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/domain/models/opportunity_request_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class MyOpportunityRequestsScreen extends StatefulWidget {
  const MyOpportunityRequestsScreen({super.key});

  @override
  State<MyOpportunityRequestsScreen> createState() => _MyOpportunityRequestsScreenState();
}

class _MyOpportunityRequestsScreenState extends State<MyOpportunityRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OpportunityRequestController>(context, listen: false).getMyRequests(1, getAll: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('my_requests', context) ?? 'Mis solicitudes'),
      body: Consumer<OpportunityRequestController>(
        builder: (context, controller, child) {
          final List<OpportunityRequest> requests = controller.opportunityRequestModel?.data ?? [];

          if (controller.isLoading && requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (requests.isEmpty) {
            return NoInternetOrDataScreenWidget(
              isNoInternet: false,
              message: getTranslated('no_request_found', context) ?? 'Aún no has solicitado contacto',
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getMyRequests(1, getAll: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              itemCount: requests.length,
              itemBuilder: (context, index) => _RequestCard(request: requests[index]),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final OpportunityRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: Theme.of(context).hintColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            child: CustomImageWidget(
              image: request.product?.thumbnailFullUrl?.path ?? '',
              height: 70, width: 70,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.product?.name ?? '',
                  style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                _StatusBadge(status: request.status),
                if (request.comment != null && request.comment!.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(request.comment!, style: textRegular.copyWith(color: Theme.of(context).hintColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (request.providerResponse != null && request.providerResponse!.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text('${getTranslated('provider_response', context) ?? 'Respuesta'}: ${request.providerResponse!}',
                      style: textRegular.copyWith(color: Theme.of(context).primaryColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});

  Color _color(BuildContext context) {
    switch (status) {
      case 'contacted':
      case 'served':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_review':
        return Colors.orange;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        getTranslated('status_${status ?? 'new'}', context) ?? (status ?? 'new'),
        style: textRegular.copyWith(color: color, fontSize: Dimensions.fontSizeSmall),
      ),
    );
  }
}
