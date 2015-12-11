module lix.miner;

import lix;

class Miner : PerformedActivity {

    mixin(CloneByCopyFrom!"Miner");

    override UpdateOrder updateOrder() const { return UpdateOrder.remover; }

}
