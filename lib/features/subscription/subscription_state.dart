class SubscriptionState {
  final bool isLoading;
  final bool isActive;       // Menudo Pro entitlement active
  final String? plan;        // 'monthly' | 'annual' | 'lifetime'
  final DateTime? expiresAt; // null for lifetime
  final bool willRenew;

  const SubscriptionState({
    this.isLoading = true,
    this.isActive = false,
    this.plan,
    this.expiresAt,
    this.willRenew = false,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isActive,
    String? plan,
    DateTime? expiresAt,
    bool? willRenew,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isActive: isActive ?? this.isActive,
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      willRenew: willRenew ?? this.willRenew,
    );
  }
}
