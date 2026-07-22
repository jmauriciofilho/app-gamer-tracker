import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Importamos os esquemas gerados automaticamente pelo build_runner
import '../../features/games/data/models/game.dart';
import '../../features/custom_lists/data/models/custom_list.dart';

class IsarService {
  static Isar? _instance;

  /// Retorna a instância única do Isar (Singleton)
  static Future<Isar> get instance async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    _instance = await _init();
    return _instance!;
  }

  /// Método privado responsável por abrir a conexão com o banco local
  static Future<Isar> _init() async {
    // 1. Descobre o diretório de arquivos do app no sistema operacional (Android/Linux)
    final dir = await getApplicationDocumentsDirectory();

    // 2. Abre a instância registrando as duas coleções (Game e CustomList)
    return await Isar.open(
      [
        GameSchema, // Esquema gerado no game.g.dart
        CustomListSchema, // Esquema gerado no custom_list.g.dart
      ],
      directory: dir.path,
      name: 'game_tracker_db', // Nome do arquivo do banco
    );
  }
}
