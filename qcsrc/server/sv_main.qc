#include "sv_main.qh"

#include "anticheat.qh"
#include "g_hook.qh"
#include "g_world.qh"

#include "bot/api.qh"

#include "command/common.qh"

#include "mutators/_mod.qh"
#include "weapons/csqcprojectile.qh"

#include "../common/constants.qh"
#include "../common/deathtypes/all.qh"
#include "../common/debug.qh"
#include "../common/mapinfo.qh"
#include "../common/util.qh"

#include <common/weapons/_all.qh>

#include "../lib/csqcmodel/sv_model.qh"

#include "../lib/warpzone/common.qh"
#include "../lib/warpzone/server.qh"

.float lastground;
.int state;

void CreatureFrame_hotliquids(entity this)
{
	if (this.dmgtime < time)
	{
		this.dmgtime = time + autocvar_g_balance_contents_damagerate;

		if (this.flags & FL_PROJECTILE)
		{
			if (this.watertype == CONTENT_LAVA)
				Damage (this, NULL, NULL, autocvar_g_balance_contents_projectiledamage * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_LAVA.m_id, this.origin, '0 0 0');
			else if (this.watertype == CONTENT_SLIME)
				Damage (this, NULL, NULL, autocvar_g_balance_contents_projectiledamage * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_SLIME.m_id, this.origin, '0 0 0');
		}
		else
		{
			if (this.watertype == CONTENT_LAVA)
			{
				if (this.watersound_finished < time)
				{
					this.watersound_finished = time + 0.5;
					sound (this, CH_PLAYER_SINGLE, SND_LAVA, VOL_BASE, ATTEN_NORM);
				}
				Damage (this, NULL, NULL, autocvar_g_balance_contents_playerdamage_lava * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_LAVA.m_id, this.origin, '0 0 0');
				if(autocvar_g_balance_contents_playerdamage_lava_burn)
					Fire_AddDamage(this, NULL, autocvar_g_balance_contents_playerdamage_lava_burn * this.waterlevel, autocvar_g_balance_contents_playerdamage_lava_burn_time * this.waterlevel, DEATH_LAVA.m_id);
			}
			else if (this.watertype == CONTENT_SLIME)
			{
				if (this.watersound_finished < time)
				{
					this.watersound_finished = time + 0.5;
					sound (this, CH_PLAYER_SINGLE, SND_SLIME, VOL_BASE, ATTEN_NORM);
				}
				Damage (this, NULL, NULL, autocvar_g_balance_contents_playerdamage_slime * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_SLIME.m_id, this.origin, '0 0 0');
			}
		}
	}
}

void CreatureFrame_Liquids(entity this)
{
	if (this.watertype <= CONTENT_WATER && this.waterlevel > 0) // workaround a retarded bug made by id software :P (yes, it's that old of a bug)
	{
		if (!(this.flags & FL_INWATER))
		{
			this.flags |= FL_INWATER;
			this.dmgtime = 0;
		}

		CreatureFrame_hotliquids(this);
	}
	else
	{
		if (this.flags & FL_INWATER)
		{
			// play leave water sound
			this.flags &= ~FL_INWATER;
			this.dmgtime = 0;
		}
		this.air_finished = time + 12;
		this.dmg = 2;
	}
}

void CreatureFrame_FallDamage(entity this)
{
	if(!(this.flags & FL_PROJECTILE)) // projectiles don't get falling damage
	if(this.velocity || this.oldvelocity) // moving or has moved
	{
		// check for falling damage
		float velocity_len = vlen(this.velocity);
		bool have_hook = false;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	    {
	    	.entity weaponentity = weaponentities[slot];
	    	if(this.(weaponentity).hook && this.(weaponentity).hook.state)
	    	{
	    		have_hook = true;
	    		break;
	    	}
	    }
		if(!have_hook)
		{
			float dm = vlen(this.oldvelocity) - velocity_len; // dm is now the velocity DECREASE. Velocity INCREASE should never cause a sound or any damage.
			if (IS_DEAD(this))
				dm = (dm - autocvar_g_balance_falldamage_deadminspeed) * autocvar_g_balance_falldamage_factor;
			else
				dm = min((dm - autocvar_g_balance_falldamage_minspeed) * autocvar_g_balance_falldamage_factor, autocvar_g_balance_falldamage_maxdamage);
			if (dm > 0)
				Damage (this, NULL, NULL, dm, DEATH_FALL.m_id, this.origin, '0 0 0');
		}

		if(autocvar_g_maxspeed > 0 && velocity_len > autocvar_g_maxspeed)
			Damage (this, NULL, NULL, 100000, DEATH_SHOOTING_STAR.m_id, this.origin, '0 0 0');
	}
}

