# 📋 Especificação: Telas de Listas Personalizadas

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Escopo estrito da execução. Leia `.agent/project_instructions.md` antes de começar.
> Marque `[x]` em cada passo do `<execution_plan>` ao concluir. Não toque arquivos fora de `<files_in_scope>`.

<specification_meta>
- **Status:** Completed
- **Data de Criação:** 2026-10-17
- **Slug:** telas-listas-personalizadas
- **Tamanho (triagem):** feature
</specification_meta>

<context>
  - **O que estamos construindo:** A UI da aba "Minhas Listas": listagem das listas personalizadas (cards), formulário de criação/edição e tela de detalhe com os jogos que atendem aos filtros da lista, incluindo exclusão com confirmação.
  - **Motivação:** Model (`CustomList`), repository e providers já existem, mas a aba exibe apenas um placeholder. O usuário não consegue criar nem consultar listas.
  - **Base existente:** `CustomListRepository` (save/getAll/delete), `customListProvider` (AsyncNotifier), `customListGamesProvider` (family por objeto `CustomList`, sem reatividade a mudanças de jogos) e `GameRepository.getGamesByCustomFilter` (igualdade exata, case-insensitive).
</context>

<requirements>
  - [x] R1: A aba "Minhas Listas" exibe um card por lista salva (ordenadas por nome), com nome, filtros ativos como chips e quantidade de jogos que atendem aos filtros.
  - [x] R2: Sem listas salvas, a aba exibe um estado vazio com a mensagem "Nenhuma lista criada ainda."
  - [x] R3: Na aba "Minhas Listas", o FAB "Nova Lista" abre o formulário de criação. O FAB "Novo Jogo" continua exclusivo da aba Biblioteca.
  - [x] R4: O formulário possui: nome (texto), desenvolvedora, plataforma e gênero (texto com sugestões de autocompletar vindas dos valores distintos já cadastrados nos jogos, permitindo valor livre) e status (dropdown com opção "Qualquer" + os 5 status existentes).
  - [x] R5: Validação: nome obrigatório (não vazio após trim) e pelo menos 1 filtro preenchido. Valores de texto são salvos com trim; campos vazios são salvos como `null`.
  - [x] R6: O mesmo formulário edita uma lista existente (campos pré-preenchidos; salvar atualiza o mesmo id, sem duplicar).
  - [x] R7: Tocar em um card abre a tela de detalhe da lista: título = nome da lista, grade de jogos reaproveitando `GameCard`; tocar em um jogo abre `GameDetailScreen`. Sem jogos correspondentes, exibe "Nenhum jogo corresponde aos filtros desta lista."
  - [x] R8: A tela de detalhe tem ações de editar (abre o formulário) e excluir (diálogo de confirmação; ao confirmar, remove a lista, volta para a aba e exibe SnackBar "<nome> foi removida.").
  - [x] R9: Os jogos de uma lista (detalhe e contagem do card) são reavaliados automaticamente quando jogos são criados, editados ou excluídos, e quando a própria lista é editada.
  - [x] R10: A comparação dos filtros permanece exata e case-insensitive (comportamento atual de `getGamesByCustomFilter`).
</requirements>

<acceptance_criteria>
  - AC1 (R1): Dado 2 listas salvas "RPGs" (gênero=RPG) e "Ação" (gênero=Ação) e 3 jogos com gênero RPG, quando a aba "Minhas Listas" abre, então aparecem 2 cards na ordem "Ação", "RPGs"; o card "RPGs" mostra o chip "RPG" e o texto "3 jogos" (singular "1 jogo").
  - AC2 (R2): Dado nenhuma lista salva, quando a aba abre, então o texto "Nenhuma lista criada ainda." é exibido.
  - AC3 (R3): Dado a aba "Minhas Listas" ativa, então existe um FAB com texto "Nova Lista" e não existe "Novo Jogo"; ao tocar, a tela "Nova Lista" é aberta. Na aba Biblioteca, existe "Novo Jogo" e não existe "Nova Lista".
  - AC4 (R4): Dado jogos com desenvolvedoras "FromSoftware" e "Capcom", quando o usuário digita "fro" no campo desenvolvedora, então a sugestão "FromSoftware" é exibida; o dropdown de status contém "Qualquer", "Para Jogar", "Jogando", "Jogado", "Finalizado" e "100%".
  - AC5 (R5): Quando o usuário salva com nome vazio, então "Informe o nome da lista" é exibido e nada é salvo. Quando salva com nome preenchido e nenhum filtro, então "Preencha pelo menos um filtro" é exibido e nada é salvo. Quando salva nome "  RPGs " e gênero " RPG ", então a lista é persistida com name="RPGs", filterGenre="RPG" e os demais filtros `null`.
  - AC6 (R6): Dado a lista id=1 "RPGs", quando o usuário a edita para "RPGs Favoritos" e salva, então o repositório contém 1 lista com id=1 e nome "RPGs Favoritos".
  - AC7 (R7): Dado a lista "RPGs" com 2 jogos correspondentes, quando o card é tocado, então a AppBar mostra "RPGs" e os 2 títulos de jogos aparecem; dada uma lista sem jogos correspondentes, então "Nenhum jogo corresponde aos filtros desta lista." aparece.
  - AC8 (R8): Dado a tela de detalhe da lista "RPGs", quando o usuário toca em excluir e confirma, então a lista é removida do repositório, a tela fecha e o SnackBar "RPGs foi removida." aparece; ao cancelar, nada é removido.
  - AC9 (R9): Dado o `customListGamesProvider(id)` com 1 jogo, quando um novo jogo que atende ao filtro é salvo via `gameListProvider.notifier.saveGame`, então o provider passa a retornar 2 jogos sem invalidação manual.
  - AC10 (R10): `GameRepository.getGamesByCustomFilter` não é alterado (verificado no diff).
  - AC-G1: `flutter analyze` sem issues e `flutter test` verde (`.agent/scripts/verify.sh lint test`).
  - AC-G2: tipagem explícita nas classes, providers e métodos públicos novos.
  - AC-G3: nenhuma dependência nova (autocomplete via `Autocomplete` do Material).
