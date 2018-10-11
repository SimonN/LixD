module gui.option.language;

import std.algorithm;
import std.conv;
import std.range; // takeOne

static import file.option;
static import basics.globals;
import file.filename;
import file.io;
import file.language;
import file.log;
import gui;
import gui.option.base;
import gui.picker;

class LanguageOption : Option {
private:
    Picker _picker;
    string _basenameNoExtLastChosen;

public:
    this(Geom g)
    {
        super(g, new Label(new Geom(mostButtonsXl + spaceGuiTextX, 0,
                            g.xlg - mostButtonsXl + spaceGuiTextX, 20),
                            Lang.optionLanguage.transl));
        auto cfg  = PickerConfig!(Breadcrumb, LanguageTiler)();
        cfg.all   = new Geom(0, 0, mostButtonsXl, this.ylg);
        cfg.bread = new Geom(-9999, -9999, 10, 10); // hack: offscreen
        cfg.files = new Geom(cfg.all);
        cfg.ls    = new AlphabeticalLs;
        cfg.baseDir = basics.globals.dirDataTransl;
        cfg.onFileSelect = (Filename fn) { this.highlight(fn); };
        _picker = new Picker(cfg);
        addChild(_picker);
    }

    override @property Lang lang() const { return Lang.optionLanguage; }
    override void loadValue() { highlight(file.option.fileLanguage); }
    override void saveValue()
    {
        if (_basenameNoExtLastChosen
            != file.option.languageBasenameNoExt.value
        ) {
            file.option.languageBasenameNoExt = _basenameNoExtLastChosen;
            loadUserLanguageAndIfNotExistSetUserOptionToEnglish();
        }
    }

protected:
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
            try {
                fillVectorFromFile(fn)
                    .filter!(ioLine => ioLine.text1 == key)
                    .takeOne.each!(ioLine => ret.text = ioLine.text2);
            }
            catch (Exception e) {
                logf("Error reading language file `%s':", fn.rootless);
                logf("    -> %s", e.msg);
                // We've already set a fallback caption for the button
            }
            return ret;
        }
    }

private:
    void highlight(Filename fn)
    {
        _basenameNoExtLastChosen = fn.fileNoExtNoPre;
        _picker.navigateToAndHighlightFile(fn,
            CenterOnHighlitFile.onlyIfOffscreen);
    }
}
