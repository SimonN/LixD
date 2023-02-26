module file.nextlev.tests;

version(unittest) {
    import std.algorithm;
    import std.format;
    import optional;

    import file.filename;
    import file.nextlev;

    struct Fixture {
        Filename rootDir;
        LevelCache cache;
        Rhino root;

        static Fixture create()
        {
            file.filename.vfsfile.initialize();
            auto ret = Fixture(new VfsFilename("./levels/single/lemforum/"));
            ret.cache = new TreeLevelCache(ret.rootDir);
            ret.root = ret.cache.rhinoOf(ret.rootDir).front;
            return ret;
        }
    }
}

unittest {
    auto fx = Fixture.create();
    auto myLevel = "./levels/single/lemforum/Cunning/miceinthepipe.txt";
    assert (myLevel.canFind(fx.root.filename.rootless),
        "The test makes no sense when we can't find myLevel under the root");
    auto sub = fx.cache.rhinoOf(new VfsFilename(myLevel));
    assert (! sub.empty, format!"%s is is 404!"(myLevel));
    assert (myLevel.canFind(sub.front.filename.rootless),
        format!"%s wasn't fetched; instead, we got %s"(
        myLevel, sub.front.filename.rootless));
}

unittest {
    auto fx = Fixture.create();
    import std.format;
    assert (fx.root.weight == 240, format!
        "root.weight is %d, but lemforum has 240 levels"(
        fx.root.weight));

    int levelsIterated = 0;
    for (auto next = fx.root.nextLevel();
        ! next.empty;
        next = next.oc.nextLevel()
    ) {
        ++levelsIterated;
        assert (next.front.filename.file.length > 0,
            "nextLevel() should never be dir, it should always be a file");
    }
    /+
     + DTODOUNITTEST:
     + This test started to fail with/before DMD v2.102.1,
     + but after DMD v2.100. It would be better if the test still passed.
     +
    assert (levelsIterated == fx.root.weight,
        "iteration should find exactly the leaves that contribute to weight");
    +/
}
