module gui.picker.search;

/*
 * LevelSearch
 *
 * The window in which you earch for levels. You can type a query string,
 * and LevelSearch will offer you a list of levels such that the query
 * matches the level's filename or title.
 *
 * This doesn't start the level immediately, but merely returns it to the
 * main browser, which should then navigate to it.
 *
 * Convention: Callers give us focus. We remove our own focus.
 *
 * You can't ask us whether we're done. Rather, register a callback that
 * we'll call with null on cancel, and with the filename on selected result.
 */

import std.algorithm;
import std.range;
import std.string;

import basics.alleg5;
import basics.globals;
import basics.user;
import file.language;
import file.filename;
import file.log;
import gui;
import gui.picker.scrolist;
import level.metadata;
import hardware.mouse : mouseClickRight;
import hardware.keyboard;
import hardware.keyset;

class LevelSearch : Window {
private:
    Texttype _query;
    TextButton _back;

    void delegate(Filename) _onDone; // called with null on cancel
    SearchResultList _results;

    // _database contains what we search through. But it's expensive to build
    // because we open each file as level metadata and look at the level title.
    // Querying the OS for the tree (a mere list of unopened filenames) is
    // fast. Therefore, we build _database over many calc() calls little by
    // little, and _unprocessed to store the unsearchable leftover work.
    CachedFilename[] _database; // readily searchable
    MutFilename[] _unprocessed; // not searched

    // search already-built database only after this has gotten different
    // from _query.text. While the database is building, search every time.
    // To search every time while building the db, this gets set to ""
    // artificially.
    string _lastQuery;

public:
    this()
    {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            Lang.winSearchTitle.transl);
        addChild(new Label(new Geom(20, 40, 400, 20, From.BOTTOM_LEFT),
            // DTODOLANG
            "Search for filenames or level titles:"));
        _results = new SearchResultList(new Geom(20, 40, xlg - 40, ylg - 120));

        _query = new Texttype(new Geom(20, 20, 400, 20, From.BOTTOM_LEFT));
        _query.hotkey = KeySet(keyMenuSearch, KeySet(ALLEGRO_KEY_ENTER));
        _query.on = true;
        _query.onEnter = () {
            matchesInDatabase.takeOne.each!((cachedFn) {
                setDoneWith(cachedFn.result);
            });
        };

        _back = new TextButton(new Geom(20, 20, 100, 40, From.BOTTOM_RIGHT),
            Lang.commonBack.transl);
        _back.hotkey = keyMenuExit;

        addChildren(_results, _query, _back);
    }

    void onDone(typeof(_onDone) f) { _onDone = f; }

protected:
    override void calcSelf()
    {
        if (_back.execute || mouseClickRight)
            setDoneWith(null);
        Filename clicked = _results.executedFilenameOrNull;
        if (clicked)
            setDoneWith(clicked);
    }

    override void workSelf()
    {
        buildDatabase();
        search();
    }

private:
    void setDoneWith(Filename fn)
    {
        rmFocus(this);
        if (_onDone)
            _onDone(fn);
    }

    void search()
    {
        // See comment at the definition of _lastQuery for how we force
        // the search every time while the database is getting built.
        if (_lastQuery == _query.text.toLower)
            return;
        _lastQuery = _query.text.toLower;
        _results.recreateButtonsFor(matchesInDatabase.take(_results.pageLen));
    }

    auto matchesInDatabase() const pure
    {
        auto rangeOfWords = _lastQuery.strip.splitter();
        return _database.filter!(entry => entry.matches(rangeOfWords.save));
    }

    // Build the database little by little over many calls to this
    void buildDatabase()
    {
        if (_database.length > 0 && _unprocessed.empty)
            // Database is complete
            return;
        if (_unprocessed.empty) {
            assert (_database.empty, "let's not do this twice");
            _unprocessed = dirLevels.findTree();
        }

        // Work on the database for a small part of the time, but return
        // early enough to make the program feel responsive.
        immutable long beforeWork = timerTicks;
        while (! _unprocessed.empty && timerTicks == beforeWork) {
            try {
                auto cf = CachedFilename(_unprocessed[0]);
                _database ~= cf;
            }
            catch (Exception e) {
                // The metadata has already logged about bad UTF.
                logf("    -> Can't search for `%s'", _unprocessed[0].rootless);
            }
            _unprocessed = _unprocessed[1 .. $];
        }
        // Force the UI to search again the now-added-to database
        _lastQuery = "";
    }
}

// We can search either for filename or for title.
// This's constructor throws on bad UTF-8 in the metadata.
private struct CachedFilename {
private:
    string titleAllLower;
    string fnAllLower;
    string authorAllLower;

public:
    Filename result;
    string titleDisplay;

    // Constructor throws on bad UTF-8 in the metadata!
    this(in Filename fn)
    {
        result = fn;

        // We cut off the prefix that should be common to all found files
        fnAllLower = fn.rootlessNoExt.toLower;
        if (fnAllLower.startsWith(dirLevels.rootless))
            fnAllLower = fnAllLower[dirLevels.rootless.length .. $];

        auto metadata = new LevelMetaData(fn); // throws on bad UTF-8
        titleDisplay = metadata.name;
        titleAllLower = titleDisplay.toLower;
        authorAllLower = metadata.author.toLower;
    }

    bool matches(R)(R rangeOfWords) const pure
    {
        return ! rangeOfWords.save.empty
            && rangeOfWords.all!(word =>
                    fnAllLower.canFind(word)
                ||  titleAllLower.canFind(word)
                ||  authorAllLower.canFind(word)
            );
    }
}

// Will be created by the SearchResultList.
private class SearchResultButton : TextButton {
public:
    Filename fn;

    this(Geom g, in Filename afn, string title)
    in { assert (afn); }
    body {
        super(g);
        fn = afn;
        enum space = 2 * gui.thickg; // space between text and edge of this

        Label makeLabel(in float ax, in float axl, in string aText)
        {
            auto ret = new Label(new Geom(ax, 0, axl, g.ylg));
            ret.text = aText;
            return ret;
        }
        auto mangledFn = fn.dirRootless.find('/').dropOne;
        addChildren(
            makeLabel(space,        g.xlg/3 + 40 - space, mangledFn),
            makeLabel(g.xlg/3 + 40, g.xlg/3 - 40, fn.fileNoExtNoPre),
            makeLabel(g.xlg*2/3,    g.xlg/3 - space, title));
    }
}

private class SearchResultList : ScrollableButtonList {
public:
    this(Geom g) { super(g); }

    void clear() { replaceAllButtons([]); }

    void recreateButtonsFor(R)(R range)
        if (is (ElementType!R : const(CachedFilename)))
    {
        Button toButton(Button b) pure @nogc { return b; } // only to help cast
        replaceAllButtons(range.map!(entry => new SearchResultButton(
                newGeomForButton, entry.result, entry.titleDisplay)
            ).map!toButton.array);
    }

    Filename executedFilenameOrNull() const
    {
        foreach (but; buttons.filter!(b => b.execute).takeOne)
            // I don't like this, but I don't want to template the list either
            return (cast (SearchResultButton) but).fn;
        return null;
    }
}
