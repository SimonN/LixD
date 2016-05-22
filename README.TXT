Lix D/A5 port
=============

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked competitive multiplayer mode,
and a level editor.

I've rewritten Lix in the D Programming Language and rely on Allegro 5
for graphics, sound, and input. The networking mode is not implemented
in this rewrite yet. To play a networked game, use the older C++ version:

    http://github.com/SimonN/Lix

How to build
------------

Detailed instructions: `./doc/build/linux.txt' or `.doc/build/windows.txt'.

Quick instructions:

*   $ git clone https://github.com/SimonN/LixD
*   Install a D compiler (e.g., dmd, from https://dlang.org/download)
*   Install dub, the D package handler (http://code.dlang.org/download)
*   Install the Allegro 5 runtime library (Allegro 5.0.x or 5.1.x work)
*   $ dub

If you get stuck, follow the detailed instructions in `./doc/build/*.txt',
or contact me:

    E-Mail: eiderdaus@gmail.com
    IRC:    irc.quakenet.org #lix

License/Copying
---------------

Almost everything of Lix is placed in the public domain via the CC0 public
domain dedication. An exception is the text font, DejaVu Sans. For detailed
information, please read `./doc/copying.txt'.

Quote
-----

<NaOH>   to be honest, I thought you were joking when you first said you were
         going to redo this in D, but it looks like you've made some good
         progress.
<SimonN> yes, it's become a serious port attempt; there's too much invested
         already to abort it anytime soon
<NaOH>   ^sunk cost fallacy?
<SimonN> sunk love
