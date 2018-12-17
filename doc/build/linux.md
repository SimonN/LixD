How to build Lix on Linux or MacOS
==================================

If you run into any kind of roadblock, don't be shy and ask me!

* IRC: QuakeNet channel `#lix`, I'm SimonN or SimonNa
* Forums: [lemmingsforums.net](https://www.lemmingsforums.net), I'm Simon
* E-Mail: `s.naarmann@gmail.com`
* Bugs or suggestions: [Github Issues](https://github.com/SimonN/LixD/issues)
* Website: [lixgame.com](http://www.lixgame.com)



Install a D environment
-----------------------

I recommend the D compiler LDC, it produces the fastest executables.
Alternatively, DMD is the best D compiler for debugging, it compiles D code
quicker than any other compiler. I haven't tested GDC.
You also need the D standard library Phobos (might be called libphobos for DMD
or liblphobos for LDC), but those often ship with the compilers already.
Finally, dub is the D build system and source library package manager.

On Arch linux, run `# pacman -S dlang`,
this group package will install everything you need.

On Debian/Ubuntu, run `# apt-get install ldc dub`.

On MacOS, install [Homebrew](https://brew.sh/), then run
`$ brew install ldc dub`.

If you don't use a package manager, download
[LDC](https://github.com/ldc-developers/ldc/releases) and
[dub](https://code.dlang.org/download) manually.



Install required libraries
--------------------------

dub only downloads source libraries and D bindings to `~/dub/`.
dub will not download binary libraries or install anything in `/usr/`.
You must install the Allegro 5 and enet binary libraries yourself.

On Arch Linux, install:

     pkgconf
     allegro
     enet

On Debian/Ubuntu, install:

     pkgconf
     liballegro5-dev
     liballegro-acodec5-dev
     liballegro-audio5-dev
     liballegro-image5-dev
     liballegro-ttf5-dev
     libenet-dev

On Fedora 29, install:

     pkgconf-pkg-config
     allegro5-devel
     allegro5-addon-acodec-devel
     allegro5-addon-audio-devel
     allegro5-addon-image-devel
     allegro5-addon-ttf-devel
     enet-devel

On MacOS, run:

     $ brew install allegro
     $ brew install enet

If you don't use a package manager, you might
[build Allegro 5 and enet 1.3 from source](
https://github.com/SimonN/LixD/blob/master/doc/build/a5manual.md).



Build Lix
---------

Open a shell, navigate to Lix's root directory, and run `$ dub build`.
This builds a debug version. To play the game, run `$ ./bin/lix`.

If the debugging version compiles, links, and runs with no problems,
build a release version for performance:
`$ dub build -b release --compiler=ldc`.

Lix will read/write configuration/levels/replays to its
working directory. If you need standard paths like
`/usr/share/lix/` instead, read my [notes for Linux package maintainers](
https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt).



Add the music
-------------

Lix's music is not in version control. I encourage you to
add the music for the complete experience:
[Download the Lix music](http://www.lixgame.com/dow/lix-music.zip)
and extract this archive into Lix's directory,
you'll get a subdirectory `./music/`.
