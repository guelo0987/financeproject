import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class SpaceRepository {
  const SpaceRepository(this._api);

  final ApiService _api;

  Future<List<SpaceSummary>> fetchSpaces() async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.spaces,
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((item) => SpaceSummary.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<SpaceSummary> createSpace({
    required String nombre,
    String? descripcion,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.spaces,
      body: {
        'nombre': nombre,
        if (descripcion != null && descripcion.trim().isNotEmpty)
          'descripcion': descripcion.trim(),
      },
      parser: asJsonMap,
    );
    return SpaceSummary.fromJson(response.requireData());
  }

  Future<SpaceDetail> fetchSpaceDetail(int spaceId) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.spaceById(spaceId),
      parser: asJsonMap,
    );
    return SpaceDetail.fromJson(response.requireData());
  }

  Future<List<SpaceInvitation>> fetchInvitations(int spaceId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.spaceInvitations(spaceId),
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((item) => SpaceInvitation.fromJson(asJsonMap(item)))
        .toList();
  }

  Future<SpaceInvitation> inviteMember(int spaceId, String email) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.inviteToSpace(spaceId),
      body: {'email': email},
      parser: asJsonMap,
    );
    return SpaceInvitation.fromJson(response.requireData());
  }

  Future<void> updateMemberRole(int spaceId, int userId, String rol) {
    return _api.patch<void>(
      ApiPaths.spaceMemberById(spaceId, userId),
      body: {'rol': rol},
    );
  }

  Future<void> removeMember(int spaceId, int userId) {
    return _api.delete<void>(ApiPaths.spaceMemberById(spaceId, userId));
  }

  Future<void> cancelInvitation(int spaceId, int invitationId) {
    return _api.delete<void>(
      ApiPaths.spaceInvitationById(spaceId, invitationId),
    );
  }

  Future<void> deleteSpace(int spaceId) {
    return _api.delete<void>(ApiPaths.spaceById(spaceId));
  }
}

final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  return SpaceRepository(ref.watch(apiServiceProvider));
});
