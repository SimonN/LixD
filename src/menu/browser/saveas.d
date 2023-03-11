module menu.browser.saveas;

import std.string; // strip whitespace

import basics.alleg5; // return accepts the file, too
import basics.globals; // extension
import file.option; // hotkey
import menu.browser.highli;
import menu.browser.mkdir;
import file.language;
import gui;
import gui.picker;
import hardware.keyboard;
import hardware.keyset;

class SaveBrowser : BrowserHighlight {
private:
    TextButton  _mkdirButton;
    MutFilename _chosenFile;
    Texttype    _texttype;
    TextButton  _saveAsTexttype;

    MkdirDialog _mkdirBrowser;

public:
    this(Filename baseDir)
    {
        super(Lang.saveBrowserTitle.transl, baseDir,
            PickerConfig!(Breadcrumb, LevelWithFilenameTiler)());

        _mkdirButton = new TextButton(new Geom(infoX, 140, infoXl/2, 40,
            From.BOTTOM_LEFT), Lang.browserMkdirTitle.transl);
        _mkdirButton.hotkey = keyMenuNewLevel;
        _mkdirButton.onExecute = () {
            _mkdirBrowser = new MkdirDialog(new Geom(20, 20,
                xlg - infoX - 20, 160, From.BOTTOM_RIGHT), currentDir);
            addFocus(_mkdirBrowser);
        };
        _texttype = new Texttype(new Geom(infoX, 80, infoXl, 20,
                                 From.BOTTOM_LEFT));
        _texttype.allowedChars = Texttype.AllowedChars.filename;
        _texttype.on = true;
        _texttype.onEnter = () { this.askForOverwriteOrReturn(); };
        _saveAsTexttype = new TextButton(new Geom(infoX, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.commonOk.transl);
        _saveAsTexttype.hotkey = KeySet(keyMenuOkay,
                                        KeySet(ALLEGRO_KEY_ENTER));
        addChildren(_mkdirButton, _texttype, _saveAsTexttype,
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
    final override void onPickerExecuteDir() { }
    final override void onPickerExecuteFile(Filename executeFileFilename)
    {
        _texttype.text = executeFileFilename.fileNoExtNoPre;
        _texttype.on = true;
    }

    override void calcSelf()
    {
        super.calcSelf();
        if (_mkdirBrowser && _mkdirBrowser.done) {
            navigateTo(_mkdirBrowser.createdDir);
            _mkdirBrowser = null;
            _texttype.on = true;
        }
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
        Filename maybe = new VfsFilename(currentDir.rootless
                         ~ _texttype.text.strip ~ filenameExtLevel);
        if (! maybe.fileExists)
            _chosenFile = maybe;
        else {
            MsgBox box = new MsgBox(Lang.saveBoxOverwriteTitle.transl);
            box.addMsg(Lang.saveBoxOverwriteQuestion.transl);
            box.addMsg("%s %s".format(Lang.saveBoxFileName.transl,
                                      maybe.rootless));
            box.addMsg("%s %s".format(Lang.saveBoxLevelName.transl,
                                      // DTODO: load the level meta data
                                      maybe.fileNoExtNoPre));
            box.addButton(Lang.saveBoxOverwrite.transl, _saveAsTexttype.hotkey,
                () { _chosenFile = maybe; });
            box.addButton(Lang.commonCancel.transl, keyMenuExit,
                () { _texttype.on = true; });
            addFocus(box);
        }
    }
}
