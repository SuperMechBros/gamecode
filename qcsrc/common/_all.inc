noref float autocvar_net_connecttimeout = 30;

#ifdef GAMEQC
#include "anim.qc"
#include "animdecide.qc"
#include "ent_cs.qc"
#include "net_notice.qc"
#include "wepent.qc"
#endif

#include "mapinfo.qc"
#ifdef SVQC
    #include "state.qc"
#endif
#include "util.qc"

#ifndef CSQC
#include "campaign_file.qc"
#include "campaign_setup.qc"
#endif

#ifdef GAMEQC
#include "physics/all.inc"
#include "triggers/include.qc"
#include "viewloc.qc"
#endif

#ifdef GAMEQC
#include "minigames/minigames.qc"
#endif

#include "debug.qh"

#include "command/_mod.inc"

#ifdef GAMEQC
#include "deathtypes/all.qc"
#include "effects/all.qc"
#include "impulses/all.qc"
#include "notifications/all.qc"
#include "t_items.qc"
#endif

#include "items/_mod.inc"
    #include "weapons/_all.inc"
        #include "monsters/_mod.inc"

#include "mutators/_mod.inc"
    #include "gamemodes/_mod.inc"

#ifdef GAMEQC
#include "mod/_mod.inc"
#endif
