module game.panel;

/* Panel: A large GUI element that features all the visible buttons
 * during gameplay. Can appear in many different forms, see enum GapaMode
 * in game.panelinf.
 */

import basics.globals;
import basics.user;
import game;
import graphic.gralib;
import gui;

class Panel : Element {

public:

    @property float skillXl() { return Geom.screenXlg / (14 + 4); }
    @property float skillYl() { return this.geom.ylg - 20; }

    SkillButton[] skills;

    BitmapButton zoom, restart, pause, nukeSingle, nukeMulti;
    TwoTasksButton speedBack, speedAhead, speedFast;

    @property auto gapamode() const { return _gapamode; }
    // setter property is down below

private:

    private GapaMode _gapamode;

    private Button _dummyBG;



public:

this()
{
    super(new Geom(0, 0, Geom.screenXlg,
                         Geom.screenYlg / Geom.panelYlDivisor, From.BOTTOM));

    _dummyBG = new Button(new Geom(0, 0, this.xlg / 2,
                           this.ylg - skillYl, From.TOP_LEFT));
    addChild(_dummyBG);

    skills.length = basics.user.skillSort.length;
    foreach (int id, ac; basics.user.skillSort) {
        skills[id] = new SkillButton(new Geom(id * skillXl, 0,
                                 skillXl, skillYl, From.BOTTOM_LEFT));
        skills[id].skill = ac;
        addChild(skills[id]);
        // DTODO: set hotkeys to skillbuttons
    }

    void newControlButton(T)(ref T b, int x, int y, int frame)
        if (is(T : BitmapButton))
    {
        b = new T(new Geom((3 - x) * skillXl,
            y == 0 ?  0.5f * skillYl : 0, skillXl,
            0.5f * skillYl, From.BOTTOM_RIGHT),
            getInternal(basics.globals.fileImageGame_panel));
        b.xf = frame;
        addChild(b);
    }

    newControlButton(zoom,       0, 0,  2);
    newControlButton(speedBack,  0, 1, 10);
    newControlButton(speedAhead, 1, 1,  3);
    newControlButton(speedFast,  2, 1,  4); // 5 if turbo is on
    newControlButton(restart,    1, 0,  8);
    newControlButton(nukeSingle, 2, 0,  9);

    pause = new BitmapButton(
        new Geom(0, 0, skillXl, skillYl, From.BOTTOM_RIGHT),
        getInternal(basics.globals.fileImageGamePause));

    nukeMulti = new BitmapButton(
        new Geom(0, 0, 4 * skillXl, this.ylg - skillYl, From.BOTTOM_RIGHT),
        getInternal(basics.globals.fileImageGameNuke));

    addChild(pause);
    addChild(nukeMulti);

    gapamode = GapaMode.PLAY_SINGLE;
}



public @property GapaMode
gapamode(in GapaMode gp)
{
    _gapamode = gp;

    if (_gapamode == GapaMode.PLAY_SINGLE) {
        nukeMulti.hide();
    }
    else {
        // ...
    }

    return _gapamode = gp;
}



public void
setLikeTribe(in Tribe tr)
{
    if (tr is null)
        return;

    foreach (b; skills) {
        b.style  = tr.style;
        b.number = tr.skills[b.skill];
    }

    /*
    stats.set_tribe_local(tr);

    spawnintSlow.set_spawnint(tr->spawnintSlow);
    spawnint_cur .set_spawnint(tr->spawnint);
    rate_fixed   .set_number  (tr->spawnintFast);

    nukeSingle.set_on  (tr->nuke);
    nukeMulti .set_on  (tr->nuke);
    spec_tribe .set_text(tr->get_name());

    set_skill_on(skillLastSetOn);
    */

    reqDraw();
}
// end function setLikeTribe()



protected override void
calcSelf()
{
    _dummyBG.down = false;
}

}
// end class Panel
