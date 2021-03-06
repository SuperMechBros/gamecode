#include "impulse.qh"
#include "round_handler.qh"

#include "bot/api.qh"

#include "weapons/throwing.qh"
#include "command/common.qh"
#include "cheats.qh"
#include "weapons/selection.qh"
#include "weapons/tracing.qh"
#include "weapons/weaponsystem.qh"

#include <common/state.qh>

#include "../common/minigames/sv_minigames.qh"

#include <common/weapons/_all.qh>

#include "../common/mutators/mutator/waypoints/waypointsprites.qh"

#define IMPULSE(id) _IMPULSE(IMP_##id)
#define _IMPULSE(id) \
	void id##_handle(entity this); \
	STATIC_INIT_LATE(id) \
	{ \
		id.impulse_handle = id##_handle; \
	} \
	void id##_handle(entity this)

/**
 * Impulse map:
 *
 * 0 reserved (no input)
 *
 * 99: loaded
 *
 * 140: moving clone
 * 141: ctf speedrun
 * 142: fixed clone
 * 143: emergency teleport
 * 148: unfairly eliminate
 *
 * TODO:
 * 200 to 209: prev weapon shortcuts
 * 210 to 219: best weapon shortcuts
 * 220 to 229: next weapon shortcuts
 * 230 to 253: individual weapons (up to 24)
 */

// weapon switching impulses

