module editor.gui.skillset;

import std.algorithm;

import basics.user; // length of sorted skill array
import basics.globals;
import editor.gui.okcancel;
import file.language;
import graphic.internal;
import gui;
import level.level;
import lix.enums;

class SkillsetWindow : OkCancelWindow {
private:
    SkillSetter[skillSort.length] _skillSetters;
    BoolOption _useExploder;
    TextButton _allToZero;
    NumPick    _numPick;
    TextButton _allToNum;
    TextButton _eightToNum;

    enum skillXl = 35f;

public:
    this(Level level)
    {
        super(new Geom(0, 0, 2*20 + skillSort.length * skillXl,
            240, From.CENTER), Lang.winSkillTitle.transl);
        _useExploder = new BoolOption(new Geom(20, 50, 180, 20, From.BOT_LEF),
            Lang.winSkillUseExploder.transl, null);
        _allToZero = new TextButton(new Geom(20, 20, 180, 20, From.BOT_LEF),
            Lang.winSkillClear.transl);

        immutable pickXl = this.xlg - 180 - 100 - 2*2*20;
        _numPick    = new NumPick   (new Geom(220, 20, pickXl,   20,
            From.BOT_LEF), this.numPickConfig);
        _allToNum   = new TextButton(new Geom(220, 50, pickXl/2, 20,
            From.BOT_LEF), Lang.winSkillAllTo.transl);
        _eightToNum = new TextButton(new Geom(220 + pickXl/2, 50, pickXl/2, 20,
            From.BOT_LEF), Lang.winSkillEightTo.transl);
        addChildren(_useExploder, _allToZero,
                    _numPick, _allToNum, _eightToNum);
        initializeFromLevel(level);
    }

protected:
    override void selfWriteChangesTo(Level level) const
    {
        foreach (Ac ac, ref int sk; level.skills)
            sk = 0;
        level.ploder = _useExploder.checked ? Ac.exploder : Ac.imploder;
        _skillSetters[].each!(b => level.skills[b.skill] = b.number);
    }

    override void calcSelf()
    {
        if (_useExploder.execute)
            setUseExploder(_useExploder.checked);
        if (_allToZero.execute)
            _skillSetters.each!(b => b.number = 0);
        if (_allToNum.execute)
            _skillSetters.each!(b => b.number = _numPick.number);
        if (_eightToNum.execute) {
            setUseExploder(false);
            immutable classic8 = [ Ac.climber, Ac.floater, Ac.imploder,
                Ac.blocker, Ac.builder, Ac.basher, Ac.miner, Ac.digger ];
            _skillSetters.each!(b => b.number =
                classic8.canFind(b.skill) ? _numPick.number : 0);
        }
    }

private:
    void initializeFromLevel(Level level)
    {
        foreach (int i; 0 .. skillSort.length) {
            Ac ac = skillSort[i].isPloder ? level.ploder : skillSort[i];
            _skillSetters[i] = new SkillSetter(new Geom(
                20 + i * skillXl, 40, skillXl, 120));
            _skillSetters[i].skill  = ac;
            _skillSetters[i].number = level.skills[ac];
            addChild(_skillSetters[i]);
        }
        setUseExploder(level.ploder == Ac.exploder);
    }

    void setUseExploder(in bool b)
    {
        _useExploder.checked = b;
        _skillSetters[].filter!(s => s.skill.isPloder)
                       .each!(s => s.skill = (b ? Ac.exploder : Ac.imploder));
    }

    NumPickConfig numPickConfig() const
    {
        NumPickConfig ret;
        ret.digits = 3;
        ret.sixButtons = true;
        ret.min = -1;
        ret.max = 999;
        ret.minusOneChar = '*';
        return ret;
    }
}

class SkillSetter : Element {
private:
    SkillButton     _main;
    BitmapButton[6] _small;

public:
    this(Geom g)
    {
        super(g);
        _main = new SkillButton(new Geom(0, 0, xlg, ylg/2, From.BOTTOM));
        addChild(_main);
        foreach (int i; 0 .. _small.length) {
            _small[i] = new BitmapButton(new Geom( i/3 * xlg/2, i%3 * ylg/6,
                xlg/2, ylg/6), getInternal(fileImageGuiNumber));
            _small[i].xf = 6 + i;
            addChild(_small[i]);
        }
    }

    @property Ac  skill()  const { return _main.skill;      }
    @property Ac  skill(Ac ac)   { return _main.skill = ac; }
    @property int number() const { return _main.number;     }
    @property int number(int i)  { return _main.number = i; }

protected:
    override void calcSelf()
    {
        int exec(int i) { return _small[i].execute ? 1 : 0; }
        immutable change = 100 * exec(0) + 10 * exec(1) + exec(2)
                         - 100 * exec(3) - 10 * exec(4) - exec(5);
        if (change > 0)
            number = number == skillInfinity ? 0
                : number == skillNumberMax ? skillInfinity
                : min(number + change, skillNumberMax);
        else if (change < 0)
            number = number == skillInfinity ? skillNumberMax
                : number == 0 ? skillInfinity
                : max(number + change, 0);
    }
}
