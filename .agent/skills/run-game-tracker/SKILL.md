---
name: run-game-tracker
description: Roda, inicia e controla o app Flutter game_tracker num emulador Android via adb — abrir o app, tocar em botões, preencher formulários, tirar screenshot e testar uma mudança no app real (Isar de verdade). Use para "rodar o app", "testar no app", "screenshot", "run", "start", "launch".
---

# ▶️ Rodar e controlar o game_tracker

App Flutter offline (Isar local). O caminho do agente é o driver
`.claude/skills/run-game-tracker/driver.py`, que fala com o emulador Android
pelo `adb`: sobe o `flutter run`, lê a árvore de acessibilidade (rótulos e
coordenadas), toca, digita e tira screenshots.
Todos os caminhos são relativos à raiz do projeto.

## Pré-requisitos

- Flutter no PATH e Android SDK em `~/Android/Sdk` (o driver acha o `adb` lá se
  ele não estiver no PATH).
- Um emulador ligado. Conferir e listar:

```bash
flutter devices
```

```bash
flutter emulators
```

  Nesta máquina o emulador é `Pixel_9` (aparece como `emulator-5554`). O desktop
  Linux **não** aparece em `flutter devices`; use o Android.

## Rodar (agente)

```bash
python3 .claude/skills/run-game-tracker/driver.py launch
```

Espera até o app abrir (primeira build leva ~1–2 min). Depois, comandos de uma
linha cada:

```bash
D=.claude/skills/run-game-tracker/driver.py
python3 $D tapl "Minhas Listas"      # toca pelo rótulo (prefixo)
python3 $D dump                      # rótulos + centro (x,y); "campo" = TextField
python3 $D tapl "Nova Lista"
python3 $D tapl "Nome da Lista"      # campos são achados pelo hint
python3 $D type "Lista de teste"
python3 $D scroll up                 # rola até os campos de baixo
python3 $D tapl "Lançado de"
python3 $D type 95
python3 $D tapl "Criar Lista"
python3 $D waitfor "Ano inválido"
python3 $D shot form-erro            # -> build/run-game-tracker/form-erro.png
python3 $D tapl "Back"               # seta da AppBar (sem salvar)
python3 $D stop
```

Outros: `tap X Y` (coordenadas do `dump`) e `erase N` (apaga N caracteres).
Log do `flutter run`: `build/run-game-tracker/flutter_run.log`.
**Olhe o screenshot** (Read no `.png`) para confirmar o que aconteceu.

## Rodar (humano)

`flutter run` num terminal; `r` faz hot reload, `q` sai.

## Testes

```bash
.agent/scripts/verify.sh lint test
```

## Gotchas

- **O banco do emulador tem dados reais do usuário** (ex.: Super Mario 64, lista
  "N64"). Prefira fluxos que não salvam; se criar listas ou jogos de teste,
  apague no final (detalhe → "Excluir Lista" → "Excluir").
- **Nunca use a tecla voltar (`keyevent 4`) para fechar o teclado.** Se o teclado
  já estiver fechado, ela desempilha a tela e, na home, **fecha o app**. Para
  sair de um campo, toque no próximo; para sair da tela, `tapl "Back"`.
- **SnackBar empurra o FAB.** Depois de salvar, "Nova Lista" sobe de y≈2035 para
  y≈1900 por ~4 s; toque por coordenada fixa acerta outra coisa (já abriu o card
  "N64" por engano). Use `tapl` (lê a posição na hora) ou espere ~6 s.
- **Screenshot é 1080×2424** e a imagem chega reduzida; não meça coordenadas
  nela, use o `dump`.
- Com o teclado aberto, os campos de ano e "Criar Lista" ficam escondidos e não
  aparecem no `dump`: rode `scroll up` antes.
- `uiautomator` mostra TextField pelo atributo `hint` (some quando o campo tem
  texto; aí o rótulo vira o próprio texto).

## Troubleshooting

- `command not found: adb` → o driver usa `~/Android/Sdk/platform-tools/adb`; em
  shell manual, chame por esse caminho.
- Tela inicial do Android no screenshot → o app foi fechado (provável tecla
  voltar). Reabra com `stop` e `launch`.
