/// Status possíveis de um jogo, na ordem em que aparecem nas telas.
///
/// O `id` é a string salva em `Game.status` e `CustomList.filterStatus`
/// (o banco continua guardando texto); o `label` é o rótulo exibido.
enum GameStatus {
  paraJogar('para_jogar', 'Para Jogar'),
  jogando('jogando', 'Jogando'),
  jogado('jogado', 'Jogado'),
  finalizado('finalizado', 'Finalizado'),
  completo('100%', '100%');

  final String id;
  final String label;

  const GameStatus(this.id, this.label);

  /// Encontra o status pelo id salvo, ignorando maiúsculas e aceitando o
  /// formato antigo `para jogar`. Retorna `null` se o id for desconhecido.
  static GameStatus? fromId(String id) {
    final normalized = id.toLowerCase();
    if (normalized == 'para jogar') return GameStatus.paraJogar;
    for (final status in GameStatus.values) {
      if (status.id == normalized) return status;
    }
    return null;
  }

  /// Converte o id salvo em rótulo amigável; devolve o próprio id se desconhecido
  static String labelOf(String id) => fromId(id)?.label ?? id;
}
