import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:game_tracker/features/custom_lists/data/models/custom_list.dart';
import 'package:game_tracker/features/custom_lists/data/repositories/custom_list_repository.dart';
import 'package:game_tracker/features/custom_lists/presentation/providers/custom_list_provider.dart';
import 'package:game_tracker/features/custom_lists/presentation/screens/custom_list_form_screen.dart';
import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/games/data/repositories/game_repository.dart';
import 'package:game_tracker/features/games/presentation/providers/game_list_provider.dart';
import 'package:game_tracker/features/games/presentation/providers/game_repository_provider.dart';
import 'package:game_tracker/main.dart';

// ==========================================
// REPOSITÓRIOS FALSOS EM MEMÓRIA (sem Isar)
// ==========================================

class FakeGameRepository extends GameRepository {
  FakeGameRepository([List<Game>? games]) : games = games ?? [];

  final List<Game> games;
  int _nextId = 100;

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

  @override
  Future<List<Game>> getAllGames() async => List.of(games);

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
  }) async {
    // Mesma semântica do repositório real: textos por "contém", sem diferenciar maiúsculas
    bool matches(String? value, String? filter) =>
        filter == null ||
        filter.isEmpty ||
        (value != null && value.toLowerCase().contains(filter.toLowerCase()));

    // Anos inclusivos; jogo sem ano fica de fora quando o intervalo está ativo
    bool inYearRange(int? year) =>
        (releaseYearFrom == null && releaseYearTo == null) ||
        (year != null &&
            year >= (releaseYearFrom ?? 0) &&
            year <= (releaseYearTo ?? 9999));

    return games
        .where(
          (game) =>
              matches(game.developer, developer) &&
              matches(game.platform, platform) &&
              matches(game.genre, genre) &&
              matches(game.title, title) &&
              (status == null || status.isEmpty || game.status == status) &&
              inYearRange(game.releaseYear) &&
              (endYear == null || game.endDate?.year == endYear),
        )
        .toList();
  }
}

class FakeCustomListRepository extends CustomListRepository {
  FakeCustomListRepository([List<CustomList>? lists]) : lists = lists ?? [];

  final List<CustomList> lists;
  int _nextId = 100;

  @override
  Future<void> saveCustomList(CustomList customList) async {
    if (customList.id == Isar.autoIncrement) customList.id = _nextId++;
    lists.removeWhere((existing) => existing.id == customList.id);
    lists.add(customList);
  }

  @override
  Future<List<CustomList>> getAllCustomLists() async =>
      List.of(lists)..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> deleteCustomList(int id) async {
    lists.removeWhere((list) => list.id == id);
  }
}

// ==========================================
// HELPERS
// ==========================================

Game _game(int id, String title, {String? developer, String? genre}) => Game()
  ..id = id
  ..title = title
  ..developer = developer
  ..genre = genre
  ..status = 'jogando';

CustomList _list(int id, String name, {String? genre}) => CustomList()
  ..id = id
  ..name = name
  ..filterGenre = genre;

List<Override> _overrides(
  FakeGameRepository gameRepo,
  FakeCustomListRepository listRepo,
) => [
  gameRepositoryProvider.overrideWithValue(gameRepo),
  customListRepositoryProvider.overrideWithValue(listRepo),
];

/// Abre o app completo já na aba "Minhas Listas"
Future<void> _pumpListsTab(
  WidgetTester tester,
  FakeGameRepository gameRepo,
  FakeCustomListRepository listRepo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(gameRepo, listRepo),
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Minhas Listas'));
  await tester.pumpAndSettle();
}

