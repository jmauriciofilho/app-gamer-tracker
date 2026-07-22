import 'package:isar/isar.dart';

// O Isar vai gerar o arquivo 'custom_list.g.dart'
part 'custom_list.g.dart';

@collection
class CustomList {
  // Identificador Único
  Id id = Isar.autoIncrement;

  // Nome exibido no Card da lista (Ex: "Jogos da FromSoftware", "Rassuragem RPGs")
  late String name;

  // CRITÉRIOS DE FILTRO (Todos opcionais):
  // Se o campo for nulo, significa que a lista ignora aquele filtro.

  String?
  filterDeveloper; // Ex: Se "FromSoftware", busca apenas jogos dessa empresa
  String? filterPlatform; // Ex: Se "PS1", traz apenas jogos de PlayStation 1
  String? filterGenre; // Ex: Se "RPG", traz apenas os do gênero RPG
  String? filterStatus; // Ex: Se "100%", traz apenas os que você platinou
}
