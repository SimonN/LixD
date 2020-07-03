How to build Lix on Linux or macOS
==================================

If you run into any kind of roadblock, don't be shy and ask me!

* IRC: QuakeNet channel `#lix`, I'm SimonN or SimonNa
* Forums: [lemmingsforums.net](https://www.lemmingsforums.net), I'm Simon
* E-Mail: `s.naarmann@gmail.com`
* Bugs or suggestions: [Github Issues](https://github.com/SimonN/LixD/issues)
* Website: [lixgame.com](http://www.lixgame.com)



Install a D environment
-----------------------

On Arch Linux, run `# pacman -S dlang`.

On Debian/Ubuntu, run `# apt-get install ldc dub`.

On macOS, install [Homebrew](https://brew.sh/), then run
`$ brew install ldc dub`. Beware: Since January 2019, Lix on macOS 10.14
shows only black window. You're welcome to help debugging, see
[issue 381: macOS black screen](https://github.com/SimonN/LixD/issues/381).

If you don't use a package manager, download
[LDC](https://github.com/ldc-developers/ldc/releases) and
[dub](https://code.dlang.org/download) manually.

I recommend the D compiler LDC, it produces the fastest executables.
LDC must be based on DMD 2.081.1 or newer, checkable with `ldc2 --version`.
Alternatively, DMD is the best D compiler for debugging, it compiles D code
quicker than any other compiler. You need version 2.081.2 or newer.
I do *not* support GDC, it is based on too old a DMD version.

You need the D standard library Phobos (might be called *libphobos* for DMD
or *liblphobos* for LDC), but those often ship with the compilers already.
Finally, dub is the D build system and source library package manager.



Install required libraries
--------------------------

dub only downloads source libraries and D bindings to `~/dub/`.
dub will not download binary libraries or install anything in `/usr/`.
You must install the Allegro 5 and enet binary libraries yourself.

Arch Linux:

     # pacman -S pkgconf allegro enet

Debian/Ubuntu:

     # apt-get install pkgconf liballegro5-dev liballegro-acodec5-dev liballegro-audio5-dev liballegro-image5-dev liballegro-ttf5-dev libenet-dev

Fedora 29:

     # dnf install pkgconf-pkg-config allegro5-devel allegro5-addon-acodec-devel allegro5-addon-audio-devel allegro5-addon-image-devel allegro5-addon-ttf-devel enet-devel

macOS:

     $ brew install allegro enet

If you don't use a package manager, you might
[build Allegro 5 and enet 1.3 from source](
https://github.com/SimonN/LixD/blob/master/doc/build/a5manual.md).



Build Lix
---------

Get the Lix source:

*   If you use git: `$ git clone https://github.com/SimonN/LixD`
*   Without git, go with your web browser to
    [Lix's github page](https://github.com/SimonN/LixD),
    click Code, then click "Download Zip". Extract the archive somewhere.

Open a shell and navigate to the cloned/extracted Lix root directory;
this is the directory that contains `README.md` and `dub.json`.
Now, build a debug version:

     $ dub build

To play, run:

     $ ./bin/lix

If the debugging version compiles, links, and runs with no problems,
build a release version for performance, choosing LDC as the compiler because
it produces the fastest-running binaries:

     $ dub build -b release --compiler=ldc2

Lix will read/write configuration/levels/replays to its
working directory. If you need standard paths like
`/usr/share/lix/` or `~/.local/share/lix/` instead, read my
[notes for Linux package maintainers](
https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt).



Add the music
-------------

Lix's music is not in version control. I encourage you to
add the music for the complete experience:
[Download the Lix music](http://www.lixgame.com/dow/lix-music.zip)
and extract this archive into Lix's directory,
you'll get a subdirectory `./music/`.
