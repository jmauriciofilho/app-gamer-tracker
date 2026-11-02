import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Acesso ao seletor de arquivos do sistema (isolado para os testes usarem um fake)
abstract class BackupFileGateway {
  /// Abre o seletor para salvar [bytes] com o nome sugerido [fileName].
  /// Retorna `false` se o usuário cancelar.
  Future<bool> save(String fileName, Uint8List bytes);

  /// Abre o seletor para escolher um arquivo e devolve seu conteúdo.
  /// Retorna `null` se o usuário cancelar.
  Future<Uint8List?> pick();
}

/// Implementação real com o pacote `file_picker` (no Android usa o seletor do sistema, sem permissões)
class FilePickerBackupFileGateway implements BackupFileGateway {
  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'Salvar backup',
    );
    return uri != null;
  }

  @override
  Future<Uint8List?> pick() async {
    // FileType.any: o filtro por extensão é instável no Android; a validação recusa o que não for backup
    final file = await FilePicker.pickFile(dialogTitle: 'Escolher backup');
    if (file == null) return null;
    return file.readAsBytes();
  }
}
