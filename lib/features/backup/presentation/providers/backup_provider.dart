import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup_codec.dart';
import '../../data/backup_file_gateway.dart';
import '../../data/backup_repository.dart';
import '../../../custom_lists/presentation/providers/custom_list_provider.dart';
import '../../../games/presentation/providers/game_list_provider.dart';

/// Provider que expõe a instância do BackupRepository
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository();
});

/// Provider do seletor de arquivos (sobrescrito por um fake nos testes)
final backupFileGatewayProvider = Provider<BackupFileGateway>((ref) {
  return FilePickerBackupFileGateway();
});

/// Provider do controlador de backup usado pela aba Configurações
final backupControllerProvider = Provider<BackupController>((ref) {
  return BackupController(ref);
});

/// Orquestra exportação e restauração: repositório + codec + seletor de arquivos
class BackupController {
  BackupController(this._ref);

  final Ref _ref;

  /// Nome sugerido para o arquivo: game_tracker_backup_AAAA-MM-DD.json
  static String fileNameFor(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'game_tracker_backup_${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}.json';
  }

  /// Exporta todos os dados para um arquivo escolhido pelo usuário.
  /// Retorna os dados exportados, ou `null` se o usuário cancelar. Lança exceção em caso de falha.
  Future<BackupData?> exportBackup() async {
    final data = await _ref.read(backupRepositoryProvider).readAll();
    final now = DateTime.now();
    final saved = await _ref
        .read(backupFileGatewayProvider)
        .save(fileNameFor(now), BackupCodec.encode(data, exportedAt: now));
    return saved ? data : null;
  }

  /// Abre o seletor e valida o arquivo escolhido, sem gravar nada.
  /// Retorna `null` se o usuário cancelar; lança [BackupFormatException] se o arquivo for inválido.
  Future<BackupData?> pickBackup() async {
    final bytes = await _ref.read(backupFileGatewayProvider).pick();
    if (bytes == null) return null;
    return BackupCodec.decode(bytes);
  }

  /// Dados atuais do banco (usados para mostrar as contagens na confirmação)
  Future<BackupData> currentData() {
    return _ref.read(backupRepositoryProvider).readAll();
  }

  /// Substitui todos os dados pelos do backup e recarrega as abas Biblioteca e Listas
  Future<void> restore(BackupData data) async {
    // A escrita fica fora de qualquer guard: se falhar, a exceção chega à tela
    await _ref.read(backupRepositoryProvider).replaceAll(data);

    // Providers derivados (contagens e detalhes de listas) observam estes dois e recarregam juntos
    _ref.invalidate(gameListProvider);
    _ref.invalidate(customListProvider);
  }
}
