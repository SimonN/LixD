Lix
===

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked multiplayer, and a level editor.
Lix is written in the D programming language, uses Allegro 5 for graphics,
sound, and input, and uses enet for networking.

![Lix screenshot](http://lixgame.com/img/lix-d-screenshot.png)

License/Copying/Public domain
-----------------------------

Lix's code, graphic sets, sprites, levels, sound effects, and some music
tracks (but not all music tracks) are released into the public domain
via the CC0 public domain dedication.

The text font, DejaVu Sans, and some music tracks have their own licenses.
[Full license/copying text](https://raw.githubusercontent.com/SimonN/LixD/master/doc/copying.txt)

Build instructions
------------------

* Install a [D compiler, e.g., dmd](https://dlang.org/download).
* Install [dub, the D package handler](http://code.dlang.org/download).
* Install Allegro 5.2 and enet 1.3:
    * On Windows, follow [my detailed build instructions
    ](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/windows.txt).
    * On Linux/Mac, your package manager should provide them.
* Build Lix: `$ dub build -b release` or, on Windows, run `win-build.bat`.
* [Download the game music](http://www.lixgame.com/dow/lix-music.zip),
    extract in Lix's directory.
* Run Lix: `$ bin/lix`

If these build instructions were too short, read my [detailed instructions for Windows](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/windows.txt) or my
[detailed instructions for Linux](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/linux.txt). Would you like to package Lix for Linux distributions? Please see my [notes for Linux package maintainers](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt).

Networked multiplayer
---------------------

Lix has competitive multiplayer: Route as many lix as possible into your exit,
even if they're your opponents' lix.

The easiest way to play networked games is on our central server: From
Lix's main menu, go to Network Game and check “Play on the central server”.

Alternatively, you can host private games independently from the central
server. Check “Host a game yourself” in the Network Game menu, then tell
your friends to connect to your machine via “Connect to somebody else”.
To host, UDP port 22934 must be forwarded to your machine, or you can agree
on a different UDP port with your players.

It's possible to run your own standalone server outside of Lix.
To build this server program, `$ cd src/server/`, then `$ dub build`,
switch back to Lix's base directory with `$ cd ../../` and run the server
with `$ bin/server`. The server will listen on UDP port 22934; you can choose
a different port by `$ bin/server --port=<number>`.

Contact
-------

* [Lix Homepage](http://www.lixgame.com)
* [Bugs & Suggestions](https://github.com/SimonN/LixD/issues)
* E-Mail: `s.naarmann@gmail.com`
* IRC: `#lix` on QuakeNet, I'm SimonN or SimonNa.
    [Web IRC client](http://webchat.quakenet.org/?channels=lix)
* [lemmingsforums.net](https://www.lemmingsforums.net/index.php?board=8.0),
    I'm Simon
