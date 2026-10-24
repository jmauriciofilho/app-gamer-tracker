# 🤖 Instruções e Contexto do Projeto

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Este arquivo é a fonte de verdade sobre o projeto. Leia e respeite antes de qualquer plano, código ou spec.
> Se não souber algo, escreva `N/A` (nunca invente).

<project_context>
  - **Nome do Projeto:** game_tracker ("Rastreador de Games")
  - **Propósito:** App Flutter pessoal e offline para catalogar jogos (status, nota, plataforma, datas) e montar listas personalizadas por filtros (desenvolvedora, plataforma, gênero, status).
  - **Público Alvo:** Uso pessoal (usuário final único, sem backend/autenticação).
</project_context>

<tech_stack>
  - **Linguagem Principal:** Dart (SDK `>=3.10.0 <4.0.0`; local: Flutter 3.47.5 stable)
  - **Framework Core:** Flutter (Material 3, tema `ThemeData.dark`)
  - **Gerenciador de pacotes:** pub (`flutter pub`)
  - **Ferramentas Auxiliares:**
    - Estado: `flutter_riverpod` ^2.5.0 (lock 2.6.1; `Provider`, `AsyncNotifierProvider`, `FutureProvider`/`.family`)
    - Estilização: Material 3 + `google_fonts`, `cached_network_image`, `flutter_rating_bar`
    - Banco de Dados / ORM: Isar Community (`isar_community` ^3.3.2) local, via `path_provider`; schemas gerados por `isar_community_generator` + `build_runner` (arquivos `*.g.dart`)
    - Testes: `flutter_test` com repositórios falsos em memória via `ProviderScope(overrides: ...)` (`test/widget_test.dart`, `test/features/`)
</tech_stack>

<commands>
  <!-- Formato: "- nome: comando". Lido por .agent/scripts/verify.sh. Use N/A se não existir. -->
  - install: flutter pub get
  - codegen: dart run build_runner build --delete-conflicting-outputs
  - lint: flutter analyze
  - typecheck: N/A
  - test: flutter test
  - build: flutter build apk --debug
  - dev: flutter run
</commands>

<architecture>
  - **Padrão Principal:** Feature-first em camadas (`data` / `presentation`), com Repository + Riverpod.
  - **Mapa de Diretórios (Resumo):**
    - `lib/core/services/` — infraestrutura compartilhada (`IsarService`: singleton que abre o banco com todos os schemas).
    - `lib/features/<feature>/data/models/` — coleções Isar (`@collection`) + `*.g.dart` gerados (não editar à mão).
    - `lib/features/<feature>/data/repositories/` — acesso ao Isar (escrita sempre em `writeTxn`).
    - `lib/features/<feature>/presentation/{providers,screens,widgets}/` — providers Riverpod, telas e widgets.
    - Features atuais: `games` (CRUD completo + busca/filtro por status) e `custom_lists` (CRUD de listas por filtros; telas de lista, detalhe e formulário).
    - Providers de repositório das duas features: `lib/features/games/presentation/providers/game_repository_provider.dart`.
    - `test/` — testes `flutter_test` (`widget_test.dart` + `test/features/<feature>/`).
  - **Pontos de entrada:** `lib/main.dart` (`ProviderScope` → `MyApp` → `HomeScreen`, com `NavigationBar` + `IndexedStack` nas abas Jogos e Listas).
</architecture>

<coding_guidelines>
  - **Nomenclatura:** arquivos `snake_case.dart`; classes `PascalCase` (`GameRepository`, `GameListNotifier`, `HomeScreen`); providers globais `camelCaseProvider`; campos privados com `_`. Status de jogo são strings fixas: `para_jogar`, `jogando`, `jogado`, `finalizado`, `100%`.
  - **Tratamento de Erros:** no Notifier, `AsyncValue.guard` para capturar falhas; na UI, `asyncValue.when(data/loading/error)` e `SnackBar` para feedback.
  - **Tipagem/Comentários:** null-safety com campos opcionais `String?`; doc comments `///` em métodos públicos e comentários explicativos em pt-BR. Imports relativos dentro de `lib/`.
  - **Lint:** `flutter_lints` (`package:flutter_lints/flutter.yaml`); analyzer exclui `build/` e pastas de plataforma.
  - **Código gerado:** após alterar qualquer `@collection`, rodar o comando `codegen` e registrar novos schemas em `IsarService._init`.
  - **Geração de Código:** código completo, sem placeholders; siga os padrões já existentes.
</coding_guidelines>

<git_conventions>
  - **Branches:** `main` + branches por tarefa: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`.
  - **Commits:** Conventional Commits (feat, fix, refactor, test, docs, chore) em pt-BR e minúsculas, com escopo opcional (ex.: `feat(custom-lists): ...`). Commits antigos não têm prefixo.
  - **PRs:** N/A (sem template nem CI no repositório).
</git_conventions>

<security>
  - Nunca commitar segredos, tokens ou `.env`.
  - Validar/sanitizar toda entrada externa (formulários, URLs de capa). Usar a query API do Isar (sem montar consultas por string).
  - Áreas sensíveis do projeto: N/A (dados locais pessoais, sem rede além do carregamento de imagens de capa).
</security>

<definition_of_done>
  - Lint e testes passando (`.agent/scripts/verify.sh`).
  - Todos os `<acceptance_criteria>` da spec atendidos e passos marcados `[x]`.
  - Sem arquivos alterados fora de `<files_in_scope>`.
  - `*.g.dart` regenerados quando models Isar mudarem.
  - Documentação/README atualizados se o comportamento público mudou.
  - `.agent/memory/learnings.md` atualizado quando houver aprendizado relevante.
</definition_of_done>

<agent_constraints>
  - **PROIBIDO:** alterar `.env`, `.gitignore` ou configs de ambiente sem pedido explícito.
  - **PROIBIDO:** modificar código de dependências instaladas (`.dart_tool`, `.pub-cache`, `build/`).
  - **PROIBIDO:** editar manualmente arquivos `*.g.dart` (sempre regenerar via `codegen`).
  - **PROIBIDO:** commitar segredos ou executar comandos destrutivos (drop, `rm -rf`, force push) sem confirmação.
  - **OBRIGATÓRIO:** passar por `dependency-eval` antes de adicionar dependências.
  - **OBRIGATÓRIO:** seguir a spec aprovada; escopo fechado em `<files_in_scope>`.
  - **OBRIGATÓRIO:** acesso ao banco somente via repositories; UI acessa dados via providers Riverpod.
</agent_constraints>

<available_skills>
  - Skills em `.agent/skills/`. Consulte o índice no `AGENTS.md`.
</available_skills>
