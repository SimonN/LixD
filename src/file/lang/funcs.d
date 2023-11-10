module file.lang.funcs;

/*  enum Lang
 *      has one ID for each to-be-translated string
 *
 *  string transl(Lang)
 *      translate the ID
 *
 *  string descr(Lang)
 *      give a translated longer `|'-linebroken description for the options
 *
 *  string skillTooltip(Ac)
 *      give the skill tooltip if defined or empty string
 *
 *  void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
 *      Should be used by loading the user file, or by the options dialogue.
 *      Both of these write to the user file anyway.
 */

import enumap;

import std.array;
import std.algorithm;
import std.conv; // (enum constant) --to!Lang--> (string of its variable name)
import std.format;

import basics.globals; // fileLanguageEnglish
import file.lang.enum_;
import file.lang.keynames;
import file.option; // fileLanguage, which file does the user want
import file.io;
import file.log;
import file.filename;
import hardware.keyset;
import net.ac;

nothrow @nogc @safe {
    string transl(in Lang key) { return _globLoaded.words[key].transl; }
    string[] descr(in Lang key) { return _globLoaded.words[key].descr; }

    SkillTranslation skillTransl(in Ac ac) { return _globLoaded.skills[ac]; }
}

string nameShort(in KeySet set) { return _globLoaded.keys.nameShort(set); }
string nameLong(in KeySet set) { return _globLoaded.keys.nameLong(set); }

struct SkillTranslation {
    string name; // "Climber"
    string isPerforming; // "is climbing"
    string buttonTooltip; // "Climb all vertical walls."
}

// Get a translated string after %d/%s substitution.
// If the translation doesn't allow substitution, log and return fallback.
nothrow string translf(FormatArgs...)(in Lang key, FormatArgs args)
{
    static assert (args.length >= 1,
        "Call transl instead of translf for 0 args.");
    try {
        return format(key.transl, args);
    }
    catch (Exception e) {
        logf("Cannot format translation of `%s':", key);
        logf("    -> Translation is `%s'", key.transl);
        logf("    -> %s", e.msg);
    }
    try {
        return text(key.transl, args);
    }
    catch (Exception) {
        return key.transl;
    }
}

void loadUserLanguageAndIfNotExistSetUserOptionToEnglish()
in {
    assert (languageBasenameNoExt !is null,
        "Initialize user options before reading language files");
}
do {
    assert (fileLanguage !is null);
    if (fileLanguage.fileExists) {
        _globLoaded = Language(fileLanguage);
        return;
    }
    logf("Language file not found: %s", fileLanguage.rootless);
    if (! languageIsEnglish) {
        log("    -> Falling back to English.");
        languageBasenameNoExt = englishBasenameNoExt;
        loadUserLanguageAndIfNotExistSetUserOptionToEnglish();
    }
    else {
        log("    -> English language file not found. Broken installation?");
    }
}

string formattedWinTopologyWarnSize2() // strange here, but it's needed 2x
{
    return format!"\u2265 %3.1f \u00D7 2\u00b2\u2070 %s"(
        // greaterThan %d times 2^20 pixels
        levelPixelsToWarn * 1.0f / 2^^20,
        Lang.winTopologyWarnSize2.transl);
}

/////////////////////////////////////////////////////////////////////// private

private Language _globLoaded;

// translated strings of a loaded language
private struct Word {
    string transl;
    string[] descr;
}

private struct Language {
private:
    MutFilename _source;
    bool _fnWrittenToLog = false;

public:
    Enumap!(Lang, Word) words;
    Enumap!(Ac, SkillTranslation) skills;
    KeyNamesForOneLanguage keys;

    this(in Filename source)
    {
        _source = source;
        auto lines = fillVectorFromFile(_source);
        foreach (li; lines.filter!(l => l.type == '$')) {
            if (li.text1.startsWith("skill=")) {
                parseSkillTooltip(li.text1["skill=".length .. $], li.text2);
            }
            else {
                parseTranslation(li.text1, li.text2);
            }
        }
        warnAboutMissingWords();
    }

    void langlog(T...)(string formatstr, T formatargs)
    {
        if (! _fnWrittenToLog) {
            _fnWrittenToLog = true;
            logfEvenDuringUnittest("In language %s:", _source.rootless);
        }
        logfEvenDuringUnittest("    -> " ~ formatstr, formatargs);
    }

    void parseTranslation(in string key, in string translFromFile)
    {
        Lang langId;
        try {
            langId = key.to!Lang;
        }
        catch (ConvException) {
            langlog("Unnecessary line: %s", key);
            return;
        }
        auto range = translFromFile.splitter('|');
        if (range.empty)
            return;
        words[langId].transl = range.front;
        keys.addTranslatedKeyName(langId, range.front);
        range.popFront;
        if (range.empty)
            return;
        words[langId].descr = range.array; // all remaining fields
    }

    void parseSkillTooltip(in string acAsString, in string payloadWithBars)
    {
        immutable Ac ac = acAsString.stringToAc;
        if (ac == Ac.nothing) {
            langlog("Unknown skill: %s", acAsString);
            return;
        }
        string[] arr = payloadWithBars.split('|');
        skills[ac].name = arr.length >= 1 ? arr[0] : "";
        skills[ac].isPerforming = arr.length >= 2 ? arr[1] : "";
        skills[ac].buttonTooltip = arr.length >= 3 ? arr[2] : "";
    }

    void warnAboutMissingWords()
    {
        foreach (Lang id, ref Word word; words) {
            if (word.transl.length > 0)
                continue;
            langlog("Missing translation: %s", id.to!string);
            words[id].transl = "!" ~ id.to!string ~ "!";
        }
        foreach (Ac ac, ref SkillTranslation tr; skills) {
            if (! ac.appearsInPanel && ac.isLeaving) {
                continue; // Nowhere will Lix print text about this ac.
            }
            if (tr.name.length > 0
                && tr.isPerforming.length > 0
                && (tr.buttonTooltip.length > 0 || ! ac.appearsInPanel)
            ) {
                continue; // The desired case: Skill is completely filled.
            }
            if (tr.name.length == 0
                && tr.isPerforming.length == 0
                && tr.buttonTooltip.length == 0
            ) {
                langlog("Missing skill: %s", ac.to!string);
                continue;
            }
            string[] missed;
            if (tr.name.empty) {
                missed ~= "name";
            }
            if (tr.isPerforming.empty) {
                missed ~= "verb";
            }
            if (tr.buttonTooltip.empty && ac.appearsInPanel) {
                missed ~= "tooltip";
            }
            langlog("Missing %s for skill: %s",
                missed.join("+"), ac.to!string);
        }
    }
}

unittest {
    auto installedLangs = dirDataTransl.findFiles();
    assert (installedLangs.length >= 3, "English, German, Swedish expected.");
    assert (installedLangs.canFind!(
        fn => (fn.fileNoExtNoPre == englishBasenameNoExt)),
        "English should be among the installed languages.");
    foreach (fn; installedLangs) {
        // Write to stdout the missing and unnecessary words.
        // They don't abort the unittests.
        Language(fn);
    }
}
