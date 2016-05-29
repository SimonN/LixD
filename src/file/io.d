module file.io;

import std.algorithm;
import std.array;
import std.file;
import std.stdio;
import std.string;
import std.utf;

import file.date;
import file.filename;

/* Outdated comment, see the functions near bottom of module sfor signature!
 *
 *  bool fillVectorFromFile   (ref IoLine[], const Filename);
 *  void fillVectorFromStream (ref IoLine[], File);
 *  bool fillVectorFromFileRaw(ref string[], const Filename) {
 *
 *      Fill the vector (first arg) with the lines from the file given in the
 *      second arg. Returns false iff the file doesn't exist. Returns true iff
 *      the file exists, whether or not it was empty.
 */

class IoLine {

    char type;
    string text1;
    string text2;
    string text3;
    int nr1;
    int nr2;
    int nr3;



// see further down for the rather long constructor this(string);

private this(char c, string s1, string s2, string s3, int n1, int n2, int n3)
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
    return new IoLine('$', t1,
        d !is null ? d.toString() : "0",
        "",  0,  0,  0);
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
        ret ~= format("%s%s%s", text1, text2.empty ? "" : " ", text2);
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
        // deliberately leave a space before the number, there is no keyword
        ret ~= format(" %d %d %s %d", nr1, nr2, text1, nr3);
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
// end class IoLine



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

nothrow IoLine[]
fillVectorFromFileNothrow(in Filename fn)
{
    try {
        return fillVectorFromFile(fn);
    }
    catch (Exception e) {
        // Ignore the exception, don't log anything. If something should be
        // logged here, instead call fillVectorFromFile(), catch the
        // exception, and log in the calling code.
        return null;
    }
}

IoLine[]
fillVectorFromFile(in Filename fn)
{
    // this can throw on file 404, it's intended
    File file = File(fn.rootful, "r");
    scope (exit) file.close();

    return fillVectorFromStream(file);
}

// return true on no error
IoLine[]
fillVectorFromStream(File file)
{
    IoLine[] ret;
    foreach (string line; lines(file)) {
        if (! line.all!(d => d.isValidDchar))
            throw new UTFException("file doesn't contain UTF8");
        line = line.stripRight;
        if (! line.empty)
            ret ~= new IoLine(line);
    }
    return ret;
}

// this cares about empty lines, doesn't throw them away
// throws on file 404
string[]
fillVectorFromFileRaw(in Filename fn)
{
    string[] ret;
    File file = File(fn.rootful);
    scope (exit) file.close();

    foreach (string line; lines(file))
        ret ~= line.stripRight;
    return ret;
}
