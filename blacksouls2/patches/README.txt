This folder is mounted above Game.rgss3a, so anything placed here replaces the
game's own files without the archive being removed or touched.

Leave it empty and the game runs as shipped, in English.


INSTALLING A TRANSLATION

Put the translation's content folders directly inside this folder:

    patches/
    |-- Data/
    |-- Graphics/
    |-- Audio/     (only if the translation ships one)
    |-- Movies/    (only if the translation ships one)
    `-- Fonts/     (only if the translation ships one)

Some archives wrap everything in a single top level folder. Copy that folder's
contents, not the folder itself.

Do not copy anything Windows specific. Game.exe, System/, *.dll, *.vdf,
Game.rvproj2 and the translation's own Game.ini are all unused here.

Delete these folders again to go back to English.


A SAVE CAN STOP LOADING WHEN YOU CHANGE THIS FOLDER

Save files live one level up, next to the engine, and adding or removing a
translation never touches them. A save does store objects of the classes the
game's scripts define, though, so a translation that adds such a class makes its
saves unreadable once it is removed, and the other way round.

The Russian translation adds one, so its saves and the English ones are not
interchangeable. Another translation may add nothing that reaches a save, and
then the save travels fine.

When it does bite the game says nothing. It plays a buzzer on the load screen
and stays where it is, which looks like the button did nothing. Put the
translation back the way it was when the save was made and it will load.

So before changing this folder, either finish what you are playing or keep a
copy of the saves.


WHAT COMPAT.RB TAKES CARE OF

Translations often bundle RGSS scripts written for the Windows runtime.
compat.rb, one level up, is loaded before the game and smooths over the two
cases that would otherwise break the port:

Win32API. Steamworks achievement scripts and the Fullscreen++ plugin call it
while loading. There is no Windows DLL to load on this platform, so those calls
would kill the game before the title screen. They are made inert instead.
Fullscreen is handled by mkxp.json anyway.

Graphics.resize_screen. RGSS3 caps the screen at 640x480 and quietly clamps
anything larger, so a script asking for more is harmless on Windows. mkxp-z
honours the request, which would squeeze an oversized buffer onto the panel.
The cap is restored, so the game stays at its native 640x480.
