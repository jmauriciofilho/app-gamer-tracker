import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:game_tracker/features/game_lookup/data/game_lookup_service.dart';
import 'package:game_tracker/features/game_lookup/data/models/game_lookup_result.dart';
import 'package:game_tracker/features/game_lookup/data/wikidata_game_lookup_service.dart';

// ==========================================
// RESPOSTAS GRAVADAS (formato real do Wikidata, reduzido)
// ==========================================

Map<String, Object?> _label(String language, String value) => {
  language: {'language': language, 'value': value},
};

Map<String, Object?> _itemClaim(String id) => {
  'mainsnak': {
    'datavalue': {
      'value': {'entity-type': 'item', 'id': id},
    },
  },
  'rank': 'normal',
};

Map<String, Object?> _timeClaim(String time) => {
  'mainsnak': {
    'datavalue': {
      'value': {'time': time, 'precision': 11},
    },
  },
  'rank': 'normal',
};

Map<String, Object?> _stringClaim(String value) => {
  'mainsnak': {
    'datavalue': {'value': value},
  },
  'rank': 'normal',
};

/// Busca por "Hollow Knight": o jogo, a série (não é jogo) e um jogo sem dados
const Map<String, Object?> _searchResponse = {
  'search': [
    {'id': 'Q29300592', 'label': 'Hollow Knight'},
    {'id': 'Q123017178', 'label': 'Hollow Knight'},
    {'id': 'Q900', 'label': 'Jogo Sem Dados'},
  ],
};

final Map<String, Object?> _entitiesResponse = {
  'entities': {
    'Q29300592': {
      'id': 'Q29300592',
      // Título só em "mul": precisa vencer o "en"
      'labels': {
        ..._label('mul', 'Hollow Knight'),
        ..._label('en', 'Hollow Knight (en)'),
      },
      'descriptions': _label('pt', 'videojogo de 2017'),
      'claims': {
        'P31': [_itemClaim('Q7889')],
        'P178': [_itemClaim('Q29326164')],
        'P136': [_itemClaim('Q19643088'), _itemClaim('Q1')],
        'P400': [
          _itemClaim('Q1406'),
          _itemClaim('Q14116'),
          _itemClaim('Q1406'), // repetida
        ],
        'P577': [
          _timeClaim('+2018-06-12T00:00:00Z'),
          _timeClaim('+2017-02-24T00:00:00Z'),
        ],
        'P1733': [_stringClaim('367520')],
      },
    },
    'Q123017178': {
      'id': 'Q123017178',
      'labels': _label('pt', 'Hollow Knight'),
      'claims': {
        'P31': [_itemClaim('Q7058673')], // série de jogos
      },
    },
    'Q900': {
      'id': 'Q900',
      'labels': _label('pt', 'Jogo Sem Dados'),
      'claims': {
        'P31': [_itemClaim('Q7889')],
      },
    },
  },
};

final Map<String, Object?> _labelsResponse = {
  'entities': {
    'Q29326164': {'id': 'Q29326164', 'labels': _label('mul', 'Team Cherry')},
    'Q19643088': {'id': 'Q19643088', 'labels': _label('pt', 'metroidvania')},
    'Q1406': {
      'id': 'Q1406',
      'labels': {
        ..._label('pt-br', 'Microsoft Windows'),
        ..._label('en', 'Windows'),
      },
    },
    'Q14116': {'id': 'Q14116', 'labels': _label('en', 'macOS')},
  },
};

// ==========================================
// HELPERS
// ==========================================

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Responde conforme a ação do Wikidata (busca, entidades ou rótulos)
http.Response _wikidataResponse(
  http.Request request, {
  Map<String, Object?>? search,
  Map<String, Object?>? entities,
  Map<String, Object?>? labels,
}) {
  final params = request.url.queryParameters;
  if (params['action'] == 'wbsearchentities') {
    return _json(search ?? _searchResponse);
  }
  if (params['props'] == 'labels') return _json(labels ?? _labelsResponse);
  return _json(entities ?? _entitiesResponse);
}

/// Cliente falso do Wikidata que guarda as requisições recebidas
MockClient _wikidataClient(
  List<http.Request> requests, {
  Map<String, Object?>? search,
  Map<String, Object?>? entities,
  Map<String, Object?>? labels,
}) {
  return MockClient((request) async {
    requests.add(request);
    return _wikidataResponse(
      request,
      search: search,
      entities: entities,
      labels: labels,
    );
  });
}

