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

import optional;

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
                             // May not point to a directory.
    Optional!MutFilename _upDownTo; // Last-highlit dir or file with up/down keys.
                                 // We need this because it may point to dirs.
    TextButton _buttonPlay;

public:
    // See constructor comment in menu.browser.highli.
    this(SomeTiler)(
        in string title,
        Filename  baseDir,
        PickerConfig!SomeTiler cfg
    ) {
        super(title, baseDir, cfg);
        _buttonPlay = new TextButton(new Geom(infoX, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserPlay.transl);
        _buttonPlay.hotkey = basics.user.keyMenuOkay;
        addChildren(_buttonPlay);
    }

    @property auto fileRecent() inout { return _fileRecent; }

    final void highlightNone()
    {
        _buttonPlay.hide();
        // keep _fileRecent as it is, we might highlight that again later
        onHighlightNone();
    }

    final void highlight(Filename fn)
    in { assert (fn, "call highlightNone() instead"); }
    body {
        if (super.navigateToAndHighlightFile(fn)) {
            _buttonPlay.show();
            _fileRecent = fn;
            _upDownTo = some(MutFilename(fn));
            onHighlight(fn);
        }
        else
            highlightNone();
    }

protected:
    abstract void onHighlightNone();
    abstract void onHighlight(Filename);
    abstract void onPlay(Filename);

    final void buttonPlayYFromBottom(in float newY)
    {
        _buttonPlay.move(_buttonPlay.geom.x, newY);
    }

    final void buttonPlayText(in string s) { _buttonPlay.text = s; }

    final void deleteFileRecentHighlightNeighbor()
    {
        if (auto newFn = super.deleteFileHighlightNeighbor(_fileRecent).unwrap)
            highlight(*newFn);
        else
            highlightNone();
        _upDownTo = none;
        playLoud(Sound.SCISSORS);
    }

    final override void onPickerExecuteFile(Filename executeFileFilename)
    {
        MutFilename clicked = executeFileFilename;
        assert (clicked !is null);
        if (clicked != _fileRecent)
            highlight(clicked);
        else
            onPlay(_fileRecent);
    }

    final override void onPickerExecuteDir()
    {
        highlightIfInCurrentDir(_fileRecent);
        _upDownTo = none;
    }

    override void calcSelf()
    {
        super.calcSelf();
        if (gotoMainMenu) {
            return;
        }
        else if (_buttonPlay.execute) {
            assert (_fileRecent !is null);
            onPlay(_fileRecent);
        }
        else if (keyMenuOkay.keyTapped && _upDownTo.unwrap) {
            super.navigateTo(*_upDownTo.unwrap);
            highlightIfInCurrentDir(_fileRecent);
            _upDownTo = none;
        }
        else {
            immutable moveBy = keyMenuUpBy1  .keyTappedAllowingRepeats * -1
                             + keyMenuUpBy5  .keyTappedAllowingRepeats * -5
                             + keyMenuDownBy1.keyTappedAllowingRepeats * 1
                             + keyMenuDownBy5.keyTappedAllowingRepeats * 5;
            if (moveBy != 0) {
                _upDownTo = some(MutFilename(super.moveHighlightBy(
                    _upDownTo.unwrap ? *_upDownTo.unwrap
                    : _fileRecent, moveBy)));
                highlightIfInCurrentDir(
                    _upDownTo.unwrap ? *_upDownTo.unwrap : null);
            }
        }
    }

private:
    @property void highlightIfInCurrentDir(Filename fn)
    {
        if (fn && fn.dirRootless == currentDir.dirRootless)
            highlight(fn);
        else
            highlightNone();
    }
}
