Building Allegro 5 and enet from source
=======================================

Lix requires the Allegro 5.2 and enet 1.3 binary libraries.
My [build notes for Linux or MacOS](
https://github.com/SimonN/LixD/blob/master/doc/build/linux.md)
describe how to get them from your package manager.
My [build notes for Windows](
https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/win64.txt)
explain how to download the binary libraries and add them to your compiler.
**Try those instructions first.**

Only if you're sure that neither works for you, keep reading.



Building Allegro 5.2
--------------------

Install the following libraries before compiling Allegro 5.
You could get away without dumb, but Lix won't play any tracked music then.

* pkgconf or pkg-config
* zlib
* libpng
* freetype
* libvorbis
* dumb 2.0 or 0.9.3

After you've installed all those, dowload the
[Allegro 5.2 source](https://github.com/liballeg/allegro5/archive/master.zip)
or clone from github:

    $ git clone https://github.com/liballeg/allegro5

Follow Allegro's build instructions.

Allegro will detect the installed libraries and compile with support for them.
If libraries are missing, Allegro will warn during its CMake configuration,
but it will still compile without support for the missing libraries.

You must `# make install` the readily-built Allegro 5.2 libraries. If
this was the first time you've installed Allegro, run `# /sbin/ldconfig`.



Building enet 1.3
-----------------

I rely on enet 1.3.x for networking. Without enet installed, Lix would still
run and allow singleplayer games, but Lix would terminate if you tried to
connect to the network.

Download the [enet source](https://github.com/lsalzman/enet/archive/master.zip)
or clone from github:

    $ git clone https://github.com/lsalzman/enet

Lix uses enet via Derelict-enet. Derelict is a set of D library bindings and
wants dynamically linked libraries, not static libraries. Therefore, we will
build enet as a shared object:

    $ autoreconf -vfi
    $ ./configure --enable-shared=yes --enable-static=no
    $ make
    $ sudo make install

If the game doesn't find the newly-built lib, run `# /sbin/ldconfig`.
