import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_stats.dart';
import '../../../games/presentation/providers/game_list_provider.dart';
import '../../../games/presentation/providers/game_repository_provider.dart';

/// Estatísticas da biblioteca inteira (ignora a busca e o filtro de status da Biblioteca)
final gameStatsProvider = FutureProvider<GameStats>((ref) async {
  // Recalcula sempre que a biblioteca de jogos mudar (cadastro, edição, exclusão, backup)
  ref.watch(gameListProvider);

  final repository = ref.read(gameRepositoryProvider);
  final games = await repository.getAllGames();
  return GameStats.fromGames(games);
});