</acceptance_criteria>

<files_in_scope>
  - `lib/features/custom_lists/presentation/providers/custom_list_provider.dart` — editar: `customListGamesProvider` passa a ser family por `int id` e observa `customListProvider` + `gameListProvider`; novo `gameFilterOptionsProvider` (valores distintos de desenvolvedora/plataforma/gênero).
  - `lib/features/custom_lists/presentation/screens/custom_lists_view.dart` — criar: conteúdo da aba (lista de cards, estado vazio/carregando/erro).
  - `lib/features/custom_lists/presentation/screens/custom_list_form_screen.dart` — criar: formulário de criação/edição.
  - `lib/features/custom_lists/presentation/screens/custom_list_detail_screen.dart` — criar: grade de jogos da lista, editar e excluir.
  - `lib/features/custom_lists/presentation/widgets/custom_list_card.dart` — criar: card com nome, chips de filtros e contagem.
  - `lib/features/games/presentation/screens/home_screen.dart` — editar: aba 2 usa `CustomListsView`; FAB varia por aba.
  - `test/widget_test.dart` — editar (autorizado em 2026-10-17): override de `customListRepositoryProvider`, pois a aba de listas passa a carregar ao abrir o app.
  - `test/features/custom_lists/custom_lists_test.dart` — criar: testes de widget e de provider com repositórios falsos em memória.
</files_in_scope>

<out_of_scope>
  - Reordenar listas manualmente; adicionar/remover jogos manualmente de uma lista.
  - Novos filtros (nota, ano, datas) e comparação parcial ("contains").
  - Sincronização com Google Drive.
  - Centralizar os status de jogo em um enum/constante compartilhada (os rótulos continuam duplicados, como no padrão atual).
  - Alterações em `CustomList`, `CustomListRepository`, `GameRepository` ou código gerado `*.g.dart`.
</out_of_scope>

<risks>
  - `customListGamesProvider` hoje usa o objeto `CustomList` como chave de family (sem `==`), gerando nova instância a cada rebuild → trocar a chave para `int id`. Ninguém consome o provider atualmente, então não há quebra.
  - Observar `gameListProvider` faz a contagem recarregar também em busca/filtro da Biblioteca → custo aceitável (consulta local Isar com poucos registros).
  - Isar não roda em widget tests → repositórios falsos via `ProviderScope(overrides: ...)` (padrão já registrado em `learnings.md`).
  - Lista inexistente no detalhe (ex.: removida durante a navegação) → o detalhe exibe "Lista não encontrada." sem lançar exceção, e `customListGamesProvider` retorna lista vazia.
</risks>

<test_plan>
  <!-- Rastreabilidade: R → AC → teste. Todos em test/features/custom_lists/custom_lists_test.dart -->
  - R1 → AC1: cards ordenados por nome, chip do filtro e "3 jogos".
  - R2 → AC2: estado vazio.
  - R3 → AC3: FAB correto por aba e navegação para "Nova Lista".
  - R4 → AC4: sugestão de autocomplete "FromSoftware" ao digitar "fro"; opções do dropdown de status.
  - R5 → AC5: erro de nome vazio; erro sem filtro; trim e `null` na persistência.
  - R6 → AC6: edição mantém id e atualiza nome.
  - R7 → AC7: detalhe com jogos e detalhe vazio.
  - R8 → AC8: exclusão confirmada (remove + SnackBar) e cancelada (mantém).
  - R9 → AC9: teste de provider com `ProviderContainer` — contagem passa de 1 para 2 após `saveGame`.
  - R10 → AC10: revisão do diff (sem mudança em `game_repository.dart`).
</test_plan>

<execution_plan>
- [x] 1. Ajustar `custom_list_provider.dart`: `customListGamesProvider` (family `int`, reativo) e `gameFilterOptionsProvider`.
- [x] 2. Criar `custom_list_card.dart` e `custom_lists_view.dart`; integrar na aba 2 e no FAB do `home_screen.dart`.
- [x] 3. Criar `custom_list_form_screen.dart` (criação/edição, validação, autocomplete, dropdown de status).
- [x] 4. Criar `custom_list_detail_screen.dart` (grade de `GameCard`, editar, excluir com confirmação).
- [x] 5. Criar `test/features/custom_lists/custom_lists_test.dart` cobrindo o `<test_plan>`.
- [x] 6. Rodar `.agent/scripts/verify.sh lint test` e corrigir.
- [x] 7. `revisao-codigo` do diff contra esta spec.
- [x] 8. Registrar aprendizados (`memoria`) e mover spec para `done/`.
</execution_plan>

<definition_of_done>
  - Todos os ACs atendidos e verificados; `verify.sh lint test` verde.
  - Diff restrito a `<files_in_scope>`.
  - `learnings.md` atualizado.
</definition_of_done>
