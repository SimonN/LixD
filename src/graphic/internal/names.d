module graphic.internal.names;

import glo = basics.globals;

/*
 * Names for the internal bitmaps.
 * Names for the individual frames (in x direction) of those bitmaps.
 *
 * Bitmap names are both for implementation and for callers.
 *
 * Frame names should be for callers of graphic.internal's public functions,
 * they should probably not be for implementation of graphic.internal.
 */

enum InternalImage {
    ability,
    debris,
    editPanel,
    explosion,
    fuse,
    fuseFlame,
    gameArrow,
    gameIcon,
    gamePanel,
    gamePanel2,
    gameReplay,
    gamePause,
    goalMarker,
    guiNumber,
    implosion,
    spritesheet,
    styleRecol,
    lobbySpec,
    menuBackground,
    menuCheckmark,
    mouse,
    previewIcon,
    rewindPrevPly,
    skillsInPanel,
    skillsInTweaker,
}

enum GamePanel2Xf {
    nuke, quicksave, quickload, showTweaker,
    showSplatRuler, highlightGoals, unusedShades, restart
}

@safe pure nothrow:

string toLoggableName(in InternalImage id)
{
    return glo.dirDataBitmap.dirRootless ~ id.toBasenameNoExt ~ ".png";
}

package:

string toBasenameNoExt(in InternalImage id) @nogc
{
    with (InternalImage) final switch (id) {
    case ability: return "abilityabovehead";
    case guiNumber: return "guinumpick";
    case debris: return "debris";
    case editPanel: return "editorpanelbuttons";
    case explosion: return "explode";
    case fuse: return "fuse";
    case fuseFlame: return "fuseflame";
    case gameArrow: return "assignmentarrow";
    case gameIcon: return "lixouticon";
    case gamePanel: return "gamebigbuttons";
    case gamePanel2: return "gamesmallbuttons";
    case gamePause: return "gamepause";
    case gameReplay: return "replayfloatingr";
    case goalMarker: return "goalmarker";
    case implosion: return "implode";
    case spritesheet: return "lixsprites";
    case styleRecol: return "lixrecol";
    case lobbySpec: return "lobbyspectatehandi";
    case menuBackground: return "mainmenubg";
    case menuCheckmark: return "checkbox";
    case mouse: return "mouse";
    case previewIcon: return "toruspreview";
    case rewindPrevPly: return "rewindprevply";
    case skillsInPanel: return "skillsinpanel";
    case skillsInTweaker: return "tweakerskills";
    }
}

bool needGuiRecoloring(in InternalImage id) @nogc
{
    with (InternalImage) switch (id) {
    case ability:
    case guiNumber:
    case editPanel:
    case gameArrow:
    case gamePanel:
    case gamePanel2:
    case gamePause:
    case lobbySpec:
    case menuCheckmark:
    case previewIcon:
    case rewindPrevPly:
    case skillsInTweaker:
        return true;
    default:
        return false;
    }
}
