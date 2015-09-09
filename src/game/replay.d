module game.replay;

import basics.nettypes;
import file.date;
import file.filename;
import level.level;
import lix.enums;
import game.state;

class Replay {

public:

    enum Action {
        NOTHING,
        SPAWNINT,
        SKILL_LEGACY_SUPPORT, // only while reading files, never used after
        ASSIGN,
        ASSIGN_LEFT,
        ASSIGN_RIGHT,
        NUKE
    };

    struct Player {
        PlNr   number;
        Style  style;
        string name;
    };

private:

    bool     file_not_found;

    int      version_min;
    Date     built_required;
    Filename level_filename;

    Player[] players;
    Permu    permu;

    ReplayData[] data;
    int          max_updates;
    Ac           first_skill_bc; // bc = backwards compatibility skill,
                                 // what skill to assign if no SKILL
                                 // command has occured yet
    PlNr         player_local;

}
