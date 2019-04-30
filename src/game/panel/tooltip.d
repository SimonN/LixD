module game.panel.tooltip;

import std.format;
import std.conv;

import file.language;
import file.log;
import file.option;
import hardware.keyset;

interface TooltipSuggester {
public:
    @property bool isSuggestingTooltip() const;
    @property Tooltip.ID suggestedTooltip() const
        in {
            assert (isSuggestingTooltip,
                "Call suggestedTooltip only when isSuggestingTooltip.");
        }
}

struct Tooltip {
    Lang lang;
    bool formatWithButtons;
    UserOption!KeySet keyToHold;

    // Sorted from most important (smallest ID) to least important.
    // When several are requested, only the most important is shown.
    enum ID : int {
        pause = 0x1,
        zoom = 0x2,
        showSplatRuler = 0x4,
        highlightGoals = 0x8,
        stateSave = 0x10,
        stateLoad = 0x20,
        showReplayEditor = 0x40,
        framestepBack = 0x80,
        framestepAhead = 0x100,
        fastForward = 0x200,
        restart = 0x400,
        nuke = 0x800,

        forceLeft = 0x1000,
        forceRight = 0x2000,
        priorityInvert = 0x4000,
        queueBuilder = 0x8000,
        queuePlatformer = 0x1_0000,
        holdToScroll = 0x2_0000,
        clickToCancelReplay = 0x4_0000,
        framestepOrQuit = 0x8_0000,
    }

    static string format(int manyIDs) nothrow
    {
        for (int i = 1; i <= ID.max; i *= 2)
            if (manyIDs & i) {
                try
                    return Tooltip.format((manyIDs & i).to!ID);
                catch (Exception)
                    continue;
            }
        return "";
    }

    static string format(ID id) { return makeTooltip(id).format; }

    string format()
    {
        try {
            string s = lang.transl;
            return formatWithButtons // see hardware.keynames for these
                ? s.format("\u27BF" /+ lmb +/, "\u27C1" /+ rmb +/)
                : keyToHold ? s.format(keyToHold.nameShort) : s;
        }
        catch (Exception e) {
            log(e.msg);
            return std.format.format!"!%s!"(lang);
        }
    }
}

private:

Tooltip makeTooltip(Tooltip.ID id) nothrow @nogc @safe
{
    Tooltip none(in Lang lang) { return Tooltip(lang, false, null); }
    Tooltip mouse(in Lang lang) { return Tooltip(lang, true, null); }
    Tooltip key(in Lang lang, UserOption!KeySet opt)
    {
        return Tooltip(lang, false, opt);
    }

    with (Tooltip) final switch (id) {
        case ID.forceLeft: return key(Lang.gameForceLeft, keyForceLeft);
        case ID.forceRight: return key(Lang.gameForceRight, keyForceRight);
        case ID.priorityInvert:
            return key(Lang.gamePriorityInvert, keyPriorityInvert);
        case ID.queueBuilder: return none(Lang.gameQueueBuilder);
        case ID.queuePlatformer: return none(Lang.gameQueuePlatformer);
        case ID.holdToScroll: return key(Lang.gameHoldToScroll, keyScroll);
        case ID.clickToCancelReplay: return none(Lang.gameClickToCancelReplay);
        case ID.framestepOrQuit:
            return key(Lang.gameFramestepOrQuit, keyGameExit);
        case ID.pause: return none(Lang.gamePause);
        case ID.zoom: return mouse(Lang.gameZoom);
        case ID.showSplatRuler: return none(Lang.gameShowSplatRuler);
        case ID.highlightGoals: return none(Lang.gameHighlightGoals);
        case ID.stateSave: return none(Lang.gameStateSave);
        case ID.stateLoad: return none(Lang.gameStateLoad);
        case ID.showReplayEditor: return none(Lang.gameShowReplayEditor);
        case ID.framestepBack: return mouse(Lang.gameFramestepBack);
        case ID.framestepAhead: return mouse(Lang.gameFramestepAhead);
        case ID.fastForward: return mouse(Lang.gameFastForward);
        case ID.restart: return none(Lang.gameRestart);
        case ID.nuke: return none(Lang.gameNuke);
    }
}
