Lix D/A5 port
=============

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked competitive multiplayer mode,
and a level editor. Lix came to life as a C++/Allegro 4 game in 2006.

I (Simon) have rewritten Lix in the D Programming Language and rely on
Allegro 5 for graphics, sound, and input. I'm still porting the networking.

Right now, in 2016, you need the C++ version to play networked games:

    http://github.com/SimonN/Lix

How to build D Lix
------------------

Detailed instructions: `./doc/build/linux.txt' or `.doc/build/windows.txt'.

Quick instructions:

*   $ git clone https://github.com/SimonN/LixD
*   Install a D compiler (e.g., dmd, from https://dlang.org/download)
*   Install dub, the D package handler (http://code.dlang.org/download)
*   Install the Allegro 5.2 runtime library. Allegro 4.x will not work.
        For Allegro 5.0 instead of 5.2, read `./doc/build/allegro.txt'.
*   Install the enet 1.3.1 runtime library.
*   $ dub

If you get stuck, follow the detailed instructions in `./doc/build/'.
Feel free to contact me, I don't bite. :-) See below for my contact details.

Report bugs
-----------

See the list of known bugs, or file a bug that you have found:

    https://github.com/SimonN/LixD/issues

License/Copying
---------------

Almost everything of Lix is placed in the public domain via the CC0 public
domain dedication. An exception is the text font, DejaVu Sans. For detailed
information, please read `./doc/copying.txt'.

Contact
-------

    E-Mail: eiderdaus@gmail.com
    IRC:    irc.quakenet.org #lix, my nickname is SimonN or SimonNa
    Forums: lemmingsforums.net, my username is Simon
