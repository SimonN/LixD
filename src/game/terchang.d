module game.terchang;

import basics.nettypes;
import lix.enums;

struct TerrainChange {

    enum Type {
        build,
        platformLong,
        platformShort,
        cube,

        implode,
        explode,
        bashLeft,
        bashRight,
        bashNoRelicsLeft,
        bashNoRelicsRight,
        mineLeft,
        mineRight,
        dig
    }

    Update update;
    Type   type;
    Style  style; // for additions
    int x; // lix store the top-left corner of the terrain change here, ...
    int y; //    ...not the effective coordinate.
    int yl; // for digger swing, cuber slice

    @property bool isAddition() const { return type < Type.implode; }
    @property bool isDeletion() const { return ! isAddition; }
}
