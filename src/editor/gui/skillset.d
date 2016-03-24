module editor.gui.skillset;

import file.language;
import gui;
import hardware.mouse;
import level.level;
import lix.enums;

class SkillsetWindow : Window {
private:
    TextButton _okay;
    TextButton _cancel;

public:
    this(Level level)
    {
        super(new Geom(0, 0, 400, 300, From.CENTER),
            Lang.winSkillTitle.transl);
        _okay   = new TextButton(new Geom(20, 60, 80, 20, From.BOT_RIG));
        _cancel = new TextButton(new Geom(20, 20, 80, 20, From.BOT_RIG));
        _okay.text = Lang.commonOk.transl;
        _cancel.text = Lang.commonCancel.transl;
        addChildren(_okay, _cancel);
        initializeFromLevel(level);
    }

    @property bool done() const
    {
        return _okay.execute || mouseClickRight || _cancel.execute;
    }

    void writeChangesTo(Level level)
    {
        if (! _okay.execute && ! mouseClickRight)
            return;
        assert (level);
    }

private:
    void initializeFromLevel(Level level)
    {
    }
}
