# 📋 Especificação: Tela de estatísticas

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Escopo estrito da execução. Leia `.agent/project_instructions.md` antes de começar.
> Marque `[x]` em cada passo do `<execution_plan>` ao concluir. Não toque arquivos fora de `<files_in_scope>`.

<specification_meta>
- **Status:** Completed
- **Data de Criação:** 2026-11-02
- **Slug:** tela-estatisticas
- **Tamanho (triagem):** feature (nova aba/feature, mudança na navegação da home)
</specification_meta>

<context>
  - **O que estamos construindo:** uma 4ª aba "Estatísticas" com um resumo da biblioteca: totais, jogos por status, terminados por ano e as 5 plataformas e os 5 gêneros com mais jogos, desenhados como barras horizontais feitas com widgets.
  - **Motivação:** hoje não há visão geral da coleção. O usuário só vê a grade de jogos.
  - **Decisões do discovery (2026-11-02):** nova aba na barra (entre "Minhas Listas" e "Ajustes & Sync"); blocos Resumo + status, Terminados por ano e Top plataformas e gêneros; barras com widgets, sem dependência; sem filtro de período (sempre a biblioteca inteira).
</context>

<requirements>
  - [x] R1: **Cálculo puro.** `GameStats.fromGames(List<Game>)` calcula tudo sem acessar o banco nem a UI:
    - `total`: número de jogos.
    - `finished`: jogos com status `finalizado` ou `100%`.
    - `averageRating`: média das notas maiores que 0 (nota 0 = "sem nota", que é o padrão do modelo), ou `null` se nenhum jogo tiver nota.
  - [x] R2: **Por status.** Contagem para cada `GameStatus`, na ordem do enum, incluindo os zeros. Ids desconhecidos (fora do enum) somam numa entrada "Outros", que só aparece se for maior que 0.
  - [x] R3: **Terminados por ano.** Jogos com `endDate`, agrupados pelo ano de `endDate` (independentemente do status), do ano mais recente para o mais antigo, só com anos que tenham jogos.
  - [x] R4: **Top plataformas e gêneros.** Até 5 de cada:
    - Os valores são agrupados com trim e sem diferenciar maiúsculas ("PS1" e "ps1 " contam juntos), exibindo a grafia que aparece primeiro na lista.
    - Valores vazios ou nulos são ignorados.
    - A ordem é por contagem decrescente; em caso de empate, por nome A–Z.
  - [x] R5: **Atualização.** O `gameStatsProvider` lê todos os jogos via `gameRepositoryProvider.getAllGames()`, sem os filtros da Biblioteca, e faz `ref.watch(gameListProvider)` para recalcular a cada cadastro, edição, exclusão ou restauração de backup (padrão do `learnings.md`).
  - [x] R6: **Tela.** A aba mostra:
    - Um cartão de resumo com "Jogos", "Terminados" e "Nota média" (com 1 casa decimal, ex.: "4,3"; "—" se não houver nota).
    - Os blocos "Por status", "Terminados por ano", "Top plataformas" e "Top gêneros". Cada linha tem o rótulo, uma barra proporcional ao maior valor do bloco e o número.
    - Um bloco sem dados mostra "Sem dados ainda." no lugar das barras.
    - Com a biblioteca vazia, a tela inteira mostra "Cadastre jogos para ver estatísticas.".
    - Em caso de erro ao carregar, mostra "Não foi possível carregar as estatísticas.".
  - [x] R7: **Navegação.** A barra inferior passa a ter 4 destinos: Biblioteca, Minhas Listas, Estatísticas (ícone `insights`) e Ajustes & Sync. O ícone "Backup" da AppBar continua abrindo "Ajustes & Sync" (índice 3). Os FABs de Biblioteca e Listas não mudam, e a aba Estatísticas não tem FAB.
</requirements>

<acceptance_criteria>
  - AC1 (R1): jogos com status `jogando` (nota 0), `finalizado` (nota 4), `100%` (nota 5) e `jogado` (nota 3) → `total = 4`, `finished = 2`, `averageRating = 4.0`. Só jogos com nota 0 → `averageRating = null`. Lista vazia → `total = 0`.
  - AC2 (R2): os mesmos jogos → `para_jogar: 0, jogando: 1, jogado: 1, finalizado: 1, 100%: 1`, nessa ordem e sem "Outros". Somando um jogo com status `abandonado` → "Outros: 1" no fim.
  - AC3 (R3): `endDate` em 2024, 2026, 2026 e um sem data → `[(2026, 2), (2024, 1)]`.
  - AC4 (R4): plataformas "PS1", "ps1 ", "PC", "Switch", "Switch", "Switch", "", null, "N64", "GBA", "Wii" → `[Switch 3, PS1 2, GBA 1, N64 1, PC 1]` (5 itens; Wii fica de fora pelo desempate A–Z).
  - AC5 (R5): com o app aberto na aba Estatísticas, cadastrar um jogo pelo `gameListProvider` faz "Jogos" passar de 2 para 3 sem reiniciar. Com um filtro de status ativo na Biblioteca, o total continua sendo o da biblioteca inteira.
  - AC6 (R6): biblioteca com 3 jogos (notas 4, 5 e 0) → o resumo mostra "3", os terminados e "4,5". Os títulos dos 4 blocos aparecem. Sem `endDate` em nenhum jogo, o bloco "Terminados por ano" mostra "Sem dados ainda.". Com a biblioteca vazia aparece "Cadastre jogos para ver estatísticas.". Com o repositório lançando exceção aparece a mensagem de erro.
  - AC7 (R7): a barra tem os 4 rótulos na ordem do R7. Tocar no ícone "Backup" mostra "Backup local", e na aba Estatísticas não há FAB "Novo Jogo" nem "Nova Lista". Os testes existentes que tocam em "Ajustes & Sync" continuam verdes.
  - AC-G1: `flutter analyze` sem nenhuma issue e `flutter test` verde.
  - AC-G2: tipagem explícita e doc comments `///` em pt-BR nas classes e métodos públicos novos.
  - AC-G3: nenhuma dependência nova.
