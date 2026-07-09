import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class AffiliateProfileRepositoryInterface<T> extends RepositoryInterface {

  Future<dynamic> getAffiliateProfile();
}
