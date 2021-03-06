#include "teamplay.qh"

#include "client.qh"
#include "race.qh"
#include "scores.qh"
#include "scores_rules.qh"

#include "bot/api.qh"

#include "command/vote.qh"

#include "mutators/_mod.qh"

#include "../common/deathtypes/all.qh"
#include "../common/gamemodes/_mod.qh"
#include "../common/teams.qh"

void TeamchangeFrags(entity e)
{
	PlayerScore_Clear(e);
}

void LogTeamchange(float player_id, float team_number, float type)
{
	if(!autocvar_sv_eventlog)
		return;

	if(player_id < 1)
		return;

	GameLogEcho(strcat(":team:", ftos(player_id), ":", ftos(team_number), ":", ftos(type)));
}

void default_delayedinit(entity this)
{
	if(!scores_initialized)
		ScoreRules_generic();
}

void ActivateTeamplay()
{
	serverflags |= SERVERFLAG_TEAMPLAY;
	teamplay = 1;
	cvar_set("teamplay", "2");  // DP needs this for sending proper getstatus replies.
}

void InitGameplayMode()
{
	VoteReset();

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	world.mins = mi_min;
	world.maxs = mi_max;
	// currently, NetRadiant's limit is 131072 qu for each side
	// distance from one corner of a 131072qu cube to the opposite corner is approx. 227023 qu
	// set the distance according to map size but don't go over the limit to avoid issues with float precision
	// in case somebody makes extremely large maps
	max_shot_distance = min(230000, vlen(world.maxs - world.mins));

	MapInfo_LoadMapSettings(mapname);
	serverflags &= ~SERVERFLAG_TEAMPLAY;
	teamplay = 0;
	cvar_set("teamplay", "0");  // DP needs this for sending proper getstatus replies.

	if (!cvar_value_issafe(world.fog))
	{
		LOG_INFO("The current map contains a potentially harmful fog setting, ignored\n");
		world.fog = string_null;
	}
	if(MapInfo_Map_fog != "")
		if(MapInfo_Map_fog == "none")
			world.fog = string_null;
		else
			world.fog = strzone(MapInfo_Map_fog);
	clientstuff = strzone(MapInfo_Map_clientstuff);

	MapInfo_ClearTemps();

	gamemode_name = MapInfo_Type_ToText(MapInfo_LoadedGametype);

	cache_mutatormsg = strzone("");
	cache_lastmutatormsg = strzone("");

	InitializeEntity(NULL, default_delayedinit, INITPRIO_GAMETYPE_FALLBACK);
}

string GetClientVersionMessage(entity this)
{
	if (this.version_mismatch) {
		if(this.version < autocvar_gameversion) {
			return strcat("This is Super Mechanical Bros ", autocvar_g_xonoticversion,
				"\n^3Your client version is outdated.\n\n\n### YOU WON'T BE ABLE TO PLAY ON THIS SERVER ###\n\n\nPlease update!!!^8");
		} else {
			return strcat("This is Super Mechanical Bros ", autocvar_g_xonoticversion,
				"\n^3This server is using an outdated Super Mechanical Bros version.\n\n\n ### THIS SERVER IS INCOMPATIBLE AND THUS YOU CANNOT JOIN ###.^8");
		}
	} else {
		return strcat("Welcome to Super Mechanical Bros ", autocvar_g_xonoticversion);
	}
}

