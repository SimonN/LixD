module file.replay.tweakrq;

/*
 * Each ChangeRequest belongs to exactly one Ply entry.
 * That connection exists only outside this module game.repedit.changerq.
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
     * For this entry X, consider the set of entries Y such that
     * Y either is X or appears after (sorted later) than X.
     * Increase the phyu of all Y by one. Preserve order within the set of Ys.
     */
    moveTailBeginningWithThisLater,

    /*
     * For this entry X, consider the set of entries Y such that
     * Y's phyu >= X's phyu. (This is a different set than that of
     * moveTailBeginningWithThisPhyuLater!)
     *
     * Decrease the phyu of all the Ys in the set by one.
     * Preserve order within the set of Ys.
     * If some moved entries Y now share a phyu with entries Z that weren't
     * moved, the rule of inserting as last applies to the Y.
     */
    moveTailBeginningWithPhyuEarlier,

    /*
     * Erase the single entry X from the replay.
     */
    eraseThis,
}

struct ChangeRequest {
    Ply what;
    ChangeVerb how;
}
