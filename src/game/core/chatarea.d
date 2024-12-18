module game.core.chatarea;

/* This is typically never hidden.
 * Only label and texttype are hidden while not typing.
 * The chat console can be empty and we can be not typing, then we don't
 * draw anything.
 */

import std.algorithm;
import std.format;
import std.range;

import file.option;
import file.replay;
import file.language;
import graphic.color;
import gui;
import net.client.richcli;
import physics.score;

class ChatArea : Element {
private:
    Console _console;
    Label _label;
    Texttype _texttype;
    RichClient _network; // not owned. May be null.

public:
    // netw may be null, then we don't register our console there.
    this(Geom g, RichClient netw)
    {
        g.yl = 20f;
        super(g);
        _network = netw;
        _label = new Label(new Geom(gui.thickg, 0,
                               50 - gui.thickg, 20, From.BOTTOM_LEFT));
        _label.text = Lang.winLobbyChat.transl;
        _label.undrawColor = color.transp;
        _label.shown = false;

        _texttype = new Texttype(new Geom(0, 0, xlg-50, 20, From.BOT_RIG));
        _texttype.allowScrolling = true;
        _texttype.undrawColor = color.transp;
        _texttype.onEsc = () { _texttype.text = ""; };
        _texttype.onEnter = () { this.maybeSendText; };
        _texttype.shown = false;

        _console = createConsole();
        addChildren(_console, _label, _texttype);
        if (_network) {
            _network.console = _console;
            _texttype.text = _network.unsentChat;
            _network.unsentChat = "";
        }
        on = _texttype.text != "";
    }

    @property bool on() const { return _texttype.shown; }

    void saveUnsentMessageAndDispose()
    {
        if (_network)
            _network.unsentChat = on ? _texttype.text : "";
        on = false;
        assert (! hasFocus(_texttype), "on() = false didn't go through");
        _network = null;
        // We leave a reference to our console in _network, so that _network
        // can later copy the lines. That's OK, the console is GC-allocated.
    }

    // To draw something else onto the console during game, e.g.
    // announce that overtime has started. Leave it to the network to get
    // lines out of the console and into the lobby console.
    @property inout(Console) console() inout { return _console; }

    // After a networking game, we print the results to the console.
    // Needs a range of scores, and a preferred style to tiebreak the sort.
    // Example print: Game outcome: Player1 32 -- Player2, Player3 16
    void printScores(R)(R rangeOfScores, in Replay rep, in Style preferred)
        if (isInputRange!R && is (ElementType!R == Score))
    {
        Score[] scores = rangeOfScores.array;
        scores.sortPreferringTeam(preferred);

        string line = Lang.netGameEndResult.transl ~ " ";
        foreach (i, score; scores)
            line ~= format!"%s %s%s"(
                rep.styleToNames(score.style),
                score.lixSaved.asText,
                i != scores.length - 1 ? " -- " : "");
        _console.add(line);
    }

protected:
    override void calcSelf()
    {
        super.calcSelf();
        if (keyChat.wasTapped && _network && ! on)
            on = true;
        on = _texttype.on;
    }

    @property bool on(in bool b)
    {
        if (on == b)
            return b;
        if (! b)
            gui.requireCompleteRedraw(); // is this still necessary?
        _label.shown = b;
        _texttype.shown = b;
        _texttype.on = b;
        return b;
    }

private:
    auto createConsole()
    {
        return new class TransparentConsole {
            this() { super(new Geom(0, 0, this.outer.geom.xlg, 0)); }
            override void onLineChange()
            {
                super.onLineChange();
                this.outer.resize(xlg, ylg + 20);
            }
        };
    }

    void maybeSendText()
    {
        if (_texttype.text != "" && _network !is null)
            _network.sendChatMessage(_texttype.text);
        _texttype.text = "";
    }
}
