module basics.verify;

import file.filename;

public void verifyFiles(Filename[] files)
{
    import std.algorithm;
    import std.stdio;
    files.each!(f => f.rootful.writeln());
}
