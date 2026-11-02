import '../../data/models/game.dart';

/// Ordens disponíveis na Biblioteca, na ordem em que aparecem no menu "Ordenar".
///
/// Cada opção tem direção fixa (a mais natural para ela).
enum GameSortOrder {
  recent('Recentes'),
  title('Título A–Z'),
  rating('Maior nota');

  final String label;

  const GameSortOrder(this.label);

  /// Comparador usado em `List.sort` para esta ordem
  int compare(Game a, Game b) {
    switch (this) {
      case GameSortOrder.recent:
        // Adicionados mais recentemente primeiro
        return b.createdAt.compareTo(a.createdAt);
      case GameSortOrder.title:
        return _compareTitle(a, b);
      case GameSortOrder.rating:
        // Maior nota primeiro; empate desempata pelo título
        final byRating = b.rating.compareTo(a.rating);
        return byRating != 0 ? byRating : _compareTitle(a, b);
    }
  }

  /// Título A–Z sem diferenciar maiúsculas
  static int _compareTitle(Game a, Game b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());
}
