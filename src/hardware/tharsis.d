module hardware.tharsis;

/* Frame-based profiling.
 *
 * To use this in the source, create a RAII struct that measures how long
 * the current scope takes to complete:
 *
 *  auto myZone = Zone(profiler, "zone-name");
 *
 * myZone can be anything that doens't clash with an existing identifier.
 * "zone-name" is the zone's name written into data/profile.txt. This should
 * be as expressive as possible.
 */

import net.versioning;

version (tharsisprofiling) {
    import std.algorithm;
    import std.range;
    import std.stdio;

    import basics.globals;
    import file.date;

    public import tharsis.prof;

    pragma (msg, "Compiling Lix " ~ gameVersion().toString() ~
                 " with profiling information...");
    pragma (msg, "(To optimize for speed, "
               ~ "use `dub build -b release-nobounds')");

    Profiler profiler;

    void initialize()
    {
        // Get 20 MB more than the minimum (maxEventBytes)
        ubyte[] storage = new ubyte[Profiler.maxEventBytes + 1024 * 1024 * 20];
        profiler        = new Profiler(storage);
    }

    void deinitialize()
    {
        // Accumulate data into this struct.
        struct Stats
        {
            ulong min_dur, max_dur, tot_dur, count;

            this(ulong n)
            {
                min_dur = max_dur = tot_dur = n;
                count = 1;
            }
        }

        auto          zones = profiler.profileData.zoneRange;
        Stats[string] stats;

        foreach (z; zones) {
            Stats* stat = (z.info in stats);
            if (stat !is null) {
                stat.min_dur = min(stat.min_dur, z.duration);
                stat.max_dur = max(stat.max_dur, z.duration);
                stat.tot_dur += z.duration;
                ++stat.count;
            }
            else {
                stats[z.info] = Stats(z.duration);
            }
        }

        File outfile = fileTharsisProf.openForWriting();

        outfile.writeln("Lix version ", gameVersion(),
            " profiling results from ", Date.now().toString(), ".");
        outfile.writeln(
            "Unit of time: 1 us == 1 microsecond == 1/1000 of a millisecond.");
        outfile.writeln(
            "At ", ticksPerSecond, " frames per second, 1 frame takes ",
            1000 * 1000 / ticksPerSecond, " us.");

        void print_column_desc()
        {
            outfile.writeln(' '.repeat(36),
                "   avg/us   min/us   max/us   amount");
        }

        // for output, sort the keys
        auto keys = stats.keys.sort();
        int every_tenth_row = 0;

        foreach (key; keys) {
            auto st = stats[key];
            assert (st.count > 0);
            if (every_tenth_row++ % 10 == 0)
                print_column_desc();
            outfile.writefln(
                "%-36.36s %8d %8d %8d %8d",
                key, st.tot_dur / st.count / 10,
                     st.min_dur / 10, st.max_dur / 10, st.count);
        }
        print_column_desc();

        outfile.close();
        destroy(profiler);
    }
}
else {
    pragma (msg, "Compiling Lix "
        ~ gameVersion().toString() ~ " release build...");
    void initialize() { }
    void deinitialize() { }
}
