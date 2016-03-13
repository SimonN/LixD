module gui.picker.ls;

import std.algorithm;
import std.array;

import file.filename;
import file.search;

class Ls {
private:
    MutFilename _currentDir;
    MutFilename[] _dirs;
    MutFilename[] _files;

public:
    final @property          dirs()       const { return _dirs; }
    final @property          files()      const { return _files; }
    final @property Filename currentDir() const { return _currentDir; }

    final @property Filename currentDir(Filename newDir)
    {
        if (newDir == currentDir)
            return currentDir;
        _currentDir = newDir;
        if (! currentDir)
            return currentDir;
        _dirs  = findDirsNoRecursion(currentDir);
        _files = findRegularFilesNoRecursion(currentDir)
            .filter!(f => searchCriterion(f)).array;
        sortDirs (_dirs);
        sortFiles(_files);
        return currentDir;
    }

protected:
    bool searchCriterion(Filename) const { return true; }
    void sortDirs (ref MutFilename[]) { }
    void sortFiles(ref MutFilename[]) { }
}
