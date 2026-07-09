import 'package:flutter/material.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_image_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/controllers/opportunity_request_controller.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/domain/models/opportunity_request_model.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/widgets/update_status_bottom_sheet.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ReceivedRequestsScreen extends StatefulWidget {
  const ReceivedRequestsScreen({super.key});

  @override
  State<ReceivedRequestsScreen> createState() => _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OpportunityRequestController>(context, listen: false).getReceivedRequests(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: getTranslated('received_requests', context) ?? 'Solicitudes recibidas'),
      body: Consumer<OpportunityRequestController>(
        builder: (context, controller, child) {
          final List<OpportunityRequest> requests = controller.opportunityRequestModel?.data ?? [];

          return Column(
            children: [
              _StatusFilterBar(controller: controller),
              Expanded(
                child: (controller.isLoading && requests.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : requests.isEmpty
                        ? NoDataScreen(title: getTranslated('no_request_found', context) ?? 'Sin solicitudes')
                        : RefreshIndicator(
                            onRefresh: () => controller.getReceivedRequests(1),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              itemCount: requests.length,
                              itemBuilder: (context, index) => _RequestCard(request: requests[index]),
                            ),
                          ),
              ),
            ],
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
    final OpportunityCustomer? customer = request.customer;
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: Theme.of(context).hintColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                child: CustomImageWidget(image: request.product?.thumbnailFullUrl?.path ?? '', height: 60, width: 60),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.product?.name ?? '',
                        style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    _StatusBadge(status: request.status),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          if (customer != null) ...[
            _InfoRow(icon: Icons.person, text: customer.fullName),
            if (customer.phone != null && customer.phone!.isNotEmpty) _InfoRow(icon: Icons.phone, text: customer.phone!),
            if (customer.email != null && customer.email!.isNotEmpty) _InfoRow(icon: Icons.email, text: customer.email!),
          ],
          if (request.comment != null && request.comment!.isNotEmpty)
            _InfoRow(icon: Icons.comment, text: request.comment!),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).cardColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeDefault)),
                  ),
                  builder: (_) => UpdateStatusBottomSheet(request: request),
                );
              },
              icon: const Icon(Icons.edit, size: 18),
              label: Text(getTranslated('update_status', context) ?? 'Actualizar estatus'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final OpportunityRequestController controller;
  const _StatusFilterBar({required this.controller});

  static const List<String?> filters = [null, 'new', 'in_review', 'contacted', 'served', 'rejected'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        itemBuilder: (context, index) {
          final String? status = filters[index];
          final bool selected = controller.statusFilter == status;
          final String label = status == null
              ? (getTranslated('status_all', context) ?? 'Todas')
              : (getTranslated('status_$status', context) ?? status);
          return Center(
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => controller.setStatusFilter(status),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).hintColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
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
        style: TextStyle(color: color, fontSize: Dimensions.fontSizeSmall),
      ),
    );
  }
}
