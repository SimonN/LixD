module gui.picker.ls;

import std.algorithm;
import std.array;

import file.filename;
import file.search;

class Ls {
private:
    MutFilename _currentDir;
    Filename[] _dirs;
    Filename[] _files;

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
        auto tempD = findDirsNoRecursion(currentDir);
        auto tempF = findRegularFilesNoRecursion(currentDir)
            .filter!(f => searchCriterion(f)).array;
        sortDirs (tempD);
        sortFiles(tempF);

        Filename deMut(in MutFilename a) { return a; }
        _dirs  = tempD.map!deMut.array;
        _files = tempF.map!deMut.array;
        return currentDir;
    }

protected:
    bool searchCriterion(Filename) const { return true; }
    void sortDirs (ref MutFilename[]) { }
    void sortFiles(ref MutFilename[]) { }
}
