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

# Rewrite the preloadScript line in place, keeping the comments around it.
new_line = '    "preloadScript": %s,' % json.dumps(pre)
if re.search(r'^\s*"preloadScript":.*$', raw, re.M):
    raw = re.sub(r'^\s*"preloadScript":.*$', new_line, raw, count=1, flags=re.M)
else:
    raw = re.sub(r'(^\s*"rgssVersion":.*$)', r'\1\n' + new_line, raw, count=1, flags=re.M)
open(cfg, "w").write(raw)
json.loads(re.sub(r"//.*", "", raw))

BLOCK = """
# >>> screenshot hook, added by tools/screenshot.sh
[controls:shot_a]
overlay = parent
r3 = f9

[controls:shot_b]
overlay = parent
l3 = f9
# <<< screenshot hook
"""

if os.path.exists(ini):
    t = open(ini).read()
    t = re.sub(r"\n# >>> screenshot hook.*?# <<< screenshot hook\n", "\n", t, flags=re.S)
    if action == "install":
        t = re.sub(r"^l3 =[ \t]*$", "l3 = hold_state shot_a", t, flags=re.M)
        t = re.sub(r"^r3 =[ \t]*$", "r3 = hold_state shot_b", t, flags=re.M)
        t = t.rstrip("\n") + "\n" + BLOCK
    else:
        t = re.sub(r"^l3 = hold_state shot_a$", "l3 =", t, flags=re.M)
        t = re.sub(r"^r3 = hold_state shot_b$", "r3 =", t, flags=re.M)
    t = t.rstrip("\n") + "\n"
    open(ini, "w").write(t)

print(f"{action}: preloadScript = {pre}")
print(f"{action}: {os.path.basename(ini)} L3+R3 " + ("bound" if action == "install" else "cleared"))
PY

if [ "$action" = "install" ]; then
  echo "Press L3 + R3 together in game. Frames land in $target/screenshots/."
  echo "Run 'tools/screenshot.sh remove $target' before building a release."
fi
