import 'package:sixvalley_vendor_app/features/opportunity_request/domain/repositories/opportunity_request_repository_interface.dart';
import 'package:sixvalley_vendor_app/features/opportunity_request/domain/services/opportunity_request_service_interface.dart';

class OpportunityRequestService implements OpportunityRequestServiceInterface {
  final OpportunityRequestRepositoryInterface opportunityRequestRepositoryInterface;
  OpportunityRequestService({required this.opportunityRequestRepositoryInterface});

  @override
  Future getReceivedRequests(String offset, {String? status}) async {
    return await opportunityRequestRepositoryInterface.getReceivedRequests(offset, status: status);
  }

  @override
  Future updateStatus(int id, String status, String? providerResponse) async {
    return await opportunityRequestRepositoryInterface.updateStatus(id, status, providerResponse);
  }
}
