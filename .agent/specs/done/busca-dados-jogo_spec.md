# 📋 Especificação: Buscar dados do jogo numa API pública ao cadastrar

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Escopo estrito da execução. Leia `.agent/project_instructions.md` antes de começar.
> Marque `[x]` em cada passo do `<execution_plan>` ao concluir. Não toque arquivos fora de `<files_in_scope>`.

<specification_meta>
- **Status:** Completed
- **Data de Criação:** 2026-11-02
- **Slug:** busca-dados-jogo
- **Tamanho (triagem):** feature (primeira chamada de rede do app, dependência direta nova, permissão Android, feature nova)
</specification_meta>

<context>
  - **O que estamos construindo:** no formulário de jogo (cadastro e edição), um botão de busca ao lado do título abre uma folha de busca. A busca consulta o **Wikidata** (sem chave) e lista só jogos eletrônicos. Ao escolher um resultado, o formulário é preenchido com título, desenvolvedora, gênero, ano e capa (da **Steam**, quando o jogo está lá), e são oferecidas as plataformas do jogo para escolher.
  - **Motivação:** hoje todo campo é digitado à mão, inclusive a URL da capa, que o usuário precisa achar na web.
  - **Decisões do discovery (2026-11-02):** fonte Wikidata + capa Steam; ao escolher, preencher **só campos vazios** (exceto o título, ver R4); várias plataformas → chips para escolher; disponível no cadastro e na edição.
  - **Pesquisa de APIs (2026-11-02):**

    | Fonte | Chave/conta | Dados | Capa | Situação |
    |---|---|---|---|---|
    | **Wikidata** (`wbsearchentities` + `wbgetentities`) | nenhuma; só `User-Agent` descritivo | desenvolvedora, plataformas, gênero, data (rótulos pt-br/pt/en) | não tem (direitos autorais); traz o id Steam (P1733) | testado: OK |
    | Steam CDN (`library_600x900.jpg`) | nenhuma | — | capa vertical 600×900 dos jogos da Steam | testado: 200 para existente, 404 para inexistente |
    | RAWG | chave no app + backlink obrigatório + limite mensal | completos | sim | API e docs com HTTP 522 no teste |
    | IGDB | client secret da Twitch (não pode ir no app) | completos | sim | exigiria backend próprio |

  - **Avaliação de dependência (`dependency-eval`):** `http` ^1.6.0 (publisher `dart.dev`). **Já está no lockfile como transitiva** (via `cached_network_image`), então vira direta sem baixar nada novo. A alternativa `dart:io HttpClient` dispensa a dependência, mas não tem o `MockClient` (`package:http/testing.dart`), que permite testar o parser sem rede. Custo de remover depois: baixo, porque o uso fica isolado no serviço.
</context>

