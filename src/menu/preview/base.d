module menu.preview.base;

/*
 * PreviewLevelOrReplay is the interface of Nameplate.
 * It's useful by itself: Preview (the small level image) implements it, too.
 * Classes that combine Nameplate and Preview will also implement this.
 *
 * A Nameplate is the structure of text labels below a Preview.
 * Usually, it describes a level, sometimes, it describes a replay. E.g.:
 *
 *      Any Way You Want
 *      By: Insane Steve
 *      Save: 1/10
 *
 * There should be some other class that combines a Nameplate with a Preview.
 *
 * There should be some other class that prints records. Or maybe a variant
 * of Nameplate?
 */

public import level.level;
public import file.replay;

interface PreviewLevelOrReplay {
    void previewNone();
    void preview(in Level);
    void preview(in Replay, in Level);
}
