#include "scores_rules.qh"

#include "client.qh"
#include "scores.qh"

int ScoreRules_teams;

void CheckAllowedTeams (entity for_whom);

int NumTeams(int teams)
{
	return boolean(teams & BIT(0)) + boolean(teams & BIT(1)) + boolean(teams & BIT(2)) + boolean(teams & BIT(3));
}

int AvailableTeams()
{
	return NumTeams(ScoreRules_teams);
	// NOTE: this method is unreliable, as forced teams set the c* globals to weird values
	//return boolean(c1 >= 0) + boolean(c2 >= 0) + boolean(c3 >= 0) + boolean(c4 >= 0);
}

// NOTE: ST_constants may not be >= MAX_TEAMSCORE
// scores that should be in all modes:
void ScoreRules_basics(int teams, float sprio, float stprio, float score_enabled)
{
	FOREACH(Scores, true, {
		ScoreInfo_SetLabel_PlayerScore(it, "", 0);
    });
	for(int i = 0; i < MAX_TEAMSCORE; ++i)
		ScoreInfo_SetLabel_TeamScore(i, "", 0);

	ScoreRules_teams = teams;

	if(score_enabled)
		ScoreInfo_SetLabel_TeamScore  (ST_SCORE,        "score",     stprio);

	if (!INDEPENDENT_PLAYERS)
		ScoreInfo_SetLabel_PlayerScore(SP_KILLS,        "kills",     0);

	ScoreInfo_SetLabel_PlayerScore(SP_DEATHS,       "deaths",    SFL_LOWER_IS_BETTER);

	if (!INDEPENDENT_PLAYERS)
		ScoreInfo_SetLabel_PlayerScore(SP_SUICIDES,     "suicides",  SFL_LOWER_IS_BETTER);

	if(score_enabled)
		ScoreInfo_SetLabel_PlayerScore(SP_SCORE,        "score",     sprio);

	ScoreInfo_SetLabel_PlayerScore(SP_DMG, "dmg", 0);
	ScoreInfo_SetLabel_PlayerScore(SP_DMGTAKEN, "dmgtaken", SFL_LOWER_IS_BETTER);
	ScoreInfo_SetLabel_PlayerScore(SP_ELO, "elo", 0);
}
void ScoreRules_basics_end()
{
	ScoreInfo_Init(ScoreRules_teams);
}
void ScoreRules_generic()
{
	if(teamplay)
	{
		CheckAllowedTeams(NULL);
		int teams = 0;
		if(c1 >= 0) teams |= BIT(0);
		if(c2 >= 0) teams |= BIT(1);
		if(c3 >= 0) teams |= BIT(2);
		if(c4 >= 0) teams |= BIT(3);
		ScoreRules_basics(teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, true);
	}
	else
		ScoreRules_basics(0, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, true);
	ScoreRules_basics_end();
}
