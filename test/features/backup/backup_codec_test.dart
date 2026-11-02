import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/backup/data/backup_codec.dart';
import 'package:game_tracker/features/custom_lists/data/models/custom_list.dart';
import 'package:game_tracker/features/games/data/models/game.dart';

/// Monta um arquivo de backup válido, permitindo trocar partes para os casos inválidos
Map<String, Object?> _validJson({List<Object?>? games}) => {
  'app': 'game_tracker',
  'version': 1,
  'exportedAt': '2026-11-02T10:00:00.000',
  'games':
      games ??
      [
        {'id': 1, 'title': 'Doom', 'status': 'jogado'},
      ],
  'customLists': [],
};

List<int> _bytes(Object? json) => utf8.encode(jsonEncode(json));

void _expectInvalid(List<int> bytes, String message) {
  expect(
    () => BackupCodec.decode(bytes),
    throwsA(
      isA<BackupFormatException>().having((e) => e.message, 'message', message),
    ),
  );
}

void main() {
  group('BackupCodec', () {
    test('AC1: ida e volta preserva jogos e listas, incluindo nulos', () {
      // Arrange
      final full = Game()
        ..id = 7
        ..title = 'Final Fantasy VII'
        ..developer = 'Square'
        ..genre = 'RPG'
        ..platform = 'PS1'
        ..releaseYear = 1997
        ..coverUrl = 'https://example.com/ff7.jpg'
        ..status = '100%'
        ..rating = 4.5
        ..startDate = DateTime(2025, 12, 1)
        ..endDate = DateTime(2026, 1, 15, 22, 30)
        ..createdAt = DateTime(2025, 11, 30, 8);
      final minimal = Game()
        ..id = 8
        ..title = 'Doom'
        ..status = 'para_jogar'
        ..createdAt = DateTime(2026, 2, 1);
      final list = CustomList()
        ..id = 3
        ..name = 'RPGs de 1995 a 2000'
        ..filterDeveloper = 'Square'
        ..filterPlatform = 'PS1'
        ..filterGenre = 'RPG'
        ..filterStatus = '100%'
        ..filterTitle = 'Final'
        ..filterReleaseYearFrom = 1995
        ..filterReleaseYearTo = 2000
        ..filterEndYear = 2026;

      // Act
      final bytes = BackupCodec.encode(
        BackupData(games: [full, minimal], customLists: [list]),
      );
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      final decoded = BackupCodec.decode(bytes);

      // Assert
      expect(json['app'], 'game_tracker');
      expect(json['version'], 1);

      final game = decoded.games[0];
      expect(game.id, 7);
      expect(game.title, 'Final Fantasy VII');
      expect(game.developer, 'Square');
      expect(game.genre, 'RPG');
      expect(game.platform, 'PS1');
      expect(game.releaseYear, 1997);
      expect(game.coverUrl, 'https://example.com/ff7.jpg');
      expect(game.status, '100%');
      expect(game.rating, 4.5);
      expect(game.startDate, DateTime(2025, 12, 1));
      expect(game.endDate, DateTime(2026, 1, 15, 22, 30));
      expect(game.createdAt, DateTime(2025, 11, 30, 8));

      final empty = decoded.games[1];
      expect(empty.id, 8);
      expect(empty.title, 'Doom');
      expect(empty.status, 'para_jogar');
      expect(empty.developer, isNull);
      expect(empty.genre, isNull);
      expect(empty.platform, isNull);
      expect(empty.releaseYear, isNull);
      expect(empty.coverUrl, isNull);
      expect(empty.rating, 0.0);
      expect(empty.startDate, isNull);
      expect(empty.endDate, isNull);
      expect(empty.createdAt, DateTime(2026, 2, 1));

      final decodedList = decoded.customLists.single;
      expect(decodedList.id, 3);
      expect(decodedList.name, 'RPGs de 1995 a 2000');
      expect(decodedList.filterDeveloper, 'Square');
      expect(decodedList.filterPlatform, 'PS1');
      expect(decodedList.filterGenre, 'RPG');
      expect(decodedList.filterStatus, '100%');
      expect(decodedList.filterTitle, 'Final');
      expect(decodedList.filterReleaseYearFrom, 1995);
      expect(decodedList.filterReleaseYearTo, 2000);
      expect(decodedList.filterEndYear, 2026);
    });

    test('AC2: recusa arquivos inválidos', () {
      const invalid = 'Arquivo de backup inválido';

      _expectInvalid(utf8.encode('isto não é json'), invalid);
      _expectInvalid(_bytes(_validJson()..remove('app')), invalid);
      _expectInvalid(_bytes(_validJson()..['app'] = 'outro_app'), invalid);
      _expectInvalid(_bytes(_validJson()..['games'] = 'Doom'), invalid);
      _expectInvalid(
        _bytes(
          _validJson(
            games: [
              {'id': 1, 'status': 'jogado'},
            ],
          ),
        ),
        invalid,
      );
      _expectInvalid(
        _bytes(
          _validJson(
            games: [
              {'title': 'Doom', 'status': 'jogado', 'startDate': 'ontem'},
            ],
          ),
        ),
        invalid,
      );
      _expectInvalid(
        _bytes(
          _validJson(
            games: [
              {'title': 'Doom', 'status': 'jogado', 'rating': 'cinco'},
            ],
          ),
        ),
        invalid,
      );
    });

    test('AC2: recusa versão de formato mais nova', () {
      _expectInvalid(
        _bytes(_validJson()..['version'] = 2),
        'Versão de backup não suportada',
      );
    });
  });
}
