module gui.picker.tiler;

import std.algorithm;
import std.array;
import std.range;

public import file.filename;
import basics.help;
import gui;
import hardware.tharsis;

enum CenterOnHighlightedFile : bool { onlyIfOffscreen, always }

abstract class Tiler : Element {
private:
    Button[] _dirs;
    Button[] _files;
    int _top;

    bool _executeDir;
    bool _executeFile;
    int _executeDirID;
    int _executeFileID;

public:
    this(Geom g) { super(g); }

    @property bool executeDir()    const { return _executeDir;    }
    @property bool executeFile()   const { return _executeFile;   }
    @property int  executeDirID()  const { return _executeDirID;  }
    @property int  executeFileID() const { return _executeFileID; }

    abstract @property int pageLen() const;

    final int totalLen() const {
        return _dirs.len * dirSizeMultiplier + _files.len;
    }

    final T shiftedID(T)(in T id) const
    {
        return id < _dirs.len
            ? dirSizeMultiplier * id
            : dirSizeMultiplier * _dirs.len + (id - _dirs.len);
    }

    final void loadDirsFiles(Filename[] newDirs, Filename[] newFiles)
    {
        version (tharsisprofiling)
            auto zone = Zone(profiler, newFiles.length
                ? "ls " ~ newFiles[0].dirRootless : "ls empty dir");
        rmAllChildren();
        _dirs  = newDirs.map!(t => newDirButton(t)).array;
        _files = newFiles.enumerate!int
            .map!(pair => newFileButton(pair[1], pair[0]))
            .array;
        chain(_dirs, _files).each!(b => addChild(b));
        top = 0;
        moveButtonsAccordingToTop();
    }

    final @property int top() const { return _top; }
    final @property int top(int newTop)
    {
        newTop = min(newTop, totalLen - pageLen);
        newTop = max(newTop, 0);
        if (newTop < _dirs.len * dirSizeMultiplier)
            newTop -= newTop % dirSizeMultiplier;
        if (_top != newTop) {
            _top = newTop;
            moveButtonsAccordingToTop();
        }
        return _top;
    }

    final void highlightNothing() { _files.each!(b => b.on = false); }
    final void highlightFile(in int i, CenterOnHighlightedFile chf)
    {
        highlightNothing();
        _files[i].on = true;
        if (chf || i < top || i >= top + pageLen)
            top = i - pageLen / 2;
    }


protected:
    // dir buttons are larger than file buttons by dirSizeMultiplier
    @property int dirSizeMultiplier() const { return 2; }

    abstract Button newDirButton (Filename data);
    abstract Button newFileButton(Filename data, in int fileID);
    abstract float buttonXg(in int shiftedIDOnPage) const;
    abstract float buttonYg(in int shiftedIDOnPage) const;

    override void calcSelf()
    {
        calcExecute(_dirs,  _executeDir,  _executeDirID);
        calcExecute(_files, _executeFile, _executeFileID);
    }

    override void drawSelf()
    {
        super.undrawSelf(); // remove all old buttons
        super.drawSelf();
    }

private:
    void moveButtonsAccordingToTop()
    {
        reqDraw();
        auto range = chain(_dirs, _files).enumerate!int;
        foreach (int unshifted, Button b; range) {
            immutable int shifted = shiftedID(unshifted);
            b.hidden = (shifted < top || shifted >= top + pageLen);
            if (! b.hidden)
                b.move(buttonXg(shifted - top), buttonYg(shifted - top));
        }
    }

    void calcExecute(const(Button[]) range, ref bool anyInRange, ref int which)
    {
        anyInRange = false;
        foreach (int i, const(Button) b; range)
            if (b.execute) {
                anyInRange = true;
                which = i;
            }
    }
}
