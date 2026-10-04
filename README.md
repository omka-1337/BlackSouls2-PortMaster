## Notes

Thanks to [Eeny, meeny, miny, moe?](https://store.steampowered.com/app/3855540/BLACK_SOULS_II/) for creating BLACK SOULS II, which takes the fairy tale cast of the first game somewhere considerably darker.

The game is a paid title, so this port ships the engine only. Copy `Audio/`, `Graphics/`, `Fonts/`, `Movies/`, `Game.ini` and `Game.rgss3a` from your own installation into the `blacksouls2` folder, alongside the engine. `Game.exe`, `System/`, `ver.txt` and the `.vdf` files are Windows or Steam only and are not needed.

The Steam release ships a heavily reduced build of the game: its `Game.rgss3a` declares 17 maps where the full release has 409. The publisher offers a free official patch that restores the full game, and it has to be applied to the Steam copy before the files are worth copying here, otherwise the port faithfully runs the reduced build. A copy bought on DLsite is complete as it is. This port was tested against both a reduced and a full set of files.

Note where the patched content ends up. If applying the patch updates `Game.rgss3a` itself, copy that archive across as usual. If it instead leaves loose `Data/`, `Graphics/` or `Audio/` folders beside the archive, those go into `patches/` rather than next to the engine: where the same file exists in both, the archive wins, so copying them alongside the engine would silently leave the reduced build running.

The loose `Graphics/` folder matters here. It holds the RTP artwork the game draws on, and only four of its files also exist inside `Game.rgss3a`; for those four the archive wins, which is what the game expects, since the archived copies are its own and the loose ones are the stock defaults.

The game renders at 640x480, so it is pixel for pixel on a 640x480 panel with no scaling.

## Translations

`blacksouls2/patches/` is mounted above `Game.rgss3a`, so a translation can replace the game's data without the archive being removed or touched. The folder is empty by default, which leaves the game in English.

Translations are distributed as a set of RPG Maker folders. Put the content folders directly inside `patches/`:

```
patches/
├── Data/
├── Graphics/
├── Audio/     (only if the translation ships one)
├── Movies/    (only if the translation ships one)
└── Fonts/     (only if the translation ships one)
```

Some archives wrap everything in a single top level folder, in which case copy that folder's contents rather than the folder itself. Leave out anything Windows specific: `Game.exe`, `System/`, `*.dll`, `*.vdf`, `Game.rvproj2` and the translation's own `Game.ini` are all unused here. Delete the folders again to go back to English.

A save belongs to the script set that made it. Saves sit next to the engine and are never touched by what you put in `patches/`, but a save stores objects of the classes the game's scripts define, and will not load under a script set that is missing one of them. The reduced Steam build and the full build differ that way, and so can two translations. That is what bit here during testing: a save made against the full data would not load against the reduced Steam scripts, because it carried a `Game_Map_Effects` object those scripts have never heard of. The game stays quiet about it: `DataManager.load_game` swallows the error, so the load screen buzzes and sits there as though the button did nothing. Put the data back the way it was when the save was made and it loads. This is how the game behaves on Windows too.

`compat.rb` is loaded before the game and covers the two things a translation's bundled RGSS scripts expect from the Windows runtime:

`Win32API`, called while loading by Steamworks achievement scripts and by the Fullscreen++ plugin. There is no Windows DLL to load on this platform, so those calls would kill the game before the title screen. They are made inert instead, and fullscreen is handled by `mkxp.json` anyway.

`Graphics.resize_screen`, which RGSS3 caps at 640x480 and silently clamps. A script asking for more therefore costs nothing on Windows, but mkxp-z honours the request and would render the game into an oversized buffer squeezed onto the panel. The cap is restored, so the game stays at 640x480 whatever a script asks for.

## Controls

| Button | Action |
|--|--|
| D-Pad | Move, menu navigation |
| B | Confirm |
| A | Cancel, open menu |
| X | Dash |
| Start | Open menu |

Face button positions vary between handhelds, so Confirm and Cancel may sit the other way round on your device. The port does not remap anything: mkxp-z reads the pad through `SDL_GameController`, and the mapping comes from the firmware's own controller database.

## Compile

The shipped `mkxp-z.aarch64` is the aarch64 build from the PortMaster Last Scenario port. To build the engine from source instead:

1. Build the bundled dependencies and Ruby.

```
git clone --recursive https://github.com/mkxp-z/mkxp-z.git
cd mkxp-z/linux
make -j$(nproc)
source vars.sh
```

2. Link against the system SDL2 rather than mkxp-z's own static fork. In `src/meson.build` force `dependency('SDL2', static: false)`, and in `linux/Makefile` drop `sdl2` from the `sdl2image`, `sdlsound`, `sdl2ttf` and `deps-core` prerequisite lists. Verify with `readelf -d build/mkxp-z.aarch64 | grep NEEDED`, which should list `libSDL2-2.0.so.0`.

3. Build the engine itself with the GLES backend.

```
cd ..
meson setup build -Dgfx_backend=gles -Denable-https=false --bindir=. --prefix=$PWD/build/local
cd build
ninja
ninja install
```

The Ruby standard library shipped as `stdlib.tar.gz` comes from `linux/build-<arch>/lib/ruby/3.1.0`.
