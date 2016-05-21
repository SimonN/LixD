module menu.browser.select;

/*  class BrowserHighlightSelect
 *
 *      Guarantee for all inherited classes: onFileHighlight will be called
 *      for every file on which possibly on_file_select could be called later.
 *      Whenever on_file_select is called, onFileHighlight has been called
 *      on the same filename before, and no other onFileHighlight calls have
 *      been made in the meantime.
 *      Implemented by private BrowserHighlightSelect._fileRecent.
 */

import std.conv;
static import std.file;

import basics.user; // hotkeys
import file.filename;
import file.language;
import file.log;
import gui;
import gui.picker;
import hardware.keyboard; // up/down change of highlighted file
import hardware.sound;
import menu.browser.highli;

class BrowserHighlightSelect : BrowserHighlight {
private:
    MutFilename _fileRecent; // highlight, not select. May be in different dir.
    MutFilename _upDownTo; // last-highlit dir or file with up/down keys

    TextButton buttonPlay;

public:
    // See constructor comment in menu.browser.highli.
    this(SomeTiler)(
        in string title,
        Filename  baseDir,
        PickerConfig!SomeTiler cfg
    ) {
        super(title, baseDir, cfg);
        buttonPlay = new TextButton(new Geom(infoX, 100,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserPlay.transl);
        buttonPlay.hotkey = basics.user.keyMenuOkay;
        addChildren(buttonPlay);
    }

    void setButtonPlayText(in string s) { buttonPlay.text = s; }

    @property auto fileRecent()   inout { return _fileRecent;   }

    final void highlight(Filename fn)
    {
        if (fn && super.navigateToAndHighlightFile(fn)) {
            buttonPlay.show();
            _fileRecent = fn;
            onFileHighlight(fn);
        }
        else {
            buttonPlay.hide();
            // keep _fileRecent as it is, we might highlight that again later
            onFileHighlight(null);
        }
    }

protected:
    // override these
    void onFileHighlight(Filename) {}
    void onFileSelect   (Filename) {}

    final void deleteFileRecentHighlightNeighbor()
    {
        highlight(super.deleteFileHighlightNeighbor(_fileRecent));
        _upDownTo = null;
        playLoud(Sound.SCISSORS);
    }

    final override void onPickerExecuteFile(Filename executeFileFilename)
    {
        MutFilename clicked = executeFileFilename;
        assert (clicked !is null);
        if (clicked != _fileRecent)
            highlight(clicked);
        else
            onFileSelect(_fileRecent);
    }

    final override void onPickerExecuteDir()
    {
        highlightIfInCurrentDir(_fileRecent);
        _upDownTo = null;
    }

    override void calcSelf()
    {
        super.calcSelf();
        if (gotoMainMenu) {
            return;
        }
        else if (buttonPlay.execute) {
            assert (_fileRecent !is null);
            onFileSelect(_fileRecent);
        }
        else if (keyMenuOkay.keyTapped && _upDownTo) {
            super.navigateTo(_upDownTo);
            highlightIfInCurrentDir(_fileRecent);
            _upDownTo = null;
        }
        else {
            immutable moveBy = keyMenuUpBy1  .keyTappedAllowingRepeats * -1
                             + keyMenuUpBy5  .keyTappedAllowingRepeats * -5
                             + keyMenuDownBy1.keyTappedAllowingRepeats * 1
                             + keyMenuDownBy5.keyTappedAllowingRepeats * 5;
            if (moveBy != 0) {
                _upDownTo = super.moveHighlightBy(
                            _upDownTo ? _upDownTo : _fileRecent, moveBy);
                highlightIfInCurrentDir(_upDownTo);
            }
        }
    }

private:
    @property void highlightIfInCurrentDir(Filename fn)
    {
        highlight(fn && fn.dirRootless == currentDir.dirRootless
            ? fn : null);
    }
}
