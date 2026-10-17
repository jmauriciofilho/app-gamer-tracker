# 🧠 Aprendizados do Projeto

> O agente LÊ este arquivo no início de cada conversa e ESCREVE nele ao fim de cada tarefa (skill `memoria`).
> Regras: entradas curtas, factuais, sem duplicatas, sem segredos. Máx. ~150 linhas (consolide as antigas).

## Formato
`- [AAAA-MM-DD] [categoria] Aprendizado. → Ação/regra para o futuro.`
Categorias: `build`, `test`, `arquitetura`, `convenção`, `armadilha`, `preferência-do-usuário`, `ambiente`.

## Entradas
- [2026-10-17] [test] Widget tests não podem abrir o Isar real. → Sobrescrever `gameRepositoryProvider` com um fake (`extends GameRepository`) via `ProviderScope(overrides: ...)`, como em `test/widget_test.dart`.
- [2026-10-17] [build] `flutter analyze` retorna erro até com issues de nível info (ex.: deprecated_member_use), o que quebra o `verify.sh`. → Zerar todas as issues, inclusive infos.
- [2026-10-17] [convenção] `DropdownButtonFormField.value` está obsoleto. → Usar `initialValue`.
- [2026-10-17] [armadilha] `HomeScreen` usa `IndexedStack`: todas as abas são construídas ao abrir o app, então todo teste que monte `MyApp` precisa sobrescrever `gameRepositoryProvider` E `customListRepositoryProvider`. → Ao criar aba/provider novo com repositório, atualizar os overrides de `test/widget_test.dart`.
- [2026-10-17] [arquitetura] Providers derivados de jogos (`customListGamesProvider`, `gameFilterOptionsProvider`) fazem `ref.watch(gameListProvider)` para reagir a CRUD de jogos. → Seguir o mesmo padrão; usar `int id` (não objetos Isar, que não têm `==`) como chave de `.family`.
- [2026-10-17] [arquitetura] Escrita (save/delete) dentro de `AsyncValue.guard` engolia a falha: a tela mostrava sucesso e a lista inteira virava estado de erro. → Nos notifiers, a escrita fica FORA do guard (a exceção sobe) e só a recarga usa guard; as telas fazem try/catch, exibem SnackBar de erro e não fecham (ver `test/features/save_feedback_test.dart`).
- [2026-10-17] [test] Para testar formulário que faz `Navigator.pop`, empilhe a tela sobre uma rota base (botão que dá `push`); para autocomplete use `RawAutocomplete` com controller próprio e procure as sugestões com `find.widgetWithText(ListTile, ...)`.
