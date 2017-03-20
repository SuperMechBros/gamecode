// Global list of models
// TODO: remove uses of _setmodel

string W_Model(string w_mdl);

MODEL(CTF_SHIELD,                       "models/ctf/shield.md3");
MODEL(CTF_CAPTURE,                      "models/ctf/shockwavetransring.md3");
MODEL(CTF_FLAG,                         "models/ctf/flags.md3");

MODEL(DOM_NEUTRAL,                      "models/domination/dom_unclaimed.md3");
MODEL(DOM_RED,                          "models/domination/dom_red.md3");
MODEL(DOM_BLUE,                         "models/domination/dom_blue.md3");
MODEL(DOM_YELLOW,                       "models/domination/dom_yellow.md3");
MODEL(DOM_PINK,                         "models/domination/dom_pink.md3");

MODEL(ICE,                              "models/ice/ice.md3");

MODEL(KH_KEY,                           "models/keyhunt/key.md3");
#ifdef KH_PLAYER_USE_CARRIEDMODEL
MODEL(KH_KEY_CARRIED,                   "models/keyhunt/key-carried.md3");
#endif

MODEL(OK_HMG,                           W_Model("g_ok_hmg.md3"));

MODEL(OK_RPC,                           W_Model("g_ok_rl.md3"));

MODEL(OK_MG_VIEW,                       W_Model("h_ok_mg.iqm"));
MODEL(OK_MG_WORLD,                      W_Model("v_ok_mg.md3"));
MODEL(OK_MG_ITEM,                       W_Model("g_ok_mg.md3"));

MODEL(OK_SHOTGUN_VIEW,                  W_Model("h_ok_shotgun.iqm"));
MODEL(OK_SHOTGUN_WORLD,                 W_Model("v_ok_shotgun.md3"));
MODEL(OK_SHOTGUN_ITEM,                  W_Model("g_ok_shotgun.md3"));

MODEL(OK_SNIPER_VIEW,                   W_Model("h_ok_sniper.iqm"));
MODEL(OK_SNIPER_WORLD,                  W_Model("v_ok_sniper.md3"));
MODEL(OK_SNIPER_ITEM,                   W_Model("g_ok_sniper.md3"));

MODEL(ONS_CP,                           "models/onslaught/controlpoint_icon.md3");
MODEL(ONS_CP_SHIELD,                    "models/onslaught/controlpoint_shield.md3");
MODEL(ONS_CP_PAD1,                      "models/onslaught/controlpoint_pad.md3");
MODEL(ONS_CP_PAD2,                      "models/onslaught/controlpoint_pad2.md3");
MODEL(ONS_CP1,                          "models/onslaught/controlpoint_icon_dmg1.md3");
MODEL(ONS_CP1_GIB,                      "models/onslaught/controlpoint_icon_gib1.md3");
MODEL(ONS_CP2,                          "models/onslaught/controlpoint_icon_dmg2.md3");
MODEL(ONS_CP2_GIB,                      "models/onslaught/controlpoint_icon_gib2.md3");
MODEL(ONS_CP3,                          "models/onslaught/controlpoint_icon_dmg3.md3");
MODEL(ONS_CP3_GIB,                      "models/onslaught/controlpoint_icon_gib4.md3");
MODEL(ONS_RAY,                          "models/onslaught/ons_ray.md3");
MODEL(ONS_GEN,                          "models/onslaught/generator.md3");
MODEL(ONS_GEN_SHIELD,                   "models/onslaught/generator_shield.md3");
MODEL(ONS_GEN_GIB1,                     "models/onslaught/gen_gib1.md3");
MODEL(ONS_GEN_GIB2,                     "models/onslaught/gen_gib2.md3");
MODEL(ONS_GEN_GIB3,                     "models/onslaught/gen_gib3.md3");
MODEL(ONS_GEN1,                         "models/onslaught/generator_dmg1.md3");
MODEL(ONS_GEN2,                         "models/onslaught/generator_dmg2.md3");
MODEL(ONS_GEN3,                         "models/onslaught/generator_dmg3.md3");
MODEL(ONS_GEN4,                         "models/onslaught/generator_dmg4.md3");
MODEL(ONS_GEN5,                         "models/onslaught/generator_dmg5.md3");
MODEL(ONS_GEN6,                         "models/onslaught/generator_dmg6.md3");
MODEL(ONS_GEN7,                         "models/onslaught/generator_dmg7.md3");
MODEL(ONS_GEN8,                         "models/onslaught/generator_dmg8.md3");
MODEL(ONS_GEN9,                         "models/onslaught/generator_dmg9.md3");
MODEL(ONS_GEN_DEAD,                     "models/onslaught/generator_dead.md3");

