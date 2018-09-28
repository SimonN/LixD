module file.option.load2017;

/*
 * Import user options from the legacy format (IoLines) that we used until
 * October 2018. All old option names were SNAKE_UPPERCASE. There are many
 * special rules how to convert, enough to make a separate module here.
 */

import std.algorithm;
import std.conv;
import std.uni;

import basics.globals;
import basics.help;
import file.filename;
import file.io;
import file.log;
import file.option.allopts;
import net.ac;

// This should be private. But for legacy trophy loading, file.trophy needs it.
Filename legacyUserOptionFilename()
{
    return new VfsFilename(dirDataUser.dirRootless
     ~ basics.help.escapeStringForFilename(userName)
     ~ filenameExtConfig);
}
///////////////////////////////////////////////////////////////////////////////

package:

string convert2017OptionNameToCamelCase(string optName)
{
    switch (optName) {
        case "SCROLL_SPEED_EDGE": return "edgeScrollSpeed";
        case "SCROLL_SPEED_CLICK": return "holdToScrollSpeed";
        default: break;
    } {
        Ac ac = stringToAc(optName);
        if (ac != Ac.max)
            return "keySkill" ~ ac.acToNiceCase.to!string;
    }
    // Otherwise return an automatic conversion of SNAKE_UPPERCASE
    // to camelCase.
    {
        string ret = "";
        bool capitalizeNext = false;
        foreach (dchar c; optName.asLowerCase) {
            if (c == '_') {
                capitalizeNext = true;
            }
            else {
                ret ~= capitalizeNext ? c.toUpper : c.toLower;
                capitalizeNext = false;
            }
        }
        return ret;
    }
}

unittest {
    assert ("BLOCKER".convert2017OptionNameToCamelCase == "keySkillBlocker");
    assert ("EXPLODER2".convert2017OptionNameToCamelCase =="keySkillExploder");
    assert ("AN_OLD_NAME".convert2017OptionNameToCamelCase == "anOldName");
    assert ("".convert2017OptionNameToCamelCase == "");
}

void loadUserName2017format()
{
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(basics.globals.fileGlobalConfigLegacy);
    }
    catch (Exception e) {
        // Don't log anything. It's okay if this legacy file doesn't exist.
    }
    foreach (i; lines) {
        if (i.text1 == "USER_NAME") {
            file.option.allopts.userNameOption = i.text2;
            log("    -> Taking username from pre-2018 config: " ~ i.text2);
        }
    }
}

void loadUserOptions2017format()
{
    IoLine[] lines;
    try
        lines = fillVectorFromFile(legacyUserOptionFilename);
    catch (Exception e) {
        log("Can't load user configuration for `" ~ userName ~ "':");
        log("    -> " ~ e.msg);
        log("    -> Falling back to the unescaped filename `"
            ~ userName ~ filenameExtConfig ~ "'.");
        try {
            lines = fillVectorFromFile(new VfsFilename(
                dirDataUser.dirRootless ~ userName ~ filenameExtConfig));
        }
        catch (Exception e) {
            log("    -> " ~ e.msg);
            log("    -> " ~ "Falling back to the default user configuration.");
            lines = null;
        }
    }
    foreach (i; lines.filter!(i => i.type != '<')) {
        i.text1 = i.text1.convert2017OptionNameToCamelCase;
        if (auto opt = i.text1 in _optvecLoad)
            opt.set(i);
    }
}
