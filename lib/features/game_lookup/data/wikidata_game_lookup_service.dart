import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'game_lookup_service.dart';
import 'models/game_lookup_result.dart';

/// Busca jogos no Wikidata (sem chave) e a capa no CDN da Steam.
///
/// Fluxo de uma busca:
/// 1. `wbsearchentities` encontra itens pelo nome;
/// 2. `wbgetentities` traz as propriedades e mantém só jogos eletrônicos (P31 = Q7889);
/// 3. `wbgetentities` traz os rótulos de desenvolvedora, plataformas e gêneros (lotes de 50).
class WikidataGameLookupService implements GameLookupService {
  WikidataGameLookupService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String wikidataHost = 'www.wikidata.org';
  static const String steamHost = 'shared.fastly.steamstatic.com';

  /// Identificação exigida pela política de User-Agent da Wikimedia
  static const String userAgent =
      'game_tracker/1.0 (app pessoal; https://github.com/jmauriciofilho/app-gamer-tracker)';

  static const Duration timeout = Duration(seconds: 10);
  static const int maxResults = 10;

  static const String _videoGame = 'Q7889';

  /// `mul` (multilíngue) é onde o Wikidata guarda muitos nomes próprios, como títulos de jogos
  static const List<String> _languages = ['pt-br', 'pt', 'mul', 'en'];
  static const int _maxIdsPerRequest = 50;

  static const Map<String, String> _headers = {'User-Agent': userAgent};

  @override
  Future<List<GameLookupResult>> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    // 1. Itens cujo nome casa com o termo
    final found = await _getJson({
      'action': 'wbsearchentities',
      'search': term,
      'language': 'pt',
      'uselang': 'pt',
      'type': 'item',
      'limit': '20',
      'format': 'json',
    });
    // Rótulo que a própria busca devolve: reserva caso a entidade não tenha um nos idiomas aceitos
    final searchLabels = <String, String>{};
    for (final item in _list(found['search'])) {
      final id = _map(item)['id'];
      final label = _map(item)['label'];
      if (id is String) searchLabels[id] = label is String ? label : '';
    }
    final ids = searchLabels.keys.toList();
    if (ids.isEmpty) return [];

    // 2. Propriedades dos itens; fica só o que é jogo eletrônico
    final entities = await _getEntities(ids, 'claims|labels|descriptions');
    final games = ids
        .map((id) => entities[id])
        .whereType<Map<String, Object?>>()
        .where((entity) => _claimIds(entity, 'P31').contains(_videoGame))
        .take(maxResults)
        .toList();
    if (games.isEmpty) return [];

    // 3. Rótulos de desenvolvedora (1ª), gênero (1º) e todas as plataformas
    final referenced = <String>{
      for (final game in games) ...[
        ..._claimIds(game, 'P178').take(1),
        ..._claimIds(game, 'P136').take(1),
        ..._claimIds(game, 'P400'),
      ],
    };
    final labels = <String, String>{};
    final referencedList = referenced.toList();
    for (var i = 0; i < referencedList.length; i += _maxIdsPerRequest) {
      final chunk = referencedList.skip(i).take(_maxIdsPerRequest).toList();
      final labelEntities = await _getEntities(chunk, 'labels');
      for (final entry in labelEntities.entries) {
        final label = _text(entry.value, 'labels');
        if (label != null) labels[entry.key] = label;
      }
    }

