import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/alerts/data/alert_repository.dart';
import '../model/models.dart';

class AlertService {
  const AlertService(this._repository);

  final AlertRepository _repository;

  Future<List<AppAlert>> fetchAlerts({bool unreadOnly = false}) {
    return _repository.fetchAlerts(unreadOnly: unreadOnly);
  }

  Future<int> fetchUnreadCount() {
    return _repository.fetchUnreadCount();
  }

  Future<AppAlert> markAsRead(int alertId) {
    return _repository.markAsRead(alertId);
  }

  Future<void> markAllAsRead() {
    return _repository.markAllAsRead();
  }

  Future<void> acceptInvitation({
    required String token,
    required String email,
  }) {
    return _repository.acceptInvitation(token: token, email: email);
  }
}

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService(ref.watch(alertRepositoryProvider));
});
