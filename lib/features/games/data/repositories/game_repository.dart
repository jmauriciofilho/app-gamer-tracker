import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../models/game.dart';

class GameRepository {
  // Metódo auxiliar interno para obter o banco
  Future<Isar> get _db async => await IsarService.instance;

  // ==========================================
  // 1. ESCRITA (Criar / Editar / Excluir)
  // ==========================================

  /// Salva um jogo no banco (Insere se for novo ou Atualiza se já possuir ID)
  Future<void> saveGame(Game game) async {
    final isar = await _db;

    // No Isar, qualquer operação de escrita (insert/update/delete)
    // obrigatoriamente deve ser executada dentro de uma transação (writeTxn)
    await isar.writeTxn(() async {
      await isar.games.put(game);
    });
  }

  /// Deleta um jogo pelo ID
  Future<void> deleteGame(int id) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.games.delete(id);
    });
  }

  // ==========================================
  // 2. LEITURA E CONSULTAS (MVP)
  // ==========================================

  /// Busca todos os jogos ordenados por data de criação (mais recentes primeiro)
  Future<List<Game>> getAllGames() async {
    final isar = await _db;
    return await isar.games.where().sortByCreatedAtDesc().findAll();
  }

  /// Busca jogos filtrados por um Status específico ('para_jogar', '100%', etc)
  Future<List<Game>> getGamesByStatus(String status) async {
    final isar = await _db;
    return await isar.games
        .filter()
        .statusEqualTo(status)
        .sortByTitle() // Ordena alfabeticamente
        .findAll();
  }

  /// Busca rápida por nome do jogo (usado na barra de pesquisa da Home)
  Future<List<Game>> searchGamesByTitle(String query) async {
    if (query.trim().isEmpty) return getAllGames();

    final isar = await _db;
    return await isar.games
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
  }

  // ==========================================
  // 3. CONSULTA DINÂMICA (Listas Personalizadas)
  // ==========================================

  /// Executa filtros combinados para responder às Listas Personalizadas
  /// Exemplo: Plataforma "PS1" + Desenvolvedora "FromSoftware"
  /// Textos comparam por "contém" sem diferenciar maiúsculas; anos são inclusivos
  /// e jogos sem o campo (ano de lançamento ou data de término) ficam de fora
  Future<List<Game>> getGamesByCustomFilter({
    String? developer,
    String? platform,
    String? genre,
    String? status,
    String? title,
    int? releaseYearFrom,
    int? releaseYearTo,
    int? endYear,
  }) async {
    final isar = await _db;

    // 1. Iniciamos a consulta na coleção de jogos
    QueryBuilder<Game, Game, QAfterFilterCondition> query = isar.games
        .filter()
        .idGreaterThan(-1);

    // 2. Aplica o filtro de desenvolvedora se foi informado
    if (developer != null && developer.isNotEmpty) {
      query = query.and().developerContains(developer, caseSensitive: false);
    }

    // 3. Aplica o filtro de plataforma se foi informado
    if (platform != null && platform.isNotEmpty) {
      query = query.and().platformContains(platform, caseSensitive: false);
    }

    // 4. Aplica o filtro de gênero se foi informado
    if (genre != null && genre.isNotEmpty) {
      query = query.and().genreContains(genre, caseSensitive: false);
    }

    // 5. Aplica o filtro de status se foi informado
    if (status != null && status.isNotEmpty) {
      query = query.and().statusEqualTo(status);
    }

    // 6. Aplica o filtro de título se foi informado
    if (title != null && title.isNotEmpty) {
      query = query.and().titleContains(title, caseSensitive: false);
    }

    // 7. Aplica o intervalo de ano de lançamento se algum lado foi informado
    // No Isar o nulo é menor que qualquer valor: o limite inferior 0 exclui jogos sem ano
    if (releaseYearFrom != null || releaseYearTo != null) {
      query = query.and().releaseYearBetween(
        releaseYearFrom ?? 0,
        releaseYearTo ?? 9999,
      );
    }

    // 8. Aplica o ano de término: de 1º de janeiro até antes de 1º de janeiro do ano seguinte
    if (endYear != null) {
      query = query.and().endDateBetween(
        DateTime(endYear),
        DateTime(endYear + 1),
        includeUpper: false,
      );
    }

    // 9. Executa e retorna os jogos que atendem a TODOS os critérios
    return await query.findAll();
  }

  /// Busca um jogo específico pelo seu ID no banco de dados Isar
  Future<Game?> getGameById(int id) async {
    final isar = await _db;
    return await isar.games.get(id);
  }
}
