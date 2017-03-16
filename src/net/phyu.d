module net.phyu;

/* Phyu is the physics update count, it measures how many times physics
 * have advanced from the zero gamestate. This is a wrapped int to be typesafe.
 */

struct Phyu {
    int u;
    alias u this;
    enum int len = Phyu.sizeof;
    static assert (len == int.sizeof);
}
