abstract class OpportunityRequestServiceInterface {

  Future<dynamic> sendContactRequest(int productId, String? comment);

  Future<dynamic> getMyRequests(String offset, bool getAll);
}
