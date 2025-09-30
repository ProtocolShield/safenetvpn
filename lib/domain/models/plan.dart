
class PlansModelResponse {
  final bool status;
  final List<PlanModel> plans;

  PlansModelResponse({
    required this.status,
    required this.plans,
  });

  factory PlansModelResponse.fromJson(Map<String, dynamic> json) {
    return PlansModelResponse(
      status: json['status'] ?? false,
      plans: (json['plans'] as List<dynamic>?)
              ?.map((e) => PlanModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PlanModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String originalPrice;
  final String discountPrice;
  final String currency;
  final String? stripePriceId;
  final String? appstoreProductId;
  final bool isActive;
  final bool isBestDeal;
  final int trialPeriod;
  final String trialInterval;
  final int invoicePeriod;
  final String invoiceInterval;
  final int gracePeriod;
  final String graceInterval;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deletedAt;

  PlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.originalPrice,
    required this.discountPrice,
    required this.currency,
    this.stripePriceId,
    this.appstoreProductId,
    required this.isActive,
    required this.isBestDeal,
    required this.trialPeriod,
    required this.trialInterval,
    required this.invoicePeriod,
    required this.invoiceInterval,
    required this.gracePeriod,
    required this.graceInterval,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      originalPrice: json['original_price'] ?? '',
      discountPrice: json['discount_price'] ?? '',
      currency: json['currency'] ?? '',
      stripePriceId: json['stripe_price_id'],
      appstoreProductId: json['appstore_product_id'],
      isActive: json['is_active'] ?? false,
      isBestDeal: json['is_best_deal'] ?? false,
      trialPeriod: json['trial_period'] ?? 0,
      trialInterval: json['trial_interval'] ?? '',
      invoicePeriod: json['invoice_period'] ?? 0,
      invoiceInterval: json['invoice_interval'] ?? '',
      gracePeriod: json['grace_period'] ?? 0,
      graceInterval: json['grace_interval'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'],
    );
  }
}