/// Abre o formulário empilhado sobre uma tela base (para o pop funcionar)
Future<void> _pumpForm(
  WidgetTester tester,
  FakeGameRepository gameRepo,
  FakeCustomListRepository listRepo, {
  CustomList? listToEdit,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(gameRepo, listRepo),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CustomListFormScreen(listToEdit: listToEdit),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Finder _fieldInput(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(TextFormField),
);

void main() {
  // R1 → AC1
  testWidgets('aba exibe cards ordenados com chip do filtro e contagem', (
    WidgetTester tester,
  ) async {
    // Arrange
    final gameRepo = FakeGameRepository([
      _game(1, 'Dark Souls', genre: 'RPG'),
      _game(2, 'Elden Ring', genre: 'RPG'),
      _game(3, 'Persona 5', genre: 'RPG'),
    ]);
    final listRepo = FakeCustomListRepository([
      _list(1, 'RPGs', genre: 'RPG'),
      _list(2, 'Ação', genre: 'Ação'),
    ]);

    // Act
    await _pumpListsTab(tester, gameRepo, listRepo);

    // Assert
    final acaoY = tester.getTopLeft(find.text('Ação').first).dy;
    final rpgsY = tester.getTopLeft(find.text('RPGs')).dy;
    expect(acaoY, lessThan(rpgsY));
    expect(find.widgetWithText(Chip, 'RPG'), findsOneWidget);
    expect(find.text('3 jogos'), findsOneWidget);
    expect(find.text('0 jogos'), findsOneWidget);
  });

  // R2 → AC2
  testWidgets('aba exibe estado vazio sem listas', (WidgetTester tester) async {
    await _pumpListsTab(
      tester,
      FakeGameRepository(),
      FakeCustomListRepository(),
    );

    expect(find.text('Nenhuma lista criada ainda.'), findsOneWidget);
  });

  // R3 → AC3
  testWidgets('FAB varia por aba e "Nova Lista" abre o formulário', (
    WidgetTester tester,
  ) async {
    // Arrange: aba Biblioteca
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(FakeGameRepository(), FakeCustomListRepository()),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Novo Jogo'), findsOneWidget);
    expect(find.text('Nova Lista'), findsNothing);

    // Act: troca para a aba Minhas Listas
    await tester.tap(find.text('Minhas Listas'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Nova Lista'), findsOneWidget);
    expect(find.text('Novo Jogo'), findsNothing);

    await tester.tap(find.text('Nova Lista'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Nova Lista'), findsOneWidget);
  });

  // R4 → AC4
  testWidgets('formulário sugere valores cadastrados e lista os status', (
    WidgetTester tester,
  ) async {
    // Arrange
    final gameRepo = FakeGameRepository([
      _game(1, 'Dark Souls', developer: 'FromSoftware'),
      _game(2, 'Resident Evil', developer: 'Capcom'),
    ]);
    await _pumpForm(tester, gameRepo, FakeCustomListRepository());

    // Act
    await tester.enterText(_fieldInput('filterDeveloperField'), 'fro');
    await tester.pumpAndSettle();

    // Assert: sugestão de autocompletar
    expect(find.widgetWithText(ListTile, 'FromSoftware'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Capcom'), findsNothing);

    // Act: abre o dropdown de status
    await tester.tap(find.byKey(const Key('filterStatusField')));
    await tester.pumpAndSettle();

    // Assert: opções de status
    for (final label in [
      'Qualquer',
      'Para Jogar',
      'Jogando',
      'Jogado',
      'Finalizado',
      '100%',
    ]) {
      expect(find.text(label), findsWidgets);
    }
  });

  // R5 → AC5
  testWidgets('valida nome e filtros e salva com trim e nulos', (
    WidgetTester tester,
  ) async {
    // Arrange
    final listRepo = FakeCustomListRepository();
    await _pumpForm(tester, FakeGameRepository(), listRepo);

    // Act / Assert: nome vazio
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome da lista'), findsOneWidget);
    expect(listRepo.lists, isEmpty);

    // Act / Assert: nome sem filtros
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da Lista *'),
      '  RPGs ',
    );
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();
    expect(find.text('Preencha pelo menos um filtro'), findsOneWidget);
    expect(listRepo.lists, isEmpty);

    // Act / Assert: nome e gênero com espaços extras
    await tester.enterText(_fieldInput('filterGenreField'), ' RPG ');
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();

    expect(listRepo.lists, hasLength(1));
    final saved = listRepo.lists.single;
    expect(saved.name, 'RPGs');
    expect(saved.filterGenre, 'RPG');
    expect(saved.filterDeveloper, isNull);
    expect(saved.filterPlatform, isNull);
    expect(saved.filterStatus, isNull);
  });

  // R6 → AC6
  testWidgets('edição mantém o id e atualiza o nome', (
    WidgetTester tester,
  ) async {
    // Arrange
    final existing = _list(1, 'RPGs', genre: 'RPG');
    final listRepo = FakeCustomListRepository([existing]);
    await _pumpForm(
      tester,
      FakeGameRepository(),
      listRepo,
      listToEdit: existing,
    );

    // Act
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da Lista *'),
      'RPGs Favoritos',
    );
    await tester.ensureVisible(find.text('Salvar Alterações'));
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pumpAndSettle();

    // Assert
    expect(listRepo.lists, hasLength(1));
    expect(listRepo.lists.single.id, 1);
    expect(listRepo.lists.single.name, 'RPGs Favoritos');
  });

  // R7 → AC7
  testWidgets('detalhe exibe os jogos da lista ou estado vazio', (
    WidgetTester tester,
  ) async {
    // Arrange
    final gameRepo = FakeGameRepository([
      _game(1, 'Dark Souls', genre: 'RPG'),
      _game(2, 'Elden Ring', genre: 'RPG'),
      _game(3, 'Doom', genre: 'FPS'),
    ]);
    final listRepo = FakeCustomListRepository([
      _list(1, 'RPGs', genre: 'RPG'),
      _list(2, 'Corrida', genre: 'Corrida'),
    ]);
    await _pumpListsTab(tester, gameRepo, listRepo);

    // Act: abre a lista com jogos
    await tester.tap(find.text('RPGs'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.widgetWithText(AppBar, 'RPGs'), findsOneWidget);
    expect(find.text('Dark Souls'), findsOneWidget);
    expect(find.text('Elden Ring'), findsOneWidget);
    expect(find.text('Doom'), findsNothing);

    // Act: volta e abre a lista sem jogos
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corrida').first);
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Nenhum jogo corresponde aos filtros desta lista.'),
      findsOneWidget,
    );
  });

  // R8 → AC8
  testWidgets('excluir com confirmação remove a lista e exibe SnackBar', (
    WidgetTester tester,
  ) async {
    // Arrange
    final listRepo = FakeCustomListRepository([_list(1, 'RPGs', genre: 'RPG')]);
    await _pumpListsTab(tester, FakeGameRepository(), listRepo);
    await tester.tap(find.text('RPGs'));
    await tester.pumpAndSettle();

    // Act: cancela a exclusão
    await tester.tap(find.byTooltip('Excluir Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Assert: nada removido
    expect(listRepo.lists, hasLength(1));
    expect(find.widgetWithText(AppBar, 'RPGs'), findsOneWidget);

    // Act: confirma a exclusão
    await tester.tap(find.byTooltip('Excluir Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    // Assert
    expect(listRepo.lists, isEmpty);
    expect(find.text('RPGs foi removida.'), findsOneWidget);
    expect(find.text('Nenhuma lista criada ainda.'), findsOneWidget);
  });

  // R9 → AC9
  test('jogos da lista são reavaliados ao salvar um jogo', () async {
    // Arrange
    final gameRepo = FakeGameRepository([_game(1, 'Dark Souls', genre: 'RPG')]);
    final listRepo = FakeCustomListRepository([_list(1, 'RPGs', genre: 'RPG')]);
    final container = ProviderContainer(
      overrides: _overrides(gameRepo, listRepo),
    );
    addTearDown(container.dispose);
    container.listen(customListGamesProvider(1), (previous, next) {});

    expect(
      await container.read(customListGamesProvider(1).future),
      hasLength(1),
    );

    // Act
    await container
        .read(gameListProvider.notifier)
        .saveGame(
          Game()
            ..title = 'Elden Ring'
            ..genre = 'RPG'
            ..status = 'jogando',
        );

    // Assert
    expect(
      await container.read(customListGamesProvider(1).future),
      hasLength(2),
    );
  });

  // ==========================================
  // FILTROS NOVOS (spec filtros-novos-listas)
  // ==========================================

  // R1 → AC1
  testWidgets('detalhe filtra por título contém sem diferenciar maiúsculas', (
    WidgetTester tester,
  ) async {
    // Arrange
    final gameRepo = FakeGameRepository([
      _game(1, 'Final Fantasy VII'),
      _game(2, 'Final Fantasy X'),
      _game(3, 'Doom'),
    ]);
    final listRepo = FakeCustomListRepository([
      CustomList()
        ..id = 1
        ..name = 'Série FF'
        ..filterTitle = 'fantasy',
    ]);
    await _pumpListsTab(tester, gameRepo, listRepo);

    // Act
    await tester.tap(find.text('Série FF'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Final Fantasy VII'), findsOneWidget);
    expect(find.text('Final Fantasy X'), findsOneWidget);
    expect(find.text('Doom'), findsNothing);
  });

  // R2 → AC2
  test(
    'intervalo de ano de lançamento é inclusivo e ignora jogos sem ano',
    () async {
      // Arrange
      Game withYear(int id, int? year) =>
          _game(id, 'Jogo $id')..releaseYear = year;
      final gameRepo = FakeGameRepository([
        withYear(1, 1994),
        withYear(2, 1995),
        withYear(3, 2000),
        withYear(4, 2001),
        withYear(5, null),
      ]);
      final listRepo = FakeCustomListRepository([
        CustomList()
          ..id = 1
          ..name = 'Fechado'
          ..filterReleaseYearFrom = 1995
          ..filterReleaseYearTo = 2000,
        CustomList()
          ..id = 2
          ..name = 'Só de'
          ..filterReleaseYearFrom = 2000,
        CustomList()
          ..id = 3
          ..name = 'Só até'
          ..filterReleaseYearTo = 1995,
      ]);
      final container = ProviderContainer(
        overrides: _overrides(gameRepo, listRepo),
      );
      addTearDown(container.dispose);

      // Act
      // Ouvinte ativo, como no teste de reavaliação: sem ele o provider é descartado no loading
      Future<List<int>> idsOf(int listId) async {
        container.listen(customListGamesProvider(listId), (previous, next) {});
        final games = await container.read(
          customListGamesProvider(listId).future,
        );
        return games.map((game) => game.id).toList();
      }

      // Assert
      expect(await idsOf(1), [2, 3]);
      expect(await idsOf(2), [3, 4]);
      expect(await idsOf(3), [1, 2]);
    },
  );

  // R3 → AC3
  test('ano de término respeita os limites do ano civil', () async {
    // Arrange
    Game endedAt(int id, DateTime? date) =>
        _game(id, 'Jogo $id')..endDate = date;
    final gameRepo = FakeGameRepository([
      endedAt(1, DateTime(2025, 12, 31)),
      endedAt(2, DateTime(2026, 1, 1)),
      endedAt(3, DateTime(2026, 12, 31)),
      endedAt(4, null),
    ]);
    final listRepo = FakeCustomListRepository([
      CustomList()
        ..id = 1
        ..name = 'Terminados 2026'
        ..filterEndYear = 2026,
    ]);
    final container = ProviderContainer(
      overrides: _overrides(gameRepo, listRepo),
    );
    addTearDown(container.dispose);
    container.listen(customListGamesProvider(1), (previous, next) {});

    // Act
    final games = await container.read(customListGamesProvider(1).future);

    // Assert
    expect(games.map((game) => game.id), [2, 3]);
  });

  // R4 → AC4
  test('plataforma compara por "contém" sem diferenciar maiúsculas', () async {
    // Arrange
    final gameRepo = FakeGameRepository([
      _game(1, 'Shadow of the Colossus')..platform = 'PlayStation 2',
      _game(2, 'Half-Life')..platform = 'PC',
    ]);
    final listRepo = FakeCustomListRepository([
      CustomList()
        ..id = 1
        ..name = 'PlayStation'
        ..filterPlatform = 'playstation',
    ]);
    final container = ProviderContainer(
      overrides: _overrides(gameRepo, listRepo),
    );
    addTearDown(container.dispose);
    container.listen(customListGamesProvider(1), (previous, next) {});

    // Act
    final games = await container.read(customListGamesProvider(1).future);

    // Assert
    expect(games.map((game) => game.id), [1]);
  });

  // R5 → AC5
  testWidgets('formulário salva título e ano com trim e nulos', (
    WidgetTester tester,
  ) async {
    // Arrange
    final listRepo = FakeCustomListRepository();
    await _pumpForm(tester, FakeGameRepository(), listRepo);

    // Act
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da Lista *'),
      'Final Fantasy anos 90',
    );
    await tester.enterText(
      find.byKey(const Key('filterTitleField')),
      ' Final Fantasy ',
    );
    await tester.enterText(
      find.byKey(const Key('filterReleaseYearFromField')),
      '1995',
    );
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();

    // Assert
    expect(listRepo.lists, hasLength(1));
    final saved = listRepo.lists.single;
    expect(saved.filterTitle, 'Final Fantasy');
    expect(saved.filterReleaseYearFrom, 1995);
    expect(saved.filterReleaseYearTo, isNull);
    expect(saved.filterEndYear, isNull);
    expect(saved.filterDeveloper, isNull);
    expect(saved.filterPlatform, isNull);
    expect(saved.filterGenre, isNull);
    expect(saved.filterStatus, isNull);
  });

  // R5 → AC5
  testWidgets('ano de término sozinho já conta como filtro', (
    WidgetTester tester,
  ) async {
    // Arrange
    final listRepo = FakeCustomListRepository();
    await _pumpForm(tester, FakeGameRepository(), listRepo);

    // Act
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da Lista *'),
      'Zerados 2026',
    );
    await tester.enterText(find.byKey(const Key('filterEndYearField')), '2026');
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Preencha pelo menos um filtro'), findsNothing);
    expect(listRepo.lists.single.filterEndYear, 2026);
  });

  // R5 → AC5
  testWidgets('edição pré-preenche os filtros novos', (
    WidgetTester tester,
  ) async {
    // Arrange
    final existing = CustomList()
      ..id = 1
      ..name = 'Clássicos'
      ..filterTitle = 'Mario'
      ..filterReleaseYearFrom = 1985
      ..filterReleaseYearTo = 1999
      ..filterEndYear = 2026;

    // Act
    await _pumpForm(
      tester,
      FakeGameRepository(),
      FakeCustomListRepository([existing]),
      listToEdit: existing,
    );

    // Assert
    String textOf(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
    expect(textOf('filterTitleField'), 'Mario');
    expect(textOf('filterReleaseYearFromField'), '1985');
    expect(textOf('filterReleaseYearToField'), '1999');
    expect(textOf('filterEndYearField'), '2026');
  });

  // R6 → AC6
  testWidgets('ano inválido e intervalo invertido não salvam', (
    WidgetTester tester,
  ) async {
    // Arrange
    final listRepo = FakeCustomListRepository();
    await _pumpForm(tester, FakeGameRepository(), listRepo);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da Lista *'),
      'Anos',
    );

    // Act / Assert: ano com 2 dígitos
    await tester.enterText(
      find.byKey(const Key('filterReleaseYearFromField')),
      '95',
    );
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();
    expect(find.text('Ano inválido'), findsOneWidget);
    expect(listRepo.lists, isEmpty);

    // Act / Assert: início maior que o fim
    await tester.enterText(
      find.byKey(const Key('filterReleaseYearFromField')),
      '2001',
    );
    await tester.enterText(
      find.byKey(const Key('filterReleaseYearToField')),
      '2000',
    );
    await tester.ensureVisible(find.text('Criar Lista'));
    await tester.tap(find.text('Criar Lista'));
    await tester.pumpAndSettle();
    expect(find.text('Ano inicial maior que o final'), findsOneWidget);
    expect(listRepo.lists, isEmpty);
  });

  // R7 → AC7
  testWidgets('card mostra chips dos filtros novos', (
    WidgetTester tester,
  ) async {
    // Arrange
    final listRepo = FakeCustomListRepository([
      CustomList()
        ..id = 1
        ..name = 'A'
        ..filterTitle = 'Final Fantasy'
        ..filterReleaseYearFrom = 1995
        ..filterReleaseYearTo = 2000,
      CustomList()
        ..id = 2
        ..name = 'B'
        ..filterReleaseYearFrom = 1995,
      CustomList()
        ..id = 3
        ..name = 'C'
        ..filterReleaseYearTo = 2000,
      CustomList()
        ..id = 4
        ..name = 'D'
        ..filterEndYear = 2026,
    ]);

    // Act
    await _pumpListsTab(tester, FakeGameRepository(), listRepo);

    // Assert
    expect(find.text('Final Fantasy'), findsOneWidget);
    expect(find.text('1995–2000'), findsOneWidget);
    expect(find.text('A partir de 1995'), findsOneWidget);
    expect(find.text('Até 2000'), findsOneWidget);
    expect(find.text('Terminados em 2026'), findsOneWidget);
  });

  // R8 → AC8
  testWidgets('lista salva sem os campos novos abre no card e no detalhe', (
    WidgetTester tester,
  ) async {
    // Arrange: lista como as já gravadas antes desta versão (campos novos nulos)
    final gameRepo = FakeGameRepository([_game(1, 'Dark Souls', genre: 'RPG')]);
    final listRepo = FakeCustomListRepository([_list(1, 'RPGs', genre: 'RPG')]);
    await _pumpListsTab(tester, gameRepo, listRepo);

    // Assert: card
    expect(find.text('1 jogo'), findsOneWidget);

    // Act
    await tester.tap(find.text('RPGs'));
    await tester.pumpAndSettle();

    // Assert: detalhe
    expect(tester.takeException(), isNull);
    expect(find.text('Dark Souls'), findsOneWidget);
  });
}
