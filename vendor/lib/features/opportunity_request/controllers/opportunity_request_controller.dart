import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/domain/models/opportunity_request_model.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/domain/services/opportunity_request_service_interface.dart';
import 'package:sixvalley_vendor_app/main.dart';

class OpportunityRequestController with ChangeNotifier {
  final OpportunityRequestServiceInterface opportunityRequestServiceInterface;
  OpportunityRequestController({required this.opportunityRequestServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  String? _statusFilter;
  String? get statusFilter => _statusFilter;

  OpportunityRequestModel? opportunityRequestModel;

  void setStatusFilter(String? status) {
    _statusFilter = status;
    getReceivedRequests(1);
  }

  Future<void> getReceivedRequests(int offset) async {
    _isLoading = true;
    if (offset == 1) {
      opportunityRequestModel = null;
      notifyListeners();
    }

    ApiResponse apiResponse = await opportunityRequestServiceInterface.getReceivedRequests(offset.toString(), status: _statusFilter);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if (offset == 1) {
        opportunityRequestModel = OpportunityRequestModel.fromJson(apiResponse.response?.data);
      } else {
        opportunityRequestModel!.data!.addAll(OpportunityRequestModel.fromJson(apiResponse.response?.data).data!);
        opportunityRequestModel!.offset = OpportunityRequestModel.fromJson(apiResponse.response?.data).offset;
        opportunityRequestModel!.totalSize = OpportunityRequestModel.fromJson(apiResponse.response?.data).totalSize;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStatus({required int id, required String status, String? providerResponse}) async {
    _isUpdating = true;
    notifyListeners();

    ApiResponse apiResponse = await opportunityRequestServiceInterface.updateStatus(id, status, providerResponse);

    bool success = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      success = true;
      final OpportunityRequest? item = opportunityRequestModel?.data?.firstWhere((e) => e.id == id, orElse: () => OpportunityRequest());
      if (item != null && item.id != null) {
        item.status = status;
        item.providerResponse = providerResponse;
      }
      showCustomSnackBarWidget(apiResponse.response?.data['message'] ?? 'Updated', Get.context!, isError: false);
    } else {
      showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, isError: true);
    }

    _isUpdating = false;
    notifyListeners();
    return success;
  }
}
