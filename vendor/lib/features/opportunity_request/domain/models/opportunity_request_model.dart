import 'package:sixvalley_vendor_app/features/product/domain/models/product_model.dart';

class OpportunityRequestModel {
  List<OpportunityRequest>? data;
  int? totalSize;
  String? limit;
  String? offset;

  OpportunityRequestModel({this.data, this.totalSize, this.limit, this.offset});

  OpportunityRequestModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <OpportunityRequest>[];
      json['data'].forEach((v) {
        data!.add(OpportunityRequest.fromJson(v));
      });
    }
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
  }
}

class OpportunityRequest {
  int? id;
  int? productId;
  int? sellerId;
  int? customerId;
  String? comment;
  String? status;
  String? providerResponse;
  String? createdAt;
  Product? product;
  OpportunityCustomer? customer;

  OpportunityRequest({
    this.id,
    this.productId,
    this.sellerId,
    this.customerId,
    this.comment,
    this.status,
    this.providerResponse,
    this.createdAt,
    this.product,
    this.customer,
  });

  OpportunityRequest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    sellerId = json['seller_id'];
    customerId = json['customer_id'];
    comment = json['comment'];
    status = json['status'];
    providerResponse = json['provider_response'];
    createdAt = json['created_at'];
    product = json['product'] != null ? Product.fromJson(json['product']) : null;
    customer = json['customer'] != null ? OpportunityCustomer.fromJson(json['customer']) : null;
  }
}

class OpportunityCustomer {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;

  OpportunityCustomer({this.id, this.fName, this.lName, this.phone, this.email});

  OpportunityCustomer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
  }

  String get fullName => '${fName ?? ''} ${lName ?? ''}'.trim();
}
