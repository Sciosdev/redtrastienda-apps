abstract class OpportunityRequestServiceInterface {

  Future<dynamic> getReceivedRequests(String offset, {String? status});

  Future<dynamic> updateStatus(int id, String status, String? providerResponse);
}
