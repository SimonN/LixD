module gui.score.board;

/*
 * Big score table. To be shown while you hover over the score bars during
 * a multiplayer game. Should ideally be shown after a networking game
 * in the lobby: The to-be-destroyed game should offer this
 * readily-instantiated UI widget to clients who don't even know about Tribes.
 */

import std.array;
import std.algorithm;
import enumap;

import basics.alleg5;
import gui;
import gui.score.bar; // for the package-declared SimpleBar
import graphic.color;
import graphic.internal;
import physics.score;
import physics.fracint;

/*
 * The large scoreboard during play that appears when you hover over the
 * small graph in the panel.
 */
class ScoreBoardOn3DBackground : ScoreBoard {
public:
    this(Geom g) { super(g, 10); }

protected:
    override void drawSelf()
    {
        if (! _bars.length)
            return;
        draw3DButton(xs, ys, xls, yls, color.gui);
        draw3DFrame(_bars[0].barXs - thicks, _bars[0].ys - thicks,
            _bars[0].xls - _bars[0].barXs + _bars[0].xs + 2*thicks,
            yls - 20*stretchFactor + 2*thicks, color.gui);
    }
}

/*
 * ScoreBoard, the base class of the above.
 * Still public, but module-private constructor.
 * Other modules choose a derived class and treat ScoreBoard as an interface.
 */
abstract class ScoreBoard : Element {
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
    do {
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
        _bar.score = Score(style, FracInt(0), 0);
        _nameLabel = new Label(new Geom(0, 0, teamL - 5f, 20));
        _nameLabel.color = getAlcol3DforStyle(style).textColor;

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

    Score score() const { return _bar.score; }
    void score(in Score sco)
    {
        if (_bar.score == sco)
            return;
        _bar.score = sco;
        _alive.number = sco.lixYetUnsavedRaw; // Yes, unscaled: not potential()
        _nuke.shown = sco.prefersGameToEnd;
        _saved.number = sco.lixSaved;
    }

    FracInt maxPotential() const { return _bar.maxPotential; }
    void maxPotential(in FracInt mp) { _bar.maxPotential = mp; }

    float barXs() const { return _bar.xs; }
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
}

struct IconNumber {
private:
    CutbitElement _icon;
    Label _label;
    FracInt _previous; // to reduce calls to the label's reqDraw

public:
    this(Geom gi, Geom gl, Style style, int xFrameForIcon)
    {
        import graphic.internal;
        _icon = new CutbitElement(gi,
                    Spritesheet.infoBarIcons.toCutbitFor(style));
        _icon.xf = xFrameForIcon;
        _icon.yf = xFrameForIcon == 5 ? 1 : 0; // exits should be greyed out
        _label = new Label(gl);
        _label.color = getAlcol3DforStyle(style).textColor;
        _previous = FracInt(-1); // merely different from 0, for number()
        number = FracInt(0);
    }

    inout(CutbitElement) icon() inout pure @nogc { return _icon;  }
    inout(Label) label() inout pure @nogc { return _label; }

    void number(in int n) { number(FracInt(n)); }
    void number(in FracInt n)
    {
        if (n == _previous) {
            return;
        }
        _previous = n;
        _icon.shown = n > 0;
        _label.shown = n > 0;
        _label.text = n.asText;
    }
}
