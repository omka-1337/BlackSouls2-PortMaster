#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR=/$directory/ports/blacksouls2
BINARY=mkxp-z.${DEVICE_ARCH}

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# The game is a paid title, so its files are user supplied.
if [ ! -f "$GAMEDIR/Game.rgss3a" ]; then
  echo "Game files not found. See README.md for how to supply them."
  echo "Expected: $GAMEDIR/Game.rgss3a"
  sleep 5
  exit 1
fi

# Ruby's standard library is 1160 files, so it ships packed.
if [ ! -d "$GAMEDIR/stdlib" ]; then
  gunzip -c "$GAMEDIR/stdlib.tar.gz" | tar xf - -C "$GAMEDIR"
fi

export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$GPTOKEYB2 "$BINARY" -c "$GAMEDIR/blacksouls2.ini" &

pm_platform_helper "$GAMEDIR/$BINARY"

./$BINARY

pm_finish
