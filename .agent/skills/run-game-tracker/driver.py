#!/usr/bin/env python3
"""Driver do game_tracker num emulador/aparelho Android via adb.

Uso (a partir da raiz do projeto):
  driver.py launch            sobe `flutter run` em background e espera o app abrir
  driver.py stop              encerra o `flutter run` iniciado pelo launch
  driver.py dump              lista os elementos visíveis: rótulo e centro (x,y)
  driver.py tap X Y           toque em coordenadas físicas (as do dump)
  driver.py tapl "Rótulo"     toca no elemento cujo rótulo começa com o texto
  driver.py type "texto"      digita no campo focado (espaços são suportados)
  driver.py erase N           apaga N caracteres do campo focado
  driver.py scroll up|down    rola a tela (up = conteúdo sobe)
  driver.py waitfor "Rótulo"  espera até 15 s o rótulo aparecer
  driver.py shot NOME         screenshot em build/run-game-tracker/NOME.png

Saídas (log e screenshots) ficam em build/run-game-tracker/ (ignorado pelo git).
"""
import os
import re
import shutil
import signal
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

OUT = os.path.join("build", "run-game-tracker")
LOG = os.path.join(OUT, "flutter_run.log")
PID = os.path.join(OUT, "flutter_run.pid")


def adb_path():
    found = shutil.which("adb")
    if found:
        return found
    fallback = os.path.expanduser("~/Android/Sdk/platform-tools/adb")
    if os.path.exists(fallback):
        return fallback
    sys.exit("adb não encontrado (nem no PATH nem em ~/Android/Sdk/platform-tools)")


def device():
    out = subprocess.run([adb_path(), "devices"], capture_output=True, text=True).stdout
    devices = [line.split()[0] for line in out.splitlines()[1:] if line.endswith("\tdevice")]
    if not devices:
        sys.exit("Nenhum aparelho no adb. Liste com `flutter emulators` e inicie um.")
    return os.environ.get("ANDROID_SERIAL", devices[0])


def adb(*args, capture=False):
    cmd = [adb_path(), "-s", device(), *args]
    if capture:
        return subprocess.run(cmd, capture_output=True, check=True).stdout
    subprocess.run(cmd, check=True)


def nodes():
    """Elementos da árvore de acessibilidade com rótulo e centro."""
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml", capture=True)
    xml = adb("shell", "cat", "/sdcard/ui.xml", capture=True).decode("utf-8")
    result = []
    for node in ET.fromstring(xml).iter("node"):
        label = node.get("content-desc") or node.get("text") or node.get("hint") or ""
        match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.get("bounds", ""))
        if not label or not match:
            continue
        x1, y1, x2, y2 = map(int, match.groups())
        kind = "campo" if node.get("class") == "android.widget.EditText" else ""
        result.append((label.replace("\n", " | "), (x1 + x2) // 2, (y1 + y2) // 2, kind))
    return result


def find(label):
    for text, x, y, _ in nodes():
        if text.startswith(label):
            return x, y
    return None


def launch():
    os.makedirs(OUT, exist_ok=True)
    serial = device()
    log = open(LOG, "w")
    proc = subprocess.Popen(
        ["flutter", "run", "-d", serial],
        stdout=log,
        stderr=subprocess.STDOUT,
        stdin=subprocess.PIPE,  # mantém o modo interativo vivo sem terminal
        start_new_session=True,
    )
    with open(PID, "w") as f:
        f.write(str(proc.pid))
    deadline = time.time() + 600
    while time.time() < deadline:
        text = open(LOG, encoding="utf-8", errors="replace").read()
        if "Flutter run key commands" in text:
            print(f"App rodando em {serial} (pid {proc.pid}). Log: {LOG}")
            return
        if proc.poll() is not None or re.search(r"Error:|FAILURE|Gradle task .* failed", text):
            sys.exit(f"flutter run falhou; veja {LOG}")
        time.sleep(2)
    sys.exit(f"Tempo esgotado esperando o app; veja {LOG}")


def stop():
    if not os.path.exists(PID):
        sys.exit("Nada para parar (sem pid salvo).")
    pid = int(open(PID).read())
    try:
        os.killpg(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    os.remove(PID)
    print("flutter run encerrado.")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "launch":
        launch()
    elif cmd == "stop":
        stop()
    elif cmd == "dump":
        for text, x, y, kind in nodes():
            print(f"{x:>5},{y:<5} {kind:5} {text}")
    elif cmd == "tap":
        adb("shell", "input", "tap", args[0], args[1])
    elif cmd == "tapl":
        pos = find(args[0])
        if not pos:
            sys.exit(f"Rótulo não encontrado: {args[0]!r} (rode `dump`)")
        adb("shell", "input", "tap", str(pos[0]), str(pos[1]))
        time.sleep(1)
    elif cmd == "type":
        adb("shell", "input", "text", args[0].replace(" ", "%s"))
        time.sleep(0.4)
    elif cmd == "erase":
        for _ in range(int(args[0])):
            adb("shell", "input", "keyevent", "67")
    elif cmd == "scroll":
        y1, y2 = ("1100", "500") if args[0] == "up" else ("500", "1100")
        adb("shell", "input", "swipe", "540", y1, "540", y2, "300")
        time.sleep(1)
    elif cmd == "waitfor":
        deadline = time.time() + 15
        while time.time() < deadline:
            if find(args[0]):
                return
            time.sleep(1)
        sys.exit(f"Rótulo não apareceu: {args[0]!r}")
    elif cmd == "shot":
        os.makedirs(OUT, exist_ok=True)
        path = os.path.join(OUT, f"{args[0]}.png")
        with open(path, "wb") as f:
            f.write(adb("exec-out", "screencap", "-p", capture=True))
        print(path)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