#define X(slot) \
	IMPULSE(weapon_group_##slot) \
	{ \
		if (IS_DEAD(this)) \
		{ \
			this.impulse = IMP_weapon_group_##slot.impulse; \
			return; \
		} \
		for(int wepslot = 0; wepslot < MAX_WEAPONSLOTS; ++wepslot) \
		{ \
			.entity weaponentity = weaponentities[wepslot]; \
			W_NextWeaponOnImpulse(this, slot, weaponentity); \
			if(wepslot == 0 && autocvar_g_weaponswitch_debug != 1) \
				break; \
		} \
	}
X(1)
X(2)
X(3)
X(4)
X(5)
X(6)
X(7)
X(8)
X(9)
X(0)
#undef X

// custom order weapon cycling

#define X(slot, dir) \
	IMPULSE(weapon_priority_##slot##_##dir) \
	{ \
		if (IS_DEAD(this)) \
		{ \
			this.impulse = IMP_weapon_priority_##slot##_##dir.impulse; \
			return; \
		} \
		noref int prev = -1; \
		noref int best =  0; \
		noref int next = +1; \
		for(int wepslot = 0; wepslot < MAX_WEAPONSLOTS; ++wepslot) \
		{ \
			.entity weaponentity = weaponentities[wepslot]; \
			W_CycleWeapon(this, this.cvar_cl_weaponpriorities[slot], dir, weaponentity); \
			if(wepslot == 0 && autocvar_g_weaponswitch_debug != 1) \
				break; \
		} \
	}
X(0, prev)
X(1, prev)
X(2, prev)
X(3, prev)
X(4, prev)
X(5, prev)
X(6, prev)
X(7, prev)
X(8, prev)
X(9, prev)

X(0, best)
X(1, best)
X(2, best)
X(3, best)
X(4, best)
X(5, best)
X(6, best)
X(7, best)
X(8, best)
X(9, best)

X(0, next)
X(1, next)
X(2, next)
X(3, next)
X(4, next)
X(5, next)
X(6, next)
X(7, next)
X(8, next)
X(9, next)
#undef X

// direct weapons

#define X(i) \
	IMPULSE(weapon_byid_##i) \
	{ \
		if (IS_DEAD(this)) \
		{ \
			this.impulse = IMP_weapon_byid_##i.impulse; \
			return; \
		} \
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot) \
		{ \
			.entity weaponentity = weaponentities[slot]; \
			W_SwitchWeapon(this, Weapons_from(WEP_FIRST + i), weaponentity); \
			if(slot == 0 && autocvar_g_weaponswitch_debug != 1) \
				break; \
		} \
	}
X(0)
X(1)
X(2)
X(3)
X(4)
X(5)
X(6)
X(7)
X(8)
X(9)
X(10)
X(11)
X(12)
X(13)
X(14)
X(15)
X(16)
X(17)
X(18)
X(19)
X(20)
X(21)
X(22)
X(23)
#undef X

IMPULSE(weapon_next_byid)
{
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_next_byid.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_NextWeapon(this, 0, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_prev_byid)
{
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_prev_byid.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_PreviousWeapon(this, 0, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_next_bygroup)
{
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_next_bygroup.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_NextWeapon(this, 1, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_prev_bygroup)
{
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_prev_bygroup.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_PreviousWeapon(this, 1, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_next_bypriority)
{
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_next_bypriority.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_NextWeapon(this, 2, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_prev_bypriority)
{
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_prev_bypriority.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_PreviousWeapon(this, 2, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_last)
{
	if (IS_DEAD(this)) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_LastWeapon(this, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_best)
{
	if (IS_DEAD(this)) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_SwitchWeapon(this, w_getbestweapon(this, weaponentity), weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_drop)
{
	if (IS_DEAD(this)) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_ThrowWeapon(this, weaponentity, W_CalculateProjectileVelocity(this, this.velocity, v_forward * 750, false), '0 0 0', true);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_reload)
{
	if (IS_DEAD(this)) return;
	if (forbidWeaponUse(this)) return;
	entity actor = this;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		Weapon w = this.(weaponentity).m_weapon;
		w.wr_reload(w, actor, weaponentity);

		if(slot == 0 && autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

void ImpulseCommands(entity this)
{
	if (game_stopped) return;

	int imp = this.impulse;
	if (!imp) return;
	this.impulse = 0;

	if (MinigameImpulse(this, imp)) return;

	if (timeout_status == TIMEOUT_ACTIVE) return;  // don't allow any impulses while the game is paused

	// allow only weapon change impulses when not in round time
	if (round_handler_IsActive() && !round_handler_IsRoundStarted())
	{
		#define X(id) case IMP_##id.impulse:
		switch (imp)
		{
			X(weapon_group_0)
			X(weapon_group_1)
			X(weapon_group_2)
			X(weapon_group_3)
			X(weapon_group_4)
			X(weapon_group_5)
			X(weapon_group_6)
			X(weapon_group_7)
			X(weapon_group_8)
			X(weapon_group_9)
			X(weapon_next_byid)
			X(weapon_prev_byid)
			X(weapon_next_bygroup)
			X(weapon_prev_bygroup)
			X(weapon_next_bypriority)
			X(weapon_prev_bypriority)
			X(weapon_last)
			X(weapon_best)
			X(weapon_reload)
			X(weapon_priority_0_prev)
            X(weapon_priority_1_prev)
            X(weapon_priority_2_prev)
            X(weapon_priority_3_prev)
            X(weapon_priority_4_prev)
            X(weapon_priority_5_prev)
            X(weapon_priority_6_prev)
            X(weapon_priority_7_prev)
            X(weapon_priority_8_prev)
            X(weapon_priority_9_prev)
            X(weapon_priority_0_next)
			X(weapon_priority_1_next)
			X(weapon_priority_2_next)
			X(weapon_priority_3_next)
			X(weapon_priority_4_next)
			X(weapon_priority_5_next)
			X(weapon_priority_6_next)
			X(weapon_priority_7_next)
			X(weapon_priority_8_next)
			X(weapon_priority_9_next)
			X(weapon_priority_0_best)
            X(weapon_priority_1_best)
            X(weapon_priority_2_best)
            X(weapon_priority_3_best)
            X(weapon_priority_4_best)
            X(weapon_priority_5_best)
            X(weapon_priority_6_best)
            X(weapon_priority_7_best)
            X(weapon_priority_8_best)
            X(weapon_priority_9_best)
            X(weapon_byid_0)
            X(weapon_byid_1)
            X(weapon_byid_2)
            X(weapon_byid_3)
            X(weapon_byid_4)
            X(weapon_byid_5)
            X(weapon_byid_6)
            X(weapon_byid_7)
            X(weapon_byid_8)
            X(weapon_byid_9)
            X(weapon_byid_10)
            X(weapon_byid_11)
            X(weapon_byid_12)
            X(weapon_byid_13)
            X(weapon_byid_14)
            X(weapon_byid_15)
            X(weapon_byid_16)
            X(weapon_byid_17)
            X(weapon_byid_18)
            X(weapon_byid_19)
            X(weapon_byid_20)
            X(weapon_byid_21)
            X(weapon_byid_22)
            X(weapon_byid_23)
			break;
			default: return;
		}
#undef X
	}

	if (CheatImpulse(this, imp)) return;

	FOREACH(IMPULSES, it.impulse == imp, {
		void(entity) f = it.impulse_handle;
		if (!f) continue;
		f(this);
		return;
	});
}

IMPULSE(use)
{
	PlayerUseKey(this);
}

IMPULSE(waypoint_personal_here)
{
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this, this.origin, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at location\n");
}

IMPULSE(waypoint_personal_crosshair)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this, trace_endpos, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at crosshair\n");
}

IMPULSE(waypoint_personal_death)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this, this.death_origin, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at death location\n");
}

IMPULSE(waypoint_here_follow)
{
	if (!teamplay) return;
	if (IS_DEAD(this)) return;
	if (!MUTATOR_CALLHOOK(HelpMePing, this))
	{
		entity wp = WaypointSprite_Attach(WP_Helpme, this, true, RADARICON_HELPME);
		if (!wp) WaypointSprite_HelpMePing(this.waypointsprite_attachedforcarrier);
		else WaypointSprite_Ping(wp);
	}
	sprint(this, "HELP ME attached\n");
}

IMPULSE(waypoint_here_here)
{
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this, this.origin, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at location\n");
}

IMPULSE(waypoint_here_crosshair)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this, trace_endpos, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at crosshair\n");
}

IMPULSE(waypoint_here_death)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this, this.death_origin, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at death location\n");
}

IMPULSE(waypoint_danger_here)
{
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this, this.origin, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at location\n");
}

IMPULSE(waypoint_danger_crosshair)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this, trace_endpos, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at crosshair\n");
}

IMPULSE(waypoint_danger_death)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this, this.death_origin, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at death location\n");
}

IMPULSE(waypoint_clear_personal)
{
	WaypointSprite_ClearPersonal(this);
	if (this.personal)
	{
		delete(this.personal);
		this.personal = NULL;

		if((g_cts || g_race) && autocvar_g_allow_checkpoints)
			ClientKill(this);
	}
	sprint(this, "personal waypoint cleared\n");
}

IMPULSE(waypoint_clear)
{
	WaypointSprite_ClearOwned(this);
	if (this.personal)
	{
		delete(this.personal);
		this.personal = NULL;
		if((g_cts || g_race) && autocvar_g_allow_checkpoints)
			ClientKill(this);
	}
	sprint(this, "all waypoints cleared\n");
}

IMPULSE(navwaypoint_spawn)
{
	if (!autocvar_g_waypointeditor) return;
	entity e;
	vector org = this.origin;
	bool sym = boolean(autocvar_g_waypointeditor_symmetrical);

	LABEL(add_wp);
	e = waypoint_spawn(org, org, 0);
	waypoint_schedulerelink(e);
	bprint(strcat("Waypoint spawned at ", vtos(org), "\n"));
	if(sym)
	{
		vector map_center = havocbot_middlepoint;
		if (autocvar_g_waypointeditor_symmetrical == 2)
			map_center = autocvar_g_waypointeditor_symmetrical_center;

		org = e.origin;
		org.x = map_center.x - (org.x - map_center.x);
		org.y = map_center.y - (org.y - map_center.y);
		if (vdist(org - this.origin, >, 10))
		{
			sym = false;
			goto add_wp;
		}
	}
}

IMPULSE(navwaypoint_remove)
{
	if (!autocvar_g_waypointeditor) return;
	entity e = navigation_findnearestwaypoint(this, false);
	bool sym = boolean(autocvar_g_waypointeditor_symmetrical);

	LABEL(remove_wp);
	if (!e) return;
	if (e.wpflags & WAYPOINTFLAG_GENERATED) return;

	if (e.wphardwired)
	{
		LOG_INFO("^1Warning: ^7Removal of hardwired waypoints is not allowed in the editor. Please remove links from/to this waypoint (", vtos(e.origin), ") by hand from maps/", mapname, ".waypoints.hardwired\n");
		return;
	}

	entity wp_sym = NULL;
	if (sym)
	{
		vector map_center = havocbot_middlepoint;
		if (autocvar_g_waypointeditor_symmetrical == 2)
			map_center = autocvar_g_waypointeditor_symmetrical_center;

		vector org = e.origin;
		org.x = map_center.x - (org.x - map_center.x);
		org.y = map_center.y - (org.y - map_center.y);
		FOREACH_ENTITY_CLASS("waypoint", !(it.wpflags & WAYPOINTFLAG_GENERATED), {
			if(vdist(org - it.origin, <, 3))
			{
				wp_sym = it;
				break;
			}
		});
	}
	bprint(strcat("Waypoint removed at ", vtos(e.origin), "\n"));
	waypoint_remove(e);
	if (sym && wp_sym)
	{
		e = wp_sym;
		sym = false;
		goto remove_wp;
	}
}

IMPULSE(navwaypoint_relink)
{
	if (!autocvar_g_waypointeditor) return;
	waypoint_schedulerelinkall();
}

IMPULSE(navwaypoint_save)
{
	if (!autocvar_g_waypointeditor) return;
	waypoint_saveall();
}

IMPULSE(navwaypoint_unreachable)
{
	if (!autocvar_g_waypointeditor) return;
	IL_EACH(g_waypoints, true,
	{
		it.colormod = '0.5 0.5 0.5';
		it.effects &= ~(EF_NODEPTHTEST | EF_RED | EF_BLUE);
	});
	entity e2 = navigation_findnearestwaypoint(this, false);
	navigation_markroutes(this, e2);

	int j, m;

	j = 0;
	m = 0;
	IL_EACH(g_waypoints, it.wpcost >= 10000000,
	{
		LOG_INFO("unreachable: ", etos(it), " ", vtos(it.origin), "\n");
		it.colormod_z = 8;
		it.effects |= EF_NODEPTHTEST | EF_BLUE;
		++j;
		++m;
	});
	if (j) LOG_INFOF("%d waypoints cannot be reached from here in any way (marked with blue light)\n", j);
	navigation_markroutes_inverted(e2);

	j = 0;
	IL_EACH(g_waypoints, it.wpcost >= 10000000,
	{
		LOG_INFO("cannot reach me: ", etos(it), " ", vtos(it.origin), "\n");
		it.colormod_x = 8;
		if (!(it.effects & EF_NODEPTHTEST))  // not already reported before
			++m;
		it.effects |= EF_NODEPTHTEST | EF_RED;
		++j;
	});
	if (j) LOG_INFOF("%d waypoints cannot walk to here in any way (marked with red light)\n", j);
	if (m) LOG_INFOF("%d waypoints have been marked total\n", m);

	j = 0;
	IL_EACH(g_spawnpoints, true,
	{
		vector org = it.origin;
		tracebox(it.origin, PL_MIN_CONST, PL_MAX_CONST, it.origin - '0 0 512', MOVE_NOMONSTERS, NULL);
		setorigin(it, trace_endpos);
		if (navigation_findnearestwaypoint(it, false))
		{
			setorigin(it, org);
			it.effects &= ~EF_NODEPTHTEST;
			it.model = "";
		}
		else
		{
			setorigin(it, org);
			LOG_INFO("spawn without waypoint: ", etos(it), " ", vtos(it.origin), "\n");
			it.effects |= EF_NODEPTHTEST;
			_setmodel(it, this.model);
			it.frame = this.frame;
			it.skin = this.skin;
			it.colormod = '8 0.5 8';
			setsize(it, '0 0 0', '0 0 0');
			++j;
		}
	});
	if (j) LOG_INFOF("%d spawnpoints have no nearest waypoint (marked by player model)\n", j);

	j = 0;
	IL_EACH(g_items, true,
	{
		it.effects &= ~(EF_NODEPTHTEST | EF_RED | EF_BLUE);
		it.colormod = '0.5 0.5 0.5';
	});
	IL_EACH(g_items, true,
	{
		if (navigation_findnearestwaypoint(it, false)) continue;
		LOG_INFO("item without waypoint: ", etos(it), " ", vtos(it.origin), "\n");
		it.effects |= EF_NODEPTHTEST | EF_RED;
		it.colormod_x = 8;
		++j;
	});
	if (j) LOG_INFOF("%d items have no nearest waypoint and cannot be walked away from (marked with red light)\n", j);

	j = 0;
	IL_EACH(g_items, true,
	{
		if (navigation_findnearestwaypoint(it, true)) continue;
		LOG_INFO("item without waypoint: ", etos(it), " ", vtos(it.origin), "\n");
		it.effects |= EF_NODEPTHTEST | EF_BLUE;
		it.colormod_z = 8;
		++j;
	});
	if (j) LOG_INFOF("%d items have no nearest waypoint and cannot be walked to (marked with blue light)\n", j);
}
