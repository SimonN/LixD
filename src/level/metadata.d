module level.metadata;

/*
 * This throws on malformed UTF! If you call new LevelMetaData("a.zip"), catch.
 */

import basics.globals;
import file.date;
import file.filename;
import file.log;
import file.io;
import level.level;

class LevelMetaData {
public:
    Date       built;
    int        initial;
    int        required;
    string     nameGerman;
    string     nameEnglish;
    string     author;

    this(in Filename fn) // throws onwards any caught exception
    {
        try {
            MutableDate tmp;
            readFile(fn, tmp);
            built = tmp;
        }
        catch (Exception e) {
            logf("Error reading level metadata for `%s':", fn.rootless);
            logf("    -> %s", e.msg);
            initial = 0;
            nameEnglish = "";
            throw e;
        }
    }

    @property string name() const nothrow @nogc
    {
        // DTODO, see comment in like-named function in level.level
        return nameEnglish == "" ? nameGerman : nameEnglish;
    }

    @property bool empty() const nothrow @nogc
    {
        return initial == 0 && nameEnglish == "";
    }

private:
    void readFile(in Filename fn, out MutableDate builtTemp)
    {
        IoLine[] lines = fillVectorFromFile(fn);
        foreach (i; lines) {
            if (i.text1 == levelBuilt)       builtTemp   = new Date(i.text2);
            if (i.text1 == levelNameGerman)  nameGerman  = i.text2;
            if (i.text1 == levelNameEnglish) nameEnglish = i.text2;
            if (i.text1 == levelInitial)     initial     = i.nr1;
            if (i.text1 == levelRequired)    required    = i.nr1;
            if (i.text1 == levelAuthor)      author      = i.text2;

            // Speed up loading many Metadatas by not processing too many
            // lines. We hope that no important data appears after first tiles.
            if (i.type == ':')
                break;
        }
    }
}
