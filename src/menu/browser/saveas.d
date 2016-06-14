module menu.browser.saveas;

import std.string; // strip whitespace

import basics.alleg5; // return accepts the file, too
import basics.globals; // extension
import basics.user; // hotkey
import menu.browser.highli;
import file.language;
import file.search; // file exists, to guard against overwrite
import gui;
import gui.picker;
import hardware.keyboard;
import hardware.keyset;

class SaveBrowser : BrowserHighlight {
private:
    MutFilename _chosenFile;
    Texttype    _texttype;
    TextButton  _saveAsTexttype;

public:
    this(Filename baseDir)
    {
        super(Lang.saveBrowserTitle.transl, baseDir,
            PickerConfig!LevelWithFilenameTiler());
        _texttype = new Texttype(new Geom(infoX, 80, infoXl, 20,
                                 From.BOTTOM_LEFT));
        _texttype.allowedChars = Texttype.AllowedChars.filename;
        _texttype.on = true;
        _texttype.onEnter = () {
            if (ALLEGRO_KEY_ENTER.keyTapped)
                this.askForOverwriteOrReturn();
        };
        _saveAsTexttype = new TextButton(new Geom(infoX, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.commonOk.transl);
        _saveAsTexttype.hotkey = KeySet(keyMenuOkay,
                                        KeySet(ALLEGRO_KEY_ENTER));
        addChildren(_texttype, _saveAsTexttype,
            new Label(new Geom(infoX, 100, infoXl, 20, From.BOTTOM_LEFT),
            Lang.saveBrowserWhatToType.transl));
    }

    Filename chosenFile() const { return _chosenFile; }
    bool     done()       const { return _chosenFile || super.gotoMainMenu; }

    void highlight(Filename fn)
    {
        super.navigateTo(fn);
        if (fn && fn.dirRootless == currentDir.dirRootless) {
            _texttype.text = fn.fileNoExtNoPre;
            _texttype.on = true;
        }
        else
            _texttype.text = "";
    }

protected:
    final override void onPickerExecuteFile(Filename executeFileFilename)
    {
        _texttype.text = executeFileFilename.fileNoExtNoPre;
        _texttype.on = true;
    }

    override void calcSelf()
    {
        super.calcSelf();
        if (! done && _saveAsTexttype.execute)
            askForOverwriteOrReturn();
    }

private:
    void askForOverwriteOrReturn()
    {
        if (_texttype.text.strip == "") {
            _texttype.on = true;
            return;
        }
        Filename maybe = new Filename(currentDir.rootless
                         ~ _texttype.text.strip ~ filenameExtLevel);
        if (! maybe.fileExists)
            _chosenFile = maybe;
        else {
            MsgBox box = new MsgBox(Lang.saveBoxOverwriteTitle.transl);
            box.addMsg(Lang.saveBoxOverwriteQuestion.transl);
            box.addMsg("%s %s".format(Lang.saveBoxFileName.transl,
                                      maybe.rootful));
            box.addMsg("%s %s".format(Lang.saveBoxLevelName.transl,
                                      // DTODO: load the level meta data
                                      maybe.fileNoExtNoPre));
            box.addButton(Lang.saveBoxOverwrite.transl, _saveAsTexttype.hotkey,
                () { _chosenFile = maybe; });
            box.addButton(Lang.commonNo.transl, keyMenuExit,
                () { _texttype.on = true; });
            addFocus(box);
        }
    }
}
