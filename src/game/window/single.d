module game.window.single;

/* The menu available on hitting ESC (or remapped key) or after end of play.
 * There are 2x2 of these, during/after single/multiplayer.
 */

import std.array;
import std.algorithm;
import std.typecons;

import basics.user; // keyMenuOkay
import file.filename;
import file.language;
import game.window.base;
import game.replay;
import game.tribe;
import graphic.color;
import gui;
import hardware.keyset;
import level.level;

class WindowDuringOffline : GameWindow {
    this(in Replay replay, in Level level)
    {
        super(myGeom(3));
        int y = 40;
        _resume     = addButton(y);
        _saveReplay = addButton(y);
        _exitGame   = addButton(y);
        super.captionSuperElements();
        super.setReplayAndLevel(replay, level);
    }
}

class WindowEndSingle : GameWindow {
public:
    // DTODO: extend this() with level filename, to allow browsing to the
    // next level/next unsolved level. Maybe subclass again, and show the
    // non-next-level-able window for replays
    this(in Tribe tribe, in Replay replay, in Level level)
    {
        assert (tribe);
        assert (level);
        enum extraYl = 95;
        immutable bool won = tribe.lixSaved >= level.required;

        super(myGeom(won ? 2 : 4, 300, extraYl), level.name);
        int y = 40 + extraYl;
        if (! won) {
            _framestepBack = addButton(y, xlg - 40);
            _restart = addButton(y, xlg - 40);
            // no OK if not won => reuse OK hotkey. captionSuperElements()
            // will add the normal restart hotkey later in this function.
            _restart.hotkey = keyMenuOkay;
        }
        _saveReplay = addButton(y, xlg - 40);
        _exitGame   = addButton(y, xlg - 40);
        if (won)
            _exitGame.hotkey = keyMenuOkay;
        super.captionSuperElements();
        super.setReplayAndLevel(replay, level);

        drawLixSaved(tribe, level);
    }

private:
    void drawLixSaved(in Tribe tribe, in Level level)
    {
        addChild(new Label(new Geom(0, 40, xlg, 0, From.TOP),
            tribe.lixSavedLate == 0 ? Lang.winGameLixSaved.transl
                              : Lang.winGameLixSavedInTime.transl));
        Label slash = new Label(new Geom(  0, 65, xlg/2, 0, From.TOP), "/");
        Label saved = new Label(new Geom(-25, 65, xlg/2, 0, From.TOP));
        Label requi = new Label(new Geom( 25, 65, xlg/2, 0, From.TOP));
        slash.font = saved.font = requi.font = djvuL;
        saved.number = tribe.lixSaved;
        requi.number = level.required;
        if (tribe.lixSaved > 0)
            saved.color = color.white;
        if (tribe.lixSaved >= level.required) {
            slash.color = color.white;
            requi.color = color.white;
        }
        addChildren(slash, saved, requi,
            new Label(new Geom(0, 95, xlg, 0, From.TOP),
                      flavorText(tribe, level)));
    }

    static string flavorText(in Tribe tribe, in Level level)
    { with (tribe) with (level)
    {
        if (lixSaved >  initial)  assert (false, "not in singleplayer");
        if (lixSaved == initial)  return Lang.winGameCommentPerfect.transl;
        if (lixSaved >  required) return Lang.winGameCommentMore.transl;
        if (lixSaved == required) return Lang.winGameCommentExactly.transl;
        if (lixSaved >  0)        return Lang.winGameCommentFewer.transl;
        else                      return Lang.winGameCommentNone.transl;
    }}
}
