module gui.score.board;

/*
 * Big score table. To be shown while you hover over the score bars during
 * a multiplayer game. Should ideally be shown after a networking game
 * in the lobby: The to-be-destroyed game should offer this
 * readily-instantiated UI widget to clients who don't even know about Tribes.
 *
 * The scoreboard isn't drawn onto any large button; you must supply that
 * yourself. Nonetheless, it clears its background to the default menu color.
 */

import std.array;
import std.algorithm;
import enumap;

public import physics.score;
import basics.alleg5;
import gui;
import gui.score.bar; // for the package-declared SimpleBar
import graphic.color;
import graphic.internal;

class ScoreBoardOn3DBackground : ScoreBoard {
public:
    this(Geom g) { super(g, 10); }

protected:
    override void drawSelf()
    {
        if (! _bars.length)
            return;
        draw3DButton(xs, ys, xls, yls, color.guiL, color.guiM, color.guiD);
        draw3DFrame(_bars[0].barXs - thicks, _bars[0].ys - thicks,
            _bars[0].xls - _bars[0].barXs + _bars[0].xs + 2*thicks,
            yls - 20*stretchFactor + 2*thicks,
            color.guiD, color.guiM, color.guiL);
    }
}

class ScoreBoardTransparentBg : ScoreBoard {
public:
    this(Geom g) { super(g, 0); }

protected:
    override void drawSelf()
    {
        if (! _bars.length)
            return;
        draw3DFrame(_bars[0].barXs - thicks, _bars[0].ys - thicks,
            _bars[0].xls - _bars[0].barXs + _bars[0].xs + 2*thicks,
            yls - 20*stretchFactor + 2*thicks,
            color.guiD, color.guiM, color.guiL);
    }
}

/*
 * ScoreBoard, the base class of the above.
 * Still public, but module-private constructor.
 * Other modules choose a derived class and treat ScoreBoard as an interface.
 */
class ScoreBoard : Element {
private:
    AnnotatedBar[] _bars;
    Style _ourStyle;
    public immutable int padding; // room around AnnotatedBar array on 4 sides

    this(Geom g, in int pa)
    {
        super(g);
        padding = pa;
    }

public:
    void add(in Style style, in string name)
    {
        if (! _bars.canFind!(bar => bar.style == style)) {
            _bars ~= new AnnotatedBar(
                new Geom(padding, padding, this.xlg - 2 * padding, 20), style);
            addChild(_bars[$-1]);
        }
        // The creation in the above 'if' ensures that this will find sth.:
        auto bar = _bars.find!(bar => bar.style == style)[0];
        if (bar.has(name))
            return;
        bar.add(name);
        reformatBars();
    }

    void update(in Score updatedScore)
    in {
        assert (_bars.canFind!(bar => bar.style == updatedScore.style),
            "call add() for some names of this tribe before you update()");
    }
    body {
        auto bar = _bars.find!(bar => bar.style == updatedScore.style)[0];
        if (updatedScore == bar.score)
            return;
        bar.score = updatedScore;
        reformatBars();
    }

    @property Style ourStyle(in Style st)
    {
        _ourStyle = st;
        reformatBars();
        return _ourStyle;
    }

private:
    void reformatBars()
    {
        reqDraw();
        updateMaxPotentials(_bars);
        _bars.sortPreferringTeam(_ourStyle);
        this.resize(this.xlg, 2 * padding + _bars.map!(b => b.ylg).sum);
        foreach (const size_t i, bar; _bars)
            bar.move(padding, padding + _bars[0 .. i].map!(b => b.ylg).sum);
    }
}

/*
 * AnnotatedBar: A long row with names at the left, stats in the middle,
 * and a SimpleBar at the right.
 *
 * Normally, a ScoreBar doesn't need to know its Style at the beginning.
 * ScoreBar's Style is set every time Score is updated, Score knows Style.
 * But in AnnotatedBar, we need to generate icons that require the Style
 * during construction. Thus, AnnotatedBar asks for the Style and then
 * hardwires that into the labels wherever possible.
 */
