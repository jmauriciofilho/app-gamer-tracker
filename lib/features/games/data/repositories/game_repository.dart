import 'package:isar/isar.dart';
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
  Future<List<Game>> getGamesByCustomFilter({
    String? developer,
    String? platform,
    String? genre,
    String? status,
  }) async {
    final isar = await _db;

    // 1. Iniciamos a consulta na coleção de jogos
    QueryBuilder<Game, Game, QAfterFilterCondition> query = isar.games
        .filter()
        .idGreaterThan(-1);

    // 2. Aplica o filtro de desenvolvedora se foi informado
    if (developer != null && developer.isNotEmpty) {
      query = query.and().developerEqualTo(developer, caseSensitive: false);
    }

    // 3. Aplica o filtro de plataforma se foi informado
    if (platform != null && platform.isNotEmpty) {
      query = query.and().platformEqualTo(platform, caseSensitive: false);
    }

    // 4. Aplica o filtro de gênero se foi informado
    if (genre != null && genre.isNotEmpty) {
      query = query.and().genreEqualTo(genre, caseSensitive: false);
    }

    // 5. Aplica o filtro de status se foi informado
    if (status != null && status.isNotEmpty) {
      query = query.and().statusEqualTo(status);
    }

    // 6. Executa e retorna os jogos que atendem a TODOS os critérios
    return await query.findAll();
  }
}
