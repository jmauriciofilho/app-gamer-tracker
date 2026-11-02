import 'models/game_lookup_result.dart';

/// Falha ao consultar a fonte externa (sem rede, timeout, resposta inesperada)
class GameLookupException implements Exception {
  const GameLookupException(this.reason);

  /// Detalhe técnico para depuração (não é exibido ao usuário)
  final String reason;

  @override
  String toString() => 'GameLookupException: $reason';
}

/// Busca dados de jogos numa fonte externa (isolada para os testes usarem um fake)
abstract class GameLookupService {
  /// Busca jogos pelo nome. Termo vazio devolve lista vazia sem consultar a rede.
  /// Lança [GameLookupException] em caso de falha.
  Future<List<GameLookupResult>> search(String query);

  /// Devolve a URL da capa do jogo, ou `null` se não houver capa disponível.
  /// Nunca lança exceção: falha na consulta equivale a "sem capa".
  Future<String?> findCoverUrl(GameLookupResult result);
}
