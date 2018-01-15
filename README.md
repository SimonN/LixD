Lix
===

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked multiplayer, and a level editor.
Lix is written in the D programming language, uses Allegro 5 for graphics,
sound, and input, and uses enet for networking.

![Lix screenshot](http://lixgame.com/img/lix-d-screenshot.png)

License/Copying/Public domain
-----------------------------

Lix's code, graphic sets, sprites, sound effects, and some music tracks (but
not all music tracks) are released into the public domain via the CC0 public
domain dedication.

The text font, DejaVu Sans, and some music tracks have their own licenses.
Details:
[doc/copying.txt](https://raw.githubusercontent.com/SimonN/LixD/master/doc/copying.txt)

Build instructions
------------------

* Install a [D compiler, e.g., dmd](https://dlang.org/download).
* Install [dub, the D package handler](http://code.dlang.org/download).
* Install Allegro 5.2 and enet 1.3:
    * On Linux/Mac, your package manager should provide them.
    * On Windows, read [my detailed build instructions
    ](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/windows.txt).
* Build Lix: `$ dub build -b release`
* [Download the game music](http://www.lixgame.com/dow/lix-music.zip)
    and extract it in Lix's directory.
* Run Lix: `$ bin/lix`

Detailed instructions:
[doc/build/windows.txt](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/windows.txt) or
[doc/build/linux.txt](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/linux.txt).
Linux package maintainers, please see
[doc/build/package.txt](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt).

Contact
-------

* [Lix Homepage](http://www.lixgame.com)
* [Bugs & Suggestions](https://github.com/SimonN/LixD/issues)
* E-Mail: `s.naarmann@gmail.com`
* IRC: `#lix` on QuakeNet, I'm SimonN or SimonNa.
    [Web IRC client](http://webchat.quakenet.org/?channels=lix)
* [lemmingsforums.net](https://www.lemmingsforums.net/index.php?board=8.0),
    I'm Simon