MODEL(PROJECTILE_ELECTRO,               "models/ebomb.mdl");
MODEL(PROJECTILE_ELECTRO_BEAM,          "models/elaser.mdl");

MODEL(PROJECTILE_ROCKET,                "models/rocket.md3");

MODEL(PROJECTILE_CRYLINK,               "models/plasmatrail.mdl");
MODEL(PROJECTILE_CRYLINK_BOUNCING,      "models/plasmatrail.mdl");

MODEL(PROJECTILE_GRENADE,               "models/grenademodel.md3");
MODEL(PROJECTILE_GRENADE_BOUNCING,      "models/grenademodel.md3");

MODEL(PROJECTILE_MINE,                  "models/mine.md3");

MODEL(PROJECTILE_BLASTER,               "models/laser.mdl");

MODEL(PROJECTILE_HLAC,                  "models/hlac_bullet.md3");

MODEL(PROJECTILE_PORTO_RED,             "models/grenademodel.md3");
MODEL(PROJECTILE_PORTO_BLUE,            "models/grenademodel.md3");

MODEL(PROJECTILE_HOOKBOMB,              "models/grenademodel.md3");

MODEL(PROJECTILE_HAGAR,                 "models/hagarmissile.mdl");
MODEL(PROJECTILE_HAGAR_BOUNCING,        "models/hagarmissile.mdl");

MODEL(PROJECTILE_ARC_BOLT,              "models/arctrail.mdl");

// napalm grenade
MODEL(PROJECTILE_NAPALM_FOUNTAIN,       "null");
// fireball primary
MODEL(PROJECTILE_FIREBALL,              "null");
// fireball secondary
MODEL(PROJECTILE_FIREMINE,              "null");

MODEL(PROJECTILE_TAG,                   "models/laser.mdl");

MODEL(PROJECTILE_FLAC,                  "models/hagarmissile.mdl");

MODEL(PROJECTILE_SEEKER,                "models/tagrocket.md3");

MODEL(PROJECTILE_MAGE_SPIKE,            "models/ebomb.mdl");
MODEL(PROJECTILE_SHAMBLER_LIGHTNING,    "models/ebomb.mdl");

MODEL(PROJECTILE_RPC,                   W_Model("ok_rocket.md3"));

MODEL(PROJECTILE_ROCKETMINSTA_LASER,    "models/elaser.mdl");

MODEL(PROJECTILE_NADE,                  W_Model("v_ok_grenade.md3"));
MODEL(NADE_VIEW,                        W_Model("h_ok_grenade.iqm"));
MODEL(NADE_TIMER,                       "models/ok_nade_counter/ok_nade_counter.md3");
MODEL(NADE_ORB,                         "models/ctf/shield.md3");

MODEL(GIB_CHUNK,                        "models/gibs/chunk.mdl");
MODEL(GIB_LEG1,                         "models/gibs/leg1.md3");
MODEL(GIB_LEG2,                         "models/gibs/leg2.md3");
MODEL(GIB_CHEST,                        "models/gibs/chest.md3");
MODEL(GIB_SMALLCHEST,                   "models/gibs/smallchest.md3");
MODEL(GIB_ARM,                          "models/gibs/arm.md3");
MODEL(GIB_BLOODYSKULL,                  "models/gibs/bloodyskull.md3");
MODEL(GIB_EYE,                          "models/gibs/eye.md3");

MODEL(GIB_ROBO,                         "models/gibs/robo.md3");
MODEL(GIB_ROBO_1,                       "models/gibs/robo1.md3");
MODEL(GIB_ROBO_2,                       "models/gibs/robo2.md3");
MODEL(GIB_ROBO_3,                       "models/gibs/robo3.md3");
MODEL(GIB_ROBO_4,                       "models/gibs/robo4.md3");
MODEL(GIB_ROBO_5,                       "models/gibs/robo5.md3");
MODEL(GIB_ROBO_6,                       "models/gibs/robo6.md3");
MODEL(GIB_ROBO_7,                       "models/gibs/robo7.md3");
MODEL(GIB_ROBO_8,                       "models/gibs/robo8.md3");
Model MDL_GIB_ROBO_RANDOM() {
    int i = floor(random() * 8);
    return Models_from(MDL_GIB_ROBO_1.m_id + i);
}

