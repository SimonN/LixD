module game.replay;

import std.algorithm; // isSorted
import std.c.string : memmove;
import std.stdio;
import std.string;

import basics.help; // array.len of type int
import basics.globals;
import basics.globconf;
import basics.help;
import basics.nettypes;
import basics.versioning;
import file.date;
import file.filename;
import file.io;
import file.log;
import level.level;
import level.metadata;
import lix.enums;

class Replay {

    static struct Player {
        PlNr   number;
        Style  style;
        string name;
    }

private:

    private bool _file_not_found;

    deprecated("use this.game_version instead") int version_min;

    Version  _game_version;
    Date     _built_required;
    Filename _level_filename;

    PlNr     _player_local;
    Player[] _players;
    Permu    _permu;

    ReplayData[] _data;
    Ac           _first_skill_bc; // bc = backwards compat skill,
                                  // what skill to assign if no SKILL
                                  // command has occured yet

public:

    @property bool    file_not_found() { return _file_not_found; }
    @property Version game_version()   { return _game_version;   }

    @property built_required()       { return _built_required;     }
    @property built_required(Date d) { return _built_required = d; }

    @property level_filename()            { return _level_filename;      }
    @property level_filename(Filename fn) { return _level_filename = fn; }

    @property PlNr player_local()       { return _player_local;     }
    @property PlNr player_local(PlNr n) { return _player_local = n; }

    @property const(Player)[] players()        { return _players;      }
    @property const(Permu)    permu()          { return _permu;        }
    @property       Permu     permu(Permu p)   { _permu = p; return p; }

    @property int max_updates()
    {
        return (_data.length > 0) ? _data[$-1].update : 0;
    }

    @property string player_local_name()
    {
        foreach (pl; _players)
            if (pl.number == _player_local)
                return pl.name;
        return null;
    }

