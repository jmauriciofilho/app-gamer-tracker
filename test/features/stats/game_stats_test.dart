import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/stats/data/models/game_stats.dart';

Game _game({
  String status = 'jogando',
  double rating = 0,
  String? platform,
  String? genre,
  DateTime? endDate,
}) => Game()
  ..title = 'Jogo'
  ..status = status
  ..rating = rating
  ..platform = platform
  ..genre = genre
  ..endDate = endDate;

/// Jogos do AC1/AC2: um em cada status principal, com notas variadas
List<Game> _mixedGames() => [
  _game(status: 'jogando'),
  _game(status: 'finalizado', rating: 4),
  _game(status: '100%', rating: 5),
  _game(status: 'jogado', rating: 3),
];

List<(String, int)> _pairs(List<StatEntry> entries) =>
    entries.map((entry) => (entry.label, entry.count)).toList();

void main() {
  group('GameStats.fromGames', () {
    test('AC1: totais e média ignorando nota 0', () {
      // Act
      final stats = GameStats.fromGames(_mixedGames());

      // Assert
      expect(stats.total, 4);
      expect(stats.finished, 2);
      expect(stats.averageRating, 4.0);
    });

    test('AC1: sem notas e lista vazia', () {
      expect(GameStats.fromGames([_game(), _game()]).averageRating, isNull);

      final empty = GameStats.fromGames([]);
      expect(empty.total, 0);
      expect(empty.finished, 0);
      expect(empty.averageRating, isNull);
    });

    test('AC2: contagem por status na ordem do enum, com zeros', () {
      // Act
      final stats = GameStats.fromGames(_mixedGames());

      // Assert
      expect(_pairs(stats.byStatus), [
        ('Para Jogar', 0),
        ('Jogando', 1),
        ('Jogado', 1),
        ('Finalizado', 1),
        ('100%', 1),
      ]);
    });

    test('AC2: status desconhecido soma em "Outros" no fim', () {
      // Act
      final stats = GameStats.fromGames([
        ..._mixedGames(),
        _game(status: 'abandonado'),
      ]);

      // Assert
      expect(stats.byStatus.last.label, 'Outros');
      expect(stats.byStatus.last.count, 1);
    });

    test('AC3: terminados por ano, do mais recente ao mais antigo', () {
      // Act
      final stats = GameStats.fromGames([
        _game(endDate: DateTime(2024, 5, 1)),
        _game(endDate: DateTime(2026, 1, 1)),
        _game(endDate: DateTime(2026, 12, 31)),
        _game(),
      ]);

      // Assert
      expect(_pairs(stats.finishedByYear), [('2026', 2), ('2024', 1)]);
    });

    test('AC4: top 5 plataformas agrupa grafias e desempata por nome', () {
      // Arrange
      final platforms = [
        'PS1',
        'ps1 ',
        'PC',
        'Switch',
        'Switch',
        'Switch',
        '',
        null,
        'N64',
        'GBA',
        'Wii',
      ];

      // Act
      final stats = GameStats.fromGames([
        for (final platform in platforms) _game(platform: platform),
      ]);

      // Assert
      expect(_pairs(stats.topPlatforms), [
        ('Switch', 3),
        ('PS1', 2),
        ('GBA', 1),
        ('N64', 1),
        ('PC', 1),
      ]);
    });

    test('AC4: top gêneros usa a mesma regra', () {
      // Act
      final stats = GameStats.fromGames([
        _game(genre: 'RPG'),
        _game(genre: 'rpg'),
        _game(genre: 'Ação'),
        _game(genre: '  '),
      ]);

      // Assert
      expect(_pairs(stats.topGenres), [('RPG', 2), ('Ação', 1)]);
    });
  });
}