void main() {
  group('WikidataGameLookupService.search', () {
    test('AC1: mantém só jogos e mapeia os campos', () async {
      // Arrange
      final requests = <http.Request>[];
      final service = WikidataGameLookupService(
        client: _wikidataClient(requests),
      );

      // Act
      final results = await service.search('Hollow Knight');

      // Assert: a série (Q7058673) fica de fora
      expect(results.map((r) => r.wikidataId), ['Q29300592', 'Q900']);

      final game = results.first;
      expect(game.title, 'Hollow Knight');
      expect(game.description, 'videojogo de 2017');
      expect(game.developer, 'Team Cherry');
      expect(game.genre, 'metroidvania');
      expect(game.releaseYear, 2017);
      expect(game.platforms, ['Microsoft Windows', 'macOS']);
      expect(game.steamAppId, '367520');

      final empty = results.last;
      expect(empty.title, 'Jogo Sem Dados');
      expect(empty.developer, isNull);
      expect(empty.genre, isNull);
      expect(empty.releaseYear, isNull);
      expect(empty.platforms, isEmpty);
      expect(empty.steamAppId, isNull);

      // Pede só a 1ª desenvolvedora e o 1º gênero (Q1 não entra)
      final labelIds = requests.last.url.queryParameters['ids']!.split('|');
      expect(labelIds, isNot(contains('Q1')));
    });

    test('AC2: termo vazio não consulta a rede', () async {
      // Arrange
      final requests = <http.Request>[];
      final service = WikidataGameLookupService(
        client: _wikidataClient(requests),
      );

      // Act
      final results = await service.search('   ');

      // Assert
      expect(results, isEmpty);
      expect(requests, isEmpty);
    });

    test('AC2: devolve no máximo 10 jogos', () async {
      // Arrange
      final ids = [for (var i = 1; i <= 15; i++) 'Q$i'];
      final requests = <http.Request>[];
      final service = WikidataGameLookupService(
        client: _wikidataClient(
          requests,
          search: {
            'search': [
              for (final id in ids) {'id': id, 'label': 'Jogo $id'},
            ],
          },
          entities: {
            'entities': {
              for (final id in ids)
                id: {
                  'id': id,
                  'labels': _label('pt', 'Jogo $id'),
                  'claims': {
                    'P31': [_itemClaim('Q7889')],
                  },
                },
            },
          },
        ),
      );

      // Act
      final results = await service.search('jogo');

      // Assert
      expect(results, hasLength(10));
      expect(results.first.title, 'Jogo Q1');
    });

    test('AC2: rótulo em en é o último recurso', () async {
      // Arrange
      final service = WikidataGameLookupService(client: _wikidataClient([]));

      // Act
      final game = (await service.search('Hollow Knight')).first;

      // Assert: macOS só tem "en"; Windows tem pt-br e en
      expect(game.platforms, ['Microsoft Windows', 'macOS']);
    });

    test('AC3: falhas viram GameLookupException', () async {
      final failures = <MockClient>[
        MockClient((_) async => _json({'error': 'x'}, 500)),
        MockClient((_) async => http.Response('<html>oops</html>', 200)),
        MockClient((_) async => throw const SocketException('sem rede')),
      ];

      for (final client in failures) {
        final service = WikidataGameLookupService(client: client);
        await expectLater(
          service.search('Hollow Knight'),
          throwsA(isA<GameLookupException>()),
        );
      }
    });

    test('AC3: toda requisição tem User-Agent e host permitido', () async {
      // Arrange
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'HEAD') return http.Response('', 200);
        return _wikidataResponse(request);
      });
      final service = WikidataGameLookupService(client: client);

      // Act
      final game = (await service.search('Hollow Knight')).first;
      await service.findCoverUrl(game);

      // Assert
      expect(requests, hasLength(4)); // busca, entidades, rótulos e HEAD
      for (final request in requests) {
        expect(
          request.headers['User-Agent'],
          WikidataGameLookupService.userAgent,
        );
        expect(request.url.scheme, 'https');
        expect(
          request.url.host,
          anyOf('www.wikidata.org', 'shared.fastly.steamstatic.com'),
        );
      }
    });
  });

  group('WikidataGameLookupService.findCoverUrl', () {
    const game = GameLookupResult(
      wikidataId: 'Q29300592',
      title: 'Hollow Knight',
      steamAppId: '367520',
    );
    const coverUrl =
        'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/367520/library_600x900.jpg';

    test('AC4: HEAD 200 devolve a capa da Steam', () async {
      final service = WikidataGameLookupService(
        client: MockClient((request) async {
          expect(request.method, 'HEAD');
          return http.Response('', 200);
        }),
      );

      expect(await service.findCoverUrl(game), coverUrl);
    });

    test('AC4: 404, falha de rede ou sem id Steam devolvem null', () async {
      final notFound = WikidataGameLookupService(
        client: MockClient((_) async => http.Response('', 404)),
      );
      final offline = WikidataGameLookupService(
        client: MockClient((_) async => throw const SocketException('x')),
      );
      final requests = <http.Request>[];
      final noRequests = WikidataGameLookupService(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('', 200);
        }),
      );

      expect(await notFound.findCoverUrl(game), isNull);
      expect(await offline.findCoverUrl(game), isNull);
      expect(
        await noRequests.findCoverUrl(
          const GameLookupResult(
            wikidataId: 'Q216995',
            title: 'Super Mario 64',
          ),
        ),
        isNull,
      );
      // Id que não é numérico nunca vira URL
      expect(
        await noRequests.findCoverUrl(
          const GameLookupResult(
            wikidataId: 'Q1',
            title: 'X',
            steamAppId: '1/../../evil',
          ),
        ),
        isNull,
      );
      expect(requests, isEmpty);
    });
  });
}