    @property string canonical_save_filename()
    {
        string base = level_filename.file_no_ext_no_pre;
        string plna = this.player_local_name;
        return plna.length ? base ~ "-" ~ plna : base;
    }



this(Filename fn = null)
{
    _game_version   = get_version();
    _built_required = new Date("0");
    _level_filename = fn ? fn : new Filename("");
    _first_skill_bc = Ac.NOTHING;

    if (fn)
        this.load_from_file(fn);
}



void touch()
{
    _game_version   = get_version();
    _file_not_found = false;
}



void
add_player(PlNr nr, Style s, string name)
{
    _players ~= Player(nr, s, name);
}



private inout(ReplayData)[]
data_slice_before_update(in int upd) inout
{
    // The binary search algo works also for the cases we're checking in this
    // if. But we add mostly to the end of the data, so check here for speed.
    if (_data.length == 0 || _data[$-1].update < upd)
        return _data;

    int bot = 0;         // first too-large is at a higher position than this
    int top = _data.len; // first too-large is here _or_ at a lower position

    while (top != bot) {
        int bisect = (top + bot) / 2;
        assert (bisect >= 0   && bisect < _data.len);
        assert (bisect >= bot && bisect < top);
        if (_data[bisect].update < upd)
            bot = bisect + 1;
        if (_data[bisect].update >= upd)
            top = bisect;
    }
    return _data[0 .. bot];
}



bool
equal_before(in typeof(this) rhs, in int upd) const
{
    // We don't check whether the metadata/general data is the same.
    // We assume the gameplay class only uses for replays of the same level
    // with the same players.
    return this.data_slice_before_update(upd)
        ==  rhs.data_slice_before_update(upd);
}



// this function is necessary to keep old replays working in new versions
// that skip the first 30 or so updates, to get into the action faster.
// The first spawn is still at update 60.
void
increase_early_data_to_update(in int upd)
{
    foreach (d; _data) {
        if (d.update < upd)
            d.update = upd;
        else break;
    }
    // This doesn't call touch().
}



void
erase_data_after_update(in int upd)
{
    assert (upd >= 0);
    _data = _data[0 .. data_slice_before_update(upd + 1).length];
    touch();
}



const(ReplayData)[]
get_data_for_update(in int upd) const
{
    auto slice = data_slice_before_update(upd + 1);
    int cut = slice.len - 1;
    while (cut >= 0 && slice[cut].update == upd)
        --cut;
    return _data[cut + 1 .. slice.length];
}



bool
get_on_update_lix_clicked(in int upd, in int lix_id, in Ac ac) const
{
    auto vec = get_data_for_update(upd);
    foreach (const ref d; vec)
        if (d.is_some_assignment && d.to_which_lix == lix_id && d.skill == ac)
            return true;
    return false;
}



void
add(in ReplayData d)
{
    touch();
    add_without_touching(d);
}



private void
add_without_touching(in ReplayData d)
{
    // Add after the latest record that's smaller than or equal to d
    // Equivalently, add before the earliest record that's greater than d.
    // data_slice_before_update doesn't do exactly that, it ignores players.
    // DTODO: I believe the C++ version had a bug in the choice of
    // comparison. I have fixed that here. Test to see if it's good now.
    auto slice = data_slice_before_update(d.update + 1);
    while (slice.length && slice[$-1] > d)
        slice = slice[0 .. $-1];

    if (slice.length < _data.length) {
        _data.length += 1;
        memmove(&_data[slice.length + 1], &_data[slice.length],
                ReplayData.sizeof * (_data.length - slice.length - 1));
        _data[slice.length] = d;
    }
    else {
        _data ~= d;
    }

    assert (_data.isSorted);
}



// ############################################################################
// ################################################################# Replay I/O
// ############################################################################



public nothrow void
save_to_file(in Filename fn, in Level lev)
{
    try {
        std.stdio.File file = File(fn.rootful, "w");
        scope (exit)
            file.close();
        save_to_file(file, lev);
    }
    catch (Exception e) {
        Log.log(e.msg);
    }
}



private void
save_to_file(std.stdio.File file, in Level lev)
{
    auto lmd = new LevelMetaData(_level_filename);
    if (lmd.file_exists)
        _built_required = lmd.built;

    // Write the path to the level, but omit the leading (dir-levels)/
    // DTODOFHS: we chop off a constant length, we shouldn't do that
    // anymore once we don't know where it's saved
    file.writeln(IoLine.Dollar(basics.globals.replay_level_filename,
        _level_filename.rootless[dir_levels.rootless.length .. $]));
    file.writeln(IoLine.Dollar(replay_built_required,
        _built_required.toString));
    file.writeln(IoLine.Dollar(replay_version_min, _game_version.toString));

    if (_players.length)
        file.writeln();
    foreach (pl; _players)
        file.writeln(IoLine.Plus(pl.number == _player_local
             ? basics.globals.replay_player : basics.globals.replay_friend,
             pl.number, style_to_string(pl.style), pl.name));
    if (_players.length > 1)
        file.writeln(IoLine.Dollar(replay_permu, permu.toString));

    if (_data.length)
        file.writeln();
    foreach (d; _data) {
        string word
            = d.action == ReplayData.SPAWNINT     ? replay_spawnint
            : d.action == ReplayData.NUKE         ? replay_nuke
            : d.action == ReplayData.ASSIGN       ? replay_assign_any
            : d.action == ReplayData.ASSIGN_LEFT  ? replay_assign_left
            : d.action == ReplayData.ASSIGN_RIGHT ? replay_assign_right : "";
        if (word == "")
            throw new Exception("bad replay data written to file");
        if (d.is_some_assignment) {
            word ~= "=";
            word ~= ac_to_string(cast (Ac) d.skill);
        }
        file.writeln(IoLine.Bang(d.update, d.player, word, d.to_which_lix));
    }

    bool ok_to_save(in Level lev)
    {
        return lev !is null && lev.nonempty;
    }

    const(Level) lev_to_save = ok_to_save(lev) ? lev
                             : new Level(_level_filename);
    if (ok_to_save(lev_to_save)) {
        file.writeln();
        level.level.save_to_file(lev_to_save, file);
    }
}



public void
save_as_auto_replay(in Level lev)
{
    const(bool) multi = (_players.length > 1);

    if ( (! multi && ! basics.globconf.replay_auto_single)
        || (multi && ! basics.globconf.replay_auto_multi)
    ) {
        return;
    }

    string outfile = multi ? basics.globals.file_replay_auto_multi.rootful
                           : basics.globals.file_replay_auto_single.rootful;
    int* nr = multi ? &basics.globconf.replay_auto_next_m
                    : &basics.globconf.replay_auto_next_s;

    if (*nr >= basics.globconf.replay_auto_max)
        *nr = 0;
    outfile ~= format("%3.3d%s", *nr, basics.globals.ext_replay);
    *nr = positive_mod(*nr + 1, basics.globconf.replay_auto_max);

    save_to_file(new Filename(outfile), lev);
}



private void
load_from_file(Filename fn)
{
    IoLine[] lines;
    try {
        lines = fill_vector_from_file(fn);
    }
    catch (Exception e) {
        Log.log(e.msg);
        _file_not_found = true;
        return;
    }

    foreach (i; lines) switch (i.type) {
    case '$':
        if (i.text1 == replay_built_required) {
            _built_required = new Date(i.text2);
        }
        else if (i.text1 == replay_permu) {
            _permu = new Permu(i.text2);
        }
        else if (i.text1 == replay_version_min) {
            _game_version = Version(i.text2);
        }
        else if (i.text1 == replay_level_filename) {
            _level_filename = new Filename(dir_levels.dir_rootless ~ i.text2);
        }
        break;

    case '+':
        if (   i.text1 == replay_player
            || i.text1 == replay_friend
        ) {
            add_player(i.nr1 & 0xFF, string_to_style(i.text2), i.text3);
            if (i.text1 == replay_player)
                _player_local = i.nr1 & 0xFF;
        }
        break;

    case '!': {
        // replays contain ASSIGN=BASHER or ASSIGN_RIGHT=BUILDER.
        // cut these strings into a left and right part, none contains '='.
        string part1 = "";
        string part2 = i.text1;
        while (part2.length && part2[0] != '=')
            part2 = part2[1 .. $];

        part1 = i.text1[0 .. i.text1.length - part2.length];
        if (part2.length > 0)
            // remove '='
            part2 = part2[1 .. $];

        ReplayData d;
        d.update       = i.nr1;
        d.player       = i.nr2 & 0xFF;
        d.to_which_lix = i.nr3;
        d.action = part1 == replay_spawnint     ? ReplayData.SPAWNINT
                 : part1 == replay_assign_any   ? ReplayData.ASSIGN
                 : part1 == replay_assign_left  ? ReplayData.ASSIGN_LEFT
                 : part1 == replay_assign_right ? ReplayData.ASSIGN_RIGHT
                 : part1 == replay_nuke         ? ReplayData.NUKE
                 : ReplayData.NOTHING;
        if (part2.length > 0)
            d.skill = string_to_ac(part2) & 0xFF;
        if (d.action != ReplayData.NOTHING)
            add_without_touching(d);
        break; }

    default:
        break;
    }
    // end switch and foreach
}

}
// end class Replay



unittest
{
    Filename fn0 = new Filename("./replays/unittest-input.txt");
    Filename fn1 = new Filename("./replays/unittest-output-1.txt");
    Filename fn2 = new Filename("./replays/unittest-output-2.txt");
    Filename fnl = new Filename("./replays/unittest-output-level.txt");

    Level lev = new Level(fn0);
    lev.save_to_file(fnl);

    Replay r = new Replay(fn0);
    const int data_len = r._data.len;

    r.save_to_file(fn1, lev);
    r = new Replay(fn1);
    assert (data_len == r._data.len);

    r.save_to_file(fn2, lev);
}