string getwelcomemessage(entity this)
{
	MUTATOR_CALLHOOK(BuildMutatorsPrettyString, "");
	string modifications = M_ARGV(0, string);

	if(g_weaponarena)
	{
		modifications = strcat(modifications, ", ", g_weaponarena_list, " Arena");
	}
	else if(cvar("g_balance_blaster_weaponstartoverride") == 0)
		modifications = strcat(modifications, ", No start weapons");
	if(cvar("sv_gravity") < stof(cvar_defstring("sv_gravity")))
		modifications = strcat(modifications, ", Low gravity");
	if(g_weapon_stay && !g_cts)
		modifications = strcat(modifications, ", Weapons stay");
	if(g_jetpack)
		modifications = strcat(modifications, ", Jet pack");
	if(autocvar_g_powerups == 0)
		modifications = strcat(modifications, ", No powerups");
	if(autocvar_g_powerups > 0)
		modifications = strcat(modifications, ", Powerups");
	modifications = substring(modifications, 2, strlen(modifications) - 2);

	string versionmessage = GetClientVersionMessage(this);
	string s = strcat(versionmessage, "^8\n^8\nmatch type is ^1", gamemode_name, "^8\n");

	if(modifications != "")
		s = strcat(s, "^8\nactive modifications: ^3", modifications, "^8\n");

	if(cache_lastmutatormsg != autocvar_g_mutatormsg)
	{
		if(cache_lastmutatormsg)
			strunzone(cache_lastmutatormsg);
		if(cache_mutatormsg)
			strunzone(cache_mutatormsg);
		cache_lastmutatormsg = strzone(autocvar_g_mutatormsg);
		cache_mutatormsg = strzone(cache_lastmutatormsg);
	}

	if (cache_mutatormsg != "") {
		s = strcat(s, "\n\n^8special gameplay tips: ^7", cache_mutatormsg);
	}

	string mutator_msg = "";
	MUTATOR_CALLHOOK(BuildGameplayTipsString, mutator_msg);
	mutator_msg = M_ARGV(0, string);

	s = strcat(s, mutator_msg); // trust that the mutator will do proper formatting

	string motd = autocvar_sv_motd;
	if (motd != "") {
		s = strcat(s, "\n\n^8MOTD: ^7", strreplace("\\n", "\n", motd));
	}
	return s;
}

void setcolor(entity this, int clr)
{
#if 0
	this.clientcolors = clr;
	this.team = (clr & 15) + 1;
#else
	builtin_setcolor(this, clr);
#endif
}

void SetPlayerColors(entity pl, float _color)
{
	/*string s;
	s = ftos(cl);
	stuffcmd(pl, strcat("color ", s, " ", s, "\n")  );
	pl.team = cl + 1;
	//pl.clientcolors = pl.clientcolors - (pl.clientcolors & 15) + cl;
	pl.clientcolors = 16*cl + cl;*/

	float pants, shirt;
	pants = _color & 0x0F;
	shirt = _color & 0xF0;


	if(teamplay) {
		setcolor(pl, 16*pants + pants);
	} else {
		setcolor(pl, shirt + pants);
	}
}

void SetPlayerTeam(entity pl, float t, float s, float noprint)
{
	float _color;

	if(t == 4)
		_color = NUM_TEAM_4 - 1;
	else if(t == 3)
		_color = NUM_TEAM_3 - 1;
	else if(t == 2)
		_color = NUM_TEAM_2 - 1;
	else
		_color = NUM_TEAM_1 - 1;

	SetPlayerColors(pl,_color);

	if(t != s) {
		LogTeamchange(pl.playerid, pl.team, 3);  // log manual team join

		if(!noprint)
			bprint(playername(pl, false), "^7 has changed from ", Team_NumberToColoredFullName(s), "^7 to ", Team_NumberToColoredFullName(t), "\n");
	}

}

