class PlanDetail {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String price;
  final int duration;
  final String durationUnit;
  final int trialDays;
  final int isBestDeal;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.duration,
    required this.durationUnit,
    required this.trialDays,
    required this.isBestDeal,
    required this.createdAt,
    required this.updatedAt,
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
      trialDays: json['trial_days'],
      isBestDeal: json['is_best_deal'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UserPlan {
  final int id;
  final int userId;
  final int planId;
  final String amountPaid;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlanDetail plan;

  UserPlan({
    required this.id,
    required this.userId,
    required this.planId,
    required this.amountPaid,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.plan,
  });

  factory UserPlan.fromJson(Map<String, dynamic> json) {
    return UserPlan(
      id: json['id'],
      userId: json['user_id'],
      planId: json['plan_id'],
      amountPaid: json['amount_paid'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      plan: PlanDetail.fromJson(json['plan']),
    );
  }
}

class ActivePlanResponse {
  final bool status;
  final String message;
  final UserPlan plan;

  ActivePlanResponse({
    required this.status,
    required this.message,
    required this.plan,
  });

  factory ActivePlanResponse.fromJson(Map<String, dynamic> json) {
    return ActivePlanResponse(
      status: json['status'],
      message: json['message'],
      plan: UserPlan.fromJson(json['plan']),
    );
  }
}
