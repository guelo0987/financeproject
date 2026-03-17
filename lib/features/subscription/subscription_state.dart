class SubscriptionState {
  final bool isLoading;
  final bool isActive;
  final String? estado; // prueba | activa | cancelada | vencida
  final String? plan; // monthly | annual | lifetime
  final DateTime? expiresAt; // trial_fin or periodo_fin
  final bool willRenew;
  final bool hasVerificationIssue;

  const SubscriptionState({
    this.isLoading = true,
    this.isActive = false,
    this.estado,
    this.plan,
    this.expiresAt,
    this.willRenew = false,
    this.hasVerificationIssue = false,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isActive,
    String? estado,
    String? plan,
    DateTime? expiresAt,
    bool? willRenew,
    bool? hasVerificationIssue,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isActive: isActive ?? this.isActive,
      estado: estado ?? this.estado,
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      willRenew: willRenew ?? this.willRenew,
      hasVerificationIssue: hasVerificationIssue ?? this.hasVerificationIssue,
    );
  }
}
