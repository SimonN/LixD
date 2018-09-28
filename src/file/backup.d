module file.backup;

import std.file;

import file.date;
import file.filename;
import file.log;

void backupBrokenSdlang(
    Filename brokenFile,
    Exception rethrowIfUnsuccessful
) {
    try {
        Filename bak = new VfsFilename(brokenFile.rootlessNoExt
            ~ "-backup-" ~ Date.now().toStringForFilename
            ~ brokenFile.extension);
        copy(brokenFile.stringForReading, bak.stringForWriting);
        log("    -> Backed up erroneous SDLang file as: " ~ bak.rootless);
        log("    -> Fix manually the errors, then rename to: "
            ~ brokenFile.rootless);
    }
    catch (Exception e) {
        log("    -> Can't backup broken SDLang file: " ~ e.msg);
        throw rethrowIfUnsuccessful;
    }
}