// set c1...c4 to show what teams are allowed
void CheckAllowedTeams (entity for_whom)
{
	int teams_mask = 0;

	c1 = c2 = c3 = c4 = -1;
	cb1 = cb2 = cb3 = cb4 = 0;

	string teament_name = string_null;

	bool mutator_returnvalue = MUTATOR_CALLHOOK(CheckAllowedTeams, teams_mask, teament_name, for_whom);
	teams_mask = M_ARGV(0, float);
	teament_name = M_ARGV(1, string);

	if(!mutator_returnvalue)
	{
		if(teams_mask & BIT(0)) c1 = 0;
		if(teams_mask & BIT(1)) c2 = 0;
		if(teams_mask & BIT(2)) c3 = 0;
		if(teams_mask & BIT(3)) c4 = 0;
	}

	// find out what teams are allowed if necessary
	if(teament_name)
	{
		entity head = find(NULL, classname, teament_name);
		while(head)
		{
			switch(head.team)
			{
				case NUM_TEAM_1: c1 = 0; break;
				case NUM_TEAM_2: c2 = 0; break;
				case NUM_TEAM_3: c3 = 0; break;
				case NUM_TEAM_4: c4 = 0; break;
			}

			head = find(head, classname, teament_name);
		}
	}

	// TODO: Balance quantity of bots across > 2 teams when bot_vs_human is set (and remove next line)
	if(AvailableTeams() == 2)
	if(autocvar_bot_vs_human && for_whom)
	{
		if(autocvar_bot_vs_human > 0)
		{
			// find last team available

			if(IS_BOT_CLIENT(for_whom))
			{
				if(c4 >= 0) { c3 = c2 = c1 = -1; }
				else if(c3 >= 0) { c4 = c2 = c1 = -1; }
				else { c4 = c3 = c1 = -1; }
				// no further cases, we know at least 2 teams exist
			}
			else
			{
				if(c1 >= 0) { c2 = c3 = c4 = -1; }
				else if(c2 >= 0) { c1 = c3 = c4 = -1; }
				else { c1 = c2 = c4 = -1; }
				// no further cases, bots have one of the teams
			}
		}
		else
		{
			// find first team available

			if(IS_BOT_CLIENT(for_whom))
			{
				if(c1 >= 0) { c2 = c3 = c4 = -1; }
				else if(c2 >= 0) { c1 = c3 = c4 = -1; }
				else { c1 = c2 = c4 = -1; }
				// no further cases, we know at least 2 teams exist
			}
			else
			{
				if(c4 >= 0) { c3 = c2 = c1 = -1; }
				else if(c3 >= 0) { c4 = c2 = c1 = -1; }
				else { c4 = c3 = c1 = -1; }
				// no further cases, bots have one of the teams
			}
		}
	}

	if(!for_whom)
		return;

	// if player has a forced team, ONLY allow that one
	if(for_whom.team_forced == NUM_TEAM_1 && c1 >= 0)
		c2 = c3 = c4 = -1;
	else if(for_whom.team_forced == NUM_TEAM_2 && c2 >= 0)
		c1 = c3 = c4 = -1;
	else if(for_whom.team_forced == NUM_TEAM_3 && c3 >= 0)
		c1 = c2 = c4 = -1;
	else if(for_whom.team_forced == NUM_TEAM_4 && c4 >= 0)
		c1 = c2 = c3 = -1;
}

float PlayerValue(entity p)
{
	return 1;
	// FIXME: it always returns 1...
}

// c1...c4 should be set to -1 (not allowed) or 0 (allowed).
// teams that are allowed will now have their player counts stored in c1...c4
void GetTeamCounts(entity ignore)
{
	float value, bvalue;
	// now count how many players are on each team already

	// FIXME: also find and memorize the lowest-scoring bot on each team (in case players must be shuffled around)
	// also remember the lowest-scoring player

	FOREACH_CLIENT(true, LAMBDA(
		float t;
		if(IS_PLAYER(it))
			t = it.team;
		else if(it.team_forced > 0)
			t = it.team_forced; // reserve the spot
		else
			continue;
		if(it != ignore)// && it.netname != "")
		{
			value = PlayerValue(it);
			if(IS_BOT_CLIENT(it))
				bvalue = value;
			else
				bvalue = 0;
			if(t == NUM_TEAM_1)
			{
				if(c1 >= 0)
				{
					c1 = c1 + value;
					cb1 = cb1 + bvalue;
				}
			}
			if(t == NUM_TEAM_2)
			{
				if(c2 >= 0)
				{
					c2 = c2 + value;
					cb2 = cb2 + bvalue;
				}
			}
			if(t == NUM_TEAM_3)
			{
				if(c3 >= 0)
				{
					c3 = c3 + value;
					cb3 = cb3 + bvalue;
				}
			}
			if(t == NUM_TEAM_4)
			{
				if(c4 >= 0)
				{
					c4 = c4 + value;
					cb4 = cb4 + bvalue;
				}
			}
		}
	));

	// if the player who has a forced team has not joined yet, reserve the spot
	if(autocvar_g_campaign)
	{
		switch(autocvar_g_campaign_forceteam)
		{
			case 1: if(c1 == cb1) ++c1; break;
			case 2: if(c2 == cb2) ++c2; break;
			case 3: if(c3 == cb3) ++c3; break;
			case 4: if(c4 == cb4) ++c4; break;
		}
	}
}

