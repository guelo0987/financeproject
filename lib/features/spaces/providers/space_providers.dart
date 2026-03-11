import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/space_controller.dart' as space_controller;
import '../../../model/models.dart';

final spaceNotifierProvider = space_controller.spaceControllerProvider;
final spaceControllerProvider = space_controller.spaceControllerProvider;

final effectiveSpacesProvider = Provider<List<SpaceSummary>>((ref) {
  final spaces = ref.watch(spaceNotifierProvider).valueOrNull;
  return spaces ?? const [];
});
