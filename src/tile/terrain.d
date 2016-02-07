module tile.terrain;

import graphic.cutbit;
import tile.phymap;
import tile.platonic;

class TerrainTile : Platonic {
private:
    Phymap _phymap;
    bool   _steel;

public:
    @property bool steel() const { return _steel; }

    static typeof(this) takeOverCutbit(Cutbit aCb, bool aSteel = false)
    {
        return new typeof(this)(aCb, aSteel);
    }

protected:
    this(Cutbit aCb, bool aSteel = false)
    {
        super(aCb);
        _steel = aSteel;
        makePhymap();
    }

private:
    void makePhymap()
    {
        assert (! _phymap);
        assert (cb);
    }
}
