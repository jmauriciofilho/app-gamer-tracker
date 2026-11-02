# 📋 Especificação: Filtros novos nas listas personalizadas

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Escopo estrito da execução. Leia `.agent/project_instructions.md` antes de começar.
> Marque `[x]` em cada passo do `<execution_plan>` ao concluir. Não toque arquivos fora de `<files_in_scope>`.

<specification_meta>
- **Status:** Completed
- **Data de Criação:** 2026-11-02
- **Slug:** filtros-novos-listas
- **Tamanho (triagem):** feature (muda `@collection` `CustomList`, contrato do repositório e formulário)
</specification_meta>

<context>
  - **O que estamos construindo:** três filtros novos nas listas personalizadas — título contém, intervalo de ano de lançamento e ano de término — e comparação parcial ("contém") nos filtros de texto existentes.
  - **Motivação:** hoje as listas só filtram por igualdade exata em desenvolvedora/plataforma/gênero/status. Não dá para montar "série Final Fantasy", "jogos de 1995 a 2000" ou "terminados em 2026", e "PlayStation" não casa com "PlayStation 2".
  - **Decisões do discovery (2026-11-02):** ano de lançamento como intervalo de/até; data de término filtrada por ano; "contém" sempre ligado nos textos, sem opção por lista; filtro por nota fica fora.
</context>

<requirements>
  - [x] R1: Filtro "Título contém": traz jogos cujo `title` contém o texto, sem diferenciar maiúsculas.
  - [x] R2: Filtro de ano de lançamento com "de" e "até", ambos opcionais e inclusivos, sobre `Game.releaseYear`. Com o filtro ativo, jogos sem `releaseYear` ficam de fora.
  - [x] R3: Filtro "Terminados em" (ano): traz jogos com `endDate` dentro daquele ano civil. Com o filtro ativo, jogos sem `endDate` ficam de fora.
  - [x] R4: Desenvolvedora, plataforma e gênero passam a comparar por "contém", sem diferenciar maiúsculas. Status continua por igualdade.
  - [x] R5: Formulário de lista ganha os campos novos (título, ano de/até, ano de término), salva-os com trim e vazio → nulo, preenche-os na edição e os conta na regra "preencha pelo menos um filtro".
  - [x] R6: Validação dos anos: inteiro de 4 dígitos entre 1950 e 2100; "de" não pode ser maior que "até". Erro mostrado no próprio campo e a lista não é salva.
  - [x] R7: Card da lista mostra um chip para cada filtro novo preenchido.
  - [x] R8: Listas já salvas continuam abrindo e funcionando: os campos novos são nulos (Isar aceita campo novo anulável sem migração).
</requirements>

<acceptance_criteria>
  - AC1 (R1): lista com título "fantasy" e jogos "Final Fantasy VII", "Final Fantasy X" e "Doom" → o detalhe mostra os dois Final Fantasy e não mostra Doom.
  - AC2 (R2): jogos de 1994, 1995, 2000 e 2001 e um sem ano; filtro 1995–2000 → só 1995 e 2000. Só "de 2000" → 2000 e 2001. Só "até 1995" → 1994 e 1995.
  - AC3 (R3): jogos terminados em 31/12/2025, 01/01/2026, 31/12/2026 e um sem `endDate`; filtro 2026 → só os dois de 2026.
  - AC4 (R4): lista com plataforma "playstation" e jogos em "PlayStation 2" e "PC" → só o de PlayStation 2.
  - AC5 (R5): preencher título " Final Fantasy " e ano de 1995 → salva `filterTitle = 'Final Fantasy'`, `filterReleaseYearFrom = 1995` e os outros campos nulos; só um campo novo preenchido já passa na regra "pelo menos um filtro"; ao editar, os campos novos vêm preenchidos.
  - AC6 (R6): ano "95" → erro "Ano inválido"; "de 2001" e "até 2000" → erro "Ano inicial maior que o final"; nos dois casos a lista não é salva.
  - AC7 (R7): card mostra `Final Fantasy` (título), `1995–2000`, `A partir de 1995`, `Até 2000` e `Terminados em 2026`, conforme o caso.
  - AC8 (R8): `CustomList` criada sem os campos novos (como as já salvas) abre no card e no detalhe sem erro.
  - AC-G1: `flutter analyze` sem nenhuma issue.
  - AC-G2: tipagem explícita nos campos, parâmetros e métodos públicos novos, com doc comments `///` em pt-BR.
  - AC-G3: nenhuma dependência nova.