float TeamSmallerEqThanTeam(float ta, float tb, entity e)
{
	// we assume that CheckAllowedTeams and GetTeamCounts have already been called
	float f;
	float ca = -1, cb = -1, cba = 0, cbb = 0, sa = 0, sb = 0;

	switch(ta)
	{
		case 1: ca = c1; cba = cb1; sa = team1_score; break;
		case 2: ca = c2; cba = cb2; sa = team2_score; break;
		case 3: ca = c3; cba = cb3; sa = team3_score; break;
		case 4: ca = c4; cba = cb4; sa = team4_score; break;
	}
	switch(tb)
	{
		case 1: cb = c1; cbb = cb1; sb = team1_score; break;
		case 2: cb = c2; cbb = cb2; sb = team2_score; break;
		case 3: cb = c3; cbb = cb3; sb = team3_score; break;
		case 4: cb = c4; cbb = cb4; sb = team4_score; break;
	}

	// invalid
	if(ca < 0 || cb < 0)
		return false;

	// equal
	if(ta == tb)
		return true;

	if(IS_REAL_CLIENT(e))
	{
		if(bots_would_leave)
		{
			ca -= cba * 0.999;
			cb -= cbb * 0.999;
		}
	}

	// keep teams alive (teams of size 0 always count as smaller, ignoring score)
	if(ca < 1)
		if(cb >= 1)
			return true;
	if(ca >= 1)
		if(cb < 1)
			return false;

	// first, normalize
	f = max(ca, cb, 1);
	ca /= f;
	cb /= f;
	f = max(sa, sb, 1);
	sa /= f;
	sb /= f;

	// the more we're at the end of the match, the more take scores into account
	f = bound(0, game_completion_ratio * autocvar_g_balance_teams_scorefactor, 1);
	ca += (sa - ca) * f;
	cb += (sb - cb) * f;

	return ca <= cb;
}

// returns # of smallest team (1, 2, 3, 4)
// NOTE: Assumes CheckAllowedTeams has already been called!
float FindSmallestTeam(entity pl, float ignore_pl)
{
	int totalteams = 0;
	int t = 1; // initialize with a random team?
	if(c4 >= 0) t = 4;
	if(c3 >= 0) t = 3;
	if(c2 >= 0) t = 2;
	if(c1 >= 0) t = 1;

	// find out what teams are available
	//CheckAllowedTeams();

	// make sure there are at least 2 teams to join
	if(c1 >= 0)
		totalteams = totalteams + 1;
	if(c2 >= 0)
		totalteams = totalteams + 1;
	if(c3 >= 0)
		totalteams = totalteams + 1;
	if(c4 >= 0)
		totalteams = totalteams + 1;

	if((autocvar_bot_vs_human || pl.team_forced > 0) && totalteams == 1)
		totalteams += 1;

	if(totalteams <= 1)
	{
		if(autocvar_g_campaign && pl && IS_REAL_CLIENT(pl))
			return 1; // special case for campaign and player joining
		else if(totalteams == 1) // single team
			LOG_TRACEF("Only 1 team available for %s, you may need to fix your map", MapInfo_Type_ToString(MapInfo_CurrentGametype()));
		else // no teams, major no no
			error(sprintf("No teams available for %s\n", MapInfo_Type_ToString(MapInfo_CurrentGametype())));
	}

	// count how many players are in each team
	if(ignore_pl)
		GetTeamCounts(pl);
	else
		GetTeamCounts(NULL);

	RandomSelection_Init();

	if(TeamSmallerEqThanTeam(1, t, pl))
		t = 1;
	if(TeamSmallerEqThanTeam(2, t, pl))
		t = 2;
	if(TeamSmallerEqThanTeam(3, t, pl))
		t = 3;
	if(TeamSmallerEqThanTeam(4, t, pl))
		t = 4;

	// now t is the minimum, or A minimum!
	if(t == 1 || TeamSmallerEqThanTeam(1, t, pl))
		RandomSelection_AddFloat(1, 1, 1);
	if(t == 2 || TeamSmallerEqThanTeam(2, t, pl))
		RandomSelection_AddFloat(2, 1, 1);
	if(t == 3 || TeamSmallerEqThanTeam(3, t, pl))
		RandomSelection_AddFloat(3, 1, 1);
	if(t == 4 || TeamSmallerEqThanTeam(4, t, pl))
		RandomSelection_AddFloat(4, 1, 1);

	return RandomSelection_chosen_float;
}

