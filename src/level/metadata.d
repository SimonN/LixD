module level.metadata;

import basics.globals;
import file.date;
import file.filename;
import file.log;
import file.io;
import level.level;
import level.levelio;

class LevelMetaData {
public:
    FileFormat format;
    Date       built;
    int        initial;
    int        required;
    string     nameGerman;
    string     nameEnglish;

    this(in Filename fn) // throws onwards any caught exception
    {
        try {
            format = level.levelio.get_file_format(fn);
            MutableDate tmp;
            if      (format == FileFormat.LIX)     metadata_lix    (fn, tmp);
            else if (format == FileFormat.BINARY)  metadata_binary (fn, tmp);
            else if (format == FileFormat.LEMMINI) metadata_lemmini(fn, tmp);
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

    @property string name() const
    {
        // DTODO, see comment in like-named function in level.level
        return nameEnglish == "" ? nameGerman : nameEnglish;
    }

    @property bool empty() const
    {
        return initial == 0 && nameEnglish == "";
    }

private:
    void metadata_lix(in Filename fn, out MutableDate builtTemp)
    {
        IoLine[] lines = fillVectorFromFile(fn);
        foreach (i; lines) {
            if (i.text1 == levelBuilt)       builtTemp   = new Date(i.text2);
            if (i.text1 == levelNameGerman)  nameGerman  = i.text2;
            if (i.text1 == levelNameEnglish) nameEnglish = i.text2;
            if (i.text1 == levelInitial)     initial     = i.nr1;
            if (i.text1 == levelRequired)    required    = i.nr1;
        }
    }

    // these functions are defined in levelBi.cpp
    // std::string read_levelName_bytes (std::ifstream&);
    // int         read_two_bytes_levelbi(std::ifstream&);
    void metadata_binary(in Filename fn, out MutableDate builtTemp)
    {
        import file.log;
        log("DTODO: reading binary metadata not impl");
    }

    void metadata_lemmini(in Filename fn, out MutableDate builtTemp)
    {
        import file.log;
        log("DTODO: reading Lemmini metadata not impl");
    }
}
