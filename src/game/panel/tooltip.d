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

    static string format(ID id)
    {
        auto ptr = id in _arr;
        return ptr ? ptr.format() : "";
    }

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

Tooltip[Tooltip.ID] _arr;

static this()
{
    key(Tooltip.ID.forceLeft, Lang.gameForceLeft, keyForceLeft);
    key(Tooltip.ID.forceRight, Lang.gameForceRight, keyForceRight);
    key(Tooltip.ID.priorityInvert, Lang.gamePriorityInvert, keyPriorityInvert);
    none(Tooltip.ID.queueBuilder, Lang.gameQueueBuilder);
    none(Tooltip.ID.queuePlatformer, Lang.gameQueuePlatformer);
    key(Tooltip.ID.holdToScroll, Lang.gameHoldToScroll, keyScroll);
    none(Tooltip.ID.clickToCancelReplay, Lang.gameClickToCancelReplay);
    key(Tooltip.ID.framestepOrQuit, Lang.gameFramestepOrQuit, keyGameExit);
    none(Tooltip.ID.pause, Lang.gamePause);
    mouse(Tooltip.ID.zoom, Lang.gameZoom);
    none(Tooltip.ID.showSplatRuler, Lang.gameShowSplatRuler);
    none(Tooltip.ID.highlightGoals, Lang.gameHighlightGoals);
    none(Tooltip.ID.stateSave, Lang.gameStateSave);
    none(Tooltip.ID.stateLoad, Lang.gameStateLoad);
    none(Tooltip.ID.showReplayEditor, Lang.gameShowReplayEditor);
    mouse(Tooltip.ID.framestepBack, Lang.gameFramestepBack);
    mouse(Tooltip.ID.framestepAhead, Lang.gameFramestepAhead);
    mouse(Tooltip.ID.fastForward, Lang.gameFastForward);
    none(Tooltip.ID.restart, Lang.gameRestart);
    none(Tooltip.ID.nuke, Lang.gameNuke);
}

void key(Tooltip.ID id, Lang lang, UserOption!KeySet opt)
{
    _arr[id] = Tooltip(lang, false, opt);
}
void mouse(Tooltip.ID id, Lang lang)
{
    _arr[id] = Tooltip(lang, true, null);
}
void none(Tooltip.ID id, Lang lang)
{
    _arr[id] = Tooltip(lang, false, null);
}
