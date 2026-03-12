import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/spaces/data/space_repository.dart';
import '../model/models.dart';

class SpaceService {
  const SpaceService(this._repository);

  final SpaceRepository _repository;

  Future<List<SpaceSummary>> fetchSpaces() {
    return _repository.fetchSpaces();
  }

  Future<SpaceDetail> fetchSpaceDetail(int spaceId) async {
    final detail = await _repository.fetchSpaceDetail(spaceId);
    try {
      final invitations = await _repository.fetchInvitations(spaceId);
      return SpaceDetail(
        id: detail.id,
        nombre: detail.nombre,
        descripcion: detail.descripcion,
        creadoPor: detail.creadoPor,
        creadoEn: detail.creadoEn,
        actualizadoEn: detail.actualizadoEn,
        miembros: detail.miembros,
        invitaciones: invitations,
      );
    } catch (_) {
      return detail;
    }
  }

  Future<void> updateMemberRole(int spaceId, int userId, String rol) {
    return _repository.updateMemberRole(spaceId, userId, rol);
  }

  Future<void> removeMember(int spaceId, int userId) {
    return _repository.removeMember(spaceId, userId);
  }

  Future<void> cancelInvitation(int spaceId, int invitationId) {
    return _repository.cancelInvitation(spaceId, invitationId);
  }

  Future<void> deleteSpace(int spaceId) {
    return _repository.deleteSpace(spaceId);
  }
}

final spaceServiceProvider = Provider<SpaceService>((ref) {
  return SpaceService(ref.watch(spaceRepositoryProvider));
});
