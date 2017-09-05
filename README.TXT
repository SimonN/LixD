Lix
===

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked multiplayer, and a level editor.
Lix is written in the D programming language, uses Allegro 5 for graphics,
sound, and input, and uses enet for networking.

License/Copying/Public domain
-----------------------------

Lix is placed in the public domain via the CC0 public domain dedication.
An exception is the text font, DejaVu Sans. See `./doc/copying.txt'.

Build instructions
------------------

    $ git clone https://github.com/SimonN/LixD
    Install a D compiler, e.g., dmd: https://dlang.org/download
    Install dub, the D package handler: http://code.dlang.org/download
    Install the Allegro 5.2 runtime library.
    Install the enet 1.3 runtime library.
    $ dub -b release

Detailed instructions: `./doc/build/windows.txt' or `./doc/build/linux.txt'.

Linux package maintainers, please see `./doc/build/package.txt'.

Found a bug, have an idea? Report on https://github.com/SimonN/LixD/issues.

Contact
-------

    Web:    http://www.lixgame.com
    E-Mail: eiderdaus@gmail.com
    IRC:    irc.quakenet.org #lix, I'm SimonN or SimonNa
    Forums: lemmingsforums.net, I'm Simon
