import '../../../games/data/models/game.dart';
import '../../../games/data/models/game_status.dart';

/// Uma linha de estatística: rótulo exibido e quantidade de jogos
class StatEntry {
  const StatEntry(this.label, this.count);

  final String label;
  final int count;
}

/// Números da biblioteca exibidos na aba Estatísticas (cálculo puro, sem banco nem UI)
class GameStats {
  const GameStats({
    required this.total,
    required this.finished,
    required this.averageRating,
    required this.byStatus,
    required this.finishedByYear,
    required this.topPlatforms,
    required this.topGenres,
  });

  /// Quantos itens entram em cada ranking (plataformas e gêneros)
  static const int topLimit = 5;

  /// Status que contam como "terminado"
  static const Set<GameStatus> finishedStatuses = {
    GameStatus.finalizado,
    GameStatus.completo,
  };

  final int total;

  /// Jogos com status Finalizado ou 100%
  final int finished;

  /// Média das notas maiores que 0 (0 = sem nota); `null` se nenhum jogo tem nota
  final double? averageRating;

  /// Um item por status, na ordem do enum (com zeros), e "Outros" se houver ids desconhecidos
  final List<StatEntry> byStatus;

  /// Jogos por ano da data de término, do mais recente ao mais antigo
  final List<StatEntry> finishedByYear;

  final List<StatEntry> topPlatforms;
  final List<StatEntry> topGenres;

  /// Calcula as estatísticas de [games]
  factory GameStats.fromGames(List<Game> games) {
    // Status (ids desconhecidos vão para "Outros")
    final statusCounts = {for (final status in GameStatus.values) status: 0};
    var unknownStatus = 0;
    for (final game in games) {
      final status = GameStatus.fromId(game.status);
      if (status == null) {
        unknownStatus++;
      } else {
        statusCounts[status] = statusCounts[status]! + 1;
      }
    }

    // Nota média (0 é "sem nota", o padrão do modelo)
    final ratings = games
        .map((game) => game.rating)
        .where((rating) => rating > 0);

    // Terminados por ano de término
    final yearCounts = <int, int>{};
    for (final game in games) {
      final year = game.endDate?.year;
      if (year != null) yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }
    final years = yearCounts.keys.toList()..sort((a, b) => b.compareTo(a));

    return GameStats(
      total: games.length,
      finished: [
        for (final status in finishedStatuses) statusCounts[status]!,
      ].fold(0, (sum, count) => sum + count),
      averageRating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      byStatus: [
        for (final status in GameStatus.values)
          StatEntry(status.label, statusCounts[status]!),
        if (unknownStatus > 0) StatEntry('Outros', unknownStatus),
      ],
      finishedByYear: [
        for (final year in years) StatEntry(year.toString(), yearCounts[year]!),
      ],
      topPlatforms: _top(games.map((game) => game.platform)),
      topGenres: _top(games.map((game) => game.genre)),
    );
  }

  /// Ranking dos valores mais frequentes: agrupa sem diferenciar maiúsculas
  /// (exibindo a primeira grafia vista), ignora vazios e desempata por nome A–Z
  static List<StatEntry> _top(Iterable<String?> values) {
    final labels = <String, String>{}; // chave normalizada → primeira grafia
    final counts = <String, int>{};
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      labels.putIfAbsent(key, () => trimmed);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final keys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return [
      for (final key in keys.take(topLimit))
        StatEntry(labels[key]!, counts[key]!),
    ];
  }
}
