import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup_codec.dart';
import '../providers/backup_provider.dart';

/// Seção "Backup local" da aba Configurações: exporta e importa todos os dados em JSON
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  // Evita toques repetidos enquanto o seletor ou a gravação estão em andamento
  bool _busy = false;

  /// "1 jogo" / "3 jogos"
  static String _countGames(int count) =>
      '$count ${count == 1 ? 'jogo' : 'jogos'}';

  /// "1 lista" / "3 listas"
  static String _countLists(int count) =>
      '$count ${count == 1 ? 'lista' : 'listas'}';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _runBusy(() async {
    try {
      final data = await ref.read(backupControllerProvider).exportBackup();
      // Usuário cancelou o seletor: nada a avisar
      if (data == null) return;
      _showMessage(
        'Backup exportado: ${_countGames(data.games.length)}, '
        '${_countLists(data.customLists.length)}',
      );
    } catch (_) {
      _showMessage('Erro ao exportar backup');
    }
  });

  Future<void> _import() => _runBusy(() async {
    final controller = ref.read(backupControllerProvider);

    // 1. Lê e valida o arquivo inteiro antes de qualquer escrita
    final BackupData? backup;
    final BackupData current;
    try {
      backup = await controller.pickBackup();
      if (backup == null) return;
      current = await controller.currentData();
    } on BackupFormatException catch (error) {
      _showMessage(error.message);
      return;
    } catch (_) {
      _showMessage('Erro ao importar backup');
      return;
    }

    // 2. Confirma a substituição mostrando as contagens
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Text(
          'Substituir ${_countGames(current.games.length)} e '
          '${_countLists(current.customLists.length)} atuais por '
          '${_countGames(backup!.games.length)} e '
          '${_countLists(backup.customLists.length)} do backup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Substituir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 3. Substitui tudo numa única transação
    try {
      await controller.restore(backup);
      _showMessage(
        'Backup restaurado: ${_countGames(backup.games.length)}, '
        '${_countLists(backup.customLists.length)}',
      );
    } catch (_) {
      _showMessage('Erro ao restaurar backup');
    }
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          leading: Icon(Icons.save_alt, size: 40),
          title: Text('Backup local'),
          subtitle: Text(
            'Salve seus jogos e listas num arquivo JSON. '
            'Importar um backup substitui todos os dados atuais.',
          ),
        ),
        const Divider(),
        ElevatedButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.upload_file),
          label: const Text('Exportar backup'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _import,
          icon: const Icon(Icons.file_open),
          label: const Text('Importar backup'),
        ),
      ],
    );
  }
}
