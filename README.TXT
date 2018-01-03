Lix
===

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked multiplayer, and a level editor.
Lix is written in the D programming language, uses Allegro 5 for graphics,
sound, and input, and uses enet for networking.

License/Copying/Public domain
-----------------------------

Lix's code, graphic sets, sprites, sound effects, and some music tracks (but
not all music tracks) are released into the public domain via the CC0 public
domain dedication.

The text font, DejaVu Sans, and some music tracks come with their own licenses.
See `./doc/copying.txt' for details.

Build instructions
------------------

    $ git clone https://github.com/SimonN/LixD
    Install a D compiler, e.g., dmd: https://dlang.org/download
    Install dub, the D package handler: http://code.dlang.org/download
    Install the Allegro 5.2 runtime library.
    Install the enet 1.3 runtime library.
    $ dub build -b release
    Extract in Lix's directory: http://www.lixgame.com/dow/lix-music.zip
    $ bin/lix

Detailed instructions: `./doc/build/windows.txt' or `./doc/build/linux.txt'.
Linux package maintainers, please see `./doc/build/package.txt'.

Contact
-------

    Web:    http://www.lixgame.com
    Issues: https://github.com/SimonN/LixD/issues
    E-Mail: s.naarmann@gmail.com
    IRC:    irc.quakenet.org #lix, I'm SimonN or SimonNa
    Forums: lemmingsforums.net, I'm Simon
