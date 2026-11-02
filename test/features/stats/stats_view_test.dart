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

class FakeGameRepository extends GameRepository {
  FakeGameRepository(this.games, {this.fail = false});

  final List<Game> games;
  final bool fail;
  int _nextId = 100;

  @override
  Future<List<Game>> getAllGames() async {
    if (fail) throw Exception('banco indisponível');
    return List.of(games);
  }

  @override
  Future<List<Game>> getGamesByStatus(String status) async =>
      games.where((game) => game.status == status).toList();

  @override
  Future<void> saveGame(Game game) async {
    if (game.id == Isar.autoIncrement) game.id = _nextId++;
    games.add(game);
  }
}

class FakeCustomListRepository extends CustomListRepository {
  @override
  Future<List<CustomList>> getAllCustomLists() async => [];
}

// ==========================================
// HELPERS
// ==========================================

Game _game(int id, String status, {double rating = 0}) => Game()
  ..id = id
  ..title = 'Jogo $id'
  ..status = status
  ..rating = rating;

Future<void> _pumpStats(
  WidgetTester tester,
  FakeGameRepository repository,
) async {
  // Tela alta: o ListView da aba constrói todos os blocos
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

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
  await tester.tap(find.text('Estatísticas'));
  await tester.pumpAndSettle();
}

/// Valor exibido acima de um rótulo do cartão de resumo ("Jogos", "Terminados"...)
String _summaryValue(WidgetTester tester, String label) {
  final column = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  final texts = tester.widgetList<Text>(
    find.descendant(of: column.first, matching: find.byType(Text)),
  );
  return texts.first.data!;
}

void main() {
  testWidgets('AC6: resumo, blocos e "Sem dados ainda."', (
    WidgetTester tester,
  ) async {
    // Arrange / Act
    await _pumpStats(
      tester,
      FakeGameRepository([
        _game(1, 'finalizado', rating: 4),
        _game(2, '100%', rating: 5),
        _game(3, 'jogando'),
      ]),
    );

    // Assert
    expect(_summaryValue(tester, 'Jogos'), '3');
    expect(_summaryValue(tester, 'Terminados'), '2');
    expect(_summaryValue(tester, 'Nota média'), '4,5');
    for (final title in [
      'Por status',
      'Terminados por ano',
      'Top plataformas',
      'Top gêneros',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    // Sem datas de término, plataformas nem gêneros
    expect(find.text('Sem dados ainda.'), findsNWidgets(3));
  });

  testWidgets('AC6: biblioteca vazia', (WidgetTester tester) async {
    await _pumpStats(tester, FakeGameRepository([]));

    expect(find.text('Cadastre jogos para ver estatísticas.'), findsOneWidget);
  });

  testWidgets('AC6: erro ao carregar', (WidgetTester tester) async {
    await _pumpStats(tester, FakeGameRepository([], fail: true));

    expect(
      find.text('Não foi possível carregar as estatísticas.'),
      findsOneWidget,
    );
  });

  testWidgets('AC5: recalcula ao cadastrar e ignora o filtro da Biblioteca', (
    WidgetTester tester,
  ) async {
    // Arrange
    final repository = FakeGameRepository([
      _game(1, 'jogando'),
      _game(2, 'finalizado'),
    ]);
    await _pumpStats(tester, repository);
    expect(_summaryValue(tester, 'Jogos'), '2');

    // Act: cadastra um jogo com a aba Estatísticas aberta
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await container
        .read(gameListProvider.notifier)
        .saveGame(
          Game()
            ..title = 'Novo'
            ..status = 'para_jogar',
        );
    await tester.pumpAndSettle();

    // Assert
    expect(_summaryValue(tester, 'Jogos'), '3');

    // Act: filtra a Biblioteca por "Jogando" e volta
    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Jogando'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estatísticas'));
    await tester.pumpAndSettle();

    // Assert: continua a biblioteca inteira
    expect(_summaryValue(tester, 'Jogos'), '3');
  });

  testWidgets('AC7: 4 destinos, atalho Backup e aba sem FAB', (
    WidgetTester tester,
  ) async {
    // Arrange / Act
    await _pumpStats(tester, FakeGameRepository([_game(1, 'jogando')]));

    // Assert
    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((destination) => destination.label)
        .toList();
    expect(labels, [
      'Biblioteca',
      'Minhas Listas',
      'Estatísticas',
      'Ajustes & Sync',
    ]);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byTooltip('Backup'));
    await tester.pumpAndSettle();

    expect(find.text('Backup local'), findsOneWidget);
  });
}
