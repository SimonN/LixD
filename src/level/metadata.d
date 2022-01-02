module level.metadata;

/*
 * This throws on malformed UTF! If you call new LevelMetaData("a.zip"), catch.
 */

import std.algorithm;
import std.string;

import basics.globals;
import file.date;
import file.filename;
import file.log;
import file.io;
import level.level;

class LevelMetaData {
private:
    MutableDate _built;
    string[] _tags;

public:
    int initial;
    int required;
    string nameGerman;
    string nameEnglish;
    string author;

    this()
    {
        touch();
        initial = 20;
        required = 20;
    }

    /*
     * Use this ctor when you want raw MetaData without loading it within a
     * full level that merely treats the MetaData as fields. You'll want to use
     * this when you have a database of MetaData.
     *
     * Throws onward any caught exception from opening the file.
     */
    this(in Filename fn)
    {
        try {
            IoLine[] lines = fillVectorFromFile(fn);
            foreach (i; lines) {
                parse(i);
                // Speed up loading many Metadatas by not processing too many
                // lines. We hope that no important data follows first tiles.
                if (i.type == ':') {
                    break;
                }
            }
        }
        catch (Exception e) {
            logf("Error reading level metadata for `%s':", fn.rootless);
            logf("    -> %s", e.msg);
            _built = new Date("0000-00-00");
            initial = 0;
            nameEnglish = "";
            throw e;
        }
        if (_built is null) {
            _built = new Date("0000-00-00");
        }
    }

    void touch()
    {
        _built = Date.now();
    }

    const pure nothrow @safe @nogc {
        Date built() { return _built; }
        string name() { return nameEnglish == "" ? nameGerman : nameEnglish; }
        const(string)[] tags() { return _tags; }
        bool empty() { return initial == 0 && nameEnglish == ""; }
    }

    override bool opEquals(Object rhs_obj)
    {
        const(LevelMetaData) rhs = cast (const(LevelMetaData)) rhs_obj;
        return rhs_obj !is null
            && this.author == rhs.author
            && this.nameGerman == rhs.nameGerman
            && this.nameEnglish == rhs.nameEnglish
            && this.initial == rhs.initial
            && this.required == rhs.required;
        // We don't compare Date. Levels can be equal even with different
        // dates of last modification.
    }


package:
    void parse(in IoLine line)
    {
        if (line.text1 == levelBuilt) _built = new Date(line.text2);
        else if (line.text1 == levelNameGerman) nameGerman = line.text2;
        else if (line.text1 == levelNameEnglish) nameEnglish = line.text2;
        else if (line.text1 == levelInitial) initial = line.nr1;
        else if (line.text1 == levelRequired) required = line.nr1;
        else if (line.text1 == levelAuthor) author = line.text2;
        else if (line.text1 == levelTag) insertTag(line.text2);
    }

    void insertTag(in string tag)
    {
        const string cleaned = tag.strip.toLower;
        if (cleaned.empty || _tags.canFind(cleaned)) {
            return;
        }
        _tags = (_tags ~ cleaned).sort.release;
    }
}

unittest {
    LevelMetaData md = new LevelMetaData;
    md.insertTag("   hello ");
    md.insertTag("z");
    md.insertTag("hello    ");
    assert (md.tags.length == 2);
    assert (md.tags[0] == "hello");
}