<requirements>
  - [x] R1: **Busca.** `GameLookupService.search(query)` com o texto com trim e não vazio:
    1. `wbsearchentities` (`language=pt`, `uselang=pt`, `limit=20`).
    2. `wbgetentities` dos ids encontrados (`props=claims|labels|descriptions`), mantendo só os itens com P31 (instância de) = Q7889 (jogo eletrônico), na ordem da busca e no máximo 10.
    3. `wbgetentities` dos ids de desenvolvedora/plataforma/gênero para obter os rótulos.

    São 3 etapas por busca: a de rótulos vai em lotes de 50 ids, que é o limite do `wbgetentities`, então costuma ser 3 requisições, raramente 4. Rótulos e descrições vêm em `pt-br` → `pt` → `mul` → `en` (`mul` é onde o Wikidata guarda muitos nomes próprios). Se faltar o título nesses idiomas, usa o rótulo que a própria busca devolveu; item sem título algum é descartado. A busca só dispara ao enviar (botão ou Enter), não a cada tecla.
  - [x] R2: **Mapeamento de cada resultado:** `title` = rótulo; `description` = descrição (ex.: "videojogo de 2017"); `developer` = primeira P178; `genre` = primeiro P136; `releaseYear` = o **menor** ano entre as P577; `platforms` = todas as P400 (rótulos, sem repetição, na ordem do Wikidata); `steamAppId` = primeira P1733. Campos ausentes ficam nulos ou com lista vazia, sem erro.
  - [x] R3: **Capa.** Ao escolher um resultado com `steamAppId`, o serviço faz um `HEAD` em `https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/<id>/library_600x900.jpg`. Com 200, essa é a capa. Com qualquer outra resposta ou erro, fica sem capa, em silêncio.
  - [x] R4: **Preenchimento.** O título é **sempre** trocado pelo nome escolhido, porque é o próprio termo da busca. Desenvolvedora, gênero, ano e URL da capa são preenchidos **só se estiverem vazios**. Status, nota e datas nunca mudam.
  - [x] R5: **Plataformas.** Com exatamente 1 plataforma e o campo vazio, ele é preenchido. Com 2 ou mais, aparece abaixo do campo Plataforma a linha "Plataformas deste jogo:" com um chip por plataforma. Tocar num chip coloca o valor no campo (substituindo o que houver, porque é uma escolha explícita) e esconde a linha.
  - [x] R6: **Folha de busca.** Tem um campo já com o título digitado, a lista de resultados (título, descrição e ano), um indicador de carregamento e as mensagens "Nenhum jogo encontrado." e "Não foi possível buscar agora. Verifique a conexão.", esta com o botão "Tentar de novo". Fechar a folha sem escolher não altera o formulário.
  - [x] R7: **Rede segura e educada.**
    - Todas as URLs são montadas com `Uri.https`, com o termo como parâmetro codificado.
    - Toda requisição tem timeout de 10 s e o cabeçalho `User-Agent: game_tracker/1.0 (app pessoal; https://github.com/jmauriciofilho/app-gamer-tracker)`, exigido pela política da Wikimedia.
    - Nenhum dado além do termo buscado é enviado.
    - Respostas fora do formato esperado viram `GameLookupException`, sem travar o app.
  - [x] R8: **Permissão.** `android/app/src/main/AndroidManifest.xml` declara `android.permission.INTERNET`. Hoje só debug e profile declaram, então no APK de release nem as capas carregam.
  - [x] R9: **Isolamento.** O formulário depende só da interface `GameLookupService` (via `gameLookupServiceProvider`), e os testes usam fakes e `MockClient`, sem rede real.
</requirements>

<acceptance_criteria>
  - AC1 (R1, R2): com `MockClient` devolvendo as respostas gravadas de "Hollow Knight" (o jogo, a série e a wiki), `search('Hollow Knight')` devolve só o jogo, com `title: 'Hollow Knight'`, `developer: 'Team Cherry'`, `releaseYear: 2017` (o menor entre 2017 e 2018), `platforms` contendo `'Microsoft Windows'` e `'macOS'` sem repetição, e `steamAppId: '367520'`. Um item sem P178/P136/P577/P400 vira resultado com campos nulos e `platforms` vazia.
  - AC2 (R1): `search('   ')` devolve lista vazia sem fazer requisição. Com 15 jogos na resposta, devolve só os 10 primeiros. Rótulo só em `en` é usado quando não há `pt-br`/`pt`/`mul`, e só em `mul` vence `en`.
  - AC3 (R7): resposta HTTP 500, JSON malformado ou exceção de rede → `GameLookupException`. Toda requisição gravada pelo `MockClient` tem o `User-Agent` do R7 e host `www.wikidata.org` ou `shared.fastly.steamstatic.com`.
  - AC4 (R3): `findCoverUrl` com HEAD 200 devolve a URL `library_600x900.jpg`. Com 404, exceção ou `steamAppId` nulo, devolve `null`.
  - AC5 (R4, R6): no formulário de **cadastro**, com o título "hollow" e a desenvolvedora "Minha Dev" já digitados, buscar e escolher "Hollow Knight" (fake) deixa: título "Hollow Knight"; desenvolvedora "Minha Dev" (não mudou); gênero "metroidvania"; ano "2017"; capa com a URL da Steam; status "Para Jogar" e nota inalterados.
  - AC6 (R5): com o resultado de 2 plataformas, aparecem os chips "Microsoft Windows" e "macOS", e tocar em "macOS" preenche Plataforma e esconde os chips. Com resultado de 1 plataforma ("Nintendo 64") e o campo vazio, ele é preenchido direto, sem chips.
  - AC7 (R6): o fake sem resultados mostra "Nenhum jogo encontrado.". O fake que lança exceção mostra a mensagem de conexão, e "Tentar de novo" refaz a busca. Fechar a folha sem escolher mantém todos os campos.
  - AC8 (R4): na **edição** de um jogo com status "Jogando", nota 4 e capa preenchida, o botão de busca existe. Escolher um resultado não muda status, nota nem a capa existente.
  - AC9 (R8): o `AndroidManifest.xml` principal contém `android.permission.INTERNET`. Verificado na revisão e pelo build de release no emulador (AC10).
  - AC10 (R1–R5, R8): no emulador, em "Novo Jogo", buscar "Hollow Knight", escolher o jogo e a plataforma "Nintendo Switch", e salvar → o card aparece com a capa da Steam. O jogo de teste é apagado no fim.
  - AC11 (R9): os testes AC5–AC8 rodam só com o `GameLookupService` fake, sobrescrito via `gameLookupServiceProvider`, e `game_form_screen.dart` não importa `package:http`. Isso é verificado por `grep` na revisão.
  - AC-G1: `flutter analyze` sem nenhuma issue e `flutter test` verde.
  - AC-G2: tipagem explícita e doc comments `///` em pt-BR nas classes e métodos públicos novos.
  - AC-G3: só o `http` vira dependência direta (aprovado nesta spec).
