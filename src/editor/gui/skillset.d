module editor.gui.skillset;

import std.algorithm;

import basics.user; // length of sorted skill array
import basics.globals;
import file.language;
import graphic.internal;
import gui;
import hardware.mouse;
import level.level;
import lix.enums;

class SkillsetWindow : Window {
private:
    TextButton _okay;
    TextButton _cancel;
    SkillSetter[skillSort.length] _skillSetters;
    Checkbox   _useExploder;
    TextButton _allToZero;

    enum skillXl = 40f;

public:
    this(Level level)
    {
        super(new Geom(0, 0, 2*20 + skillSort.length * skillXl,
            240, From.CENTER), Lang.winSkillTitle.transl);
        _okay   = new TextButton(new Geom(20, 50, 100, 20, From.BOT_RIG));
        _cancel = new TextButton(new Geom(20, 20, 100, 20, From.BOT_RIG));
        _okay.text = Lang.commonOk.transl;
        _cancel.text = Lang.commonCancel.transl;
        _useExploder = new Checkbox(new Geom(20, 50, 20, 20, From.BOT_LEF));
        addChild(new Label(new Geom(50, 50, 150, 20, From.BOT_LEF),
            Lang.winSkillUseExploder.transl));
        _allToZero = new TextButton(new Geom(20, 20, 180, 20, From.BOT_LEF),
            Lang.winSkillClear.transl);
        addChildren(_okay, _cancel, _useExploder, _allToZero);
        initializeFromLevel(level);
    }

    @property bool done() const
    {
        return _okay.execute || mouseClickRight || _cancel.execute;
    }

    void writeChangesTo(Level level) const
    {
        if (! _okay.execute && ! mouseClickRight)
            return;
        assert (level);
        foreach (Ac ac, ref int sk; level.skills)
            sk = 0;
        foreach (setter; _skillSetters) {
            if (setter.skill.isPloder)
                level.ploder = setter.skill;
            level.skills[setter.skill] = setter.number;
        }
    }

protected:
    override void calcSelf()
    {
        if (_useExploder.execute)
            foreach (b; _skillSetters[])
                if (b.skill.isPloder)
                    b.skill = _useExploder.checked ? Ac.exploder : Ac.imploder;
        if (_allToZero.execute)
            foreach (b; _skillSetters[])
                b.number = 0;
    }

private:
    void initializeFromLevel(Level level)
    {
        _useExploder.checked = (level.ploder == Ac.exploder);
        foreach (int i; 0 .. skillSort.length) {
            Ac ac = skillSort[i].isPloder ? level.ploder : skillSort[i];
            _skillSetters[i] = new SkillSetter(new Geom(
                20 + i * skillXl, 40, skillXl, 120));
            _skillSetters[i].skill  = ac;
            _skillSetters[i].number = level.skills[ac];
            addChild(_skillSetters[i]);
        }
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
            immutable a = this.xlg / 2;
            _small[i] = new BitmapButton(new Geom(
                i/3 * a, i%3 * a, a, a), getInternal(fileImageGuiNumber));
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