void CreatureFrame_All()
{
	IL_EACH(g_damagedbycontents, it.damagedbycontents,
	{
		if (it.move_movetype == MOVETYPE_NOCLIP) continue;
		CreatureFrame_Liquids(it);
		CreatureFrame_FallDamage(it);
		it.oldvelocity = it.velocity;
	});
}

void Pause_TryPause(bool ispaused)
{
	int n = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), LAMBDA(
		if (PHYS_INPUT_BUTTON_CHAT(it) != ispaused) return;
		++n;
	));
	if (!n) return;
	setpause(ispaused);
}

void SV_PausedTic(float elapsedtime)
{
	if (!server_is_dedicated) Pause_TryPause(false);
}

/*
=============
StartFrame

Called before each frame by the server
=============
*/

float game_delay;
float game_delay_last;

bool autocvar_sv_autopause = false;
float RedirectionThink();
void systems_update();
void sys_phys_update(entity this, float dt);
void StartFrame()
{
    // TODO: if move is more than 50ms, split it into two moves (this matches QWSV behavior and the client prediction)
    IL_EACH(g_players, IS_FAKE_CLIENT(it), sys_phys_update(it, frametime));
    IL_EACH(g_players, IS_FAKE_CLIENT(it), PlayerPreThink(it));

	execute_next_frame();
	if (autocvar_sv_autopause && !server_is_dedicated) Pause_TryPause(true);

	delete_fn = remove_unsafely; // not during spawning!
	serverprevtime = servertime;
	servertime = time;
	serverframetime = frametime;

#ifdef PROFILING
	if(time > client_cefc_accumulatortime + 1)
	{
		float t = client_cefc_accumulator / (time - client_cefc_accumulatortime);
		LOG_INFO("CEFC time: ", ftos(t * 1000), "ms; ");
		int c_seeing = 0;
		int c_seen = 0;
		FOREACH_CLIENT(true, LAMBDA(
			if(IS_REAL_CLIENT(it))
				++c_seeing;
			if(IS_PLAYER(it))
				++c_seen;
		));
		LOG_INFO("CEFC calls per second: ", ftos(c_seeing * (c_seen - 1) / t), "; ");
		LOG_INFO("CEFC 100% load at: ", ftos(solve_quadratic(t, -t, -1) * '0 1 0'), "\n");

		client_cefc_accumulatortime = time;
		client_cefc_accumulator = 0;
	}
#endif

	IL_EACH(g_projectiles, it.csqcprojectile_clientanimate, CSQCProjectile_Check(it));

	if (RedirectionThink()) return;

	UncustomizeEntitiesRun();
	InitializeEntitiesRun();

	WarpZone_StartFrame();

	sys_frametime = autocvar_sys_ticrate * autocvar_slowmo;
	if (sys_frametime <= 0) sys_frametime = 1.0 / 60.0; // somewhat safe fallback

	if (timeout_status == TIMEOUT_LEADTIME) // just before the timeout (when timeout_status will be TIMEOUT_ACTIVE)
		orig_slowmo = autocvar_slowmo; // slowmo will be restored after the timeout

	skill = autocvar_skill;

	// detect when the pre-game countdown (if any) has ended and the game has started
	game_delay = (time < game_starttime);

	if (autocvar_sv_eventlog && game_delay_last && !game_delay)
		GameLogEcho(":startdelay_ended");

	game_delay_last = game_delay;

	CreatureFrame_All();
	CheckRules_World();

	if (warmup_stage && !game_stopped && warmup_limit > 0 && time >= warmup_limit) {
		ReadyRestart();
		return;
	}

	bot_serverframe();
	anticheat_startframe();
	MUTATOR_CALLHOOK(SV_StartFrame);

    FOREACH_CLIENT(true, GlobalStats_update(it));
    IL_EACH(g_players, IS_FAKE_CLIENT(it), PlayerPostThink(it));
}