MODEL(CASING_SHELL,                     "models/casing_shell.mdl");
MODEL(CASING_BULLET,                    "models/casing_bronze.iqm");

MODEL(BLASTER_VIEW,                     W_Model("h_laser.iqm"));
MODEL(BLASTER_WORLD,                    W_Model("v_laser.md3"));
MODEL(BLASTER_ITEM,                     W_Model("g_laser.md3"));

MODEL(SHOTGUN_MUZZLEFLASH,              "models/uziflash.md3");
MODEL(SHOTGUN_VIEW,                     W_Model("h_shotgun.iqm"));
MODEL(SHOTGUN_WORLD,                    W_Model("v_shotgun.md3"));
MODEL(SHOTGUN_ITEM,                     W_Model("g_shotgun.md3"));

MODEL(MACHINEGUN_MUZZLEFLASH,           "models/uziflash.md3");
MODEL(MACHINEGUN_VIEW,                  W_Model("h_uzi.iqm"));
MODEL(MACHINEGUN_WORLD,                 W_Model("v_uzi.md3"));
MODEL(MACHINEGUN_ITEM,                  W_Model("g_uzi.md3"));

MODEL(MORTAR_VIEW,                      W_Model("h_gl.iqm"));
MODEL(MORTAR_WORLD,                     W_Model("v_gl.md3"));
MODEL(MORTAR_ITEM,                      W_Model("g_gl.md3"));

MODEL(MINELAYER_MUZZLEFLASH,            "models/flash.md3");
MODEL(MINELAYER_MINE,                   "models/mine.md3");
MODEL(MINELAYER_VIEW,                   W_Model("h_minelayer.iqm"));
MODEL(MINELAYER_WORLD,                  W_Model("v_minelayer.md3"));
MODEL(MINELAYER_ITEM,                   W_Model("g_minelayer.md3"));

MODEL(ELECTRO_VIEW,                     W_Model("h_electro.iqm"));
MODEL(ELECTRO_WORLD,                    W_Model("v_electro.md3"));
MODEL(ELECTRO_ITEM,                     W_Model("g_electro.md3"));

MODEL(CRYLINK_VIEW,                     W_Model("h_crylink.iqm"));
MODEL(CRYLINK_WORLD,                    W_Model("v_crylink.md3"));
MODEL(CRYLINK_ITEM,                     W_Model("g_crylink.md3"));

MODEL(VORTEX_MUZZLEFLASH,               "models/nexflash.md3");
MODEL(VORTEX_VIEW,                      W_Model("h_nex.iqm"));
MODEL(VORTEX_WORLD,                     W_Model("v_nex.md3"));
MODEL(VORTEX_ITEM,                      W_Model("g_nex.md3"));

MODEL(HAGAR_VIEW,                       W_Model("h_hagar.iqm"));
MODEL(HAGAR_WORLD,                      W_Model("v_hagar.md3"));
MODEL(HAGAR_ITEM,                       W_Model("g_hagar.md3"));

MODEL(DEVASTATOR_MUZZLEFLASH,           "models/flash.md3");
MODEL(DEVASTATOR_VIEW,                  W_Model("h_rl.iqm"));
MODEL(DEVASTATOR_WORLD,                 W_Model("v_rl.md3"));
MODEL(DEVASTATOR_ITEM,                  W_Model("g_rl.md3"));

MODEL(PORTAL,                           "models/portal.md3");
MODEL(PORTO_VIEW,                       W_Model("h_porto.iqm"));
MODEL(PORTO_WORLD,                      W_Model("v_porto.md3"));
MODEL(PORTO_ITEM,                       W_Model("g_porto.md3"));

MODEL(VAPORIZER_MUZZLEFLASH,            "models/nexflash.md3");
MODEL(VAPORIZER_VIEW,                   W_Model("h_minstanex.iqm"));
MODEL(VAPORIZER_WORLD,                  W_Model("v_minstanex.md3"));
MODEL(VAPORIZER_ITEM,                   W_Model("g_minstanex.md3"));