    return games
        .map((game) => _toResult(game, labels, searchLabels))
        .where((result) => result.title.isNotEmpty)
        .toList();
  }

  @override
  Future<String?> findCoverUrl(GameLookupResult result) async {
    final appId = result.steamAppId;
    // Só aceita id numérico: a URL é sempre montada aqui, no domínio da Steam
    if (appId == null || !RegExp(r'^\d+$').hasMatch(appId)) return null;

    final url = Uri.https(
      steamHost,
      '/store_item_assets/steam/apps/$appId/library_600x900.jpg',
    );
    try {
      final response = await _client
          .head(url, headers: _headers)
          .timeout(timeout);
      return response.statusCode == 200 ? url.toString() : null;
    } catch (_) {
      // Sem capa é um resultado aceitável; não interrompe o preenchimento
      return null;
    }
  }

  // ==========================================
  // REQUISIÇÕES
  // ==========================================

  Future<Map<String, Object?>> _getEntities(
    List<String> ids,
    String props,
  ) async {
    final json = await _getJson({
      'action': 'wbgetentities',
      'ids': ids.join('|'),
      'props': props,
      'languages': _languages.join('|'),
      'format': 'json',
    });
    final entities = json['entities'];
    if (entities is! Map<String, Object?>) {
      throw const GameLookupException('resposta sem "entities"');
    }
    return entities;
  }

  Future<Map<String, Object?>> _getJson(Map<String, String> params) async {
    final url = Uri.https(wikidataHost, '/w/api.php', params);
    final http.Response response;
    try {
      response = await _client.get(url, headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw const GameLookupException('tempo esgotado');
    } catch (error) {
      throw GameLookupException('falha de rede: $error');
    }

    if (response.statusCode != 200) {
      throw GameLookupException('HTTP ${response.statusCode}');
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, Object?>) return json;
    } on FormatException {
      // tratado abaixo
    }
    throw const GameLookupException('resposta não é um objeto JSON');
  }

  // ==========================================
  // LEITURA DO FORMATO DO WIKIDATA
  // ==========================================

  GameLookupResult _toResult(
    Map<String, Object?> game,
    Map<String, String> labels,
    Map<String, String> searchLabels,
  ) {
    final id = _map(game)['id'] as String? ?? '';

    String? labelOf(String property) {
      final ids = _claimIds(game, property);
      return ids.isEmpty ? null : labels[ids.first];
    }

    final platforms = <String>[];
    for (final id in _claimIds(game, 'P400')) {
      final label = labels[id];
      if (label != null && !platforms.contains(label)) platforms.add(label);
    }

    final years = _claimValues(game, 'P577')
        .map((value) => _map(value)['time'])
        .whereType<String>()
        .map(_yearOf)
        .whereType<int>();

    final steamIds = _claimValues(game, 'P1733').whereType<String>();

    return GameLookupResult(
      wikidataId: id,
      title: _text(game, 'labels') ?? searchLabels[id] ?? '',
      description: _text(game, 'descriptions'),
      developer: labelOf('P178'),
      genre: labelOf('P136'),
      releaseYear: years.isEmpty ? null : years.reduce((a, b) => a < b ? a : b),
      platforms: platforms,
      steamAppId: steamIds.isEmpty ? null : steamIds.first,
    );
  }

  /// Texto em pt-br → pt → mul → en de `labels` ou `descriptions`
  static String? _text(Object? entity, String field) {
    final texts = _map(_map(entity)[field]);
    for (final language in _languages) {
      final value = _map(texts[language])['value'];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Valores das afirmações de uma propriedade, ignorando as depreciadas
  static List<Object?> _claimValues(Object? entity, String property) {
    final claims = _list(_map(_map(entity)['claims'])[property]);
    return [
      for (final claim in claims)
        if (_map(claim)['rank'] != 'deprecated')
          _map(_map(_map(claim)['mainsnak'])['datavalue'])['value'],
    ].where((value) => value != null).toList();
  }

  /// Ids de itens (Qxxx) referenciados por uma propriedade
  static List<String> _claimIds(Object? entity, String property) =>
      _claimValues(
        entity,
        property,
      ).map((value) => _map(value)['id']).whereType<String>().toList();

  /// Ano de um tempo do Wikidata (`+2017-02-24T00:00:00Z`); ignora anos negativos
  static int? _yearOf(String time) {
    final match = RegExp(r'^\+(\d{1,4})-').firstMatch(time);
    return match == null ? null : int.parse(match.group(1)!);
  }

  static Map<String, Object?> _map(Object? value) =>
      value is Map<String, Object?> ? value : const {};

  static List<Object?> _list(Object? value) =>
      value is List<Object?> ? value : const [];
}