int JoinBestTeam(entity this, bool only_return_best, bool forcebestteam)
{
	float smallest, selectedteam;

	// don't join a team if we're not playing a team game
	if(!teamplay)
		return 0;

	// find out what teams are available
	CheckAllowedTeams(this);

	// if we don't care what team he ends up on, put him on whatever team he entered as.
	// if he's not on a valid team, then let other code put him on the smallest team
	if(!forcebestteam)
	{
		if(     c1 >= 0 && this.team == NUM_TEAM_1)
			selectedteam = this.team;
		else if(c2 >= 0 && this.team == NUM_TEAM_2)
			selectedteam = this.team;
		else if(c3 >= 0 && this.team == NUM_TEAM_3)
			selectedteam = this.team;
		else if(c4 >= 0 && this.team == NUM_TEAM_4)
			selectedteam = this.team;
		else
			selectedteam = -1;

		if(selectedteam > 0)
		{
			if(!only_return_best)
			{
				SetPlayerColors(this, selectedteam - 1);

				// when JoinBestTeam is called by client.qc/ClientKill_Now_TeamChange the players team is -1 and thus skipped
				// when JoinBestTeam is called by client.qc/ClientConnect the player_id is 0 the log attempt is rejected
				LogTeamchange(this.playerid, this.team, 99);
			}
			return selectedteam;
		}
		// otherwise end up on the smallest team (handled below)
	}

	smallest = FindSmallestTeam(this, true);

	if(!only_return_best && !this.bot_forced_team)
	{
		TeamchangeFrags(this);
		if(smallest == 1)
		{
			SetPlayerColors(this, NUM_TEAM_1 - 1);
		}
		else if(smallest == 2)
		{
			SetPlayerColors(this, NUM_TEAM_2 - 1);
		}
		else if(smallest == 3)
		{
			SetPlayerColors(this, NUM_TEAM_3 - 1);
		}
		else if(smallest == 4)
		{
			SetPlayerColors(this, NUM_TEAM_4 - 1);
		}
		else
		{
			error("smallest team: invalid team\n");
		}

		LogTeamchange(this.playerid, this.team, 2); // log auto join

		if(!IS_DEAD(this))
			Damage(this, this, this, 100000, DEATH_TEAMCHANGE.m_id, this.origin, '0 0 0');
	}

	return smallest;
}

void SV_ChangeTeam(entity this, float _color)
{
	float scolor, dcolor, steam, dteam; //, dbotcount, scount, dcount;

	// in normal deathmatch we can just apply the color and we're done
	if(!teamplay)
		SetPlayerColors(this, _color);

	if(!IS_CLIENT(this))
	{
		// since this is an engine function, and gamecode doesn't have any calls earlier than this, do the connecting message here
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_CONNECTING, this.netname);
		return;
	}

	if(!teamplay)
		return;

	scolor = this.clientcolors & 0x0F;
	dcolor = _color & 0x0F;

	if(scolor == NUM_TEAM_1 - 1)
		steam = 1;
	else if(scolor == NUM_TEAM_2 - 1)
		steam = 2;
	else if(scolor == NUM_TEAM_3 - 1)
		steam = 3;
	else // if(scolor == NUM_TEAM_4 - 1)
		steam = 4;
	if(dcolor == NUM_TEAM_1 - 1)
		dteam = 1;
	else if(dcolor == NUM_TEAM_2 - 1)
		dteam = 2;
	else if(dcolor == NUM_TEAM_3 - 1)
		dteam = 3;
	else // if(dcolor == NUM_TEAM_4 - 1)
		dteam = 4;

	CheckAllowedTeams(this);

	if(dteam == 1 && c1 < 0) dteam = 4;
	if(dteam == 4 && c4 < 0) dteam = 3;
	if(dteam == 3 && c3 < 0) dteam = 2;
	if(dteam == 2 && c2 < 0) dteam = 1;

	// not changing teams
	if(scolor == dcolor)
	{
		//bprint("same team change\n");
		SetPlayerTeam(this, dteam, steam, true);
		return;
	}

	if((autocvar_g_campaign) || (autocvar_g_changeteam_banned && this.wasplayer)) {
		Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_NOTALLOWED);
		return; // changing teams is not allowed
	}

	// autocvar_g_balance_teams_prevent_imbalance only makes sense if autocvar_g_balance_teams is on, as it makes the team selection dialog pointless
	if(autocvar_g_balance_teams && autocvar_g_balance_teams_prevent_imbalance)
	{
		GetTeamCounts(this);
		if(!TeamSmallerEqThanTeam(dteam, steam, this))
		{
			Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_LARGERTEAM);
			return;
		}
	}

