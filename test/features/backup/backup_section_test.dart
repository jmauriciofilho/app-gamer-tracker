import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_tracker/features/backup/data/backup_codec.dart';
import 'package:game_tracker/features/backup/data/backup_file_gateway.dart';
import 'package:game_tracker/features/backup/data/backup_repository.dart';
import 'package:game_tracker/features/backup/presentation/providers/backup_provider.dart';
import 'package:game_tracker/features/custom_lists/data/models/custom_list.dart';
import 'package:game_tracker/features/custom_lists/data/repositories/custom_list_repository.dart';
import 'package:game_tracker/features/games/data/models/game.dart';
import 'package:game_tracker/features/games/data/repositories/game_repository.dart';
import 'package:game_tracker/features/games/presentation/providers/game_repository_provider.dart';
import 'package:game_tracker/main.dart';

// ==========================================
// FAKES EM MEMÓRIA (sem Isar nem plugin)
// ==========================================

/// "Banco" compartilhado pelos repositórios falsos
class FakeDatabase {
  FakeDatabase({List<Game>? games, List<CustomList>? lists})
    : games = games ?? [],
      lists = lists ?? [];

  final List<Game> games;
  final List<CustomList> lists;
}

class FakeGameRepository extends GameRepository {
  FakeGameRepository(this.db);

  final FakeDatabase db;

  @override
  Future<List<Game>> getAllGames() async => List.of(db.games);

  @override
  Future<List<Game>> getGamesByStatus(String status) async =>
      db.games.where((game) => game.status == status).toList();
}

class FakeCustomListRepository extends CustomListRepository {
  FakeCustomListRepository(this.db);

  final FakeDatabase db;

  @override
  Future<List<CustomList>> getAllCustomLists() async => List.of(db.lists);
}

class FakeBackupRepository extends BackupRepository {
  FakeBackupRepository(this.db);

  final FakeDatabase db;
  int replaceAllCalls = 0;

  @override
  Future<BackupData> readAll() async =>
      BackupData(games: List.of(db.games), customLists: List.of(db.lists));

  @override
  Future<void> replaceAll(BackupData data) async {
    replaceAllCalls++;
    db.games
      ..clear()
      ..addAll(data.games);
    db.lists
      ..clear()
      ..addAll(data.customLists);
  }
}

class FakeBackupFileGateway implements BackupFileGateway {
  bool saveResult = true;
  Object? saveError;
  Uint8List? pickBytes;

  String? savedName;
  Uint8List? savedBytes;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    if (saveError != null) throw saveError!;
    savedName = fileName;
    savedBytes = bytes;
    return saveResult;
  }

  @override
  Future<Uint8List?> pick() async => pickBytes;
}

// ==========================================
// HELPERS
// ==========================================

Game _game(int id, String title, {String status = 'jogando'}) => Game()
  ..id = id
  ..title = title
  ..status = status;

CustomList _list(int id, String name) => CustomList()
  ..id = id
  ..name = name
  ..filterGenre = 'RPG';

