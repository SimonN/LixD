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
public import file.filename;

interface PreviewLevelOrReplay {
    void previewNone();

    void preview(in Level l)
    in { assert (l !is null); };

    void preview(in Replay r, in Filename fnOfThatReplay, in Level l)
    in {
        assert (r !is null);
        assert (fnOfThatReplay !is null);
        assert (l !is null);
    };
}
