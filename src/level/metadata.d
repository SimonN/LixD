module level.metadata;

import basics.globals;
import file.date;
import file.filename;
import file.io;
import level.level;
import level.levelio;

class LevelMetaData {

    FileFormat format;
    Date       built;
    int        initial;
    int        required;
    string     name_german;
    string     name_english;



this(in Filename fn)
{
    format = level.levelio.get_file_format(fn);

    if      (format == FileFormat.LIX)     read_metadata_lix    (fn);
    else if (format == FileFormat.BINARY)  read_metadata_binary (fn);
    else if (format == FileFormat.LEMMINI) read_metadata_lemmini(fn);
}



@property string
name() const
{
    // DTODO, see comment in like-named function in level.level
    return name_english == null ? name_german : name_english;
}



@property bool
file_exists() const
{
    return format != FileFormat.NOTHING;
}



private void
read_metadata_lix(in Filename fn)
{
    IoLine[] lines = fill_vector_from_file_nothrow(fn);
    foreach (i; lines) {
        if (i.text1 == level_built)        built        = new Date(i.text2);
        if (i.text1 == level_name_german)  name_german  = i.text2;
        if (i.text1 == level_name_english) name_english = i.text2;
        if (i.text1 == level_initial)      initial      = i.nr1;
        if (i.text1 == level_required)     required     = i.nr1;
    }
}



// these functions are defined in level_bi.cpp
// std::string read_level_name_bytes (std::ifstream&);
// int         read_two_bytes_levelbi(std::ifstream&);
private void read_metadata_binary(in Filename fn)
{
    import file.log;
    Log.log("DTODO: reading binary metadata not impl");
    /*
    std::ifstream file(fn.rootful.c_str(), std::ios::binary);

    // see level_bi.cpp for documentation of the L1 format
    file.seekg(0x2);
    initial  = read_two_bytes_levelbi(file);
    required = read_two_bytes_levelbi(file);
    name_english = read_level_name_bytes(file);
    file.close();
    */
}



private void
read_metadata_lemmini(in Filename fn)
{
    import file.log;
    Log.log("DTODO: reading Lemmini metadata not impl");
    /*
    std::ifstream file(fn.rootful.c_str());
    if (! file.good()) return;

    // File exists
    std::string s;
    while (file >> s) {
        if (s == "name") {
            file >> s; // parse the "=";
            s.clear();
            char c;
            while (file.get(c)) {
                if (c == ' ' && s.empty()); // discard spaces before name
                else if (c == '\n' || c == '\r') break; // done reading name
                else s += c;
            }
            name_english = s;
        }
        else if (s == "numLemmings") {
            file >> s; // parse the "="
            file >> initial;
        }
        else if (s == "numToRescue") {
            file >> s; // parse the "="
            file >> required;
        }
    }
    file.close();
    */
}
// end read_metadata_lemmini

}
// end class LevelMetaData
