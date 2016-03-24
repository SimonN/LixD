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
        addChildren(_okay, _cancel);
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
        foreach (setter; _skillSetters)
            level.skills[setter.skill] = setter.number;
    }

private:
    void initializeFromLevel(Level level)
    {
        foreach (int i; 0 .. skillSort.length) {
            _skillSetters[i] = new SkillSetter(new Geom(
                20 + i * skillXl, 40, skillXl, 120), skillSort[i]);
            _skillSetters[i].number = level.skills[skillSort[i]];
            addChild(_skillSetters[i]);
        }
    }
}

class SkillSetter : Element {
private:
    SkillButton     _main;
    BitmapButton[6] _small;

public:
    this(Geom g, Ac ac)
    {
        super(g);
        _main = new SkillButton(new Geom(0, 0, xlg, ylg/2, From.BOTTOM));
        _main.skill = ac;
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
