#include "spawnpoints.qh"

#include "mutators/_mod.qh"
#include "g_world.qh"
#include "race.qh"
#include "../common/constants.qh"
#include <common/net_linked.qh>
#include "../common/teams.qh"
#include "../common/triggers/subs.qh"
#include "../common/util.qh"
#include "../lib/warpzone/common.qh"
#include "../lib/warpzone/util_server.qh"

bool SpawnPoint_Send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_SPAWNPOINT);

	WriteByte(MSG_ENTITY, this.team);
	WriteCoord(MSG_ENTITY, this.origin.x);
	WriteCoord(MSG_ENTITY, this.origin.y);
	WriteCoord(MSG_ENTITY, this.origin.z);

	return true;
}

bool SpawnEvent_Send(entity this, entity to, int sf)
{
	float send;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_SPAWNEVENT);

	if(autocvar_g_spawn_alloweffects)
	{
		WriteByte(MSG_ENTITY, etof(this.owner));
		WriteCoord(MSG_ENTITY, this.owner.origin.x);
		WriteCoord(MSG_ENTITY, this.owner.origin.y);
		WriteCoord(MSG_ENTITY, this.owner.origin.z);
		send = true;
	}
	else if((to == this.owner) || (IS_SPEC(to) && (to.enemy == this.owner)) )
	{
		WriteByte(MSG_ENTITY, 0);
		send = true;
	}
	else { send = false; }

	return send;
}

.vector spawnpoint_prevorigin;
void spawnpoint_think(entity this)
{
	this.nextthink = time + 0.1;
	if(this.origin != this.spawnpoint_prevorigin)
	{
		this.spawnpoint_prevorigin = this.origin;
		this.SendFlags |= 1;
	}
}

void spawnpoint_use(entity this, entity actor, entity trigger)
{
	if(teamplay)
	if(have_team_spawns > 0)
	{
		this.team = actor.team;
		some_spawn_has_been_used = 1;
	}
	//LOG_INFO("spawnpoint was used!\n");
}

void relocate_spawnpoint(entity this)
{
    // nudge off the floor
    setorigin(this, this.origin + '0 0 1');

    tracebox(this.origin, PL_MIN_CONST, PL_MAX_CONST, this.origin, true, this);
    if (trace_startsolid)
    {
        vector o;
        o = this.origin;
        this.mins = PL_MIN_CONST;
        this.maxs = PL_MAX_CONST;
        if (!move_out_of_solid(this))
            objerror(this, "could not get out of solid at all!");
        LOG_INFO("^1NOTE: this map needs FIXING. Spawnpoint at ", vtos(o - '0 0 1'));
        LOG_INFO(" needs to be moved out of solid, e.g. by '", ftos(this.origin.x - o.x));
        LOG_INFO(" ", ftos(this.origin.y - o.y));
        LOG_INFO(" ", ftos(this.origin.z - o.z), "'\n");
        if (autocvar_g_spawnpoints_auto_move_out_of_solid)
        {
            if (!spawnpoint_nag)
                LOG_INFO("\{1}^1NOTE: this map needs FIXING (it contains spawnpoints in solid, see server log)\n");
            spawnpoint_nag = 1;
        }
        else
        {
            setorigin(this, o);
            this.mins = this.maxs = '0 0 0';
            objerror(this, "player spawn point in solid, mapper sucks!\n");
            return;
        }
    }

    this.use = spawnpoint_use;
    setthink(this, spawnpoint_think);
    this.nextthink = time + 0.5 + random() * 2; // shouldn't need it for a little second
    this.team_saved = this.team;
    if (!this.cnt)
        this.cnt = 1;

    if (have_team_spawns != 0)
        if (this.team)
            have_team_spawns = 1;
    have_team_spawns_forteam[this.team] = 1;

    if (autocvar_r_showbboxes)
    {
        // show where spawnpoints point at too
        makevectors(this.angles);
        entity e = new(info_player_foo);
        setorigin(e, this.origin + v_forward * 24);
        setsize(e, '-8 -8 -8', '8 8 8');
        e.solid = SOLID_TRIGGER;
    }

	// Don't show team spawns in non-team matches,
	// and don't show non-team spawns in team matches.
	// (Unless useallspawns is activated)
	if(
		!(
			( // if this passes, there is a DM spawn on a team match
				teamplay
				&& (this.team != NUM_TEAM_1)
				&& (this.team != NUM_TEAM_2)
				&& (this.team != NUM_TEAM_3)
				&& (this.team != NUM_TEAM_4)
			)
			||
			( // if this passes, there is a team spawn on a DM match
				!teamplay
				&&
				(
					(this.team == NUM_TEAM_1)
					|| (this.team == NUM_TEAM_2)
					|| (this.team == NUM_TEAM_3)
					|| (this.team == NUM_TEAM_4)
				)
			)
		)
		||
		autocvar_g_spawn_useallspawns
	)
	{ Net_LinkEntity(this, false, 0, SpawnPoint_Send); }
}