class AnnotatedBar : Element, ScoreBar {
private:
    SimpleBar _bar;
    Label _nameLabel;
    IconNumber _alive; // == potential minus score
    IconNumber _saved; // == potential minus score
    CutbitElement _nuke;
    string[] _names;

public:
    /*
     * +----------------------------------------------------------------------+
     * | All names of team  Lix alive   Lix saved   Nuke           Bar        |
     * | 45 % - 1/2 * 120f  20f + 45f   20f + 45f   30 f    55 % - 1/2 * 120f |
     * |                    \________       ___________/                      |
     * |                             = 120 f                                  |
     * +----------------------------------------------------------------------+
     */
    this(Geom g, Style style)
    {
        super(g);
        immutable float teamL = xlg*9/20f - 60f;
        immutable float barL = xlg*11/20f - 60f;
        immutable float nukeL = 30f;
        immutable float iconL = 45f;
        immutable float savedE = barL + nukeL; // endpoint (x From.RIGHT)
        immutable float aliveE = barL + nukeL + iconL; // endpoint
        assert (teamL > 20f, "this is a very short AnnotatedBar");
        assert (barL > 20f, "this is a very short AnnotatedBar");

        _bar = new SimpleBar(new Geom(0, 0, barL, 20, From.RIGHT));
        _bar.score = Score(style, 0, 0);
        _nameLabel = new Label(new Geom(0, 0, teamL - 5f, 20));
        _nameLabel.color = brighten(style);

        _alive = IconNumber(
            new Geom(aliveE+3, 0, 20, 20, From.RIGHT),
            new Geom(aliveE+20, 0, iconL, 20, From.RIGHT),
            style, 2);
        _saved = IconNumber(
            new Geom(savedE, 0, 20, 20, From.RIGHT),
            new Geom(savedE+20, 0, iconL, 20, From.RIGHT),
            style, 5);

        _nuke = new CutbitElement(new Geom(barL, 0, nukeL, 20, From.RIGHT),
            InternalImage.gamePanel2.toCutbit);
        _nuke.xf = GamePanel2Xf.nuke;

        addChildren(_bar, _nameLabel, _alive.icon, _alive.label,
            _saved.icon, _saved.label, _nuke);
    }

    @property Score score() const { return _bar.score; }
    @property Score score(in Score sco)
    {
        if (_bar.score == sco)
            return sco;
        _alive.number = sco.potential - sco.current;
        _saved.number = sco.current;
        _nuke.shown = sco.prefersGameToEnd;
        return _bar.score = sco;
    }

    @property int maxPotential() const { return _bar.maxPotential; }
    @property int maxPotential(in int mp) { return _bar.maxPotential = mp; }

    @property float barXs() const { return _bar.xs; }
    bool has(string aName) const { return _names.canFind(aName); }

    void add(string aName)
    {
        if (has(aName))
            return;
        reqDraw();
        _names ~= aName;
        sort(_names);
        _nameLabel.text = _names.join(", ");
    }

private:
    static Alcol brighten(in Style st)
    {
        float r, g, b;
        al_unmap_rgb_f(getAlcol3DforStyle(st).m, &r, &g, &b);
        return al_map_rgb_f(r/3 + 0.66f, g/3 + 0.66f, b/3 + 0.66f);
    }
}

struct IconNumber {
private:
    CutbitElement _icon;
    Label _label;
    int _lastNumber; // to reduce calls to the label's reqDraw

public:
    this(Geom gi, Geom gl, Style style, int xFrameForIcon)
    {
        import graphic.internal;
        _icon = new CutbitElement(gi, getPanelInfoIcon(style));
        _icon.xf = xFrameForIcon;
        _icon.yf = xFrameForIcon == 5 ? 1 : 0; // exits should be greyed out
        _label = new Label(gl);
        _label.color = AnnotatedBar.brighten(style);
        _lastNumber = -1; // merely different from 0 for the next line here
        number = 0;
    }

    inout(CutbitElement) icon() inout pure @nogc { return _icon;  }
    inout(Label) label() inout pure @nogc { return _label; }

    @property int number() const pure @nogc { return _lastNumber; }
    @property int number(in int n)
    {
        if (n == _lastNumber)
            return n;
        _lastNumber = n;
        _icon.shown = (n != 0);
        _label.shown = (n != 0);
        _label.number = n;
        return n;
    }
}
