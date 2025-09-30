
class ActivePlanResponse {
  final bool status;
  final String message;
  final Subscription? subscription;
  final bool isOnTrial;
  final String provider;
  final bool hasFreeTrial;
  final TrialInfo? trialInfo;

  ActivePlanResponse({
    required this.status,
    required this.message,
    this.subscription,
    required this.isOnTrial,
    required this.provider,
    required this.hasFreeTrial,
    this.trialInfo,
  });

  factory ActivePlanResponse.fromJson(Map<String, dynamic> json) {
    return ActivePlanResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
      isOnTrial: json['is_on_trial'] ?? false,
      provider: json['provider'] ?? '',
      hasFreeTrial: json['has_free_trial'] ?? false,
      trialInfo: json['trial_info'] != null
          ? TrialInfo.fromJson(json['trial_info'])
          : null,
    );
  }
}

class Subscription {
  final int id;
  final Plan plan;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime trialEndsAt;
  final DateTime graceEndsAt;
  final String amountPaid;
  final String currency;
  final String status;
  final bool isRecurring;
  final String provider;
  final String? cancelledBy;
  final String? cancelledReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.plan,
    required this.startsAt,
    required this.endsAt,
    required this.trialEndsAt,
    required this.graceEndsAt,
    required this.amountPaid,
    required this.currency,
    required this.status,
    required this.isRecurring,
    required this.provider,
    this.cancelledBy,
    this.cancelledReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      plan: Plan.fromJson(json['plan']),
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      trialEndsAt: DateTime.parse(json['trial_ends_at']),
      graceEndsAt: DateTime.parse(json['grace_ends_at']),
      amountPaid: json['amount_paid'] ?? '',
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
      isRecurring: json['is_recurring'] ?? false,
      provider: json['provider'] ?? '',
      cancelledBy: json['cancelled_by'],
      cancelledReason: json['cancelled_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Plan {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String originalPrice;
  final String discountPrice;
  final int invoicePeriod;
  final String invoiceInterval;
  final int trialPeriod;
  final String trialInterval;
  final String? stripe;
  final String? appstoreProductId;
  final bool isActive;
  final bool isBestDeal;
  final DateTime createdAt;

  Plan({
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
    this.stripe,
    this.appstoreProductId,
    required this.isActive,
    required this.isBestDeal,
    required this.createdAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      originalPrice: json['original_price'] ?? '',
      discountPrice: json['discount_price'] ?? '',
      invoicePeriod: json['invoice_period'] ?? 0,
      invoiceInterval: json['invoice_interval'] ?? '',
      trialPeriod: json['trial_period'] ?? 0,
      trialInterval: json['trial_interval'] ?? '',
      stripe: json['stripe'],
      appstoreProductId: json['appstore_product_id'],
      isActive: json['is_active'] ?? false,
      isBestDeal: json['is_best_deal'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TrialInfo {
  final DateTime trialEndsAt;
  final int daysRemaining;
  final int hoursRemaining;

  TrialInfo({
    required this.trialEndsAt,
    required this.daysRemaining,
    required this.hoursRemaining,
  });

  factory TrialInfo.fromJson(Map<String, dynamic> json) {
    return TrialInfo(
      trialEndsAt: DateTime.parse(json['trial_ends_at']),
      daysRemaining: json['days_remaining'] ?? 0,
      hoursRemaining: json['hours_remaining'] ?? 0,
    );
  }
}
