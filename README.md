Lix
===

Lix is a puzzle game inspired by *Lemmings* (DMA Design, 1991). Lix is free and open source.

Assign skills to guide the lix through over 600 singleplayer puzzles. Design your own levels with the included editor.

Attack and defend in real-time multiplayer for 2 to 8 players: Who can save the most lix?

![Lix screenshot](http://lixgame.com/img/lix-d-screenshot.png)

Download
--------

[![Download icon](http://lixgame.com/img/download-icon.png)](https://github.com/SimonN/LixD/releases)
[Download Lix for Windows or Linux](https://github.com/SimonN/LixD/releases)

macOS or others: Build from source, see below.

macOS users: In January-April 2019, Lix on macOS 10.14
sometimes showed only a black window. Does this still happen? See
[issue 381: macOS black screen](https://github.com/SimonN/LixD/issues/381).

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

* [Build instructions for Windows](
https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/win64.txt)
* [Build instructions for Linux or macOS](
https://github.com/SimonN/LixD/blob/master/doc/build/linux.md)
* [Notes for Linux package maintainers](
https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt)

Quick instructions: You need a D compiler, dub, Allegro 5.2, and enet 1.3. Build Lix with `$ dub build -b release`, then [download the game music](http://www.lixgame.com/dow/lix-music.zip) and extract it in Lix's directory.

Contact
-------

* [Lix Homepage](http://www.lixgame.com)
* [Bugs & Suggestions](https://github.com/SimonN/LixD/issues)
* E-Mail: `s.naarmann@gmail.com`
* IRC: `#lix` on QuakeNet, I'm SimonN or SimonNa.
    [Web IRC client](http://webchat.quakenet.org/?channels=lix)
* [lemmingsforums.net](https://www.lemmingsforums.net/index.php?board=8.0),
    I'm Simon
