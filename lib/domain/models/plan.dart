import 'dart:convert';

class PlansModelResponse {
    bool status;
    List<PlanModel> plans;

    PlansModelResponse({
        required this.status,
        required this.plans,
    });

    factory PlansModelResponse.fromRawJson(String str) => PlansModelResponse.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory PlansModelResponse.fromJson(Map<String, dynamic> json) => PlansModelResponse(
        status: json["status"],
        plans: List<PlanModel>.from(json["plans"].map((x) => PlanModel.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "plans": List<dynamic>.from(plans.map((x) => x.toJson())),
    };
}

class PlanModel {
    int id;
    String name;
    String slug;
    String description;
    String originalPrice;
    String discountPrice;
    int invoicePeriod;
    String invoiceInterval;
    int trialPeriod;
    String trialInterval;
    dynamic paddlePriceId;
    dynamic appstoreProductId;
    bool isActive;
    bool isBestDeal;
    DateTime createdAt;

    PlanModel({
        required this.id,
        required this.name,
        required this.slug,
        required this.description,
        required this.originalPrice,
        required this.discountPrice,
        required this.invoicePeriod,
        required this.invoiceInterval,
        required this.trialPeriod,
        required this.trialInterval,
        required this.paddlePriceId,
        required this.appstoreProductId,
        required this.isActive,
        required this.isBestDeal,
        required this.createdAt,
    });

    factory PlanModel.fromRawJson(String str) => PlanModel.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        description: json["description"],
        originalPrice: json["original_price"],
        discountPrice: json["discount_price"],
        invoicePeriod: json["invoice_period"],
        invoiceInterval: json["invoice_interval"],
        trialPeriod: json["trial_period"],
        trialInterval: json["trial_interval"],
        paddlePriceId: json["paddle_price_id"],
        appstoreProductId: json["appstore_product_id"],
        isActive: json["is_active"],
        isBestDeal: json["is_best_deal"],
        createdAt: DateTime.parse(json["created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "description": description,
        "original_price": originalPrice,
        "discount_price": discountPrice,
        "invoice_period": invoicePeriod,
        "invoice_interval": invoiceInterval,
        "trial_period": trialPeriod,
        "trial_interval": trialInterval,
        "paddle_price_id": paddlePriceId,
        "appstore_product_id": appstoreProductId,
        "is_active": isActive,
        "is_best_deal": isBestDeal,
        "created_at": createdAt.toIso8601String(),
    };
}
