module tile.visitor;

public import tile.abstile;
public import tile.gadtile;
public import tile.group;
public import tile.terrain;

interface TileVisitor {
    void visit(const(TerrainTile));
    void visit(const(GadgetTile));
    void visit(const(TileGroup));
}
