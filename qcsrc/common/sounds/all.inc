// Global list of sounds
// TODO: remove uses of _sound

#include "../teams.qh"
string W_Sound(string w_snd);
string Item_Sound(string it_snd);

SOUND(ARC_FIRE, W_Sound("arc_fire"));
SOUND(ARC_LOOP, W_Sound("arc_loop"));
SOUND(ARC_LOOP_OVERHEAT, W_Sound("arc_loop_overheat"));
SOUND(ARC_STOP, W_Sound("arc_stop"));
SOUND(CAMPINGRIFLE_FIRE2, W_Sound("campingrifle_fire2"));
SOUND(CAMPINGRIFLE_FIRE, W_Sound("campingrifle_fire"));
SOUND(CRYLINK_FIRE2, W_Sound("crylink_fire2"));
SOUND(CRYLINK_FIRE, W_Sound("crylink_fire"));
SOUND(CRYLINK_IMPACT2, W_Sound("crylink_impact2"));
SOUND(CRYLINK_IMPACT, W_Sound("crylink_impact"));
SOUND(CRYLINK_LINKJOIN, W_Sound("crylink_linkjoin"));
SOUND(DRYFIRE, W_Sound("dryfire"));
SOUND(ELECTRO_BOUNCE, W_Sound("electro_bounce"));
SOUND(ELECTRO_FIRE2, W_Sound("electro_fire2"));
SOUND(ELECTRO_FIRE, W_Sound("electro_fire"));
SOUND(ELECTRO_FLY, W_Sound("electro_fly"));
SOUND(ELECTRO_IMPACT, W_Sound("electro_impact"));
SOUND(ELECTRO_IMPACT_COMBO, W_Sound("electro_impact_combo"));
SOUND(FIREBALL_FIRE2, W_Sound("fireball_fire2"));
SOUND(FIREBALL_FIRE, W_Sound("fireball_fire"));
SOUND(FIREBALL_FLY2, W_Sound("fireball_fly2"));
SOUND(FIREBALL_FLY, W_Sound("fireball_fly"));
SOUND(FIREBALL_IMPACT2, W_Sound("fireball_impact2"));
SOUND(FIREBALL_PREFIRE2, W_Sound("fireball_prefire2"));
SOUND(FLAC_FIRE, W_Sound("flac_fire"));
SOUND(GRENADE_BOUNCE1, W_Sound("grenade_bounce1"));
SOUND(GRENADE_BOUNCE2, W_Sound("grenade_bounce2"));
SOUND(GRENADE_BOUNCE3, W_Sound("grenade_bounce3"));
SOUND(GRENADE_BOUNCE4, W_Sound("grenade_bounce4"));
SOUND(GRENADE_BOUNCE5, W_Sound("grenade_bounce5"));
SOUND(GRENADE_BOUNCE6, W_Sound("grenade_bounce6"));
Sound SND_GRENADE_BOUNCE_RANDOM() {
    return Sounds_from(SND_GRENADE_BOUNCE1.m_id + rint(random() * 5));
}
SOUND(GRENADE_FIRE, W_Sound("grenade_fire"));
SOUND(GRENADE_IMPACT, W_Sound("grenade_impact"));
SOUND(GRENADE_STICK, W_Sound("grenade_stick"));
SOUND(HAGAR_BEEP, W_Sound("hagar_beep"));
SOUND(HAGAR_FIRE, W_Sound("hagar_fire"));
SOUND(HAGAR_LOAD, W_Sound("hagar_load"));
SOUND(HAGEXP1, W_Sound("hagexp1"));
SOUND(HAGEXP2, W_Sound("hagexp2"));
SOUND(HAGEXP3, W_Sound("hagexp3"));
Sound SND_HAGEXP_RANDOM() {
    return Sounds_from(SND_HAGEXP1.m_id + rint(random() * 2));
}

SOUND(HOOKBOMB_FIRE, W_Sound("hookbomb_fire"));
SOUND(HOOKBOMB_IMPACT, W_Sound("hookbomb_impact"));
SOUND(HOOK_FIRE, W_Sound("hook_fire"));
SOUND(HOOK_IMPACT, W_Sound("hook_impact"));
SOUND(LASERGUN_FIRE, W_Sound("lasergun_fire"));
SOUND(LASERIMPACT, W_Sound("laserimpact"));
SOUND(LGBEAM_FLY, W_Sound("lgbeam_fly"));
SOUND(MINE_DET, W_Sound("mine_det"));
SOUND(MINE_EXP, W_Sound("mine_exp"));
SOUND(MINE_FIRE, W_Sound("mine_fire"));
SOUND(MINE_STICK, W_Sound("mine_stick"));
SOUND(MINE_TRIGGER, W_Sound("mine_trigger"));
SOUND(MINSTANEXFIRE, W_Sound("minstanexfire"));
SOUND(NEXCHARGE, W_Sound("nexcharge"));
SOUND(NEXFIRE, W_Sound("nexfire"));
SOUND(NEXIMPACT, W_Sound("neximpact"));
SOUND(NEXWHOOSH1, W_Sound("nexwhoosh1"));
SOUND(NEXWHOOSH2, W_Sound("nexwhoosh2"));
SOUND(NEXWHOOSH3, W_Sound("nexwhoosh3"));
Sound SND_NEXWHOOSH_RANDOM() {
    return Sounds_from(SND_NEXWHOOSH1.m_id + rint(random() * 2));
}
SOUND(RELOAD, W_Sound("reload")); // until weapons have individual reload sounds, precache the reload sound here