</acceptance_criteria>

<files_in_scope>
  - `lib/features/custom_lists/data/models/custom_list.dart` — editar: campos `String? filterTitle`, `int? filterReleaseYearFrom`, `int? filterReleaseYearTo`, `int? filterEndYear`.
  - `lib/features/custom_lists/data/models/custom_list.g.dart` — regenerar via `codegen` (sem edição manual).
  - `lib/features/games/data/repositories/game_repository.dart` — editar: `getGamesByCustomFilter` ganha `title`, `releaseYearFrom`, `releaseYearTo`, `endYear`; textos passam a usar `...Contains(caseSensitive: false)`.
  - `lib/features/custom_lists/presentation/providers/custom_list_provider.dart` — editar: `customListGamesProvider` repassa os filtros novos.
  - `lib/features/custom_lists/presentation/screens/custom_list_form_screen.dart` — editar: campos, validação e gravação.
  - `lib/features/custom_lists/presentation/widgets/custom_list_card.dart` — editar: chips dos filtros novos.
  - `test/features/custom_lists/custom_lists_test.dart` — editar: fake com a nova assinatura e a mesma semântica do repositório (contém, intervalos); testes novos de AC1–AC8.
  - `test/features/save_feedback_test.dart` — editar: só a assinatura do fake (parâmetros novos).
</files_in_scope>

<out_of_scope>
  - Filtro por nota e por data de início.
  - Opção "correspondência exata" por lista; status por "contém".
  - Autocomplete no campo de título.
  - Mudanças em `Game`, `IsarService` ou nas telas de jogos.
  - Reordenar listas ou adicionar e remover jogos manualmente.
</out_of_scope>

<risks>
  - "Contém" passa a valer para listas já salvas: uma lista "PS1" pode passar a trazer também "PS1 Classic" → aceito no discovery; registrado aqui.
  - A consulta Isar real não roda nos testes (eles usam fakes), então a semântica é testada no fake → manter o fake com o mesmo comportamento do repositório e conferir a consulta Isar linha a linha na revisão. `endDate` usa `endDateBetween(DateTime(ano), DateTime(ano + 1), includeUpper: false)`.
  - O formulário fica mais alto e o botão Salvar pode sair da área visível do teste (800×600) → nos testes novos, usar `tester.ensureVisible` antes de tocar; os testes existentes que quebrarem por isso recebem só esse ajuste mecânico.
  - Campo novo em `@collection` → rodar `codegen`; o schema já está registrado em `IsarService`, então não muda.
</risks>

<test_plan>
  <!-- Todos em test/features/custom_lists/custom_lists_test.dart -->
  - R1 → AC1: detalhe de lista por título contém.
  - R2 → AC2: intervalo fechado, só "de" e só "até", jogo sem ano excluído.
  - R3 → AC3: limites do ano (31/12 e 01/01) e jogo sem `endDate` excluído.
  - R4 → AC4: plataforma parcial e sem diferenciar maiúsculas.
  - R5 → AC5: gravação com trim e nulos, regra "pelo menos um filtro" com campo novo, edição pré-preenchida.
  - R6 → AC6: ano inválido e intervalo invertido não salvam.
  - R7 → AC7: chips do card para cada combinação.
  - R8 → AC8: lista sem os campos novos renderiza no card e no detalhe.
  - Regressão: suíte existente (`widget_test.dart`, `save_feedback_test.dart`, `custom_lists_test.dart`) verde.
</test_plan>

<execution_plan>
- [x] 1. Adicionar campos em `CustomList` e rodar `codegen`.
- [x] 2. Estender `getGamesByCustomFilter` (contém + intervalos) e o `customListGamesProvider`.
- [x] 3. Atualizar a assinatura e a semântica dos fakes de teste; rodar a suíte (regressão).
- [x] 4. Formulário: campos, validação, gravação e edição.
- [x] 5. Card: chips dos filtros novos.
- [x] 6. Testes AC1–AC8.
- [x] 7. Rodar `.agent/scripts/verify.sh lint test`.
- [x] 8. `revisao-codigo` do diff contra esta spec.
- [x] 9. Registrar aprendizados (`memoria`) e mover spec para `done/`.
</execution_plan>

<definition_of_done>
  - Todos os ACs atendidos e verificados; `verify.sh` verde.
  - Diff restrito a `<files_in_scope>`; `custom_list.g.dart` regenerado.
  - `learnings.md` atualizado.
</definition_of_done>
