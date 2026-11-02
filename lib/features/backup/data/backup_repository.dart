import 'package:isar_community/isar.dart';
import '../../../core/services/isar_service.dart';
import '../../custom_lists/data/models/custom_list.dart';
import '../../games/data/models/game.dart';
import 'backup_codec.dart';

class BackupRepository {
  Future<Isar> get _db async => await IsarService.instance;

  /// Lê todos os jogos e listas personalizadas do banco
  Future<BackupData> readAll() async {
    final isar = await _db;
    return BackupData(
      games: await isar.games.where().findAll(),
      customLists: await isar.customLists.where().findAll(),
    );
  }

  /// Substitui TODOS os jogos e listas pelos do backup.
  /// Tudo acontece numa única transação: se algo falhar, o banco fica como estava.
  Future<void> replaceAll(BackupData data) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.games.clear();
      await isar.customLists.clear();
      await isar.games.putAll(data.games);
      await isar.customLists.putAll(data.customLists);
    });
  }
}
