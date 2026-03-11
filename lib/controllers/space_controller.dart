import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/models.dart';
import '../services/space_service.dart';

class SpaceController extends AsyncNotifier<List<SpaceSummary>> {
  @override
  Future<List<SpaceSummary>> build() async {
    return ref.read(spaceServiceProvider).fetchSpaces();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(spaceServiceProvider).fetchSpaces(),
    );
  }

  Future<SpaceSummary> createSpace({
    required String nombre,
    String? descripcion,
  }) async {
    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(spaceServiceProvider)
          .createSpace(nombre: nombre, descripcion: descripcion);
      final spaces = await ref.read(spaceServiceProvider).fetchSpaces();
      state = AsyncValue.data(spaces);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSpace(int spaceId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(spaceServiceProvider).deleteSpace(spaceId);
      final spaces = await ref.read(spaceServiceProvider).fetchSpaces();
      state = AsyncValue.data(spaces);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<SpaceDetail> loadDetail(int spaceId) {
    return ref.read(spaceServiceProvider).fetchSpaceDetail(spaceId);
  }

  Future<void> inviteMember(int spaceId, String email) {
    return ref.read(spaceServiceProvider).inviteMember(spaceId, email);
  }

  Future<void> updateMemberRole(int spaceId, int userId, String rol) {
    return ref.read(spaceServiceProvider).updateMemberRole(spaceId, userId, rol);
  }

  Future<void> removeMember(int spaceId, int userId) {
    return ref.read(spaceServiceProvider).removeMember(spaceId, userId);
  }

  Future<void> cancelInvitation(int spaceId, int invitationId) {
    return ref
        .read(spaceServiceProvider)
        .cancelInvitation(spaceId, invitationId);
  }
}

final spaceControllerProvider =
    AsyncNotifierProvider<SpaceController, List<SpaceSummary>>(
      SpaceController.new,
    );
