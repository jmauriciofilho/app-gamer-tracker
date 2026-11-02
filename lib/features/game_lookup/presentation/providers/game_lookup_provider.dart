import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/game_lookup_service.dart';
import '../../data/wikidata_game_lookup_service.dart';

/// Provider do serviço de busca de dados do jogo (sobrescrito por um fake nos testes)
final gameLookupServiceProvider = Provider<GameLookupService>((ref) {
  return WikidataGameLookupService();
});
