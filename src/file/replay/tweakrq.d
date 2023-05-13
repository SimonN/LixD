module file.replay.tweakrq;

/*
 * Most ChangeRequests refer to exactly one Ply entry.
 *
 * ChangeVerb.eraseThisAndFutureOfSameLix refers to later plies, not the given.
 * The given ply is only examined for its phyu and lix ID, not for its skill.
 *
 * See also net.repdata.Ply.opCmp:
 * In the same frame, order by player number. From same player in same frame,
 * replay entries may be in any order, and that order must be preserved because
 * that order affects physics.
 *
 * The replay editor should not be as fine-grained; it's enough if the replay
 * editor cannot order (several same-frame same-player assignments).
 * But still, we must spec what a ChangeRequest should do: See enum.
 * UI and game and replay must all interpret a ChangeRequest identically.
 */

/*
 * The rule of skipping and inserting as last:
 *
 * If X's old phyu was shared with other entries Z, those entries Z
 * may be skipped. I.e., Y can move from X's place by several places
 * in the list of entries.
 *
 * If Y's new phyu will be shared with other entries Z, insert
 * the moved entry as the latest. I.e., either Y will be the final replay
 * entry, or there won't be any entries Z between Y and a higher-phyu
 * entry.
 */

public import net.repdata;

enum ChangeVerb {
    /*
     * Increase phyu of the single entry X; i.e., remove X and add Y such
     * that Y is identical to X, except that Y's phyu is one more.
     *
     * The rule of skipping and inserting as last applies.
     */
    moveThisLater,

    /*
     * Decrease phyu of the single entry X; i.e., remove X and add Y such
     * that Y is identical to X, except that Y's phyu is one less.
     *
     * The rule of skipping and inserting as last applies.
     */
    moveThisEarlier,

    /*
     * Don't erase the single entry X from the replay, but
     * erase all other entries Y that satisfy all of the following:
     *  -   X and Y refer to the same lix,
     *  -   and Y's phyu > X's phyu.
     */
    cutFutureOfOneLix,
}

struct ChangeRequest {
    Ply what;
    ChangeVerb how;
}

struct TweakResult {
    // If false, ignore the other fields.
    bool somethingChanged;
    /*
     * The first phyu in which (the replay before the tweak) differs from
     * (the replay after the tweak). See the general comment of
     * file.replay.tweakimp.tweakImpl() for how to use this.
     */
    Phyu firstDifference;
    /*
     * Viewers should look at this phyu to clearly see the result of the tweak.
     * This will be later than the first difference if the ply moved later.
     * Any later phyus than goodPhyuToView are also fine to view.
     */
    Phyu goodPhyuToView;
}
