import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class OpportunityRequestRepositoryInterface<T> extends RepositoryInterface {

  Future<dynamic> sendContactRequest(int productId, String? comment);

  Future<dynamic> getMyRequests(String offset, bool getAll);
}
