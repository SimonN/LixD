module file.trophy.case_;

/*
 * TrophyCase: Caches trophies, loads/saves them.
 *
 * The saving/loading is called from the user options module because the
 * trophies are stored in the same file as user options. I don't like that.
 * Ultimately, the trophies should save into a standalone file, to cut
 * dependence on the user options file.
 */

import std.algorithm;
import std.conv;
import std.file;
import std.string;
import std.typecons;

import optional;
import sdlang;

import basics.globals;
import file.date;
import file.backup;
import file.filename;
import file.log;
import file.trophy.trophy;
import hardware.tharsis;

private Trophy[TrophyKey] _trophies;

void deleteAllTrophies()
{
    _trophies = null;
}

/*
 * maybeImprove: Update trophy database (user progress, list of checkmarks)
 * with a new level result. This tries to save the best result per level.
 * Call this only with winning _trophies! The progress database doesn't know
 * whether a result is winning, it merely knows how many lix were saved.
 *
 * Returns true if we updated the previous result or if no previous result
 * existed. Returns false if the previous result was already equal or better.
 */
bool maybeImprove(in TrophyKey key, in Trophy tro)
in {
    assert (tro.built !is null, "don't save trophies without a built Date");
}
body {
    if (key.fileNoExt == "")
        return false;
    Trophy* old = key in _trophies;
    if (! old) {
        old = legacyKeyFor(key) in _trophies;
    }
    if (! old || tro.shouldReplaceAfterPlay(*old)) {
        _trophies.remove(legacyKeyFor(key));
        _trophies[key] = tro;
        return true;
    }
    else {
        return false;
    }
}

Optional!Trophy getTrophy(in TrophyKey key)
{
    if (Trophy* ret = key in _trophies)
        return some(*ret);
    else if (Trophy* ret = legacyKeyFor(key) in _trophies)
        return some(*ret);
    else
        return no!Trophy;
}

void loadTrophies()
{
    _trophies = null;
    try {
        loadTrophiesSdlang();
    }
    catch (FileException e) {
        log("Can't open trophy file: " ~ fileTrophies.rootless);
        log("    -> " ~ e.msg.replace(": Bad address", "File doesn't exist"));
        loadTrophies2017format();
    }
    catch (Exception e) {
        log("Syntax errors in trophy file: " ~ fileTrophies.rootless);
        log("    -> " ~ e.msg);
        backupBrokenSdlang(fileTrophies, e);
    }
}

void saveTrophies()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "save trophies as SDLang");
    auto root = new Tag();
    foreach (key, tro; _trophies) {
        assert (tro.built !is null, "null built for " ~ key.fileNoExt);
        root.add(new Tag(null, tagName, [], [
            new Attribute("", attrFileNoExt, Value(key.fileNoExt)),
            new Attribute("", attrTitle, Value(key.title)),
            new Attribute("", attrAuthor, Value(key.author)),
            new Attribute("", attrLixSaved, Value(tro.lixSaved)),
            new Attribute("", attrSkillsUsed, Value(tro.skillsUsed)),
            new Attribute("", attrBuilt, Value(tro.built.toString)),
            new Attribute("", attrLastDir, Value(tro.lastDirWithinLevels))]));
    }
    auto f = fileTrophies.openForWriting;
    f.write(root.toSDLDocument);
    f.close();
}

///////////////////////////////////////////////////////////////////////////////

private:

enum tagName = "trophy";
enum attrFileNoExt = "file";
enum attrTitle = "title";
enum attrAuthor = "author";
enum attrLixSaved = "lixSaved";
enum attrSkillsUsed = "skillsUsed";
enum attrBuilt = "built";
enum attrLastDir = "lastDir"; // saved without leading "levels/"

TrophyKey legacyKeyFor(in TrophyKey normalKey) pure @nogc nothrow
{
    TrophyKey ret;
    ret.fileNoExt = normalKey.fileNoExt;
    ret.title = "";
    ret.author = "";
    return ret;
}

void addDuringLoad(in TrophyKey key, in Trophy tro)
in {
    assert (tro.built !is null, "don't save trophies without a built Date");
}
body {
    // Don't call addTrophy because that always overwrites the date.
    // We want the newest date here to tiebreak, unlike addTrophy.
    Trophy* old = (key in _trophies);
    if (! old || tro.shouldReplaceDuringUserDataLoad(*old))
        _trophies[key] = tro;
}

void loadTrophiesSdlang()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "load trophies as SDLang");

    auto root = sdlang.parseFile(fileTrophies.stringForReading);
    foreach (tag; root.tags.filter!(ta => ta.name == "trophy")) {
        TrophyKey key;
        key.fileNoExt = tag.getAttribute(attrFileNoExt, "");
        key.title = tag.getAttribute(attrTitle, "");
        key.author = tag.getAttribute(attrAuthor, "");
        if (key.fileNoExt == "")
            continue;

        Trophy tro = Trophy(
            new Date(tag.getAttribute(attrBuilt, "0000-00-00")),
            tag.getAttribute(attrLastDir, ""));
        tro.lixSaved = tag.getAttribute(attrLixSaved, 0);
        tro.skillsUsed = tag.getAttribute(attrSkillsUsed, 0);
        if (tro.lixSaved <= 0)
            continue;
        addDuringLoad(key, tro);
    }
}

// Legacy trophy format with IoLines, saved in ./data/user/<username>.txt.
// I should support at least until beginning of 2020.
void loadTrophies2017format()
{
    import file.option;
    import file.option;
    import file.io;

    if (userName == null) {
        log("    -> No pre-2018 format trophies found, either.");
        log("    -> That's normal when you start Lix for the first time.");
        return;
    }

    // Copypasta from file.option.load
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(legacyUserOptionFilename);
    }
    catch (Exception e) {
        // We won't log anything for the legacy format.
        try {
            lines = fillVectorFromFile(new VfsFilename(
                dirDataUser.dirRootless ~ userName ~ filenameExtConfig));
        }
        catch (Exception e) {
            log("    -> No pre-2018 format trophies found, either.");
            log("    -> That's normal when you start Lix for the first time.");
            lines = null;
        }
    }
    log("    -> Converting trophies from the pre-2018 format instead.");
    foreach (i; lines.filter!(i => i.type == '<')) {
        Filename fullPath = new VfsFilename(i.text1);
        Trophy tro = Trophy(new Date(i.text2), fullPath);
        tro.lixSaved = i.nr1;
        tro.skillsUsed = i.nr2;
        TrophyKey key;
        key.fileNoExt = fullPath.fileNoExtNoPre;
        addDuringLoad(key, tro);
    }
}
