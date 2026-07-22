import 'package:isar/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../models/custom_list.dart';

class CustomListRepository {
  Future<Isar> get _db async => await IsarService.instance;

  /// Salva uma nova lista de filtro personalizado
  Future<void> saveCustomList(CustomList customList) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.customLists.put(customList);
    });
  }

  /// Retorna todas as listas personalizadas criadas pelo usuário
  Future<List<CustomList>> getAllCustomLists() async {
    final isar = await _db;
    return await isar.customLists.where().sortByName().findAll();
  }

  /// Exclui uma lista personalizada salva
  Future<void> deleteCustomList(int id) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.customLists.delete(id);
    });
  }
}
