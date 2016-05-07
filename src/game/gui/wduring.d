module game.gui.wduring;

/* The menu available on hitting ESC (or remapped key) during play. Different
 * from the menu at end of play.
 *
 *  class WindowDuringOffline -- playing singleplayer or
 *  class WindowDuringNetwork
 */

import basics.user; // keyMenuOkay
import file.filename;
import file.language;
import game.gui.gamewin;
import game.replay;
import game.tribe;
import graphic.color;
import graphic.textout;
import gui;
import hardware.keyset;
import level.level;

private enum butXl  = 150;
private enum butYsp =  10;
private enum butYl  =  20;

private auto addButton(ref int y, in float xl = butXl)
{
    TextButton b = new TextButton(new Geom(0, y, xl, butYl, From.TOP));
    y += butYl + butYsp;
    return b;
}

private Geom
myGeom(in int numButtons, in int totalXl = butXl + 40, in int plusYl = 0)
{
    return new Geom(0, -Geom.panelYlg / 2, totalXl,
        60 + (numButtons - 1) * butYsp +  numButtons * butYl + plusYl,
        From.CENTER);
}

class WindowDuringOffline : GameWindow {

    this(in Replay replay, in Filename levelFn, in Level level)
    {
        super(myGeom(4));
        int y = 40;
        _resume     = addButton(y);
        _restart    = addButton(y);
        _saveReplay = addButton(y);
        _exitGame   = addButton(y);
        super.captionSuperElements();
        super.setReplayAndLevel(replay, levelFn, level);
    }

}



class WindowDuringNetwork : GameWindow {

    this(in Replay replay, in Filename levelFn, in Level level)
    {
        super(myGeom(3));
        int y = 40;
        _resume     = addButton(y);
        _saveReplay = addButton(y);
        _exitGame   = addButton(y);
        super.captionSuperElements();
        super.setReplayAndLevel(replay, levelFn, level);
    }

}



class WindowEndSingle : GameWindow {

    // DTODO: extend this() with level filename, to allow browsing to the
    // next level/next unsolved level. Maybe subclass again, and show the
    // non-next-level-able window for replays
    this(in Tribe tribe, in Replay replay, in Filename levelFn, in Level level)
    {
        assert (tribe);
        assert (level);

        enum extraYl = 95;
        super(myGeom(3, 300, extraYl), level.name);
        int y = 40 + extraYl;
        immutable bool won = tribe.lixSaved >= tribe.lixRequired;
        _restart = addButton(y, xlg - 40);
        if (! won)
            _restart.hotkey = keyMenuOkay;
        _saveReplay = addButton(y, xlg - 40);
        _exitGame   = addButton(y, xlg - 40);
        if (won)
            _exitGame.hotkey = keyMenuOkay;
        super.captionSuperElements();
        super.setReplayAndLevel(replay, levelFn, level);

        drawLixSaved(tribe);
        drawSkillsAndTimeUsed(tribe);
    }

private:

    void drawLixSaved(in Tribe tribe)
    {
        addChild(new Label(new Geom(0, 40, xlg, 0, From.TOP),
            tribe.lixSavedLate == 0 ? Lang.winGameLixSaved.transl
                              : Lang.winGameLixSavedInTime.transl));
        Label slash = new Label(new Geom(  0, 65, xlg/2, 0, From.TOP), "/");
        Label saved = new Label(new Geom(-25, 65, xlg/2, 0, From.TOP));
        Label requi = new Label(new Geom( 25, 65, xlg/2, 0, From.TOP));
        slash.font = saved.font = requi.font = graphic.textout.djvuL;
        saved.number = tribe.lixSaved;
        requi.number = tribe.lixRequired;
        if (tribe.lixSaved > 0)
            saved.color = color.white;
        if (tribe.lixSaved >= tribe.lixRequired) {
            slash.color = color.white;
            requi.color = color.white;
        }
        addChildren(slash, saved, requi,
            new Label(new Geom(0, 95, xlg, 0, From.TOP), flavorText(tribe)));
    }

    static string flavorText(in Tribe tribe) { with (tribe)
    {
        if (lixSaved >  lixInitial)  assert (false, "not in singleplayer");
        if (lixSaved == lixInitial)  return Lang.winGameCommentPerfect.transl;
        if (lixSaved >  lixRequired) return Lang.winGameCommentMore.transl;
        if (lixSaved == lixRequired) return Lang.winGameCommentExactly.transl;
        if (lixSaved >  0)           return Lang.winGameCommentFewer.transl;
        else                         return Lang.winGameCommentNone.transl;
    }}

    void drawSkillsAndTimeUsed(in Tribe tribe)
    {
        /*
        winGameResultSkillsUsed,
        winGameResultTimeUsed,
        */
    }

}
