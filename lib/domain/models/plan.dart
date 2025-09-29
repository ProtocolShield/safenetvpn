class ActivePlanResponse {
  final bool status;
  final String message;
  final Subscription? subscription;
  final bool isOnTrial;
  final String provider;
  final bool hasFreeTrial;
  final dynamic trialInfo;

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
      trialInfo: json['trial_info'],
    );
  }
}

class Subscription {
  final int id;
  final PlanDetail plan;
  final String startsAt;
  final String endsAt;
  final String trialEndsAt;
  final String graceEndsAt;
  final String amountPaid;
  final String currency;
  final String status;
  final bool isRecurring;
  final String provider;

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
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      plan: PlanDetail.fromJson(json['plan']),
      startsAt: json['starts_at'],
      endsAt: json['ends_at'],
      trialEndsAt: json['trial_ends_at'],
      graceEndsAt: json['grace_ends_at'],
      amountPaid: json['amount_paid'],
      currency: json['currency'],
      status: json['status'],
      isRecurring: json['is_recurring'],
      provider: json['provider'],
    );
  }
}

class PlanDetail {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? price;
  final int? duration;
  final String? durationUnit;
  final String? stripePriceId;
  final int trialPeriodDays;
  final bool isBestDeal;
  final DateTime createdAt;

  PlanDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.price,
    this.duration,
    this.durationUnit,
    this.stripePriceId,
    required this.trialPeriodDays,
    required this.isBestDeal,
    required this.createdAt,
  });

  factory PlanDetail.fromJson(Map<String, dynamic> json) {
    return PlanDetail(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      price: json['price'],
      duration: json['duration'],
      durationUnit: json['duration_unit'],
      stripePriceId: json['stripe_price_id'],
      trialPeriodDays: json['trial_period_days'],
      isBestDeal: json['is_best_deal'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
