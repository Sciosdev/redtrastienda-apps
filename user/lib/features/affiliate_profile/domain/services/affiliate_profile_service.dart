import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/repositories/affiliate_profile_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/domain/services/affiliate_profile_service_interface.dart';

class AffiliateProfileService implements AffiliateProfileServiceInterface {
  final AffiliateProfileRepositoryInterface affiliateProfileRepositoryInterface;
  AffiliateProfileService({required this.affiliateProfileRepositoryInterface});

  @override
  Future getAffiliateProfile() async {
    return await affiliateProfileRepositoryInterface.getAffiliateProfile();
  }
}
