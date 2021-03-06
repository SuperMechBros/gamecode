#include "teleporters.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <lib/warpzone/common.qh>
    #include <lib/warpzone/util_server.qh>
    #include <lib/warpzone/server.qh>
    #include "../constants.qh"
	#include "../triggers/subs.qh"
    #include "../util.qh"
    #include <server/weapons/csqcprojectile.qh>
    #include <server/autocvars.qh>
    #include <server/constants.qh>
    #include <server/defs.qh>
    #include "../deathtypes/all.qh"
    #include "../mapinfo.qh"
    #include <server/anticheat.qh>
#endif

#ifdef SVQC
float check_tdeath(entity player, vector org, vector telefragmin, vector telefragmax)
{
	if (IS_PLAYER(player) && !IS_DEAD(player))
	{
		TDEATHLOOP(org)
		{
		#ifdef SVQC
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
		#endif
				if(IS_PLAYER(head))
					if(!IS_DEAD(head))
						return 1;
		}
	}
	return 0;
}

void trigger_teleport_link(entity this);

void tdeath(entity player, entity teleporter, entity telefragger, vector telefragmin, vector telefragmax)
{
	TDEATHLOOP(player.origin)
	{
		if (IS_PLAYER(player) && player.health >= 1)
		{
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
			{
				if(IS_PLAYER(head))
					if(head.health >= 1)
						++tdeath_hit;
				Damage (head, teleporter, telefragger, 10000, DEATH_TELEFRAG.m_id, head.origin, '0 0 0');
			}
		}
		else // dead bodies and monsters gib themselves instead of telefragging
			Damage (telefragger, teleporter, telefragger, 10000, DEATH_TELEFRAG.m_id, telefragger.origin, '0 0 0');
	}
}

void spawn_tdeath(vector v0, entity e, vector v)
{
	tdeath(e, e, e, '0 0 0', '0 0 0');
}
#endif

void TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity, vector telefragmin, vector telefragmax, float tflags)
{
	entity telefragger;
	vector from;

	if(teleporter.owner)
		telefragger = teleporter.owner;
	else
		telefragger = player;

	makevectors (to_angles);

#ifdef SVQC
	if(player.teleportable == TELEPORT_NORMAL) // don't play sounds or show particles for anything that isn't a player, maybe change later to block only observers
	{
		if(teleporter.pushltime < time) // only show one teleport effect per teleporter per 0.2 seconds, for better fps
		{
			if(tflags & TELEPORT_FLAG_SOUND)
			{
				string thesound = SND(TELEPORT);
				if(teleporter.noise != "")
				{
					RandomSelection_Init();
					FOREACH_WORD(teleporter.noise, true,
					{
						RandomSelection_AddString(it, 1, 1);
					});
					thesound = RandomSelection_chosen_string;
				}
				_sound (player, CH_TRIGGER, thesound, VOL_BASE, ATTEN_NORM);
			}
			if(tflags & TELEPORT_FLAG_PARTICLES)
			{
				Send_Effect(EFFECT_TELEPORT, player.origin, '0 0 0', 1);
				Send_Effect(EFFECT_TELEPORT, to + v_forward * 32, '0 0 0', 1);
			}
			teleporter.pushltime = time + 0.2;
		}
	}
#endif

	// Relocate the player
	// assuming to allows PL_MIN to PL_MAX box and some more
#ifdef SVQC
	from = player.origin;
	setorigin(player, to);
	player.oldorigin = to; // don't undo the teleport by unsticking
	player.angles = to_angles;
	player.fixangle = true;
	player.velocity = to_velocity;
	BITXOR_ASSIGN(player.effects, EF_TELEPORT_BIT);

	makevectors(player.angles);
	Reset_ArcBeam(player, v_forward);
	UpdateCSQCProjectileAfterTeleport(player);
	UpdateItemAfterTeleport(player);
#elif defined(CSQC)
	from = player.origin;
	setorigin(player, to);
	player.angles = to_angles;
	player.velocity = to_velocity;
	UNSET_ONGROUND(player);
	player.iflags |= IFLAG_TELEPORTED | IFLAG_V_ANGLE | IFLAG_ANGLES;
	player.csqcmodel_teleported = 1;
	player.v_angle = to_angles;

	if(player == csqcplayer) // not for anything but the main player
	{
		setproperty(VF_ANGLES, player.angles);
		setproperty(VF_CL_VIEWANGLES, player.angles);
	}
#endif

#ifdef SVQC
	if(IS_PLAYER(player))
	{
		if(tflags & TELEPORT_FLAG_TDEATH)
			if(player.takedamage && !IS_DEAD(player) && !g_race && !g_cts && (autocvar_g_telefrags || (tflags & TELEPORT_FLAG_FORCE_TDEATH)))
				tdeath(player, teleporter, telefragger, telefragmin, telefragmax);

		// player no longer is on ground
		UNSET_ONGROUND(player);

		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		player.oldvelocity = player.velocity;

		// reset tracking of who pushed you into a hazard (for kill credit)
		if(teleporter.owner)
		{
			player.pusher = teleporter.owner;
			player.pushltime = time + autocvar_g_maxpushtime;
			player.istypefrag = PHYS_INPUT_BUTTON_CHAT(player);
		}
		else
		{
			player.pushltime = 0;
			player.istypefrag = 0;
		}

		player.lastteleporttime = time;
	}
#endif
}