.vector originjitter;
.vector anglesjitter;
.float anglejitter;
.string gametypefilter;
.string cvarfilter;
bool DoesQ3ARemoveThisEntity(entity this);
void SV_OnEntityPreSpawnFunction(entity this)
{
	__spawnfunc_expecting = true;
	__spawnfunc_expect = this;
	if (this)
	if (this.gametypefilter != "")
	if (!isGametypeInFilter(MapInfo_LoadedGametype, teamplay, have_team_spawns, this.gametypefilter))
	{
		delete(this);
		__spawnfunc_expecting = false;
		return;
	}
	if(this.cvarfilter != "")
	{
		float n, i, o, inv;
		string s, k, v;
		inv = 0;

		s = this.cvarfilter;
		if(substring(s, 0, 1) == "+")
		{
			s = substring(s, 1, -1);
		}
		else if(substring(s, 0, 1) == "-")
		{
			inv = 1;
			s = substring(s, 1, -1);
		}

		n = tokenize_console(s);
		for(i = 0; i < n; ++i)
		{
			s = argv(i);
			// syntax:
			// var>x
			// var<x
			// var>=x
			// var<=x
			// var==x
			// var!=x
			// var===x
			// var!==x
			if((o = strstrofs(s, ">=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) < stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "<=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) > stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, ">", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) <= stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "<", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) >= stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "==", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) != stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "!=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) == stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "===", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar_string(k) != v)
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "!==", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar_string(k) == v)
					goto cvar_fail;
			}
			else if(substring(s, 0, 1) == "!")
			{
				k = substring(s, 1, -1);
				if(cvar(k))
					goto cvar_fail;
			}
			else
			{
				k = s;
				if (!cvar(k))
					goto cvar_fail;
			}
		}
		inv = !inv;
LABEL(cvar_fail)
		// now inv is 1 if we want to keep the item, and 0 if we want to get rid of it
		if (!inv)
		{
			//print("cvarfilter fail\n");
			delete(this);
			__spawnfunc_expecting = false;
			return;
		}
	}

	if(DoesQ3ARemoveThisEntity(this))
	{
		delete(this);
		__spawnfunc_expecting = false;
		return;
	}

	set_movetype(this, this.movetype);

	// support special -1 and -2 angle from radiant
	if (this.angles == '0 -1 0')
		this.angles = '-90 0 0';
	else if (this.angles == '0 -2 0')
		this.angles = '+90 0 0';

	if(this.originjitter.x != 0)
		this.origin_x = this.origin.x + (random() * 2 - 1) * this.originjitter.x;
	if(this.originjitter.y != 0)
		this.origin_y = this.origin.y + (random() * 2 - 1) * this.originjitter.y;
	if(this.originjitter.z != 0)
		this.origin_z = this.origin.z + (random() * 2 - 1) * this.originjitter.z;
	if(this.anglesjitter.x != 0)
		this.angles_x = this.angles.x + (random() * 2 - 1) * this.anglesjitter.x;
	if(this.anglesjitter.y != 0)
		this.angles_y = this.angles.y + (random() * 2 - 1) * this.anglesjitter.y;
	if(this.anglesjitter.z != 0)
		this.angles_z = this.angles.z + (random() * 2 - 1) * this.anglesjitter.z;
	if(this.anglejitter != 0)
		this.angles_y = this.angles.y + (random() * 2 - 1) * this.anglejitter;

	if(MUTATOR_CALLHOOK(OnEntityPreSpawn, this))
	{
		delete(this);
		__spawnfunc_expecting = false;
		return;
	}
}

void WarpZone_PostInitialize_Callback()
{
	// create waypoint links for warpzones
	//for(entity e = warpzone_first; e; e = e.warpzone_next)
	for(entity e = NULL; (e = find(e, classname, "trigger_warpzone")); )
	{
		vector src, dst;
		src = (e.absmin + e.absmax) * 0.5;
		makevectors(e.warpzone_angles);
		src = src + ((e.warpzone_origin - src) * v_forward) * v_forward + 16 * v_right;
		dst = (e.enemy.absmin + e.enemy.absmax) * 0.5;
		makevectors(e.enemy.warpzone_angles);
		dst = dst + ((e.enemy.warpzone_origin - dst) * v_forward) * v_forward - 16 * v_right;
		waypoint_spawnforteleporter_v(e, src, dst, 0);
	}
}
