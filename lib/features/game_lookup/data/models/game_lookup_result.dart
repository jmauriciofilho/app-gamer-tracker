/// Um jogo encontrado na busca externa (Wikidata), pronto para preencher o formulário.
///
/// Todos os campos além de [wikidataId] e [title] são opcionais: os dados do
/// Wikidata variam de jogo para jogo.
class GameLookupResult {
  const GameLookupResult({
    required this.wikidataId,
    required this.title,
    this.description,
    this.developer,
    this.genre,
    this.releaseYear,
    this.platforms = const [],
    this.steamAppId,
    this.coverUrl,
  });

  /// Id do item no Wikidata (ex.: `Q29300592`)
  final String wikidataId;
  final String title;

  /// Descrição curta exibida na lista (ex.: "videojogo de 2017")
  final String? description;
  final String? developer;
  final String? genre;
  final int? releaseYear;

  /// Plataformas do jogo, sem repetição, na ordem do Wikidata
  final List<String> platforms;

  /// Id do jogo na Steam (só dígitos), usado para montar a capa
  final String? steamAppId;

  /// URL da capa confirmada (preenchida só depois de escolher o resultado)
  final String? coverUrl;

  /// Cópia com a capa resolvida
  GameLookupResult withCoverUrl(String? url) => GameLookupResult(
    wikidataId: wikidataId,
    title: title,
    description: description,
    developer: developer,
    genre: genre,
    releaseYear: releaseYear,
    platforms: platforms,
    steamAppId: steamAppId,
    coverUrl: url,
  );
}
