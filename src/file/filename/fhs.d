module file.filename.fhs;

version (useXDGBaseDirs) {
    enum selfContained = false;
    enum ourSubdir = "/lix/";
    pragma (msg, "Using the XDG Base Directory Specification: `",
        "$XDG_DATA_DIRS", ourSubdir, "'");
}
else {
    enum selfContained = true;
}

package:

static if (selfContained) {
    // Self-contained means that we look for data only in the working directory
    // and write only to the working directory. It's okay to run the game
    // inside (its root)/bin/, then we treat as our the base path the
    // parent directory. But we never look into /usr/ or $HOME/.
    // This code here works in Windows and Linux.
    string[] getRootsForReading() { return [ getRootForWriting() ]; }

    string getRootForWriting()
    {
        import std.file;
        if (exists("./images") && isDir("./images"))
            return "./";
        else if (exists("../images") && isDir("../images"))
            return "../";
        else
            throw new FileException("Can't find the Lix file tree. "
                ~ "Run the game from its root directory or from ./bin/.");
    }
}
else {
    // Allow installation into a Linux FHS tree, subject to the
    // XDG Base Directory Specification, version 0.7 from 2010:
    // https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
    // rootForWriting "~/.local/share/lix/", and rootsForReading should be
    // [ "~/.local/lix/", "/usr/local/share/lix/", "/usr/share/lix/" ].
    version (Windows) {
        static assert (false, "On Windows, I support only self-contained Lix. "
            ~ "I probably should look into standard directories again. "
            ~ "Contact me if you would like to have this on Windows.");
    }
    import core.stdc.stdlib;
    import std.algorithm;
    import std.array;
    import std.conv;

    // Assuming (ourSubdir == "/lix/"), the most likely return value will be:
    // "/home/simon/.local/share/lix/"
    string getRootForWriting()
    {
        string xdg = getenv("XDG_DATA_HOME").to!string;
        if (xdg == "") {
            string home = getenv("HOME").to!string;
            if (home == "")
                throw new Exception("Can't find $HOME. Isn't this Linux?");
            // Use the fallback value according to the XDG Base Dir Spec
            xdg = home ~ "/.local/share";
        }
        return xdg ~ ourSubdir;
    }

    // Assuming (ourSubdir == "/lix/"), the most likely return value will be:
    // [ "/home/simon/.local/share/lix/",
    //   "/usr/local/share/lix/",
    //   "/usr/share/lix/" ]
    string[] getRootsForReading()
    {
        string xdg = getenv("XDG_DATA_DIRS").to!string;
        if (xdg == "")
            // Use the fallback value according to the XDG Base Dir Spec
            xdg = "/usr/local/share/:/usr/share/";
        return getRootForWriting
            ~ xdg.splitter(':').map!(path => path ~ ourSubdir).array;
    }
}
