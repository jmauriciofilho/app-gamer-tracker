# 🎮 Rastreador de Games

App Flutter pessoal e offline para catalogar jogos: status, nota, plataforma e
datas, além de listas personalizadas montadas por filtros. Os dados ficam no
aparelho (banco Isar local), sem conta nem servidor.

## Funcionalidades

- **Biblioteca** com busca por nome, filtro por status (Para Jogar, Jogando,
  Jogado, Finalizado, 100%) e ordenação (Recentes, Título A–Z, Maior nota).
- **Cadastro e edição de jogos** com capa, plataforma, desenvolvedora, gênero,
  ano, nota em estrelas e datas de início e término.
- **Busca de dados do jogo**: o botão ao lado do título consulta o
  [Wikidata](https://www.wikidata.org) (sem chave de API) e preenche título,
  desenvolvedora, gênero, ano e a capa da Steam, quando o jogo está lá. As
  plataformas do jogo aparecem como chips para escolher.
- **Listas personalizadas** por filtros: desenvolvedora, plataforma, gênero,
  status, título, intervalo de ano de lançamento e ano de término.
- **Estatísticas**: totais, nota média, jogos por status, terminados por ano e
  as 5 plataformas e os 5 gêneros mais frequentes.
- **Backup local em JSON**: exporta e importa todos os jogos e listas pelo
  seletor de arquivos do sistema. Importar substitui os dados atuais, depois
  de uma confirmação.

## Stack

| Área | Tecnologia |
|---|---|
| Linguagem / framework | Dart `>=3.10` · Flutter (Material 3, tema escuro) |
| Estado | `flutter_riverpod` |
| Banco local | `isar_community` (schemas gerados com `build_runner`) |
| Rede | `http` (Wikidata e CDN da Steam) · `cached_network_image` (capas) |
| Arquivos | `file_picker` (backup) |
| Testes | `flutter_test` com repositórios e serviços falsos (sem Isar nem rede) |

## Como rodar

Pré-requisitos: Flutter estável instalado e um emulador ou aparelho Android
(`flutter devices`).

```bash
flutter pub get
```

```bash
flutter run
```

Depois de alterar uma `@collection` do Isar, regenere os arquivos `*.g.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Qualidade

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter build apk --debug
```

O script `.agent/scripts/verify.sh` roda lint, testes e build em sequência.

## Estrutura

Organização por feature, cada uma separada em `data` (modelos, repositórios,
serviços) e `presentation` (providers, telas, widgets):

```
lib/
├── main.dart                 # ProviderScope → MyApp → HomeScreen (4 abas)
├── core/services/            # IsarService (abre o banco com todos os schemas)
└── features/
    ├── games/                # biblioteca, cadastro/edição, ordenação, status
    ├── custom_lists/         # listas por filtros
    ├── game_lookup/          # busca de dados no Wikidata + capa da Steam
    ├── stats/                # aba Estatísticas
    └── backup/               # exportar/importar JSON
test/                         # espelha lib/features/
```

O acesso ao banco passa sempre pelos repositórios, e a UI lê os dados pelos
providers Riverpod.

## Fluxo de desenvolvimento

O projeto segue **Spec Driven Development**: as instruções para agentes de IA
estão em [`AGENTS.md`](AGENTS.md) e o contexto técnico em
[`.agent/project_instructions.md`](.agent/project_instructions.md). As specs de
cada entrega ficam em `.agent/specs/done/`.

Commits seguem Conventional Commits em pt-BR (`feat(escopo): ...`,
`fix: ...`, `chore: ...`).
