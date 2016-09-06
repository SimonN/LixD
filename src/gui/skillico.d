module gui.skillico;

public import net.ac;
public import net.style;

import graphic.internal;
import gui.cutbitel;
import gui.geometry;

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
