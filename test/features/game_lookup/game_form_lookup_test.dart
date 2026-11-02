import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/game_lookup/data/game_lookup_service.dart';
import 'package:game_tracker/features/game_lookup/data/models/game_lookup_result.dart';
import 'package:game_tracker/features/game_lookup/presentation/providers/game_lookup_provider.dart';
import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/games/presentation/screens/game_form_screen.dart';

// ==========================================
// SERVIÇO FALSO (sem rede)
// ==========================================

class FakeGameLookupService implements GameLookupService {
  FakeGameLookupService({
    this.results = const [],
    this.coverUrl,
    this.failuresBeforeSuccess = 0,
  });

  final List<GameLookupResult> results;
  final String? coverUrl;

  /// Quantas buscas falham antes de devolver [results]
  int failuresBeforeSuccess;
  final List<String> queries = [];

  @override
  Future<List<GameLookupResult>> search(String query) async {
    queries.add(query);
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw const GameLookupException('sem rede');
    }
    return results;
  }

  @override
  Future<String?> findCoverUrl(GameLookupResult result) async => coverUrl;
}

// ==========================================
// HELPERS
// ==========================================

const _steamCover =
    'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/367520/library_600x900.jpg';

const _hollowKnight = GameLookupResult(
  wikidataId: 'Q29300592',
  title: 'Hollow Knight',
  description: 'videojogo de 2017',
  developer: 'Team Cherry',
  genre: 'metroidvania',
  releaseYear: 2017,
  platforms: ['Microsoft Windows', 'macOS'],
  steamAppId: '367520',
);

const _mario64 = GameLookupResult(
  wikidataId: 'Q216995',
  title: 'Super Mario 64',
  developer: 'Nintendo EAD',
  releaseYear: 1996,
  platforms: ['Nintendo 64'],
);

Future<void> _pumpForm(
  WidgetTester tester,
  FakeGameLookupService service, {
  Game? gameToEdit,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gameLookupServiceProvider.overrideWithValue(service)],
      child: MaterialApp(home: GameFormScreen(gameToEdit: gameToEdit)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _text(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

Future<void> _searchAndPick(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('Buscar dados do jogo'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC5: cadastro troca o título e preenche só os campos vazios', (
    WidgetTester tester,
  ) async {
    // Arrange
    final service = FakeGameLookupService(
      results: [_hollowKnight],
      coverUrl: _steamCover,
    );
    await _pumpForm(tester, service);
    await tester.enterText(_field('Título do Jogo *'), 'hollow');
    await tester.enterText(_field('Desenvolvedora'), 'Minha Dev');

    // Act
    await _searchAndPick(tester, 'Hollow Knight');

    // Assert
    expect(service.queries, ['hollow']);
    expect(_text(tester, 'Título do Jogo *'), 'Hollow Knight');
    expect(_text(tester, 'Desenvolvedora'), 'Minha Dev');
    expect(_text(tester, 'Gênero'), 'metroidvania');
    expect(_text(tester, 'Ano'), '2017');
    expect(_text(tester, 'URL da Imagem da Capa'), _steamCover);
    expect(find.text('Para Jogar'), findsOneWidget);
  });

  testWidgets('AC6: várias plataformas viram chips; um toque preenche', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpForm(tester, FakeGameLookupService(results: [_hollowKnight]));
    await tester.enterText(_field('Título do Jogo *'), 'hollow');

    // Act
    await _searchAndPick(tester, 'Hollow Knight');

    // Assert
    expect(find.text('Plataformas deste jogo:'), findsOneWidget);
    expect(
      find.widgetWithText(ActionChip, 'Microsoft Windows'),
      findsOneWidget,
    );
    expect(_text(tester, 'Plataforma'), isEmpty);

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'macOS'));
    await tester.tap(find.widgetWithText(ActionChip, 'macOS'));
    await tester.pumpAndSettle();

    expect(_text(tester, 'Plataforma'), 'macOS');
    expect(find.text('Plataformas deste jogo:'), findsNothing);
  });

  testWidgets('AC6: uma plataforma preenche direto, sem chips', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpForm(tester, FakeGameLookupService(results: [_mario64]));
    await tester.enterText(_field('Título do Jogo *'), 'mario 64');

    // Act
    await _searchAndPick(tester, 'Super Mario 64');

    // Assert
    expect(_text(tester, 'Plataforma'), 'Nintendo 64');
    expect(find.text('Plataformas deste jogo:'), findsNothing);
    expect(_text(tester, 'URL da Imagem da Capa'), isEmpty);
  });

  testWidgets('AC7: sem resultados mostra aviso', (WidgetTester tester) async {
    // Arrange
    await _pumpForm(tester, FakeGameLookupService());
    await tester.enterText(_field('Título do Jogo *'), 'xyz');

    // Act
    await tester.tap(find.byTooltip('Buscar dados do jogo'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Nenhum jogo encontrado.'), findsOneWidget);
  });

  testWidgets('AC7: erro de rede permite tentar de novo', (
    WidgetTester tester,
  ) async {
    // Arrange
    final service = FakeGameLookupService(
      results: [_hollowKnight],
      failuresBeforeSuccess: 1,
    );
    await _pumpForm(tester, service);
    await tester.enterText(_field('Título do Jogo *'), 'hollow');

    // Act
    await tester.tap(find.byTooltip('Buscar dados do jogo'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Não foi possível buscar agora. Verifique a conexão.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(service.queries, ['hollow', 'hollow']);
    expect(find.widgetWithText(ListTile, 'Hollow Knight'), findsOneWidget);
  });

  testWidgets('AC7: fechar a folha sem escolher não altera o formulário', (
    WidgetTester tester,
  ) async {
    // Arrange
    await _pumpForm(tester, FakeGameLookupService(results: [_hollowKnight]));
    await tester.enterText(_field('Título do Jogo *'), 'hollow');

    // Act: toca fora da folha (na barreira do modal)
    await tester.tap(find.byTooltip('Buscar dados do jogo'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ListTile), findsNothing);
    expect(_text(tester, 'Título do Jogo *'), 'hollow');
    expect(_text(tester, 'Gênero'), isEmpty);
  });

  testWidgets('AC8: edição preserva status, nota e capa existente', (
    WidgetTester tester,
  ) async {
    // Arrange
    final game = Game()
      ..id = 1
      ..title = 'hollow'
      ..status = 'jogando'
      ..rating = 4
      ..coverUrl = 'https://exemplo.com/minha-capa.jpg';
    await _pumpForm(
      tester,
      FakeGameLookupService(results: [_hollowKnight], coverUrl: _steamCover),
      gameToEdit: game,
    );

    // Act
    await _searchAndPick(tester, 'Hollow Knight');

    // Assert
    expect(_text(tester, 'Título do Jogo *'), 'Hollow Knight');
    expect(
      _text(tester, 'URL da Imagem da Capa'),
      'https://exemplo.com/minha-capa.jpg',
    );
    expect(find.text('Jogando'), findsOneWidget);
    expect(_text(tester, 'Gênero'), 'metroidvania');
    // A nota não é tocada pelo preenchimento
    expect(game.rating, 4);
  });
}