</acceptance_criteria>

<files_in_scope>
  - `lib/features/stats/data/models/game_stats.dart` — criar: `GameStats`, `StatEntry` (rótulo + contagem) e `GameStats.fromGames`.
  - `lib/features/stats/presentation/providers/game_stats_provider.dart` — criar: `gameStatsProvider` (`FutureProvider`).
  - `lib/features/stats/presentation/screens/stats_view.dart` — criar: conteúdo da aba (resumo, blocos, estados vazio e de erro).
  - `lib/features/stats/presentation/widgets/stat_bar_section.dart` — criar: bloco com título e linhas de barra.
  - `lib/features/games/presentation/screens/home_screen.dart` — editar: 4º destino, `IndexedStack` com `StatsView`, índice do atalho da AppBar.
  - `test/features/stats/game_stats_test.dart` — criar: AC1–AC4.
  - `test/features/stats/stats_view_test.dart` — criar: AC5–AC7.
  - `.agent/project_instructions.md` — editar: feature `stats` e as 4 abas.
</files_in_scope>

<out_of_scope>
  - Filtro por período/ano; comparação entre anos.
  - Gráficos de pizza/colunas ou qualquer biblioteca de gráficos.
  - Melhores notas, tempo de jogo (início→término), estatísticas de listas personalizadas.
  - Tocar numa barra para abrir os jogos correspondentes.
  - Mudanças em `Game`, repositórios ou `*.g.dart`.
</out_of_scope>

<risks>
  - **Mais uma aba no `IndexedStack`**: ela também é construída ao abrir o app, então todo teste que monta `MyApp` passa a chamar `getAllGames()` ao montar → todos os fakes existentes já implementam `getAllGames`. Conferir rodando a suíte inteira.
  - **O atalho da AppBar usa índice fixo (`2`)** → passar a usar uma constante nomeada para o índice de Ajustes, e testar pelo AC7.
  - **Nota 0 é ambígua** (sem nota ou nota zero) → tratada como "sem nota", porque a UI só permite de 0,5 em diante e o padrão do modelo é 0,0. Documentado no R1.
  - **Custo de recalcular a cada mudança na Biblioteca** (inclusive busca e filtro, porque observa o `gameListProvider`) → só leitura local, O(n), sem impacto perceptível numa biblioteca pessoal (mesmo trade-off já aceito em `customListGamesProvider`).
  - **Formato decimal** → usar `toStringAsFixed(1)` com troca de "." por ",", sem `intl` (que não é dependência direta).
</risks>

<test_plan>
  - R1 → AC1 → `game_stats_test.dart`: totais, média ignorando nota 0, lista vazia.
  - R2 → AC2 → `game_stats_test.dart`: ordem do enum com zeros; "Outros".
  - R3 → AC3 → `game_stats_test.dart`: agrupamento por ano, ordem decrescente, sem data ignorado.
  - R4 → AC4 → `game_stats_test.dart`: normalização, vazios, top 5 com desempate.
  - R5 → AC5 → `stats_view_test.dart`: recálculo após cadastrar; total ignora filtro da Biblioteca.
  - R6 → AC6 → `stats_view_test.dart`: resumo, blocos, "Sem dados ainda.", estado vazio e de erro.
  - R7 → AC7 → `stats_view_test.dart` + suíte existente: destinos, atalho Backup, sem FAB.
</test_plan>

<execution_plan>
- [x] 1. `GameStats` + testes AC1–AC4 (TDD).
- [x] 2. `gameStatsProvider`.
- [x] 3. `StatBarSection` e `StatsView`.
- [x] 4. Aba na `HomeScreen` (destino, `IndexedStack`, índice do atalho).
- [x] 5. Testes AC5–AC7.
- [x] 6. `.agent/scripts/verify.sh` e conferir no emulador.
- [x] 7. `revisao-codigo`, atualizar `project_instructions.md`, `memoria` e mover a spec para `done/`.
</execution_plan>

<definition_of_done>
  - Todos os ACs atendidos e verificados; `verify.sh` verde.
  - Diff restrito a `<files_in_scope>`.
  - `project_instructions.md` e `learnings.md` atualizados.
</definition_of_done>

<review_notes>
  - `verify.sh` verde: lint, 70 testes (12 novos), build. Diff restrito a `<files_in_scope>`; nenhuma dependência nova.
  - Os testes de widget usam a tela de teste em 800×2400 (`tester.view.physicalSize`) para o `ListView` construir todos os blocos.
  - Emulador `Pixel_9` em 2026-11-02, com os dados reais (1 jogo): resumo "1 / 0 / —", Por status com Para Jogar 1, "Sem dados ainda." em Terminados por ano, N64 e Plataforma 3D nos tops; 4 abas; o atalho "Backup" abre Ajustes & Sync.
</review_notes>
