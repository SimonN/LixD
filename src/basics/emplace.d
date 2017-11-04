module basics.emplace;

/*
 * My Lix Job code used std.conv.emplace, but broke in dmd 2.077.
 * Here's my custom emplace to work around the crash.
 */

void emplace(T)(void[] where)
    if (is (T == class))
{
    assert (__traits(classInstanceSize, T) <= where.length,
        "emplace: class doesn't fit into the given void array.");

    static immutable(T) prototype = new immutable T();
    where[] = (cast (void*) prototype)[0 .. where.length];
}