spawnfunc(info_player_survivor)
{
	spawnfunc_info_player_deathmatch(this);
}

spawnfunc(info_player_start)
{
	spawnfunc_info_player_deathmatch(this);
}

spawnfunc(info_player_deathmatch)
{
	this.classname = "info_player_deathmatch";
	IL_PUSH(g_spawnpoints, this);
	relocate_spawnpoint(this);
}

/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team one (Red).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team1)
{
	this.team = NUM_TEAM_1; // red
	spawnfunc_info_player_deathmatch(this);
}


/*QUAKED spawnfunc_info_player_team2 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team two (Blue).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team2)
{
	this.team = NUM_TEAM_2; // blue
	spawnfunc_info_player_deathmatch(this);
}

/*QUAKED spawnfunc_info_player_team3 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team three (Yellow).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team3)
{
	this.team = NUM_TEAM_3; // yellow
	spawnfunc_info_player_deathmatch(this);
}


/*QUAKED spawnfunc_info_player_team4 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team four (Purple).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team4)
{
	this.team = NUM_TEAM_4; // purple
	spawnfunc_info_player_deathmatch(this);
}

// Returns:
//   _x: prio (-1 if unusable)
//   _y: weight
vector Spawn_Score(entity this, entity spot, float mindist, float teamcheck)
{
	float shortest, thisdist;
	float prio;

	prio = 0;

	// filter out spots for the wrong team
	if(teamcheck >= 0)
		if(spot.team != teamcheck)
			return '-1 0 0';

	if(race_spawns)
		if(spot.target == "")
			return '-1 0 0';

	if(IS_REAL_CLIENT(this))
	{
		if(spot.restriction == 1)
			return '-1 0 0';
	}
	else
	{
		if(spot.restriction == 2)
			return '-1 0 0';
	}

	shortest = vlen(world.maxs - world.mins);
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, LAMBDA(
		thisdist = vlen(it.origin - spot.origin);
		if (thisdist < shortest)
			shortest = thisdist;
	));
	if(shortest > mindist)
		prio += SPAWN_PRIO_GOOD_DISTANCE;

	vector spawn_score = prio * '1 0 0' + shortest * '0 1 0';

	// filter out spots for assault
	if(spot.target != "")
	{
		int found = 0;
		for(entity targ = findchain(targetname, spot.target); targ; targ = targ.chain)
		{
			++found;
			if(targ.spawn_evalfunc)
			{
				spawn_score = targ.spawn_evalfunc(targ, this, spot, spawn_score);
				if(spawn_score.x < 0)
					return spawn_score;
			}
		}

		if(!found)
		{
			LOG_TRACE("WARNING: spawnpoint at ", vtos(spot.origin), " could not find its target ", spot.target);
			return '-1 0 0';
		}
	}

	MUTATOR_CALLHOOK(Spawn_Score, this, spot, spawn_score);
	spawn_score = M_ARGV(2, vector);
	return spawn_score;
}

void Spawn_ScoreAll(entity this, entity firstspot, float mindist, float teamcheck)
{
	entity spot;
	for(spot = firstspot; spot; spot = spot.chain)
		spot.spawnpoint_score = Spawn_Score(this, spot, mindist, teamcheck);
}

entity Spawn_FilterOutBadSpots(entity this, entity firstspot, float mindist, float teamcheck)
{
	entity spot, spotlist, spotlistend;

	spotlist = NULL;
	spotlistend = NULL;

	Spawn_ScoreAll(this, firstspot, mindist, teamcheck);

	for(spot = firstspot; spot; spot = spot.chain)
	{
		if(spot.spawnpoint_score.x >= 0) // spawning allowed here
		{
			if(spotlistend)
				spotlistend.chain = spot;
			spotlistend = spot;
			if(!spotlist)
				spotlist = spot;
		}
	}
	if(spotlistend)
		spotlistend.chain = NULL;

	return spotlist;
}

entity Spawn_WeightedPoint(entity firstspot, float lower, float upper, float exponent)
{
	// weight of a point: bound(lower, mindisttoplayer, upper)^exponent
	// multiplied by spot.cnt (useful if you distribute many spawnpoints in a small area)
	entity spot;

	RandomSelection_Init();
	for(spot = firstspot; spot; spot = spot.chain)
		RandomSelection_AddEnt(spot, (bound(lower, spot.spawnpoint_score.y, upper) ** exponent) * spot.cnt, (spot.spawnpoint_score.y >= lower) * 0.5 + spot.spawnpoint_score.x);

	return RandomSelection_chosen_ent;
}

/*
=============
SelectSpawnPoint

Finds a point to respawn
=============
*/
entity SelectSpawnPoint(entity this, bool anypoint)
{
	float teamcheck;
	entity spot, firstspot;

	spot = find(NULL, classname, "testplayerstart");
	if (spot)
		return spot;

	if(anypoint || autocvar_g_spawn_useallspawns)
		teamcheck = -1;
	else if(have_team_spawns > 0)
	{
		if(have_team_spawns_forteam[this.team] == 0)
		{
			// we request a spawn for a team, and we have team
			// spawns, but that team has no spawns?
			if(have_team_spawns_forteam[0])
				// try noteam spawns
				teamcheck = 0;
			else
				// if not, any spawn has to do
				teamcheck = -1;
		}
		else
			teamcheck = this.team; // MUST be team
	}
	else if(have_team_spawns == 0 && have_team_spawns_forteam[0])
		teamcheck = 0; // MUST be noteam
	else
		teamcheck = -1;
		// if we get here, we either require team spawns but have none, or we require non-team spawns and have none; use any spawn then


	// get the entire list of spots
	firstspot = findchain(classname, "info_player_deathmatch");
	// filter out the bad ones
	// (note this returns the original list if none survived)
	if(anypoint)
	{
		spot = Spawn_WeightedPoint(firstspot, 1, 1, 1);
	}
	else
	{
		firstspot = Spawn_FilterOutBadSpots(this, firstspot, 100, teamcheck);

		// there is 50/50 chance of choosing a random spot or the furthest spot
		// (this means that roughly every other spawn will be furthest, so you
		// usually won't get fragged at spawn twice in a row)
		if (random() > autocvar_g_spawn_furthest)
			spot = Spawn_WeightedPoint(firstspot, 1, 1, 1);
		else
			spot = Spawn_WeightedPoint(firstspot, 1, 5000, 5); // chooses a far far away spawnpoint
	}

	if (!spot)
	{
		if(autocvar_spawn_debug)
			GotoNextMap(0);
		else
		{
			if(some_spawn_has_been_used)
				return NULL; // team can't spawn any more, because of actions of other team
			else
				error("Cannot find a spawn point - please fix the map!");
		}
	}

	return spot;
}
