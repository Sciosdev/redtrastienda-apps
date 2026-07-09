import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/models/affiliate_profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/repositories/affiliate_profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/services/affiliate_profile_service_interface.dart';

class AffiliateProfileController with ChangeNotifier {
  final AffiliateProfileServiceInterface affiliateProfileServiceInterface;
  AffiliateProfileController({required this.affiliateProfileServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // true cuando el backend responde 404: el usuario aún no tiene perfil.
  bool _hasNoProfile = false;
  bool get hasNoProfile => _hasNoProfile;

  // Mensaje de error genérico (distinto del estado "sin perfil").
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AffiliateProfileModel? _profile;
  AffiliateProfileModel? get profile => _profile;

  Future<void> getAffiliateProfile() async {
    _isLoading = true;
    _hasNoProfile = false;
    _errorMessage = null;
    notifyListeners();

    ApiResponseModel apiResponse = await affiliateProfileServiceInterface.getAffiliateProfile();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _profile = AffiliateProfileModel.fromJson(apiResponse.response!.data);
    } else if (apiResponse.error?.toString() == AffiliateProfileRepository.noProfileError) {
      _profile = null;
      _hasNoProfile = true;
    } else {
      _profile = null;
      _errorMessage = apiResponse.error?.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
