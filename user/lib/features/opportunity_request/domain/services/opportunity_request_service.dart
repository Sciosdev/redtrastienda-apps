import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/domain/repositories/opportunity_request_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/opportunity_request/domain/services/opportunity_request_service_interface.dart';

class OpportunityRequestService implements OpportunityRequestServiceInterface {
  final OpportunityRequestRepositoryInterface opportunityRequestRepositoryInterface;
  OpportunityRequestService({required this.opportunityRequestRepositoryInterface});

  @override
  Future sendContactRequest(int productId, String? comment) async {
    return await opportunityRequestRepositoryInterface.sendContactRequest(productId, comment);
  }

  @override
  Future getMyRequests(String offset, bool getAll) async {
    return await opportunityRequestRepositoryInterface.getMyRequests(offset, getAll);
  }
}
