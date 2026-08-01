import 'package:isar_community/isar.dart';

// Este 'part' faz o Isar entender que vai gerar o arquivo 'game.g.dart' automaticamente.
part 'game.g.dart';

@collection
class Game {
  // 1. Identificador Único
  // O Isar exige um id. Com Isar.autoIncrement, o próprio banco atribui 1, 2, 3...
  Id id = Isar.autoIncrement;

  // 2. Título do Jogo com Índice
  // Usamos @Index() para permitir buscas ultra-rápidas e ordenação por nome.
  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  // 3. Informações de Mídia e Desenvolvimento
  String? developer; // Ex: "FromSoftware", "Capcom"
  String? genre; // Ex: "RPG", "Hack and Slash"
  String? platform; // Ex: "PS1", "PS5", "PC", "Nintendo Switch"
  int? releaseYear; // Ex: 1998, 2022
  String? coverUrl; // URL de imagem na web ou caminho local

  // 4. Status do Jogo com Índice
  // Índices em campos de filtro (como status) tornam as abas da HomeScreen instantâneas.
  // Valores esperados: 'para_jogar', 'jogando', 'jogado', 'finalizado', '100%'
  @Index()
  late String status;

  // 5. Avaliação Pessoal
  // Nota de 0.0 a 5.0 (usada com a lib flutter_rating_bar)
  double rating = 0.0;

  // 6. Datas de Acompanhamento
  DateTime? startDate; // Data em que você começou a jogar
  DateTime? endDate; // Data em que zerou/platinou

  // 7. Controle Interno
  // Guarda quando o registro foi criado no app
  DateTime createdAt = DateTime.now();
}
