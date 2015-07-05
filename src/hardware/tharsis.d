module hardware.tharsis;

Profiler profiler;

version (tharsisprofiling)
{
    import std.algorithm;
    import std.range;
    import std.stdio;

    import basics.globals;

    public import tharsis.prof;

    pragma (msg, "Compiling Lix with profiling information...");
    pragma (msg, "(To optimize for speed, "
                 "use `dub build -b release-nobounds')");

    void initialize()
    {
        // Get 2 MB more than the minimum (maxEventBytes)
        ubyte[] storage = new ubyte[Profiler.maxEventBytes + 1024 * 1024 * 2];
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

        foreach (key, st; stats) {
            assert (st.count > 0);
            outfile.writefln(
                "%-20.20s min: %8d, max: %8d, avg: %8d, cnt: %6d",
                key, st.min_dur, st.max_dur, st.tot_dur / st.count, st.count);
        }
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
