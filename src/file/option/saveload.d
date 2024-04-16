module file.option.saveload;

import std.file;
import std.string;

import sdlang;

import basics.globals;
import file.backup;
import file.option.allopts;
import file.log;
import hardware.tharsis;

void loadUserOptions()
{
    file.option.allopts.initializeIfNecessary();
    try {
        loadUserOptionsSdlang();
    }
    catch (FileException e) {
        log("Can't open options file: " ~ fileOptions.rootless);
        log("    -> " ~ e.msg.replace(": Bad address", "File doesn't exist."));
        log("    -> This is normal on first run. Using default options.");
    }
    catch (Exception e) {
        log("Syntax errors in options file: " ~ fileOptions.rootless);
        log("    -> " ~ e.msg);
        backupBrokenSdlang(fileOptions, e);
    }
}

nothrow void saveUserOptions()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "save options SDLang");
    try {
        auto f = fileOptions.openForWriting;
        writeKnownOptionsTo(f);
        writeUnknownOptionsTo(f);
    }
    catch (Exception e) {
        log("Can't save options to: " ~ fileOptions.rootless);
        log("    -> " ~ e.msg);
    }
}

///////////////////////////////////////////////////////////////////////////////

private:

/*
 * Before Lix 0.10.22, when you played Lix version B, then play A < B,
 * then play B again, version A saved only the options that A knew and
 * failed to save those that were new in B. Now, if we're in version A,
 * _unknownOptions will track (as children) what's new in B.
 */
Tag _unknownOptions = null;

// Can throw FileException or SDLang's own exceptions.
void loadUserOptionsSdlang()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "load options SDLang");
    _unknownOptions = new Tag();
    auto root = sdlang.parseFile(fileOptions.stringForReading);
    foreach (tag; root.tags) {
        if (auto opt = tag.name in _optvecLoad) {
            opt.set(tag);
        }
        else {
            _unknownOptions.add(tag.clone);
        }
    }
}

// Can throw FileException or SDLang's own exceptions.
void writeKnownOptionsTo(ref typeof(fileOptions.openForWriting()) f)
{
    // We'll make two root tags. One until before screenMode, then
    // one for screenMode and everything afterwards. Reason: We'll
    // write a comment between the two tags which sdlang-d doesn't support.
    Tag[] roots = [ new Tag() ];
    foreach (opt; _optvecSave) {
        if (opt is screenType) {
            roots ~= [ new Tag() ];
        }
        roots[$-1].add(opt.createTag);
    }
    assert (roots.length == 2, "no screenMode tag? Can't save comment");
    f.write(roots[0].toSDLDocument);
    f.writeln("// screenMode 0: windowed, user-defined window size");
    f.writeln("// screenMode 1: software fullscreen, auto-detect resol.");
    f.writeln("// screenMode 2: hardware fullscreen, user-defined resol.");
    f.write(roots[1].toSDLDocument);
}

// Can throw FileException or SDLang's own exceptions.
void writeUnknownOptionsTo(ref typeof(fileOptions.openForWriting()) f)
{
    if (_unknownOptions is null || _unknownOptions.tags.length == 0) {
        return;
    }
    f.writeln();
    f.writeln("// Unknown options from past or future Lix versions");
    f.write(_unknownOptions.toSDLDocument);
}