entity Simple_TeleportPlayer(entity teleporter, entity player)
{
	vector locout;
	entity e = NULL;

	// Find the output teleporter
	if(teleporter.enemy)
	{
		e = teleporter.enemy;
	}
	else
	{
		// sorry CSQC, random stuff ain't gonna happen
#ifdef SVQC
		RandomSelection_Init();
		FOREACH_ENTITY_STRING(targetname, teleporter.target,
		{
			bool p = true;
			if(STAT(TELEPORT_TELEFRAG_AVOID, player))
			{
			#ifdef SVQC
				locout = it.origin + '0 0 1' * (1 - player.mins.z - 24);
			#elif defined(CSQC)
				locout = it.origin + '0 0 1' * (1 - player.mins.z - 24);
			#endif
				if(check_tdeath(player, locout, '0 0 0', '0 0 0'))
					p = false;
			}
			RandomSelection_AddEnt(it, (it.cnt ? it.cnt : 1), p);
		});
		e = RandomSelection_chosen_ent;
#endif
	}

#ifdef SVQC
	if(!e) { sprint(player, "Teleport destination vanished. Sorry... please complain to the mapper.\n"); }
#elif defined(CSQC)
	if(!e) { LOG_INFO("Teleport destination could not be found from CSQC.\n"); }
#endif

	makevectors(e.mangle);

	if(e.speed)
		if(vdist(player.velocity, >, e.speed))
			player.velocity = normalize(player.velocity) * max(0, e.speed);

	if(STAT(TELEPORT_MAXSPEED, player))
		if(vdist(player.velocity, >, STAT(TELEPORT_MAXSPEED, player)))
			player.velocity = normalize(player.velocity) * max(0, STAT(TELEPORT_MAXSPEED, player));

	locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);

	TeleportPlayer(teleporter, player, locout, e.mangle, v_forward * vlen(player.velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);

	return e;
}

void teleport_findtarget(entity this)
{
	int n = 0;
	entity e;
	for(e = NULL; (e = find(e, targetname, this.target)); )
	{
		++n;
#ifdef SVQC
		if(e.move_movetype == MOVETYPE_NONE)
			waypoint_spawnforteleporter(this, e.origin, 0);
		if(e.classname != "info_teleport_destination")
			LOG_INFO("^3MAPPER ERROR: teleporter does target an invalid teleport destination entity. Angles will not work.\n");
#endif
	}

	if(n == 0)
	{
		// no dest!
		objerror (this, "Teleporter with nonexistant target");
		return;
	}
	else if(n == 1)
	{
		// exactly one dest - bots love that
		this.enemy = find(e, targetname, this.target);
	}
	else
	{
		// have to use random selection every single time
		this.enemy = NULL;
	}

	// now enable touch
	settouch(this, Teleport_Touch);
#ifdef SVQC
	trigger_teleport_link(this);
#endif
}

entity Teleport_Find(vector mi, vector ma)
{
	IL_EACH(g_teleporters, WarpZoneLib_BoxTouchesBrush(mi, ma, it, NULL),
	{
		return it;
	});
	return NULL;
}

void WarpZone_PostTeleportPlayer_Callback(entity pl)
{
#ifdef SVQC
	makevectors(pl.angles);
	Reset_ArcBeam(pl, v_forward);
	UpdateCSQCProjectileAfterTeleport(pl);
	UpdateItemAfterTeleport(pl);
    if (IS_PLAYER(pl)) anticheat_fixangle(pl);
#endif
	// "disown" projectiles after teleport
	if(pl.owner)
	if(pl.owner == pl.realowner)
	{
	#ifdef SVQC
		if(!(pl.flags & FL_PROJECTILE))
	#elif defined(CSQC)
		if(!(pl.flags & BIT(15))) // FL_PROJECTILE
	#endif
			LOG_INFO("A non-projectile got through a warpzone and its owner cleared. It's a ", pl.classname, ".\n");
		pl.owner = NULL;
	}
	if(IS_PLAYER(pl))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
	#ifdef SVQC
		pl.oldvelocity = pl.velocity;
	#endif
		// reset teleport time tracking too (or multijump can cause insane speeds)
		pl.lastteleporttime = time;
	}
}
