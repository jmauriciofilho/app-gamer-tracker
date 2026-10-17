import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/custom_lists/data/models/custom_list.dart';
import 'package:game_tracker/features/custom_lists/data/repositories/custom_list_repository.dart';
import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/games/data/repositories/game_repository.dart';
import 'package:game_tracker/features/games/presentation/providers/game_repository_provider.dart';
import 'package:game_tracker/main.dart';

/// Repositório falso em memória para não depender do Isar nos testes
class FakeGameRepository extends GameRepository {
  FakeGameRepository(this._games);

  final List<Game> _games;

  @override
  Future<List<Game>> getAllGames() async => _games;
}

/// Repositório falso de listas: a aba "Minhas Listas" também carrega ao abrir o app
class FakeCustomListRepository extends CustomListRepository {
  @override
  Future<List<CustomList>> getAllCustomLists() async => [];
}

Future<void> _pumpApp(WidgetTester tester, List<Game> games) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(FakeGameRepository(games)),
        customListRepositoryProvider.overrideWithValue(
          FakeCustomListRepository(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('HomeScreen exibe estado vazio quando não há jogos', (
    WidgetTester tester,
  ) async {
    // Arrange / Act
    await _pumpApp(tester, []);

    // Assert
    expect(find.text('Rastreador de Games'), findsOneWidget);
    expect(find.text('Nenhum jogo encontrado.'), findsOneWidget);
    expect(find.text('Novo Jogo'), findsOneWidget);
  });

  testWidgets('HomeScreen lista os jogos do repositório', (
    WidgetTester tester,
  ) async {
    // Arrange
    final game = Game()
      ..id = 1
      ..title = 'Bloodborne'
      ..status = 'jogando';

    // Act
    await _pumpApp(tester, [game]);

    // Assert
    expect(find.text('Bloodborne'), findsOneWidget);
    expect(find.text('Nenhum jogo encontrado.'), findsNothing);
  });
}