MODEL(HOOK,                             "models/hook.md3");
MODEL(HOOK_VIEW,                        W_Model("h_hookgun.iqm"));
MODEL(HOOK_WORLD,                       W_Model("v_hookgun.md3"));
MODEL(HOOK_ITEM,                        W_Model("g_hookgun.md3"));

MODEL(HLAC_VIEW,                        W_Model("h_hlac.iqm"));
MODEL(HLAC_WORLD,                       W_Model("v_hlac.md3"));
MODEL(HLAC_ITEM,                        W_Model("g_hlac.md3"));

MODEL(TUBA_VIEW,                        W_Model("h_tuba.iqm"));
MODEL(TUBA_WORLD,                       W_Model("v_tuba.md3"));
MODEL(TUBA_ITEM,                        W_Model("g_tuba.md3"));
MODEL(ACCORDION_VIEW,                   W_Model("h_akordeon.iqm"));
MODEL(ACCORDION_WORLD,                  W_Model("v_akordeon.md3"));
MODEL(KLEINBOTTLE_VIEW,                 W_Model("h_kleinbottle.iqm"));
MODEL(KLEINBOTTLE_WORLD,                W_Model("v_kleinbottle.md3"));

MODEL(RIFLE_VIEW,                       W_Model("h_campingrifle.iqm"));
MODEL(RIFLE_WORLD,                      W_Model("v_campingrifle.md3"));
MODEL(RIFLE_ITEM,                       W_Model("g_campingrifle.md3"));

MODEL(FIREBALL_SPHERE,                  "models/sphere/sphere.md3");
MODEL(FIREBALL_VIEW,                    W_Model("h_fireball.iqm"));
MODEL(FIREBALL_WORLD,                   W_Model("v_fireball.md3"));
MODEL(FIREBALL_ITEM,                    W_Model("g_fireball.md3"));

MODEL(SEEKER_VIEW,                      W_Model("h_seeker.iqm"));
MODEL(SEEKER_WORLD,                     W_Model("v_seeker.md3"));
MODEL(SEEKER_ITEM,                      W_Model("g_seeker.md3"));

MODEL(SHOCKWAVE_MUZZLEFLASH,            "models/uziflash.md3");
MODEL(SHOCKWAVE_VIEW,                   W_Model("h_shotgun.iqm"));
MODEL(SHOCKWAVE_WORLD,                  W_Model("v_shotgun.md3"));
MODEL(SHOCKWAVE_ITEM,                   W_Model("g_shotgun.md3"));

MODEL(ARC_MUZZLEFLASH,                  "models/flash.md3");
MODEL(ARC_VIEW,                         W_Model("h_arc.iqm"));
MODEL(ARC_WORLD,                        W_Model("v_arc.md3"));
MODEL(ARC_ITEM,                         W_Model("g_arc.md3"));

MODEL(HMG_MUZZLEFLASH,                  "models/uziflash.md3");
MODEL(HMG_VIEW,                         W_Model("h_ok_hmg.iqm"));
MODEL(HMG_WORLD,                        W_Model("v_ok_hmg.md3"));
MODEL(HMG_ITEM,                         W_Model("g_ok_hmg.md3"));

MODEL(RPC_MUZZLEFLASH,                  "models/flash.md3");
MODEL(RPC_VIEW,                         W_Model("h_ok_rl.iqm"));
MODEL(RPC_WORLD,                        W_Model("v_ok_rl.md3"));
MODEL(RPC_ITEM,                         W_Model("g_ok_rl.md3"));

MODEL(CHAT,                             "models/misc/chatbubble.spr");

MODEL(0,                                "models/sprites/0.spr32");
MODEL(1,                                "models/sprites/1.spr32");
MODEL(2,                                "models/sprites/2.spr32");
MODEL(3,                                "models/sprites/3.spr32");
MODEL(4,                                "models/sprites/4.spr32");
MODEL(5,                                "models/sprites/5.spr32");
MODEL(6,                                "models/sprites/6.spr32");
MODEL(7,                                "models/sprites/7.spr32");
MODEL(8,                                "models/sprites/8.spr32");
MODEL(9,                                "models/sprites/9.spr32");
MODEL(10,                               "models/sprites/10.spr32");
Model MDL_NUM(int i) {
    if ((i >= 0 && i <= 10))
        return Models_from(MDL_0.m_id + i);
    return MDL_Null;
}

MODEL(WAYPOINT,                         "models/runematch/rune.mdl");
MODEL(MARKER,                           "models/marker.md3");
