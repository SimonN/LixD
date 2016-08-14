module gui.skillico;

import graphic.internal;
import gui.cutbitel;
import gui.geometry;
import lix.enums;

class SkillIcon : CutbitElement {
public:
    this(Geom g, Style st = Style.garden)
    {
        super(g, st.getSkillButtonIcon);
    }

    @property Ac ac(in Ac _ac)
    {
        xf = _ac.acToSkillIconXf;
        return _ac;
    }
}
