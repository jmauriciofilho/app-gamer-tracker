# 📋 Especificação: Backup e restauração local em JSON

> **[META INSTRUÇÃO PARA O AGENTE IA]**
> Escopo estrito da execução. Leia `.agent/project_instructions.md` antes de começar.
> Marque `[x]` em cada passo do `<execution_plan>` ao concluir. Não toque arquivos fora de `<files_in_scope>`.

<specification_meta>
- **Status:** Completed
- **Data de Criação:** 2026-11-02
- **Slug:** backup-local-json
- **Tamanho (triagem):** feature (nova feature `backup`, dependência nova, escrita em massa no Isar)
</specification_meta>

<context>
  - **O que estamos construindo:** exportar todos os jogos e listas personalizadas para um arquivo JSON escolhido pelo usuário no seletor do sistema, e restaurar a partir desse arquivo, na aba Configurações.
  - **Motivação:** os dados só existem no Isar do aparelho (`getApplicationDocumentsDirectory`), que é apagado ao desinstalar o app ou trocar de celular. A aba Configurações tem botões de Google Drive sem ação (`onPressed: () {}`).
  - **Decisões do discovery (2026-11-02):** arquivo salvo/lido pelo seletor do sistema (dependência `file_picker`); restaurar **substitui tudo** após confirmação; os botões do Drive saem e dão lugar ao backup local; capas vão só como URL (`coverUrl`).
  - **Avaliação de dependência (`dependency-eval`):**

    | Opção | Salvar no Android | Abrir arquivo | Manutenção / popularidade | Licença |
    |---|---|---|---|---|
    | `file_picker` ^13.3.0 | ✅ `saveFile` (SAF, sem permissão) | ✅ `pickFile` | releases semanais, 150/160 pts, ~5 mi downloads/mês | MIT |
    | `file_selector` 1.1.0 (oficial) | ❌ sem `getSaveLocation` no Android | ✅ | oficial, último release 2025-11 | BSD-3 |
    | `share_plus` + `file_picker` | ✅ via compartilhar | ✅ | duas deps | BSD-3 / MIT |
    | Só `path_provider` (já instalado) | só pasta privada (some ao desinstalar) | ❌ | — | — |

    Recomendação: `file_picker`, que é uma única dependência para os dois sentidos e exige SDK `>=3.10.0`/Flutter `>=3.38.0` (compatível). Custo de remover depois: baixo, porque fica isolado atrás de `BackupFileGateway`.
</context>

<requirements>
  - [x] R1: **Formato do arquivo.** JSON UTF-8 com `app: "game_tracker"`, `version: 1`, `exportedAt` (ISO-8601), `games` (todos os campos de `Game`, incluindo `id`, com datas em ISO-8601 ou `null`) e `customLists` (todos os campos de `CustomList`, incluindo `id`). Nome sugerido: `game_tracker_backup_AAAA-MM-DD.json`.
  - [x] R2: **Exportar.** O botão "Exportar backup" lê todos os jogos e listas pelo repositório, gera o JSON e abre o seletor do sistema para salvar. Em caso de sucesso, mostra o SnackBar "Backup exportado: N jogos, M listas" (singular quando a contagem é 1: "1 jogo", "1 lista"). Se o usuário cancelar, nada é mostrado. Se houver falha, mostra o SnackBar "Erro ao exportar backup". Banco vazio também exporta (com as listas vazias).
  - [x] R3: **Validar ao importar.** O arquivo é lido e validado por inteiro **antes** de qualquer escrita. É recusado com "Arquivo de backup inválido" quando: o JSON é malformado, falta `app: "game_tracker"`, `games`/`customLists` não são listas, ou algum jogo não tem `title`/`status` em texto ou tem data, número ou tipo inválido. Se `version` for maior que 1, a mensagem é "Versão de backup não suportada". `status` fora de `GameStatus` é aceito como está (o app já exibe ids desconhecidos pelo próprio valor via `labelOf`). `coverUrl` é importado como texto e exibido como hoje (só via `CachedNetworkImage`). Em qualquer recusa, o banco fica intacto.
  - [x] R4: **Confirmar e substituir.** Com o arquivo válido, um diálogo mostra "Substituir N jogos e M listas atuais por X jogos e Y listas do backup?". Ao tocar em "Cancelar", nada muda. Ao tocar em "Substituir", apaga todos os jogos e listas e grava os do arquivo **numa única transação** `writeTxn` (se falhar, nada muda). Ao terminar, mostra "Backup restaurado: X jogos, Y listas" (com singular/plural como em R2) e as abas Biblioteca e Listas recarregam sem reiniciar o app.
  - [x] R5: **Ida e volta sem perda.** Exportar e depois importar reproduz os mesmos jogos e listas, com os mesmos ids, valores e datas, incluindo os campos nulos.
  - [x] R6: **Aba Configurações.** "Conta do Google", "Fazer Backup no Google Drive" e "Restaurar do Google Drive" são substituídos por uma seção "Backup local" com os botões "Exportar backup" e "Importar backup" e um texto explicando que importar substitui os dados atuais. O ícone da AppBar continua levando à aba, agora com o tooltip "Backup".
  - [x] R7: **Isolamento.** O acesso ao seletor fica atrás da interface `BackupFileGateway` (para os testes usarem um fake) e o acesso ao Isar fica em `BackupRepository`, sem a UI tocar o banco.