</acceptance_criteria>

<files_in_scope>
  - `pubspec.yaml` / `pubspec.lock` — editar: `http: ^1.6.0` como dependência direta.
  - `android/app/src/main/AndroidManifest.xml` — editar: permissão `INTERNET`.
  - `lib/features/game_lookup/data/models/game_lookup_result.dart` — criar: `GameLookupResult` (imutável).
  - `lib/features/game_lookup/data/game_lookup_service.dart` — criar: interface `GameLookupService` (`search`, `findCoverUrl`) e `GameLookupException`.
  - `lib/features/game_lookup/data/wikidata_game_lookup_service.dart` — criar: implementação com `http.Client` injetável (Wikidata + HEAD na Steam).
  - `lib/features/game_lookup/presentation/providers/game_lookup_provider.dart` — criar: `gameLookupServiceProvider`.
  - `lib/features/game_lookup/presentation/widgets/game_lookup_sheet.dart` — criar: folha de busca (estados de carregando/vazio/erro, devolve o resultado com a capa resolvida).
  - `lib/features/games/presentation/screens/game_form_screen.dart` — editar: botão no título, regra de preenchimento e chips de plataforma.
  - `test/features/game_lookup/wikidata_game_lookup_service_test.dart` — criar: AC1–AC4 com `MockClient` e JSON gravado no próprio teste.
  - `test/features/game_lookup/game_form_lookup_test.dart` — criar: AC5–AC8 com o serviço fake.
  - `.agent/project_instructions.md` — editar: feature `game_lookup`, `http` na stack, e `<security>` passa a citar a consulta ao Wikidata/Steam.
</files_in_scope>

<out_of_scope>
  - RAWG, IGDB ou qualquer API com chave; backend próprio.
  - Capa para jogos fora da Steam (ex.: consoles antigos). O campo de URL continua manual.
  - Cache de resultados, busca offline, busca automática enquanto digita.
  - Vários gêneros ou desenvolvedoras (só o primeiro de cada).
  - Buscar a partir da Biblioteca ou das Listas; atualizar jogos em lote.
  - Mudar `Game`, `IsarService` ou os `*.g.dart`.
</out_of_scope>

<risks>
  - **O Wikidata pode ficar fora do ar ou limitar requisições** → timeout de 10 s, mensagem com "Tentar de novo", busca só ao enviar (3 etapas por busca, com rótulos em lotes de 50 ids, + 1 HEAD por escolha) e `User-Agent` descritivo, conforme a política da Wikimedia.
  - **Os dados do Wikidata são incompletos ou variam de jogo para jogo** (ex.: Super Mario 64 não tem id Steam, então fica sem capa) → todos os campos são opcionais e nada que o usuário já digitou é sobrescrito (exceto o título, R4).
  - **Os rótulos podem vir em inglês** ("Microsoft Windows", "metroidvania") → aceito; o usuário pode editar antes de salvar.
  - **Os testes não podem depender da rede** → JSON gravado no teste + `MockClient`. A integração real é coberta pelo AC10.
  - **A URL da capa vem de fora** → só é aceita se montada pelo próprio serviço no domínio `shared.fastly.steamstatic.com` com um `steamAppId` numérico (validar `^\d+$`).
  - **A permissão INTERNET no manifest principal muda o APK de release** → é necessária (as capas já dependiam dela) e não exige pedido em tempo de execução.
  - **O formulário fica mais alto** → os testes usam `tester.ensureVisible` antes de tocar, conforme `learnings.md`.
