import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:game_tracker/features/custom_lists/data/models/custom_list.dart';
import 'package:game_tracker/features/custom_lists/data/repositories/custom_list_repository.dart';
import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/games/data/repositories/game_repository.dart';
import 'package:game_tracker/features/games/presentation/providers/game_list_provider.dart';
import 'package:game_tracker/features/games/presentation/providers/game_repository_provider.dart';
import 'package:game_tracker/features/games/presentation/screens/home_screen.dart';
import 'package:game_tracker/main.dart';

// ==========================================
// REPOSITÓRIOS FALSOS EM MEMÓRIA (sem Isar)
// ==========================================

/// Devolve os jogos na ordem em que foram cadastrados no fake (sem ordenar),
/// para provar que quem ordena é o notifier
class FakeGameRepository extends GameRepository {
  FakeGameRepository(this.games);

  final List<Game> games;
  int _nextId = 100;

  @override
  Future<List<Game>> getAllGames() async => games;

  @override
  Future<List<Game>> getGamesByStatus(String status) async =>
      games.where((game) => game.status == status).toList();

  @override
  Future<List<Game>> searchGamesByTitle(String query) async => games
      .where((game) => game.title.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Future<void> saveGame(Game game) async {
    if (game.id == Isar.autoIncrement) game.id = _nextId++;
    games.removeWhere((existing) => existing.id == game.id);
    games.add(game);
  }

  @override
  Future<void> deleteGame(int id) async {
    games.removeWhere((game) => game.id == id);
  }
}

class FakeCustomListRepository extends CustomListRepository {
  @override
  Future<List<CustomList>> getAllCustomLists() async => [];
}

// ==========================================
// HELPERS
// ==========================================

Game _game(
  int id,
  String title, {
  required int day,
  double rating = 0,
  String status = 'jogando',
}) => Game()
  ..id = id
  ..title = title
  ..rating = rating
  ..status = status
  ..createdAt = DateTime(2026, 1, day);

/// Biblioteca de exemplo: criação, título e nota em ordens diferentes
List<Game> _library() => [
  _game(1, 'Bloodborne', day: 2, rating: 4, status: 'jogado'),
  _game(2, 'alan wake', day: 3, rating: 3),
  _game(3, 'Celeste', day: 1, rating: 5),
  _game(4, 'Doom', day: 4, rating: 4),
];

Future<FakeGameRepository> _pumpApp(WidgetTester tester) async {
  final repository = FakeGameRepository(_library());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repository),
        customListRepositoryProvider.overrideWithValue(
          FakeCustomListRepository(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Títulos na ordem atual da Biblioteca (estado do gameListProvider)
List<String> _titles(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(HomeScreen)),
  );
  return container
      .read(gameListProvider)
      .requireValue
      .map((game) => game.title)
      .toList();
}

Future<void> _chooseSort(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Ordenar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC1: padrão é Recentes e vem marcado no menu', (
    WidgetTester tester,
  ) async {
    // Arrange / Act
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();

    // Assert
    expect(_titles(tester), ['Doom', 'alan wake', 'Bloodborne', 'Celeste']);
    final checked = tester
        .widgetList<CheckedPopupMenuItem<Object?>>(
          find.byWidgetPredicate((widget) => widget is CheckedPopupMenuItem),
        )
        .where((item) => item.checked)
        .map((item) => (item.child as Text).data)
        .toList();
    expect(checked, ['Recentes']);
  });

  testWidgets('AC2: título A–Z ignora maiúsculas e nota desempata por título', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);

    // Act / Assert
    await _chooseSort(tester, 'Título A–Z');
    expect(_titles(tester), ['alan wake', 'Bloodborne', 'Celeste', 'Doom']);

    await _chooseSort(tester, 'Maior nota');
    expect(_titles(tester), ['Celeste', 'Bloodborne', 'Doom', 'alan wake']);
  });

  testWidgets('AC3: ordem vale no filtro de status e na busca', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);
    await _chooseSort(tester, 'Título A–Z');

    // Act: filtro "Jogando" (exclui Bloodborne)
    await tester.tap(find.widgetWithText(FilterChip, 'Jogando'));
    await tester.pumpAndSettle();

    // Assert
    expect(_titles(tester), ['alan wake', 'Celeste', 'Doom']);

    // Act: busca por "o" (Bloodborne e Doom)
    await tester.enterText(find.byType(TextField), 'o');
    await tester.pumpAndSettle();

    // Assert
    expect(_titles(tester), ['Bloodborne', 'Doom']);
  });

  testWidgets('AC4: salvar e excluir mantêm a ordem escolhida', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);
    await _chooseSort(tester, 'Maior nota');
    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).read(gameListProvider.notifier);

    // Act
    await notifier.saveGame(_game(5, 'Elden Ring', day: 5, rating: 4.5));
    await notifier.deleteGame(3);
    await tester.pumpAndSettle();

    // Assert
    expect(_titles(tester), ['Elden Ring', 'Bloodborne', 'Doom', 'alan wake']);
  });
}