//	bprint("allow change teams from ", ftos(steam), " to ", ftos(dteam), "\n");

	if(IS_PLAYER(this) && steam != dteam)
	{
		// reduce frags during a team change
		TeamchangeFrags(this);
	}

	MUTATOR_CALLHOOK(Player_ChangeTeam, this, steam, dteam);

	SetPlayerTeam(this, dteam, steam, !IS_CLIENT(this));

	if(IS_PLAYER(this) && steam != dteam)
	{
		// kill player when changing teams
		if(!IS_DEAD(this))
			Damage(this, this, this, 100000, DEATH_TEAMCHANGE.m_id, this.origin, '0 0 0');
	}
}

void ShufflePlayerOutOfTeam (float source_team)
{
	float smallestteam, smallestteam_count, steam;
	float lowest_bot_score, lowest_player_score;
	entity lowest_bot, lowest_player, selected;

	smallestteam = 0;
	smallestteam_count = 999999999;

	if(c1 >= 0 && c1 < smallestteam_count)
	{
		smallestteam = 1;
		smallestteam_count = c1;
	}
	if(c2 >= 0 && c2 < smallestteam_count)
	{
		smallestteam = 2;
		smallestteam_count = c2;
	}
	if(c3 >= 0 && c3 < smallestteam_count)
	{
		smallestteam = 3;
		smallestteam_count = c3;
	}
	if(c4 >= 0 && c4 < smallestteam_count)
	{
		smallestteam = 4;
		smallestteam_count = c4;
	}

	if(!smallestteam)
	{
		bprint("warning: no smallest team\n");
		return;
	}

	if(source_team == 1)
		steam = NUM_TEAM_1;
	else if(source_team == 2)
		steam = NUM_TEAM_2;
	else if(source_team == 3)
		steam = NUM_TEAM_3;
	else // if(source_team == 4)
		steam = NUM_TEAM_4;

	lowest_bot = NULL;
	lowest_bot_score = 999999999;
	lowest_player = NULL;
	lowest_player_score = 999999999;

	// find the lowest-scoring player & bot of that team
	FOREACH_CLIENT(IS_PLAYER(it) && it.team == steam, LAMBDA(
		if(it.isbot)
		{
			if(it.totalfrags < lowest_bot_score)
			{
				lowest_bot = it;
				lowest_bot_score = it.totalfrags;
			}
		}
		else
		{
			if(it.totalfrags < lowest_player_score)
			{
				lowest_player = it;
				lowest_player_score = it.totalfrags;
			}
		}
	));

	// prefers to move a bot...
	if(lowest_bot != NULL)
		selected = lowest_bot;
	// but it will move a player if it has to
	else
		selected = lowest_player;
	// don't do anything if it couldn't find anyone
	if(!selected)
	{
		bprint("warning: couldn't find a player to move from team\n");
		return;
	}

	// smallest team gains a member
	if(smallestteam == 1)
	{
		c1 = c1 + 1;
	}
	else if(smallestteam == 2)
	{
		c2 = c2 + 1;
	}
	else if(smallestteam == 3)
	{
		c3 = c3 + 1;
	}
	else if(smallestteam == 4)
	{
		c4 = c4 + 1;
	}
	else
	{
		bprint("warning: destination team invalid\n");
		return;
	}
	// source team loses a member
	if(source_team == 1)
	{
		c1 = c1 + 1;
	}
	else if(source_team == 2)
	{
		c2 = c2 + 2;
	}
	else if(source_team == 3)
	{
		c3 = c3 + 3;
	}
	else if(source_team == 4)
	{
		c4 = c4 + 4;
	}
	else
	{
		bprint("warning: source team invalid\n");
		return;
	}

	// move the player to the new team
	TeamchangeFrags(selected);
	SetPlayerTeam(selected, smallestteam, source_team, false);

	if(!IS_DEAD(selected))
		Damage(selected, selected, selected, 100000, DEATH_AUTOTEAMCHANGE.m_id, selected.origin, '0 0 0');
	Send_Notification(NOTIF_ONE, selected, MSG_CENTER, CENTER_DEATH_SELF_AUTOTEAMCHANGE, selected.team);
}
