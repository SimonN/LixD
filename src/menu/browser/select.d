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

import file.option; // hotkeys
import file.filename;
import file.language;
import file.log;
import gui;
import gui.picker;
import hardware.semantic; // up/down change of highlighted file
import hardware.sound;
import menu.browser.highli;

class BrowserHighlightSelect : BrowserHighlight {
private:
    // highlight, not select. May be in different dir. Never a directory.
    MutFilename _fileRecent;

    // Last-highlit dir or file with up/down keys.
    // We need this because it may point to dirs, not only to files as
    // _fileRecent would allow.
    // _upDownToCanBeNull cannot be Optional because Optional doesn't behave
    // well with Rebindable!Filename == MutFilename: Both together corrupt RAM.
    MutFilename _upDownToCanBeNull;

    TextButton _buttonPlay;

public:
    // See constructor comment in menu.browser.highli.
    this(SomePickerConfig)(
        in string title,
        Filename  baseDir,
        SomePickerConfig cfg
    ) {
        super(title, baseDir, cfg);
        _buttonPlay = new TextButton(new Geom(infoX, 20,
            infoXl/2, 40, From.BOTTOM_LEFT), Lang.browserPlay.transl);
        _buttonPlay.hotkey = file.option.keyMenuOkay;
        addChild(_buttonPlay);
    }

    Filename fileRecent() inout const pure nothrow @safe @nogc
    {
        return _fileRecent;
    }

    final void highlightNone()
    {
        _buttonPlay.hide();
        // keep _fileRecent as it is, we might highlight that again later
        onHighlightNone();
    }

    final void highlight(Filename fn)
    in { assert (fn, "call highlightNone() instead"); }
    do {
        if (super.navigateToAndHighlightFile(fn)) {
            _buttonPlay.show();
            _fileRecent = fn;
            _upDownToCanBeNull = fn;
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
        Optional!Filename opt = super.deleteFileHighlightNeighbor(_fileRecent);
        // Super class only tells the picker to highlight the neighbor.
        // We, as a browser, must highlight the neighbor, too. Bad OO? <_<
        opt.match!(
            () { highlightNone(); },
            (fn) { highlight(fn); });
        _upDownToCanBeNull = null;
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
        _upDownToCanBeNull = null;
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
        else if (keyMenuOkay.keyTapped && _upDownToCanBeNull) {
            super.navigateTo(_upDownToCanBeNull);
            highlightIfInCurrentDir(_fileRecent);
            _upDownToCanBeNull = null;
        }
        else if (keyMenuMoveByTotal() != 0) {
            _upDownToCanBeNull = super.moveHighlightBy(
                _upDownToCanBeNull ? _upDownToCanBeNull
                : _fileRecent, keyMenuMoveByTotal);
            highlightIfInCurrentDir(_upDownToCanBeNull); // may be null here
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
