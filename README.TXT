Lix D/A5 port
=============

Lix is an action-puzzle game inspired by Lemmings (DMA Design, 1991),
with singleplayer puzzles, networked competitive multiplayer mode,
and a level editor. The current main repository is over there:

    http://github.com/SimonN/Lix

The repository here instead is an ongoing attempt to port Lix to the
D Programming Language, using Allegro 5 for graphics, input, and sound.
The port is not finished yet, but you can already see lix walk around
the level, and click on them.

If you would like to play Lix, do not build from this repository,
instead build from the main repository linked above.

How to build
------------

For detailed instructions, read the file for your operating system:
`./doc/build/linux.txt' or `.doc/build/windows.txt'. Ignore `cross.txt'.

Quick instructions:

*   $ git clone https://github.com/SimonN/LixD
*   Install a D compiler (e.g., dmd, from https://dlang.org/download)
*   Install dub (the D package handler, ships with dmd)
*   Install the Allegro 5 runtime library (Allegro 5.0.x or 5.1.x work)
*   $ dub

If you get stuck, follow the detailed instructions in `./doc/build/',
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
