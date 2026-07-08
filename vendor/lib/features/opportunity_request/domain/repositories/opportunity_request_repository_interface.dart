import 'package:sixvalley_vendor_app/interface/repository_interface.dart';

abstract class OpportunityRequestRepositoryInterface<T> extends RepositoryInterface {

  Future<dynamic> getReceivedRequests(String offset, {String? status});

  Future<dynamic> updateStatus(int id, String status, String? providerResponse);
}