</requirements>

<acceptance_criteria>
  - AC1 (R1, R5): `BackupCodec.encode` com 2 jogos (um com todos os campos e outro só com os obrigatórios) e 1 lista com todos os filtros, seguido de `decode`, devolve objetos com os campos iguais aos originais. O JSON tem `app == 'game_tracker'` e `version == 1`.
  - AC2 (R3): `decode` lança `BackupFormatException` com a mensagem "Arquivo de backup inválido" para: texto que não é JSON, `app` ausente ou diferente, `games` não lista, jogo sem `title`, `startDate` = `"ontem"`, `rating` = `"cinco"`. Com `version: 2`, lança "Versão de backup não suportada".
  - AC3 (R2): na aba Configurações, tocar em "Exportar backup" com o gateway fake → o fake recebe um nome que casa com `game_tracker_backup_\d{4}-\d{2}-\d{2}\.json` e bytes que decodificam para os jogos e listas do repositório fake, e aparece "Backup exportado: 2 jogos, 1 lista". Se o fake devolver "cancelado", nenhum SnackBar aparece. Se o fake lançar exceção, aparece "Erro ao exportar backup".
  - AC4 (R3, R4): com um arquivo inválido no fake, tocar em "Importar backup" mostra "Arquivo de backup inválido", nenhum diálogo abre e o repositório fake não recebe `replaceAll`.
  - AC5 (R4): com um arquivo válido (3 jogos, 2 listas) e o banco fake com 1 jogo e 0 listas → aparece o diálogo "Substituir 1 jogo e 0 listas atuais por 3 jogos e 2 listas do backup?". "Cancelar" não chama `replaceAll`. "Substituir" chama `replaceAll` com os 3 jogos e as 2 listas, mostra "Backup restaurado: 3 jogos, 2 listas", e a aba Biblioteca passa a mostrar os 3 títulos importados.
  - AC6 (R4): no app real (emulador), exportar, apagar um jogo, importar o arquivo exportado e confirmar → o jogo apagado volta e as contagens batem.
  - AC7 (R6): a aba Configurações não contém mais os textos "Google Drive" nem "Conta do Google". Contém "Backup local", "Exportar backup" e "Importar backup".
  - AC8 (R7): os testes de AC3–AC5 rodam só com o `BackupFileGateway` fake e os repositórios fakes (sem Isar nem plugin), e `backup_section.dart` não importa `isar_community` nem `file_picker`. Isso é verificado por `grep` na revisão.
  - AC-G1: `flutter analyze` sem nenhuma issue e `flutter test` verde.
  - AC-G2: tipagem explícita e doc comments `///` em pt-BR nas classes e métodos públicos novos.
  - AC-G3: só a dependência `file_picker` é adicionada (aprovada nesta spec).
</acceptance_criteria>

<files_in_scope>
  - `pubspec.yaml` / `pubspec.lock` — editar: adicionar `file_picker: ^13.3.0`.
  - `lib/features/backup/data/backup_codec.dart` — criar: `BackupData` (jogos + listas), `BackupCodec.encode/decode` e `BackupFormatException`.
  - `lib/features/backup/data/backup_repository.dart` — criar: `readAll()` → `BackupData`; `replaceAll(BackupData)` com `clear` + `putAll` das duas coleções numa única `writeTxn`.
  - `lib/features/backup/data/backup_file_gateway.dart` — criar: interface `BackupFileGateway` (`save(fileName, bytes) → bool`, `pick() → Uint8List?`) e a implementação `FilePickerBackupFileGateway`.
  - `lib/features/backup/presentation/providers/backup_provider.dart` — criar: `backupRepositoryProvider`, `backupFileGatewayProvider` e `BackupController` (exportar, ler e validar, restaurar e invalidar `gameListProvider`/`customListProvider`).
  - `lib/features/backup/presentation/widgets/backup_section.dart` — criar: seção "Backup local" com os botões, o diálogo e os SnackBars.
  - `lib/features/games/presentation/screens/home_screen.dart` — editar: `_buildSettingsTab` passa a usar `BackupSection` e o tooltip da AppBar muda para "Backup".
  - `test/features/backup/backup_codec_test.dart` — criar: AC1, AC2.
  - `test/features/backup/backup_section_test.dart` — criar: AC3, AC4, AC5, AC7 (repositórios e gateway fakes).
  - `test/widget_test.dart` — editar **somente se necessário**: overrides dos providers novos, caso a aba Configurações passe a lê-los no build.
  - `.agent/project_instructions.md` — editar: registrar a feature `backup` e o `file_picker` na stack.
  - `macos/Flutter/GeneratedPluginRegistrant.swift` — regenerado automaticamente pelo `flutter pub add` (registro do plugin; sem edição manual).
