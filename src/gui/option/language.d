module gui.option.language;

import std.algorithm;
import std.conv;
import std.range; // takeOne

static import basics.user;
static import basics.globals;
import file.filename;
import file.io;
import file.language;
import gui;
import gui.option.base;
import gui.picker;

class LanguageOption : Option {
private:
    Picker _picker;
    MutFilename _lastChosen;

public:
    this(Geom g, string cap)
    {
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, 20), cap));
        auto cfg  = PickerConfig!LanguageTiler();
        cfg.all   = new Geom(0, 0, mostButtonsXl, this.ylg);
        cfg.bread = new Geom(-9999, -9999, 10, 10); // hack: offscreen
        cfg.files = new Geom(cfg.all);
        cfg.ls    = new AlphabeticalLs;
        _picker   = new Picker(cfg);
        _picker.basedir = basics.globals.dirDataTransl;
        addChild(_picker);
    }

    override void loadValue()
    {
        _lastChosen = basics.user.fileLanguage;
        _picker.navigateToAndHighlightFile(_lastChosen,
                                           CenterOnHighlitFile.always);
    }

    override void saveValue()
    {
        if (_lastChosen !is null
            && _lastChosen != MutFilename(basics.user.fileLanguage)
        ) {
            basics.user.fileLanguage = _lastChosen;
            loadUserLanguageAndIfNotExistSetUserOptionToEnglish();
        }
    }

protected:
    override void calcSelf()
    {
        if (_picker.executeFile) {
            _lastChosen = _picker.executeFileFilename;
            _picker.highlightFile(_picker.executeFileID,
                                  CenterOnHighlitFile.onlyIfOffscreen);
        }
    }

    static class LanguageTiler : LevelOrReplayTiler {
    public:
        this(Geom g) { super(g); }

    protected:
        final override TextButton newFileButton(Filename fn, in int fileID)
        {
            assert (fn);
            auto ret = new TextButton(new Geom(0, 0, xlg, buttonYlg));
            ret.text = fn.file;
            immutable key = Lang.mainNameOfLanguage.to!string;
            fillVectorFromFileNothrow(fn)
                .filter!(ioLine => ioLine.text1 == key)
                .takeOne.each!(ioLine => ret.text = ioLine.text2);
            return ret;
        }
    }
}
