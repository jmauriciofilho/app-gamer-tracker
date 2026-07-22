import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_list.dart';
import '../../../games/data/models/game.dart';
import '../../../games/presentation/providers/game_repository_provider.dart';

/// Notifier que gerencia as definições de Listas Personalizadas
class CustomListNotifier extends AsyncNotifier<List<CustomList>> {
  @override
  FutureOr<List<CustomList>> build() async {
    return _fetchCustomLists();
  }

  Future<List<CustomList>> _fetchCustomLists() async {
    final repository = ref.read(customListRepositoryProvider);
    return await repository.getAllCustomLists();
  }

  /// Salva uma nova lista de filtro personalizado
  Future<void> saveCustomList(CustomList customList) async {
    final repository = ref.read(customListRepositoryProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await repository.saveCustomList(customList);
      return _fetchCustomLists();
    });
  }

  /// Exclui uma lista de filtro
  Future<void> deleteCustomList(int id) async {
    final repository = ref.read(customListRepositoryProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await repository.deleteCustomList(id);
      return _fetchCustomLists();
    });
  }
}

/// Provider que expõe todas as listas salvas pelo usuário
final customListProvider =
    AsyncNotifierProvider<CustomListNotifier, List<CustomList>>(() {
      return CustomListNotifier();
    });

/// Provider de Família (Family): Busca os jogos filtrados de UMA lista específica
/// Usado quando o usuário clica em um card de lista personalizada para ver os jogos dela
final customListGamesProvider = FutureProvider.family<List<Game>, CustomList>((
  ref,
  customList,
) async {
  final repository = ref.read(gameRepositoryProvider);

  return await repository.getGamesByCustomFilter(
    developer: customList.filterDeveloper,
    platform: customList.filterPlatform,
    genre: customList.filterGenre,
    status: customList.filterStatus,
  );
});