</files_in_scope>

<out_of_scope>
  - Google Drive / login Google / sincronização automática ou agendada.
  - Mesclar o backup com os dados atuais; importar só parte dos dados.
  - Embutir imagens de capa no arquivo.
  - Criptografia ou senha no backup.
  - Migração de versões futuras do formato (só existe a `version: 1`).
  - Alterar `Game`, `CustomList`, `IsarService` ou os `*.g.dart`.
  - Renomear a aba "Ajustes & Sync" ou mudar o ícone da AppBar (só o tooltip muda).
  - Suporte testado a iOS/desktop (o `file_picker` funciona lá, mas a validação é só no Android).
</out_of_scope>

<risks>
  - Importação apaga tudo → validar o arquivo inteiro antes, pedir confirmação com as contagens e gravar numa transação única (rollback do Isar em caso de falha).
  - `saveFile` no Android usa o SAF, com bytes obrigatórios → passar `bytes` e `mimeType: 'application/json'`. Nenhuma permissão nova no `AndroidManifest`; confirmar no emulador (AC6).
  - `file_picker` lança versões com frequência (13.3.2 saiu hoje) → o lockfile fixa a versão resolvida; usar só `saveFile`/`pickFile`/`PlatformFile.readAsBytes` (API estável desde a 13.0).
  - O Isar real não roda nos testes → a semântica de `replaceAll` é coberta pelo fake e pelo AC6 no emulador; conferir o código de `writeTxn` linha a linha na revisão.
  - O seletor do Android pode filtrar mal por extensão `.json` → usar `FileType.any` no `pickFile` e deixar a validação recusar o que não for backup.
  - `IndexedStack` constrói a aba Configurações em todo teste de `MyApp` → a `BackupSection` só lê os providers ao tocar no botão (`ref.read`), para não exigir overrides novos.
</risks>

<test_plan>
  - R1/R5 → AC1 → `test/features/backup/backup_codec_test.dart`: ida e volta com campos cheios e nulos e datas.
  - R3 → AC2 → `test/features/backup/backup_codec_test.dart`: cada tipo de arquivo inválido e versão não suportada.
  - R2 → AC3 → `test/features/backup/backup_section_test.dart`: sucesso, cancelamento e falha na exportação.
  - R3/R4 → AC4 → `test/features/backup/backup_section_test.dart`: arquivo inválido sem diálogo nem escrita.
  - R4 → AC5 → `test/features/backup/backup_section_test.dart`: cancelar e substituir no diálogo; a Biblioteca recarrega.
  - R6 → AC7 → `test/features/backup/backup_section_test.dart`: textos da aba.
  - R7 → AC8 → os próprios testes de widget com fakes + `grep` de imports na revisão.
  - R4/R5 → AC6 → manual no emulador (skill `run-game-tracker`).
</test_plan>

<execution_plan>
- [x] 1. Adicionar `file_picker` (`flutter pub add file_picker:^13.3.0`) e rodar `flutter pub get`.
- [x] 2. `BackupCodec` + `BackupFormatException` + testes AC1/AC2.
- [x] 3. `BackupRepository` e `BackupFileGateway` (+ implementação com `FilePicker`).
- [x] 4. `backup_provider.dart` com o `BackupController`.
- [x] 5. `BackupSection` e troca na aba Configurações / tooltip.
- [x] 6. Testes de widget AC3, AC4, AC5, AC7.
- [x] 7. `.agent/scripts/verify.sh` e corrigir.
- [x] 8. AC6 no emulador (`run-game-tracker`).
- [x] 9. `revisao-codigo` do diff contra esta spec.
- [x] 10. Atualizar `project_instructions.md`, `memoria` e mover a spec para `done/`.
</execution_plan>

<definition_of_done>
  - Todos os ACs atendidos e verificados; `verify.sh` verde.
  - Diff restrito a `<files_in_scope>`.
  - `project_instructions.md` e `learnings.md` atualizados.
</definition_of_done>

<review_notes>
  - `test/widget_test.dart` não precisou mudar: a `BackupSection` só lê os providers ao tocar nos botões.
  - AC6 validado no emulador `Pixel_9` em 2026-11-02 com um jogo de teste (criado, exportado, apagado, restaurado e removido no fim). Os dados reais (Super Mario 64, lista N64) continuaram intactos.
  - Suspeita descartada: o chip de status e a busca da Biblioteca continuam coerentes após importar, porque no Riverpod 2 o `invalidate` reaproveita a instância do `GameListNotifier` (os filtros em campos privados sobrevivem). Coberto pelo teste "importar mantém o filtro de status ativo na Biblioteca".
  - Ids repetidos no arquivo fazem o Isar manter só o último; `rating` não é limitado a 0–5. Só acontece com arquivo editado à mão.
</review_notes>
