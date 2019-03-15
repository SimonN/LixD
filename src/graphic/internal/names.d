module graphic.internal.names;

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
    skillIcons,
}

enum GamePanel2Xf {
    nuke, quicksave, quickload, showReplayEditor,
    showSplatRuler, highlightGoals, unusedShades
}

@safe pure nothrow @nogc:

string toBasename(in InternalImage id)
{
    with (InternalImage) final switch (id) {
    case ability: return "ability.I.png";
    case guiNumber: return "api_numb.I.png";
    case debris: return "debris.I.png";
    case editPanel: return "edit_pan.I.png";
    case explosion: return "explode.I.png";
    case fuse: return "fuse.I.png";
    case fuseFlame: return "fuse_fla.I.png";
    case gameArrow: return "game_arr.I.png";
    case gameIcon: return "game_ico.I.png";
    case gamePanel: return "game_pan.I.png";
    case gamePanel2: return "game_pa2.I.png";
    case gamePause: return "game_pau.I.png";
    case gameReplay: return "game_rep.I.png";
    case goalMarker: return "goalmark.I.png";
    case implosion: return "implode.I.png";
    case spritesheet: return "lix.I.png";
    case styleRecol: return "lixrecol.I.png";
    case lobbySpec: return "lobby_sp.I.png";
    case menuBackground: return "menu_bg.I.png";
    case menuCheckmark: return "menu_chk.I.png";
    case mouse: return "mouse.I.png";
    case previewIcon: return "prev_ico.I.png";
    case skillIcons: return "skillico.I.png";
    }
}

package:

bool needGuiRecoloring(in InternalImage id)
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
        return true;
    default:
        return false;
    }
}
