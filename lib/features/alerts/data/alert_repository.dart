import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class AlertRepository {
  const AlertRepository(this._api);

  final ApiService _api;

  Future<List<AppAlert>> fetchAlerts({bool unreadOnly = false}) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.alerts,
      queryParameters: unreadOnly ? {'no_leidas': 'true'} : null,
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((item) => AppAlert.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.alertsUnreadCount,
      parser: asJsonMap,
    );
    final data = response.requireData();
    final rawCount = data['no_leidas'] ?? data['count'] ?? 0;
    return switch (rawCount) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }

  Future<AppAlert> markAsRead(int alertId) async {
    final response = await _api.patch<Map<String, dynamic>>(
      ApiPaths.markAlertRead(alertId),
      parser: asJsonMap,
    );
    return AppAlert.fromJson(response.requireData());
  }

  Future<void> markAllAsRead() {
    return _api.patch<void>(ApiPaths.markAllAlertsRead);
  }

  Future<void> acceptInvitation({
    required String token,
    required String email,
  }) {
    return _api.post<void>(
      ApiPaths.acceptInvitation(token),
      authenticated: false,
      body: {'email': email},
    );
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(ref.watch(apiServiceProvider));
});
