import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/domain/models/opportunity_request_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/domain/services/opportunity_request_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

class OpportunityRequestController with ChangeNotifier {
  final OpportunityRequestServiceInterface opportunityRequestServiceInterface;
  OpportunityRequestController({required this.opportunityRequestServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  OpportunityRequestModel? opportunityRequestModel;

  Future<bool> sendContactRequest({required int productId, String? comment}) async {
    _isSubmitting = true;
    notifyListeners();

    ApiResponseModel apiResponse = await opportunityRequestServiceInterface.sendContactRequest(productId, comment);

    bool success = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      success = true;
      showCustomSnackBarWidget(apiResponse.response?.data['message'], Get.context!, snackBarType: SnackBarType.success);
    } else {
      showCustomSnackBarWidget(apiResponse.error?.toString() ?? 'Error', Get.context!, snackBarType: SnackBarType.error);
    }

    _isSubmitting = false;
    notifyListeners();
    return success;
  }

  Future<void> getMyRequests(int offset, {bool getAll = false}) async {
    _isLoading = true;
    if (offset == 1) {
      notifyListeners();
    }

    ApiResponseModel apiResponse = await opportunityRequestServiceInterface.getMyRequests(offset.toString(), getAll);

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
}