/// Abre o app com os fakes e vai para a aba Configurações
Future<void> _pumpSettings(
  WidgetTester tester, {
  required FakeDatabase db,
  required FakeBackupRepository backupRepository,
  required FakeBackupFileGateway gateway,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(FakeGameRepository(db)),
        customListRepositoryProvider.overrideWithValue(
          FakeCustomListRepository(db),
        ),
        backupRepositoryProvider.overrideWithValue(backupRepository),
        backupFileGatewayProvider.overrideWithValue(gateway),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ajustes & Sync'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC7: aba Configurações mostra o backup local sem Google Drive', (
    WidgetTester tester,
  ) async {
    // Arrange
    final db = FakeDatabase();

    // Act
    await _pumpSettings(
      tester,
      db: db,
      backupRepository: FakeBackupRepository(db),
      gateway: FakeBackupFileGateway(),
    );

    // Assert
    expect(find.text('Backup local'), findsOneWidget);
    expect(find.text('Exportar backup'), findsOneWidget);
    expect(find.text('Importar backup'), findsOneWidget);
    expect(find.textContaining('Google Drive'), findsNothing);
    expect(find.text('Conta do Google'), findsNothing);
  });

  group('AC3: exportar', () {
    testWidgets('salva o arquivo com todos os dados e avisa', (
      WidgetTester tester,
    ) async {
      // Arrange
      final db = FakeDatabase(
        games: [_game(1, 'Doom'), _game(2, 'Bloodborne')],
        lists: [_list(1, 'RPGs')],
      );
      final gateway = FakeBackupFileGateway();
      await _pumpSettings(
        tester,
        db: db,
        backupRepository: FakeBackupRepository(db),
        gateway: gateway,
      );

      // Act
      await tester.tap(find.text('Exportar backup'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        gateway.savedName,
        matches(RegExp(r'^game_tracker_backup_\d{4}-\d{2}-\d{2}\.json$')),
      );
      final exported = BackupCodec.decode(gateway.savedBytes!);
      expect(exported.games.map((game) => game.title), ['Doom', 'Bloodborne']);
      expect(exported.customLists.map((list) => list.name), ['RPGs']);
      expect(find.text('Backup exportado: 2 jogos, 1 lista'), findsOneWidget);
    });

    testWidgets('cancelar o seletor não mostra mensagem', (
      WidgetTester tester,
    ) async {
      // Arrange
      final db = FakeDatabase(games: [_game(1, 'Doom')]);
      final gateway = FakeBackupFileGateway()..saveResult = false;
      await _pumpSettings(
        tester,
        db: db,
        backupRepository: FakeBackupRepository(db),
        gateway: gateway,
      );

      // Act
      await tester.tap(find.text('Exportar backup'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('falha ao salvar mostra erro', (WidgetTester tester) async {
      // Arrange
      final db = FakeDatabase();
      final gateway = FakeBackupFileGateway()..saveError = Exception('disco');
      await _pumpSettings(
        tester,
        db: db,
        backupRepository: FakeBackupRepository(db),
        gateway: gateway,
      );

      // Act
      await tester.tap(find.text('Exportar backup'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Erro ao exportar backup'), findsOneWidget);
    });
  });

  testWidgets('AC4: arquivo inválido não abre diálogo nem grava', (
    WidgetTester tester,
  ) async {
    // Arrange
    final db = FakeDatabase(games: [_game(1, 'Doom')]);
    final backupRepository = FakeBackupRepository(db);
    final gateway = FakeBackupFileGateway()
      ..pickBytes = utf8.encode('{"app": "outro"}');
    await _pumpSettings(
      tester,
      db: db,
      backupRepository: backupRepository,
      gateway: gateway,
    );

    // Act
    await tester.tap(find.text('Importar backup'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Arquivo de backup inválido'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(backupRepository.replaceAllCalls, 0);
    expect(db.games.single.title, 'Doom');
  });

  group('AC5: importar', () {
    late FakeDatabase db;
    late FakeBackupRepository backupRepository;
    late FakeBackupFileGateway gateway;

    setUp(() {
      db = FakeDatabase(games: [_game(1, 'Doom')]);
      backupRepository = FakeBackupRepository(db);
      gateway = FakeBackupFileGateway()
        ..pickBytes = BackupCodec.encode(
          BackupData(
            games: [
              _game(10, 'Hollow Knight'),
              _game(11, 'Celeste'),
              _game(12, 'Hades'),
            ],
            customLists: [_list(10, 'Indies'), _list(11, 'Roguelikes')],
          ),
        );
    });

    testWidgets('cancelar no diálogo mantém os dados', (
      WidgetTester tester,
    ) async {
      // Arrange
      await _pumpSettings(
        tester,
        db: db,
        backupRepository: backupRepository,
        gateway: gateway,
      );

      // Act
      await tester.tap(find.text('Importar backup'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text(
          'Substituir 1 jogo e 0 listas atuais por 3 jogos e 2 listas do backup?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(backupRepository.replaceAllCalls, 0);
      expect(db.games.single.title, 'Doom');
    });

    testWidgets('substituir grava o backup e recarrega a Biblioteca', (
      WidgetTester tester,
    ) async {
      // Arrange
      await _pumpSettings(
        tester,
        db: db,
        backupRepository: backupRepository,
        gateway: gateway,
      );

      // Act
      await tester.tap(find.text('Importar backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Substituir'));
      await tester.pumpAndSettle();

      // Assert
      expect(backupRepository.replaceAllCalls, 1);
      expect(db.games.map((game) => game.title), [
        'Hollow Knight',
        'Celeste',
        'Hades',
      ]);
      expect(db.lists.map((list) => list.name), ['Indies', 'Roguelikes']);
      expect(find.text('Backup restaurado: 3 jogos, 2 listas'), findsOneWidget);

      await tester.tap(find.text('Biblioteca'));
      await tester.pumpAndSettle();

      expect(find.text('Hollow Knight'), findsOneWidget);
      expect(find.text('Celeste'), findsOneWidget);
      // A lista é preguiçosa e o terceiro card fica abaixo da área do teste (800×600)
      await tester.scrollUntilVisible(
        find.text('Hades'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Hades'), findsOneWidget);
      expect(find.text('Doom'), findsNothing);
    });
  });

  testWidgets('importar mantém o filtro de status ativo na Biblioteca', (
    WidgetTester tester,
  ) async {
    // Arrange: Biblioteca filtrada por "Para Jogar" antes de importar
    final db = FakeDatabase(games: [_game(1, 'Doom')]);
    final gateway = FakeBackupFileGateway()
      ..pickBytes = BackupCodec.encode(
        BackupData(
          games: [
            _game(10, 'Hollow Knight', status: 'para_jogar'),
            _game(11, 'Celeste'),
          ],
          customLists: [],
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(FakeGameRepository(db)),
          customListRepositoryProvider.overrideWithValue(
            FakeCustomListRepository(db),
          ),
          backupRepositoryProvider.overrideWithValue(FakeBackupRepository(db)),
          backupFileGatewayProvider.overrideWithValue(gateway),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Para Jogar'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('Ajustes & Sync'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Substituir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();

    // Assert: o chip continua marcado e a lista respeita o filtro
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Para Jogar'),
    );
    expect(chip.selected, isTrue);
    expect(find.text('Hollow Knight'), findsOneWidget);
    expect(find.text('Celeste'), findsNothing);
  });
}
