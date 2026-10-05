#!/bin/bash
# Installs or removes the L2 screenshot hook on an installed port.
# Development only: the hook must not be in a release.
#
#   tools/screenshot.sh install /run/media/you/SHARE/roms/ports/blacksouls
#   tools/screenshot.sh remove  /run/media/you/SHARE/roms/ports/blacksouls
set -euo pipefail

cd "$(dirname "$(realpath "$0")")/.."

action="${1:-}"
target="${2:-}"

if [ "$action" != "install" ] && [ "$action" != "remove" ]; then
  echo "usage: tools/screenshot.sh install|remove <path to the installed port>"
  exit 1
fi
if [ ! -d "$target" ] || [ ! -f "$target/mkxp.json" ]; then
  echo "ERROR: $target does not look like an installed port (no mkxp.json)."
  exit 1
fi

python3 - "$action" "$target" <<'PY'
import json, os, re, shutil, sys

action, target = sys.argv[1], sys.argv[2]
hook = "screenshot_tool.rb"
ini = os.path.join(target, os.path.basename(target.rstrip("/")) + ".ini")
cfg = os.path.join(target, "mkxp.json")

raw = open(cfg).read()
data = json.loads(re.sub(r"//.*", "", raw))
pre = data.get("preloadScript", [])

if action == "install":
    shutil.copy(os.path.join("tools", hook), os.path.join(target, hook))
    if hook not in pre:
        pre.append(hook)
else:
    if os.path.exists(os.path.join(target, hook)):
        os.remove(os.path.join(target, hook))
    pre = [x for x in pre if x != hook]
    for f in os.listdir(target):
        if re.fullmatch(r"screenshot_\d+\.png", f):
            os.remove(os.path.join(target, f))

# Rewrite the preloadScript line in place, keeping the comments around it.
new_line = '    "preloadScript": %s,' % json.dumps(pre)
if re.search(r'^\s*"preloadScript":.*$', raw, re.M):
    raw = re.sub(r'^\s*"preloadScript":.*$', new_line, raw, count=1, flags=re.M)
else:
    raw = re.sub(r'(^\s*"rgssVersion":.*$)', r'\1\n' + new_line, raw, count=1, flags=re.M)
open(cfg, "w").write(raw)
json.loads(re.sub(r"//.*", "", raw))

if os.path.exists(ini):
    t = open(ini).read()
    t = re.sub(r"^l2 = f9$", "l2 =", t, flags=re.M) if action == "remove" else re.sub(r"^l2 =\s*$", "l2 = f9", t, flags=re.M)
    open(ini, "w").write(t)

print(f"{action}: preloadScript = {pre}")
print(f"{action}: {os.path.basename(ini)} l2 = " + ("f9" if action == "install" else "<blank>"))
PY

if [ "$action" = "install" ]; then
  echo "Press L2 in game. Frames land in $target as screenshot_NNN.png."
  echo "Run 'tools/screenshot.sh remove $target' before building a release."
fi
