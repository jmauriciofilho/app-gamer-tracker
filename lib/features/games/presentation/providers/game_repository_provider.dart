import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/game_repository.dart';
import '../../../custom_lists/data/repositories/custom_list_repository.dart';

/// Provider que expõe a instância do GameRepository
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

/// Provider que expõe a instância do CustomListRepository
final customListRepositoryProvider = Provider<CustomListRepository>((ref) {
  return CustomListRepository();
});
