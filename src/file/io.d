module file.io;

import std.array;
import std.file;
import std.stdio;

import file.date;
import file.filename;
import file.log;

/*  bool fill_vector_from_file  (ref IoLine[], const Filename);
 *  void fill_vector_from_stream(ref IoLine[], File);
 *
 *      Fill the vector (first arg) with the lines from the file given in the
 *      second arg. Returns false iff the file doesn't exist. Returns true iff
 *      the file exists, whether or not it was empty.
 */

bool fill_vector_from_file_raw(ref string[], const Filename) {
    assert (false, "DTODO: raw IoLine filling isn't implemented yet");
}

class IoLine {

    char type;
    string text1;
    string text2;
    string text3;
    int nr1;
    int nr2;
    int nr3;

    this(string = "");
    this(char, string, string, string, int, int, int);

//  override string toString() const;

    // Generate IoLine objects for the various line types in Lix.
    // These functions shall look like constructors. LineDollar can be made
    // with a date object instead of a string.
    static IoLine Hash  (const string = "",
                         const int    = 0);
    static IoLine Colon (const string = "",
                         const int    = 0,
                         const int    = 0,
                         const string = "");
    static IoLine Dollar(const string = "",
                         const string = "");
    static IoLine Dollar(const string,
                         const Date);
    static IoLine Plus  (const string = "",
                         const int    = 0,
                         const string = "",
                         const string = "");
    static IoLine Bang  (const int    = 0,
                         const int    = 0,
                         const string = "",
                         const int    = 0);
    static IoLine Angle (const string = "",
                         const int    = 0,
                         const int    = 0,
                         const int    = 0,
                         const string = "");



// see further down for the rather long constructor this(string);

this(char c, string s1, string s2, string s3, int n1, int n2, int n3)
{
    type  = c;
    text1 = s1;
    text2 = s2;
    text3 = s3;
    nr1   = n1;
    nr2   = n2;
    nr3   = n3;
}



static IoLine Hash(const string t1, const int n1)
{
    return new IoLine('#', t1, "", "", n1,  0,  0);
}

static IoLine Colon(const string t1, const int n1,
                    const int n2, const string t2)
{
    return new IoLine(':', t1, t2, "", n1, n2,  0);
}

static IoLine Dollar(const string t1, const string t2)
{
    return new IoLine('$', t1, t2, "",  0,  0,  0);
}

static IoLine Dollar(const string t1, const Date d)
{
    return new IoLine('$', t1, d.toString(), "",  0,  0,  0);
}

static IoLine Plus(const string t1, const int n1,
                   const string t2, const string t3)
{
    return new IoLine('+', t1, t2, t3, n1,  0,  0);
}


static IoLine Bang(const int n1, const int n2,
                   const string t1, const int n3)
{
    return new IoLine('!', t1, "", "", n1, n2, n3);
}

static IoLine Angle(const string t1, const int n1,
                    const int n2, const int n3, const string t2)
{
    return new IoLine('<', t1, t2, "", n1, n2, n3);
}



this (string src)
{
    // all fields have been initialized to zero at the beginning.
    if (! src.empty) {
        type = src[0];
        src = src[1 .. $];
    }

    bool minus1 = false;
    bool minus2 = false;
    bool minus3 = false;

    // see below for the three functions munch

    switch (type) {
    case '$':
        while (! src.empty && src[0] != ' ') munch(src, text1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty                 ) munch(src, text2);
        break;

    case '#':
        while (! src.empty && src[0] != ' ') munch(src, text1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr1, minus1);
        break;

    case ':':
        while (! src.empty && src[0] != ':') munch(src, text1);
        while (! src.empty && src[0] == ':') munch(src);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr1, minus1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr2, minus2);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty                 ) munch(src, text2);
        break;

    case '+':
        while (! src.empty && src[0] != ' ') munch(src, text1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr1, minus1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, text2);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty                 ) munch(src, text3);
        break;

    case '!':
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr1, minus1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr2, minus2);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, text1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr3, minus3);
        break;

    case '<':
        while (! src.empty && src[0] != '>') munch(src, text1);
        while (! src.empty && src[0] == '>') munch(src);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr1, minus1);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr2, minus2);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty && src[0] != ' ') munch(src, nr3, minus3);
        while (! src.empty && src[0] == ' ') munch(src);
        while (! src.empty                 ) munch(src, text2);
        break;


    default:
        // Any other string leads to marking the line as invalid.
        // No fields will be read from the source string.
        type = 0;
        break;
    }

    if (minus1) nr1 *= -1;
    if (minus2) nr2 *= -1;
    if (minus3) nr3 *= -1;
}
// end this(string)



override string toString() const
{
    string ret = "" ~ type;

    switch (type) {
    case '$':
        ret ~= text1 ~ " " ~ text2;
        break;
    case '#':
        ret ~= format("%s %d", text1, nr1);
        break;
    case ':':
        ret ~= format("%s: %d %d", text1, nr1, nr2);
        if (! text2.empty) ret ~= " " ~ text2;
        break;
    case '+':
        ret ~= format("%s %d %s %s", text1, nr1, text2, text3);
        break;
    case '!':
        ret ~= format("%d %d %s %d", nr1, nr2, text1, nr3);
        break;
    case '<':
        ret ~= format("%s> %d %d %d %s", text1, nr1, nr2, nr3, text2);
        break;
    default:
        // don't return null bytes or anyhting if this.type is strange
        return "";
    }
    return ret;
}
// end toString()

}
// end struct



// some local functions to parse the source string
private void munch(ref string s, ref int nr, ref bool minus)
{
    assert (! s.empty);
    if (s[0] == '-') minus = true;
    else {
        nr *= 10;
        nr += (s[0] - '0');
    }
    s = s[1 .. $];
}

private void munch(ref string s, ref string target)
{
    assert (! s.empty);
    target ~= s[0];
    s = s[1 .. $];
}

private void munch(ref string s) {
    assert (! s.empty);
    s = s[1 .. $];
}



bool fill_vector_from_file(ref IoLine[] v, const Filename fn)
{
    try {
        File file = File(fn.get_rootful());
        bool was_good = fill_vector_from_stream(v, file);
        file.close();
        return was_good;
    }
    catch (Exception e) {
        // DTODOLANG
        Log.log(e.msg);
        return false;
    }
}



// return true on no error
bool fill_vector_from_stream(ref IoLine[] v, File file)
{
    foreach (string line; lines(file)) {
        // prune trailing LFs, CRs, and spaces
        while (! line.empty) {
            immutable char c = line[$-1];
            if (c == ' ' || c == '\n' || c == '\r') line = line[0 .. $-1];
            else break;
        }
        if (! line.empty) v ~= new IoLine(line);
    }
    return true;
}