SOUND(RIC1, W_Sound("ric1"));
SOUND(RIC2, W_Sound("ric2"));
SOUND(RIC3, W_Sound("ric3"));
Sound SND_RIC_RANDOM() {
    return Sounds_from(SND_RIC1.m_id + rint(random() * 2));
}

SOUND(ROCKET_DET, W_Sound("rocket_det"));
SOUND(ROCKET_FIRE, W_Sound("rocket_fire"));
SOUND(ROCKET_FLY, W_Sound("rocket_fly"));
SOUND(ROCKET_IMPACT, W_Sound("rocket_impact"));
SOUND(ROCKET_MODE, W_Sound("rocket_mode"));
SOUND(SEEKEREXP1, W_Sound("seekerexp1"));
SOUND(SEEKEREXP2, W_Sound("seekerexp2"));
SOUND(SEEKEREXP3, W_Sound("seekerexp3"));
SOUND(SEEKER_FIRE, W_Sound("seeker_fire"));
SOUND(SHOTGUN_FIRE, W_Sound("shotgun_fire"));
SOUND(SHOTGUN_MELEE, W_Sound("shotgun_melee"));
SOUND(STRENGTH_FIRE, W_Sound("strength_fire"));
SOUND(TAGEXP1, W_Sound("tagexp1"));
SOUND(TAGEXP2, W_Sound("tagexp2"));
SOUND(TAGEXP3, W_Sound("tagexp3"));
SOUND(TAG_FIRE, W_Sound("tag_fire"));
SOUND(TAG_IMPACT, W_Sound("tag_impact"));
SOUND(TAG_ROCKET_FLY, W_Sound("tag_rocket_fly"));
SOUND(UNAVAILABLE, W_Sound("unavailable"));
SOUND(UZI_FIRE, W_Sound("uzi_fire"));
SOUND(WEAPONPICKUP, W_Sound("weaponpickup"));
SOUND(WEAPON_SWITCH, W_Sound("weapon_switch"));

SOUND(PORTO_BOUNCE, "porto/bounce");
SOUND(PORTO_CREATE, "porto/create");
SOUND(PORTO_EXPIRE, "porto/expire");
SOUND(PORTO_EXPLODE, "porto/explode");
SOUND(PORTO_FIRE, "porto/fire");
SOUND(PORTO_UNSUPPORTED, "porto/unsupported");

SOUND(POWEROFF, Item_Sound("poweroff"));
SOUND(POWERUP, Item_Sound("powerup"));
SOUND(SHIELD_RESPAWN, Item_Sound("shield_respawn"));
SOUND(STRENGTH_RESPAWN, Item_Sound("strength_respawn"));

SOUND(ARMOR25, Item_Sound("armor25"));
SOUND(ARMORIMPACT, "misc/armorimpact");
SOUND(BODYIMPACT1, "misc/bodyimpact1");
SOUND(BODYIMPACT2, "misc/bodyimpact2");

SOUND(ITEMPICKUP, Item_Sound("itempickup"));
SOUND(ITEMRESPAWNCOUNTDOWN, Item_Sound("itemrespawncountdown"));
SOUND(ITEMRESPAWN, Item_Sound("itemrespawn"));
SOUND(MEGAHEALTH, Item_Sound("megahealth"));

SOUND(LAVA, "player/lava");
SOUND(SLIME, "player/slime");

SOUND(GIB, "misc/gib");
SOUND(GIB_SPLAT01, "misc/gib_splat01");
SOUND(GIB_SPLAT02, "misc/gib_splat02");
SOUND(GIB_SPLAT03, "misc/gib_splat03");
SOUND(GIB_SPLAT04, "misc/gib_splat04");
Sound SND_GIB_SPLAT_RANDOM() {
    return Sounds_from(SND_GIB_SPLAT01.m_id + floor(prandom() * 4));
}

SOUND(HIT, "misc/hit");
SOUND(TYPEHIT, "misc/typehit");
SOUND(KILL, "misc/kill");

SOUND(SPAWN, "misc/spawn");

SOUND(TALK, "misc/talk");

SOUND(TELEPORT, "misc/teleport");

SOUND(INVSHOT, "misc/invshot");

SOUND(JETPACK_FLY, "misc/jetpack_fly");
