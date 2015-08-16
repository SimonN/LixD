module hardware.tharsis;

/* Frame-based profiling.
 *
 * To use this in the source, create a RAII struct that measures how long
 * the current scope takes to complete:
 *
 *  auto my_zone = Zone(profiler, "zone-name");
 *
 * my_zone can be anything that doens't clash with an existing identifier.
 * "zone-name" is the zone's name written into data/profile.txt. This should
 * be as expressive as possible.
 */

Profiler profiler;

version (tharsisprofiling)
{
    import std.algorithm;
    import std.range;
    import std.stdio;

    import basics.globals;
    import basics.versioning;
    import file.date;

    public import tharsis.prof;

    pragma (msg, "Compiling Lix with profiling information...");
    pragma (msg, "(To optimize for speed, "
                 "use `dub build -b release-nobounds')");

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

        File outfile = File(file_tharsis_prof.rootful, "w");

        outfile.writeln("Lix version ", get_version_string,
            " profiling results from ", Date.now().toString(), ".");
        outfile.writeln(
            "Unit of time: 1 us == 1 microsecond == 1/1000 of a millisecond.");
        outfile.writeln(
            "At ", ticks_per_sec, " frames per second, 1 frame takes ",
            1000 * 1000 / ticks_per_sec, " us.");

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

else
{
    pragma (msg, "Compiling Lix release build without profiling...");

    // empty stubs which the compiler should optimize away fully
    class Profiler { }
    struct Zone { this(Profiler, string) { } }
    void initialize() { }
    void deinitialize() { }
}
