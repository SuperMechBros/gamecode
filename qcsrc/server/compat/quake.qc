#include "quake.qh"

#include <common/weapons/_all.qh>

spawnfunc(weapon_electro);
spawnfunc(weapon_hagar);
spawnfunc(weapon_machinegun);
spawnfunc(item_bullets);
spawnfunc(item_armor_mega);
spawnfunc(item_health_mega);
spawnfunc(item_health_medium);

//***********************
//QUAKE 1 ENTITIES - So people can play quake1 maps with the xonotic weapons
//***********************
spawnfunc(weapon_nailgun) {spawnfunc_weapon_electro(this);}
spawnfunc(weapon_supernailgun) {spawnfunc_weapon_hagar(this);}
spawnfunc(weapon_supershotgun) {spawnfunc_weapon_machinegun(this);}

spawnfunc(item_spikes) {spawnfunc_item_bullets(this);}
//spawnfunc(item_armor1) {spawnfunc_item_armor_medium(this);}  // FIXME: in Quake this is green armor, in Xonotic maps it is an armor shard
spawnfunc(item_armor2) {spawnfunc_item_armor_mega(this);}
spawnfunc(item_armorInv) {spawnfunc_item_armor_mega(this);} // TODO: make sure we actually want this
spawnfunc(item_health) {if (this.spawnflags & 2) spawnfunc_item_health_mega(this);else spawnfunc_item_health_medium(this);}

//spawnfunc_item_spikes
//spawnfunc_item_health



