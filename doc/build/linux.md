How to build Lix on Linux or macOS
==================================

If you run into any kind of roadblock, don't be shy and ask me!

* Bugs or suggestions: [Github Issues](https://github.com/SimonN/LixD/issues)
* Forums: [lemmingsforums.net](https://www.lemmingsforums.net), I'm Simon
* IRC: QuakeNet channel `#lix`, I'm SimonN or SimonNa
* E-Mail: `s.naarmann@gmail.com`
* Website: [lixgame.com](https://www.lixgame.com)



Install a D environment
-----------------------

On Arch Linux, run `# pacman -S dlang`.

On Debian/Ubuntu, run `# apt-get install ldc dub`.

On macOS, install [Homebrew](https://brew.sh/), then run
`$ brew install ldc dub`.

If you don't use a package manager, download
[LDC](https://github.com/ldc-developers/ldc/releases) and
[dub](https://code.dlang.org/download) manually.

I recommend the D compiler LDC, it produces the fastest executables.
LDC should be version 1.24.0 or newer (based on DMD 2.094.1 or newer),
checkable with `ldc2 --version`. An older LDC aren't guaranteed to build Lix.
A newer LDC should work; if it doesn't, tell me.

Alternatively, DMD is the best D compiler for debugging, it compiles D code
quicker than any other compiler. I recommend version 2.094.1 or newer,
checkable with `dmd --version`. I do *not* support GDC yet; if you prefer GDC,
tell me.

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

Run Lix:

    $ ./bin/lix

If the build fails, see the final section in this file, Troubleshooting.

If Lix runs with no problems, build a release version for better performance.
Choose LDC as the compiler; it produces the fastest-running binaries:

    $ dub build -b release --compiler=ldc2

Again, if you run into problems, see Troubleshooting at the bottom.

Lix will read/write configuration/levels/replays to its
working directory. If you need standard paths like
`/usr/share/lix/` or `~/.local/share/lix/` instead, read my
[notes for Linux package maintainers](
https://raw.githubusercontent.com/SimonN/LixD/master/doc/build/package.txt).



Add the music
-------------

Lix's music is not in version control. I encourage you to
add the music for the complete experience:
[Download the Lix music](https://www.lixgame.com/dow/lix-music.zip)
and extract this archive into Lix's directory,
you'll get a subdirectory `./music/`.



Troubleshooting
---------------

### Old Debian/Ubunto reops

If Lix fails to build on Debian or Ubuntu, your repositories might have
outdated compilers. Occasionally, Lix needs newer compilers to build. Follow
the instructions at [APT Repository for D](https://d-apt.sourceforge.io/)
to add a package repository with more recent DMD versions to your package
manager, then update DMD using that, then build Lix with

    $ dub build -b release --compiler=dmd

If you want to force a 64-bit or 32-bit build, append one of these to your
`dub build` command line:

    --arch=x86
    --arch=x86_64



### LDC runs out of memory

The D compiler LDC might abort with an internal error that prints lines like:

    #3 0x0000561462aba7b7 TemplateInstance::needsCodegen()
    #4 0x0000561462aba896 TemplateInstance::needsCodegen()
    #5 0x0000561462aba896 TemplateInstance::needsCodegen()
    ...many more such lines...

This happens because LDC runs out of stack space. Check the stack size:

    ulimit -s

Set the stack size to double that value. E.g., if it printed `8192` (8 MB),
set it to 16 MB for applications in the current shell, then run LDC again:

    ulimit -s 16384
    dub build -b release --compiler=ldc2

I ran into this problem on LDC 1.28.1 in February 2022. I hope that future
versions don't need this manual setting of the stack size.



### Other problems

If you run into any other problems, don't be shy and ask:

* Bugs or suggestions: [Github Issues](https://github.com/SimonN/LixD/issues)
* Forums: [lemmingsforums.net](https://www.lemmingsforums.net), I'm Simon
* IRC: QuakeNet channel `#lix`, I'm SimonN or SimonNa
* E-Mail: `s.naarmann@gmail.com`
* Website: [lixgame.com](https://www.lixgame.com)
