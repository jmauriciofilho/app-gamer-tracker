import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/custom_lists/data/models/custom_list.dart';
import 'package:game_tracker/features/custom_lists/data/repositories/custom_list_repository.dart';
import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/games/data/repositories/game_repository.dart';
import 'package:game_tracker/features/games/presentation/providers/game_repository_provider.dart';
import 'package:game_tracker/features/games/presentation/widgets/game_card.dart';
import 'package:game_tracker/main.dart';

// ==========================================
// REPOSITÓRIOS FALSOS QUE FALHAM NA ESCRITA
// ==========================================

class FailingGameRepository extends GameRepository {
  FailingGameRepository(this.games);

  final List<Game> games;

  @override
  Future<void> saveGame(Game game) async => throw Exception('falha no save');

  @override
  Future<void> deleteGame(int id) async => throw Exception('falha no delete');

  @override
  Future<List<Game>> getAllGames() async => List.of(games);

  @override
  Future<Game?> getGameById(int id) async =>
      games.where((game) => game.id == id).firstOrNull;

  @override
  Future<List<Game>> getGamesByCustomFilter({
    String? developer,
    String? platform,
    String? genre,
    String? status,
    String? title,
    int? releaseYearFrom,
    int? releaseYearTo,
    int? endYear,
  }) async => List.of(games);
}

class FailingCustomListRepository extends CustomListRepository {
  FailingCustomListRepository(this.lists);

  final List<CustomList> lists;

  @override
  Future<void> saveCustomList(CustomList customList) async =>
      throw Exception('falha no save');

  @override
  Future<void> deleteCustomList(int id) async =>
      throw Exception('falha no delete');

  @override
  Future<List<CustomList>> getAllCustomLists() async => List.of(lists);
}

// ==========================================
// HELPERS
// ==========================================

Future<void> _pumpApp(WidgetTester tester) async {
  final game = Game()
    ..id = 1
    ..title = 'Bloodborne'
    ..genre = 'RPG'
    ..status = 'jogando';
  final customList = CustomList()
    ..id = 1
    ..name = 'RPGs'
    ..filterGenre = 'RPG';

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(FailingGameRepository([game])),
        customListRepositoryProvider.overrideWithValue(
          FailingCustomListRepository([customList]),
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('falha ao salvar jogo exibe erro e mantém o formulário aberto', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);
    await tester.tap(find.text('Novo Jogo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título do Jogo *'),
      'Elden Ring',
    );

    // Act
    await tester.ensureVisible(find.text('Salvar Jogo'));
    await tester.tap(find.text('Salvar Jogo'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Não foi possível salvar o jogo. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Jogo cadastrado com sucesso!'), findsNothing);
    expect(find.text('Salvar Jogo'), findsOneWidget);
  });

  testWidgets('falha ao excluir jogo exibe erro e mantém o detalhe aberto', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);
    await tester.tap(find.byType(GameCard));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('Excluir Jogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Não foi possível excluir o jogo. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Bloodborne foi removido.'), findsNothing);
    expect(find.byTooltip('Excluir Jogo'), findsOneWidget);
  });

  testWidgets('falha ao salvar lista exibe erro e mantém o formulário aberto', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);
    await tester.tap(find.text('Minhas Listas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova Lista'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da Lista *'),
      'Ação',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('filterGenreField')),
        matching: find.byType(TextFormField),
      ),
      'Ação',
    );

    // Act
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Não foi possível salvar a lista. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Lista criada com sucesso!'), findsNothing);
    expect(find.text('Criar Lista'), findsOneWidget);
  });

  testWidgets('falha ao excluir lista exibe erro e mantém o detalhe aberto', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpApp(tester);
    await tester.tap(find.text('Minhas Listas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RPGs'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('Excluir Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    // Assert: a lista continua carregada (sem tela de erro) e o usuário é avisado
    expect(
      find.text('Não foi possível excluir a lista. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('RPGs foi removida.'), findsNothing);
    expect(find.byTooltip('Excluir Lista'), findsOneWidget);
  });
}
