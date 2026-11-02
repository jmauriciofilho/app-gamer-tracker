import 'dart:convert';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';

import '../../custom_lists/data/models/custom_list.dart';
import '../../games/data/models/game.dart';

/// Conteúdo de um backup: todos os jogos e todas as listas personalizadas
class BackupData {
  const BackupData({required this.games, required this.customLists});

  final List<Game> games;
  final List<CustomList> customLists;
}

/// Erro de arquivo de backup inválido ou incompatível (mensagem pronta para a UI)
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Converte [BackupData] em JSON e vice-versa (formato versão 1)
class BackupCodec {
  /// Identificador gravado no arquivo para reconhecer backups deste app
  static const String appId = 'game_tracker';

  /// Versão atual do formato do arquivo
  static const int formatVersion = 1;

  static const String invalidFileMessage = 'Arquivo de backup inválido';
  static const String unsupportedVersionMessage =
      'Versão de backup não suportada';

  /// Gera o JSON (UTF-8) com todos os jogos e listas
  static Uint8List encode(BackupData data, {DateTime? exportedAt}) {
    final json = <String, Object?>{
      'app': appId,
      'version': formatVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'games': data.games.map(_gameToJson).toList(),
      'customLists': data.customLists.map(_customListToJson).toList(),
    };
    return utf8.encode(const JsonEncoder.withIndent('  ').convert(json));
  }

  /// Lê e valida o arquivo inteiro.
  /// Lança [BackupFormatException] se qualquer parte for inválida, sem devolver dados parciais.
  static BackupData decode(List<int> bytes) {
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupFormatException(invalidFileMessage);
    }

    if (root is! Map<String, Object?> || root['app'] != appId) {
      throw const BackupFormatException(invalidFileMessage);
    }

    final version = root['version'];
    if (version is! int) {
      throw const BackupFormatException(invalidFileMessage);
    }
    if (version > formatVersion) {
      throw const BackupFormatException(unsupportedVersionMessage);
    }

    final games = root['games'];
    final customLists = root['customLists'];
    if (games is! List || customLists is! List) {
      throw const BackupFormatException(invalidFileMessage);
    }

    return BackupData(
      games: games.map((item) => _gameFromJson(_asMap(item))).toList(),
      customLists: customLists
          .map((item) => _customListFromJson(_asMap(item)))
          .toList(),
    );
  }

  // ==========================================
  // JOGOS
  // ==========================================

  static Map<String, Object?> _gameToJson(Game game) => {
    'id': game.id,
    'title': game.title,
    'developer': game.developer,
    'genre': game.genre,
    'platform': game.platform,
    'releaseYear': game.releaseYear,
    'coverUrl': game.coverUrl,
    'status': game.status,
    'rating': game.rating,
    'startDate': game.startDate?.toIso8601String(),
    'endDate': game.endDate?.toIso8601String(),
    'createdAt': game.createdAt.toIso8601String(),
  };

  static Game _gameFromJson(Map<String, Object?> json) {
    final game = Game()
      ..id = _optionalInt(json['id']) ?? Isar.autoIncrement
      ..title = _requiredString(json['title'])
      ..developer = _optionalString(json['developer'])
      ..genre = _optionalString(json['genre'])
      ..platform = _optionalString(json['platform'])
      ..releaseYear = _optionalInt(json['releaseYear'])
      ..coverUrl = _optionalString(json['coverUrl'])
      ..status = _requiredString(json['status'])
      ..rating = _optionalDouble(json['rating']) ?? 0.0
      ..startDate = _optionalDate(json['startDate'])
      ..endDate = _optionalDate(json['endDate']);

    // Sem createdAt no arquivo, mantém o padrão do modelo (agora)
    final createdAt = _optionalDate(json['createdAt']);
    if (createdAt != null) game.createdAt = createdAt;

    return game;
  }

  // ==========================================
  // LISTAS PERSONALIZADAS
  // ==========================================

  static Map<String, Object?> _customListToJson(CustomList list) => {
    'id': list.id,
    'name': list.name,
    'filterDeveloper': list.filterDeveloper,
    'filterPlatform': list.filterPlatform,
    'filterGenre': list.filterGenre,
    'filterStatus': list.filterStatus,
    'filterTitle': list.filterTitle,
    'filterReleaseYearFrom': list.filterReleaseYearFrom,
    'filterReleaseYearTo': list.filterReleaseYearTo,
    'filterEndYear': list.filterEndYear,
  };

  static CustomList _customListFromJson(Map<String, Object?> json) {
    return CustomList()
      ..id = _optionalInt(json['id']) ?? Isar.autoIncrement
      ..name = _requiredString(json['name'])
      ..filterDeveloper = _optionalString(json['filterDeveloper'])
      ..filterPlatform = _optionalString(json['filterPlatform'])
      ..filterGenre = _optionalString(json['filterGenre'])
      ..filterStatus = _optionalString(json['filterStatus'])
      ..filterTitle = _optionalString(json['filterTitle'])
      ..filterReleaseYearFrom = _optionalInt(json['filterReleaseYearFrom'])
      ..filterReleaseYearTo = _optionalInt(json['filterReleaseYearTo'])
      ..filterEndYear = _optionalInt(json['filterEndYear']);
  }

  // ==========================================
  // VALIDAÇÃO DE CAMPOS
  // ==========================================

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const BackupFormatException(invalidFileMessage);
  }

  static String _requiredString(Object? value) {
    if (value is String) return value;
    throw const BackupFormatException(invalidFileMessage);
  }

  static String? _optionalString(Object? value) {
    if (value == null || value is String) return value as String?;
    throw const BackupFormatException(invalidFileMessage);
  }

  static int? _optionalInt(Object? value) {
    if (value == null || value is int) return value as int?;
    throw const BackupFormatException(invalidFileMessage);
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw const BackupFormatException(invalidFileMessage);
  }

  static DateTime? _optionalDate(Object? value) {
    if (value == null) return null;
    final date = value is String ? DateTime.tryParse(value) : null;
    if (date != null) return date;
    throw const BackupFormatException(invalidFileMessage);
  }
}
