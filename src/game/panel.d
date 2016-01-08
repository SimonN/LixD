module game.panel;

/* Panel: A large GUI element that features all the visible buttons
 * during gameplay. Can appear in many different forms, see enum GapaMode
 * in game.panelinf.
 */

import basics.globals;
import basics.user;
import game.panelinf;
import game.tribe;
import graphic.gralib;
import gui;
import hardware.keyboard; // we need a different behavior of skill button
import hardware.mouse;    // execution and skill button warning sound
import hardware.sound;
import lix.enums;

class Panel : Element {

public:

    @property float skillYl() const { return this.geom.ylg - 20; }
    @property float skillXl() const {
        return Geom.screenXlg / (skillSort.length + 4);
    }

    SkillButton[] skills;

    BitmapButton zoom, restart, pause, nukeSingle, nukeMulti;
    TwoTasksButton speedBack, speedAhead, speedFast;

    PanelStats stats;

    @property auto gapamode() const { return _gapamode; }
    // setter property is down below

    enum frameFast  = 4;
    enum frameTurbo = 5;

private:

    private GapaMode _gapamode;




public:

this()
{
    super(new Geom(0, 0, Geom.screenXlg, Geom.panelYlg, From.BOTTOM));

    stats = new PanelStats(new Geom(0, 0, this.xlg - 4 * skillXl,
                           this.ylg - skillYl, From.TOP_LEFT));
    addChild(stats);

    skills.length = basics.user.skillSort.length;
    foreach (int id, ac; basics.user.skillSort) {
        skills[id] = new SkillButton(new Geom(id * skillXl, 0,
                                 skillXl, skillYl, From.BOTTOM_LEFT));
        skills[id].skill = ac;
        skills[id].hotkey = basics.user.keySkill[skillSort[id]];
        addChild(skills[id]);
    }

    void newControlButton(T)(ref T b, int x, int y, int frame,
        in int keyLeft = 0, in int keyRight = 0)
        if (is(T : BitmapButton))
    {
        b = new T(new Geom((3 - x) * skillXl,
            y == 0 ?  0.5f * skillYl : 0, skillXl,
            0.5f * skillYl, From.BOTTOM_RIGHT),
            getInternal(basics.globals.fileImageGame_panel));
        b.xf     = frame;
        b.hotkey = keyLeft;
        static if (is (T == TwoTasksButton))
            b.hotkeyRight = keyRight;
        addChild(b);
    }

    newControlButton(zoom,       0, 0,  2, keyZoom);
    newControlButton(speedBack,  0, 1, 10, keyFrameBackOne, keyFrameBackMany);
    newControlButton(speedAhead, 1, 1,  3, keyFrameAheadOne,keyFrameAheadMany);
    newControlButton(speedFast,  2, 1, frameFast, keySpeedFast, keySpeedTurbo);
    newControlButton(restart,    1, 0,  8, keyRestart);
    newControlButton(nukeSingle, 2, 0,  9, keyNuke);

    pause = new BitmapButton(
        new Geom(0, 0, skillXl, skillYl, From.BOTTOM_RIGHT),
        getInternal(basics.globals.fileImageGamePause));

    nukeMulti = new BitmapButton(
        new Geom(0, 0, 4 * skillXl, this.ylg - skillYl, From.BOTTOM_RIGHT),
        getInternal(basics.globals.fileImageGameNuke));

    pause    .hotkey = keyPause;
    nukeMulti.hotkey = keyNuke;

    addChild(pause);
    addChild(nukeMulti);

    gapamode = GapaMode.PLAY_SINGLE;
}



@property GapaMode
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



void
setLikeTribe(in Tribe tr)
{
    if (tr is null)
        return;

    foreach (b; skills) {
        b.style  = tr.style;
        b.number = tr.skills[b.skill];
    }
    nukeSingle.on = tr.nuke;
    nukeMulti .on = tr.nuke;

    /*
    stats.set_tribe_local(tr);
    spawnintSlow.set_spawnint(tr->spawnintSlow);
    spawnint_cur .set_spawnint(tr->spawnint);
    rate_fixed   .set_number  (tr->spawnintFast);
    spec_tribe .set_text(tr->get_name());
    set_skill_on(skillLastSetOn);
    */

    reqDraw();
}
// end function setLikeTribe()



void
highlightFirstSkill()
{
    assert (currentSkill is null);
    foreach (skill; skills)
        if (skill.number != 0) {
            skill.on = true;
            break;
        }
}



SkillButton
currentSkill()
{
    foreach (b; skills)
        if (b.on && b.skill != Ac.nothing && b.number != 0)
            return b;
    return null;
}



bool nukeDoubleclicked() const
{
    // DTODO nuke doubleclick
    return ! nukeSingle.on && nukeSingle.execute
        || ! nukeMulti.on  && nukeMulti.execute;
}



private void
handleExecutingSkillButton(SkillButton skill)
{
    // We set on/off-ness correctly. The game interprets on-ness only.
    if (skill.number != 0) {
        if (currentSkill)
            currentSkill.on = false;
        skill.on = true;
    }
    else {
        assert (skill.number == 0);
        // The button executes continually when the mouse button is held down
        // over it, but we should only play the warning sound on the click.
        if (mouseClickLeft() || keyTapped(skill.hotkey))
            hardware.sound.playLoud(Sound.PANEL_EMPTY);
    }
}



protected override void
calcSelf()
{
    void setSpeedTo(in int a)
    {
        assert (a >= 0);
        assert (a <  4);
        pause.on     = (a == 0);
        speedFast.on = (a >= 2);
        speedFast.xf = (a < 3 ? frameFast : frameTurbo);
    }

    if (pause.execute) {
        setSpeedTo(pause.on ? 1 : 0);
    }
    else if (speedBack.executeLeft
        ||   speedBack.executeRight
        ||   speedAhead.executeLeft // but not on speedAhead.executeRight
    ) {
        setSpeedTo(0);
    }
    else if (speedFast.executeLeft) {
        setSpeedTo(speedFast.on ? 1 : 2);
    }
    else if (speedFast.executeRight) {
        setSpeedTo(speedFast.xf == frameTurbo ? 1 : 3);
    }

    SkillButton oldSkill = currentSkill();
    foreach (skill; skills)
        if (skill.execute)
            handleExecutingSkillButton(skill);
    if (currentSkill !is oldSkill)
        hardware.sound.playLoud(Sound.PANEL);
}

}
// end class Panel
