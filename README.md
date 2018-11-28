Lix
===

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991). Lix is free and open source.

Assign skills to guide the lix through over 600 singleplayer puzzles. Design your own levels with the included editor.

Attack and defend in real-time multiplayer for 2 to 8 players: Who can save the most lix?

![Lix screenshot](http://lixgame.com/img/lix-d-screenshot.png)

Download
--------

[![Download icon](http://lixgame.com/img/download-icon.png)](https://github.com/SimonN/LixD/releases)
[Download Lix for Windows or Linux](https://github.com/SimonN/LixD/releases)

Mac or other systems: Build from source, see below.

License/Copying/Public domain
-----------------------------

Lix's code, graphic sets, sprites, levels, sound effects, and some music
tracks (but not all music tracks) are released into the public domain
via the CC0 public domain dedication.

The text font DejaVu Sans and some music tracks have their own licenses.
[Full license/copying text](https://raw.githubusercontent.com/SimonN/LixD/master/doc/copying.txt)

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

Build instructions
------------------

Detailed instructions:

* [Detailed build instructions for Windows](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/win64.txt)
* [Detailed instructions for Linux](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/linux.txt), Mac should be similar
* [Notes for Linux package maintainers](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt)

Quick build instructions:

* Install a D compiler and dub, the build system:
    * On Windows, get [LDC for Windows-x64](https://github.com/ldc-developers/ldc/releases), it ships with dub.
    * On Arch Linux, install the `dlang` group package.
    * On other Linuxes or Mac, follow [my detailed build instructions
    ](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/linux.txt).
* Install Allegro 5.2 and enet 1.3:
    * On Windows, follow [my detailed build instructions
    ](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/win64.txt).
    * On Arch Linux, install the packages `pkgconf`, `allegro`, and `enet`.
    * On Debian or Ubuntu, install the packages `pkg-config`, `liballegro5-dev`, and `libenet-dev`.
    * On Fedora 29, install the packages `pkgconf-pkg-config`, `allegro5-devel`, `allegro5-addon-acodec-devel`, `allegro5-addon-audio-devel`, `allegro5-addon-image-devel`, `allegro5-addon-ttf-devel`, and `enet-devel`.
    * On other Linuxes or Mac, follow [my detailed build instructions
    ](https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/linux.txt).
* Build Lix: `$ dub build -b release` or, on Windows, run `win-build.bat`.
* [Download the game music](http://www.lixgame.com/dow/lix-music.zip),
    extract in Lix's directory.
* Run Lix: `$ bin/lix`

Contact
-------

* [Lix Homepage](http://www.lixgame.com)
* [Bugs & Suggestions](https://github.com/SimonN/LixD/issues)
* E-Mail: `s.naarmann@gmail.com`
* IRC: `#lix` on QuakeNet, I'm SimonN or SimonNa.
    [Web IRC client](http://webchat.quakenet.org/?channels=lix)
* [lemmingsforums.net](https://www.lemmingsforums.net/index.php?board=8.0),
    I'm Simon
