import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/games/data/models/game_status.dart';

void main() {
  // AC1: ids, rótulos e ordem de exibição
  test('values tem os 5 status na ordem de exibição', () {
    // Act
    final ids = GameStatus.values.map((s) => s.id).toList();
    final labels = GameStatus.values.map((s) => s.label).toList();

    // Assert
    expect(ids, ['para_jogar', 'jogando', 'jogado', 'finalizado', '100%']);
    expect(labels, ['Para Jogar', 'Jogando', 'Jogado', 'Finalizado', '100%']);
  });

  // AC2: conversão id → rótulo
  test('labelOf converte ids válidos, maiúsculas e legado', () {
    expect(GameStatus.labelOf('jogando'), 'Jogando');
    expect(GameStatus.labelOf('100%'), '100%');
    expect(GameStatus.labelOf('JOGANDO'), 'Jogando');
    expect(GameStatus.labelOf('para jogar'), 'Para Jogar');
  });

  test(
    'status desconhecido: labelOf devolve o valor e fromId devolve null',
    () {
      expect(GameStatus.labelOf('xyz'), 'xyz');
      expect(GameStatus.fromId('xyz'), isNull);
    },
  );
}
