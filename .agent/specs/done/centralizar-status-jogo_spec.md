# 📋 Especificação: Centralizar status de jogo

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Escopo estrito da execução. Leia `.agent/project_instructions.md` antes de começar.
> Marque `[x]` em cada passo do `<execution_plan>` ao concluir. Não toque arquivos fora de `<files_in_scope>`.

<specification_meta>
- **Status:** Completed
- **Data de Criação:** 2026-11-02
- **Slug:** centralizar-status-jogo
- **Tamanho (triagem):** feature (refatoração mecânica em 7 arquivos; sem contrato público novo nem migração)
</specification_meta>

<context>
  - **O que estamos construindo:** um `enum GameStatus` único com id interno (string salva no Isar) e rótulo exibido, usado por todas as telas que listam ou formatam status.
  - **Motivação:** hoje os 5 status (`para_jogar`, `jogando`, `jogado`, `finalizado`, `100%`) e seus rótulos estão repetidos em 6 lugares (`home_screen`, `game_form_screen`, `game_card`, `game_detail_screen` ×2, `custom_list_card`). Adicionar ou renomear um status exige editar todos, com risco de divergência — e os próximos filtros de listas dependem disso.
</context>

<requirements>
  - [x] R1: Existe um único ponto de definição dos status, com id, rótulo e ordem de exibição.
  - [x] R2: Conversão id → rótulo centralizada, tolerante a maiúsculas e ao legado `para jogar` (comportamento atual do detalhe), devolvendo o próprio valor quando desconhecido.
  - [x] R3: Chips da home, dropdown do formulário de jogo, dropdown do formulário de lista, card de jogo, card de lista e detalhe do jogo passam a usar o enum, sem mudança visível (mesmos rótulos, mesma ordem, mesmas cores).
  - [x] R4: O campo `Game.status` continua `String` com os mesmos valores (sem migração nem codegen).
</requirements>

<acceptance_criteria>
  - AC1 (R1): `GameStatus.values` contém exatamente, nesta ordem, os ids `para_jogar`, `jogando`, `jogado`, `finalizado`, `100%` com rótulos `Para Jogar`, `Jogando`, `Jogado`, `Finalizado`, `100%`.
  - AC2 (R2): `GameStatus.labelOf('jogando')` → `Jogando`; `labelOf('JOGANDO')` → `Jogando`; `labelOf('para jogar')` → `Para Jogar`; `labelOf('xyz')` → `xyz`.
  - AC3 (R3): os testes de widget existentes (`test/widget_test.dart`, `test/features/**`) passam sem alteração.
  - AC4 (R3): `grep` por `'para_jogar'` em `lib/` (exceto comentários e `*.g.dart`) só encontra `game_status.dart`.
  - AC5 (R4): `game.dart` e `*.g.dart` sem diff.
  - AC-G1: `flutter analyze` sem nenhuma issue.
  - AC-G2: tipagem explícita no enum e métodos públicos, com doc comments `///` em pt-BR.
  - AC-G3: nenhuma dependência nova.
</acceptance_criteria>

<files_in_scope>
  - `lib/features/games/data/models/game_status.dart` — criar: enum `GameStatus` (id, label, `fromId`, `labelOf`). Não é `@collection`, não precisa de codegen.
  - `lib/features/games/presentation/screens/home_screen.dart` — editar: chips a partir de `GameStatus.values` (mantendo "Todos").
  - `lib/features/games/presentation/screens/game_form_screen.dart` — editar: dropdown a partir de `GameStatus.values`; default `GameStatus.paraJogar.id`.
  - `lib/features/games/presentation/widgets/game_card.dart` — editar: `_formatStatus` → `GameStatus.labelOf`.
  - `lib/features/games/presentation/screens/game_detail_screen.dart` — editar: `_formatStatus` → `GameStatus.labelOf`; `_getStatusColor` usa `GameStatus.fromId` (cores continuam na tela).
  - `lib/features/custom_lists/presentation/widgets/custom_list_card.dart` — editar: remover `customListStatusLabels`, usar `GameStatus.labelOf`.
  - `lib/features/custom_lists/presentation/screens/custom_list_form_screen.dart` — editar: dropdown a partir de `GameStatus.values`.
  - `test/features/games/game_status_test.dart` — criar: testes unitários de AC1 e AC2.
</files_in_scope>

<out_of_scope>
  - Mudar o tipo de `Game.status` / `CustomList.filterStatus` para enum no Isar (exigiria migração e codegen).
  - Mover as cores de status para o enum (cor é responsabilidade de apresentação).
  - Alterar textos, ordem ou cores exibidas; alterar testes existentes.
  - Comentários de documentação em `game.dart`, `game_repository.dart` e `game_list_provider.dart` que citam os valores.
</out_of_scope>

<risks>
  - `game_card` hoje não normaliza maiúsculas/legado; com `labelOf` passa a normalizar → só afeta dados fora do padrão (melhora a exibição); documentado em R2.
  - Imports cruzados de feature (`custom_lists` → `games/data/models`) → já existe esse acoplamento (listas filtram jogos); aceitável.
</risks>

<test_plan>
  - R1 → AC1 → `test/features/games/game_status_test.dart`: ids, rótulos e ordem de `GameStatus.values`.
  - R2 → AC2 → `test/features/games/game_status_test.dart`: id válido, maiúsculas, legado `para jogar`, desconhecido; `fromId` devolve `null` para desconhecido.
  - R3 → AC3 → `test/widget_test.dart`, `test/features/custom_lists/custom_lists_test.dart` (inclui "formulário ... lista os status"), `test/features/save_feedback_test.dart`: inalterados e verdes.
  - R3/R4 → AC4/AC5 → verificação por `grep` e `git diff --stat` na revisão.
</test_plan>

<execution_plan>
- [x] 1. Criar `game_status.dart` e `game_status_test.dart`; rodar o teste.
- [x] 2. Migrar `game_card.dart` e `game_detail_screen.dart`.
- [x] 3. Migrar `home_screen.dart` e `game_form_screen.dart`.
- [x] 4. Migrar `custom_list_card.dart` e `custom_list_form_screen.dart`.
- [x] 5. Rodar `.agent/scripts/verify.sh lint test` e as checagens de AC4/AC5.
- [x] 6. `revisao-codigo` do diff contra esta spec.
- [x] 7. Registrar aprendizados (`memoria`) e mover spec para `done/`.
</execution_plan>

<definition_of_done>
  - Todos os ACs atendidos e verificados; `verify.sh` verde.
  - Diff restrito a `<files_in_scope>`.
  - `learnings.md` atualizado.
</definition_of_done>
