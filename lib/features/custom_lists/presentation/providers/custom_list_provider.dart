import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_list.dart';
import '../../../games/data/models/game.dart';
import '../../../games/presentation/providers/game_list_provider.dart';
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
  /// Lança exceção se a gravação falhar, para a tela avisar o usuário
  Future<void> saveCustomList(CustomList customList) async {
    final repository = ref.read(customListRepositoryProvider);

    // A escrita fica fora do guard: se falhar, a exceção chega à tela e as listas atuais são preservadas
    await repository.saveCustomList(customList);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomLists());
  }

  /// Exclui uma lista de filtro
  /// Lança exceção se a exclusão falhar, para a tela avisar o usuário
  Future<void> deleteCustomList(int id) async {
    final repository = ref.read(customListRepositoryProvider);

    // A exclusão fica fora do guard: se falhar, a exceção chega à tela e as listas atuais são preservadas
    await repository.deleteCustomList(id);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomLists());
  }
}

/// Provider que expõe todas as listas salvas pelo usuário
final customListProvider =
    AsyncNotifierProvider<CustomListNotifier, List<CustomList>>(() {
      return CustomListNotifier();
    });

/// Provider de Família (Family): Busca os jogos filtrados de UMA lista específica pelo id
/// Usado no card (contagem) e na tela de detalhe da lista personalizada
final customListGamesProvider = FutureProvider.family<List<Game>, int>((
  ref,
  listId,
) async {
  // Observa a lista de jogos para reavaliar sempre que um jogo for criado, editado ou excluído
  ref.watch(gameListProvider);

  // Observa as listas salvas para refletir edições nos filtros da própria lista
  final customLists = await ref.watch(customListProvider.future);
  final customList = customLists.where((list) => list.id == listId).firstOrNull;

  // Lista inexistente (ex.: removida durante a navegação) não possui jogos
  if (customList == null) return [];

  final repository = ref.read(gameRepositoryProvider);

  return await repository.getGamesByCustomFilter(
    developer: customList.filterDeveloper,
    platform: customList.filterPlatform,
    genre: customList.filterGenre,
    status: customList.filterStatus,
  );
});

/// Valores distintos já cadastrados nos jogos, usados como sugestões no formulário de lista
class GameFilterOptions {
  final List<String> developers;
  final List<String> platforms;
  final List<String> genres;

  const GameFilterOptions({
    required this.developers,
    required this.platforms,
    required this.genres,
  });
}

/// Provider que extrai desenvolvedoras, plataformas e gêneros distintos dos jogos salvos
final gameFilterOptionsProvider = FutureProvider<GameFilterOptions>((
  ref,
) async {
  // Recalcula as sugestões sempre que a biblioteca de jogos mudar
  ref.watch(gameListProvider);

  final repository = ref.read(gameRepositoryProvider);
  final games = await repository.getAllGames();

  return GameFilterOptions(
    developers: _distinctSorted(games.map((game) => game.developer)),
    platforms: _distinctSorted(games.map((game) => game.platform)),
    genres: _distinctSorted(games.map((game) => game.genre)),
  );
});

/// Remove nulos, vazios e duplicados, ordenando alfabeticamente sem diferenciar maiúsculas
List<String> _distinctSorted(Iterable<String?> values) {
  final distinct = values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
  distinct.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return distinct;
}