</risks>

<test_plan>
  - R1/R2 → AC1 → `wikidata_game_lookup_service_test.dart`: filtro por Q7889, mapeamento, menor ano, plataformas sem repetição, item sem campos.
  - R1 → AC2 → `wikidata_game_lookup_service_test.dart`: termo vazio, limite de 10, rótulo em `en` como fallback.
  - R7 → AC3 → `wikidata_game_lookup_service_test.dart`: 500, JSON malformado, exceção de rede; `User-Agent` e hosts.
  - R3 → AC4 → `wikidata_game_lookup_service_test.dart`: HEAD 200, 404, exceção, sem id Steam.
  - R4/R6 → AC5 → `game_form_lookup_test.dart`: cadastro preenche só os vazios e troca o título.
  - R5 → AC6 → `game_form_lookup_test.dart`: chips com 2 plataformas; preenchimento direto com 1.
  - R6 → AC7 → `game_form_lookup_test.dart`: vazio, erro com tentar de novo, fechar sem escolher.
  - R4 → AC8 → `game_form_lookup_test.dart`: edição preserva status, nota e capa.
  - R9 → AC11 → testes de widget com fake + `grep` de imports na revisão.
  - R8 → AC9/AC10 → revisão do manifest + emulador (skill `run-game-tracker`).
</test_plan>

<execution_plan>
- [x] 1. `http` como dependência direta + permissão `INTERNET`.
- [x] 2. `GameLookupResult`, `GameLookupService`, `GameLookupException`.
- [x] 3. `WikidataGameLookupService` + testes AC1–AC4 (TDD com `MockClient`).
- [x] 4. Provider e `GameLookupSheet`.
- [x] 5. Integração no `GameFormScreen` (botão, preenchimento, chips) + testes AC5–AC8.
- [x] 6. `.agent/scripts/verify.sh` e corrigir.
- [x] 7. AC10 no emulador.
- [x] 8. `revisao-codigo` + `security-audit` focado na chamada de rede.
- [x] 9. Atualizar `project_instructions.md`, `memoria` e mover a spec para `done/`.
</execution_plan>

<definition_of_done>
  - Todos os ACs atendidos e verificados; `verify.sh` verde.
  - Diff restrito a `<files_in_scope>`.
  - `project_instructions.md` e `learnings.md` atualizados.
</definition_of_done>

<review_notes>
  - O teste ao vivo contra o Wikidata (antes dos testes com respostas gravadas) mostrou que muitos nomes próprios ficam na língua `mul`. Sem ela, o título do Hollow Knight vinha vazio e 5 das 9 plataformas sumiam. Ordem final: `pt-br → pt → mul → en`, com o rótulo da busca como reserva (R1 atualizado).
  - A etapa de rótulos vai em lotes de 50 ids, o limite do `wbgetentities` (R1 e riscos atualizados).
  - AC9: `aapt2 dump permissions` no `app-release.apk` lista `android.permission.INTERNET`.
  - AC10 no emulador `Pixel_9` em 2026-11-02: a busca "hollow knight" trouxe Hollow Knight e Silksong. A escolha preencheu título, capa, Team Cherry, metroidvania e 2017, mostrou 9 chips de plataforma, e o card foi salvo com a capa. O jogo de teste foi apagado no fim.
  - Segurança: sem segredos; só `Uri.https` para os dois hosts; id da Steam validado (`^\d+$`); mensagens ao usuário sem detalhes internos.
  - [SUGESTÃO, não feita] O `http.Client` do provider não é fechado; vive enquanto o app estiver aberto.
</review_notes>
