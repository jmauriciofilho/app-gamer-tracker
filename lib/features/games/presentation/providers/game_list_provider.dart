import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game.dart';
import 'game_repository_provider.dart';

/// Notifier responsável por gerenciar a lista de jogos exibida na UI
class GameListNotifier extends AsyncNotifier<List<Game>> {
  // Guarda os filtros ativos no momento
  String? _selectedStatus;
  String _searchQuery = '';

  @override
  FutureOr<List<Game>> build() async {
    // Ao inicializar o provider, carrega os jogos do repositório
    return _fetchGames();
  }

  /// Método privado para buscar jogos baseando-se nos filtros ativos
  Future<List<Game>> _fetchGames() async {
    final repository = ref.read(gameRepositoryProvider);

    // Se houver busca por texto, prioriza a busca por título
    if (_searchQuery.trim().isNotEmpty) {
      return await repository.searchGamesByTitle(_searchQuery);
    }

    // Se houver filtro de status selecionado (ex: 'jogando', '100%')
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      return await repository.getGamesByStatus(_selectedStatus!);
    }

    // Caso contrário, retorna todos os jogos
    return await repository.getAllGames();
  }

  // ==========================================
  // AÇÕES DE FILTRO E BUSCA
  // ==========================================

  /// Filtra os jogos pelo status ('para_jogar', 'jogando', 'jogado', 'finalizado', '100%')
  Future<void> filterByStatus(String? status) async {
    _selectedStatus = status;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGames());
  }

  /// Pesquisa jogos pelo nome
  Future<void> search(String query) async {
    _searchQuery = query;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGames());
  }

  // ==========================================
  // AÇÕES CRUD (Escrita)
  // ==========================================

  /// Adiciona ou atualiza um jogo e recarrega a lista reativamente
  /// Lança exceção se a gravação falhar, para a tela avisar o usuário
  Future<void> saveGame(Game game) async {
    final repository = ref.read(gameRepositoryProvider);

    // A escrita fica fora do guard: se falhar, a exceção chega à tela e a lista atual é preservada
    await repository.saveGame(game);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGames());
  }

  /// Exclui um jogo pelo ID e atualiza a UI
  /// Lança exceção se a exclusão falhar, para a tela avisar o usuário
  Future<void> deleteGame(int id) async {
    final repository = ref.read(gameRepositoryProvider);

    // A exclusão fica fora do guard: se falhar, a exceção chega à tela e a lista atual é preservada
    await repository.deleteGame(id);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGames());
  }
}

/// Provider global acessível pelas telas para escutar a lista de jogos
final gameListProvider = AsyncNotifierProvider<GameListNotifier, List<Game>>(
  () {
    return GameListNotifier();
  },
);
