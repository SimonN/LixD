module game.terchang;

import lix.enums;

struct TerrainChange {

    enum Type {
        build,
        platform,
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

    int   update;
    Type  type;
    Style style; // for additions
    int x;
    int y;
    int yl; // for digger swing, cuber slice

    @property bool isAddition() const { return type < Type.implode; }
    @property bool isDeletion() const { return ! isAddition; }
}
