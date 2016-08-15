module gui.picker.lsimg;

import std.algorithm;

import file.filename;
import gui.picker.ls;

class ImageLs : AlphabeticalLs {
private:
    const(string) _allowedPreExts;

public:
    this(string allowedPreExts)
    {
        _allowedPreExts = allowedPreExts;
    }

protected:
    override bool searchCriterion(Filename fn) const
    {
        if (! fn.hasImageExtension)
            return false;
        if (_allowedPreExts.length == 0)
            return true;
        return _allowedPreExts.canFind(fn.preExtension);
    }
}

class RecursingImageLs : ImageLs {
public
    this(string allowedPreExts) { super(allowedPreExts); }

protected:
    final override MutFilename[] dirsInCurrentDir() const { return []; }
    final override MutFilename[] filesInCurrentDir() const
    {
        return currentDir.findTree();
    }
}
