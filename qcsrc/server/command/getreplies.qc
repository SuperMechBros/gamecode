#include "getreplies.qh"
#include <common/command/_mod.qh>
#include "getreplies.qh"

#include "../race.qh"

#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/mapinfo.qh>
#include <common/util.qh>

#include <common/monsters/_mod.qh>

// =========================================================
//  Reply messages for common commands, re-worked by Samual
//  Last updated: December 30th, 2011
// =========================================================

// These strings are set usually during init in g_world.qc,
// or also by some game modes or other functions manually,
// and their purpose is to output information to clients
// without using any extra processing time.

// See common.qc for their proper commands

string getrecords(int page)  // 50 records per page
{
	string s = "";

	MUTATOR_CALLHOOK(GetRecords, page, s);
	s = M_ARGV(1, string);

	MapInfo_ClearTemps();

	if (s == "" && page == 0) return "No records are available on this server.\n";
	else return s;
}

string getrankings()
{
	float t, i;
	string n, s, p, map;

	map = GetMapname();

	s = "";
	for (i = 1; i <= RANKINGS_CNT; ++i)
	{
		t = race_readTime(map, i);

		if (t == 0) continue;

		n = race_readName(map, i);
		p = count_ordinal(i);
		s = strcat(s, strpad(8, p), " ", strpad(-8, TIME_ENCODED_TOSTRING(t)), " ", n, "\n");
	}

	MapInfo_ClearTemps();

	if (s == "") return strcat("No records are available for the map: ", map, "\n");
	else return strcat("Records for ", map, ":\n", s);
}

string getladder()
{
	int i, j, k, uidcnt = 0, thiscnt;
	string s, temp_s, rr, myuid, thisuid;

	rr = (g_cts) ? CTS_RECORD : RACE_RECORD;

	for (k = 0; k < MapInfo_count; ++k)
	{
		if (MapInfo_Get_ByID(k))
		{
			for (i = 0; i <= LADDER_CNT; ++i) // i = 0 because it is the speed award
			{
				if (i == 0)                   // speed award
				{
					if (stof(db_get(ServerProgsDB, strcat(MapInfo_Map_bspname, rr, "speed/speed"))) == 0) continue;

					myuid = db_get(ServerProgsDB, strcat(MapInfo_Map_bspname, rr, "speed/crypto_idfp"));
				}
				else  // normal record, if it exists (else break)
				{
					if (race_readTime(MapInfo_Map_bspname, i) == 0) continue;

					myuid = race_readUID(MapInfo_Map_bspname, i);
				}

				// string s contains:
				// arg 0 = # of speed recs
				// arg 1 = # of 1st place recs
				// arg 2 = # of 2nd place recs
				// ... etc
				// LADDER_CNT+1 = total points

				temp_s = db_get(TemporaryDB, strcat("ladder", myuid));

				if (temp_s == "")
				{
					db_put(TemporaryDB, strcat("uid", ftos(uidcnt)), myuid);
					++uidcnt;

					for (j = 0; j <= LADDER_CNT + 1; ++j)
					{
						if (j != LADDER_CNT + 1) temp_s = strcat(temp_s, "0 ");
						else temp_s = strcat(temp_s, "0");
					}
				}

				tokenize_console(temp_s);
				s = "";

				if (i == 0)                                         // speed award
				{
					for (j = 0; j <= LADDER_CNT; ++j)               // loop over each arg in the string
					{
						if (j == 0)                                 // speed award
							s = strcat(s, ftos(stof(argv(j)) + 1)); // add 1 to speed rec count and write
						else s = strcat(s, " ", argv(j));           // just copy over everything else
					}
				}
				else  // record
				{
					for (j = 0; j <= LADDER_CNT; ++j)                    // loop over each arg in the string
					{
						if (j == 0) s = strcat(s, argv(j));              // speed award, dont prefix with " "
						else if (j == i)                                 // wanted rec!
							s = strcat(s, " ", ftos(stof(argv(j)) + 1)); // update argv(j)
						else s = strcat(s, " ", argv(j));                // just copy over everything else
					}
				}

				// total points are (by default) calculated like this:
				// speedrec = floor(100 / 10) = 10 points
				// 1st place = floor(100 / 1) = 100 points
				// 2nd place = floor(100 / 2) = 50 points
				// 3rd place = floor(100 / 3) = 33 points
				// 4th place = floor(100 / 4) = 25 points
				// 5th place = floor(100 / 5) = 20 points
				// ... etc

				if (i == 0) s = strcat(s, " ", ftos(stof(argv(LADDER_CNT + 1)) + LADDER_FIRSTPOINT / 10)); // speed award, add LADDER_FIRSTPOINT / 10 points
				else s = strcat(s, " ", ftos(stof(argv(LADDER_CNT + 1)) + floor(LADDER_FIRSTPOINT / i)));  // record, add LADDER_FIRSTPOINT / i points

				db_put(TemporaryDB, strcat("ladder", myuid), s);
			}
		}
	}

	for (i = 0; i <= uidcnt; ++i)  // for each known uid
	{
		thisuid = db_get(TemporaryDB, strcat("uid", ftos(i)));
		temp_s = db_get(TemporaryDB, strcat("ladder", thisuid));
		tokenize_console(temp_s);
		thiscnt = stof(argv(LADDER_CNT + 1));

		if (thiscnt > top_scores[LADDER_SIZE - 1])
		{
			for (j = 0; j < LADDER_SIZE; ++j)  // for each place in ladder
			{
				if (thiscnt > top_scores[j])
				{
					for (k = LADDER_SIZE - 1; k >= j; --k)
					{
						top_uids[k] = top_uids[k - 1];
						top_scores[k] = top_scores[k - 1];
					}

					top_uids[j] = thisuid;
					top_scores[j] = thiscnt;
					break;
				}
			}
		}
	}

	s = "^3-----------------------\n\n";

	s = strcat(s, "Pos ^3|");
	s = strcat(s, " ^7Total  ^3|");

	for (i = 1; i <= LADDER_CNT; ++i)
		s = strcat(s, " ^7", count_ordinal(i), " ^3|");
	s = strcat(s, " ^7Speed awards ^3| ^7Name");
	s = strcat(s, "\n^3----+--------");

	for (i = 1; i <= min(9, LADDER_CNT); ++i)
		s = strcat(s, "+-----");
#if LADDER_CNT > 9
		for (i = 1; i <= LADDER_CNT - 9; ++i)
			s = strcat(s, "+------");
#endif

	s = strcat(s, "+--------------+--------------------\n");

	for (i = 0; i < LADDER_SIZE; ++i)
	{
		temp_s = db_get(TemporaryDB, strcat("ladder", top_uids[i]));
		tokenize_console(temp_s);

		if (argv(LADDER_CNT + 1) == "")                           // total is 0, skip
			continue;

		s = strcat(s, strpad(4, count_ordinal(i + 1)), "^3| ^7"); // pos
		s = strcat(s, strpad(7, argv(LADDER_CNT + 1)), "^3| ^7"); // total

		for (j = 1; j <= min(9, LADDER_CNT); ++j)
			s = strcat(s, strpad(4, argv(j)), "^3| ^7");          // 1st, 2nd, 3rd etc cnt

#if LADDER_CNT > 9
			for (j = 10; j <= LADDER_CNT; ++j)
				s = strcat(s, strpad(4, argv(j)), " ^3| ^7"); // 1st, 2nd, 3rd etc cnt
#endif

		s = strcat(s, strpad(13, argv(0)), "^3| ^7");         // speed award cnt
		s = strcat(s, uid2name(top_uids[i]), "\n");           // name
	}

	MapInfo_ClearTemps();

	if (s == "") return "No ladder on this server!\n";
	else return strcat("Top ", ftos(LADDER_SIZE), " ladder rankings:\n", s);
}

string getmaplist()
{
	string maplist = "", col;
	int i, argc;

	argc = tokenize_console(autocvar_g_maplist);
	for (i = 0; i < argc; ++i)
	{
		if (MapInfo_CheckMap(argv(i)))
		{
			if (i % 2) col = "^2"; else col = "^3";
			maplist = sprintf("%s%s%s ", maplist, col, argv(i));
		}
	}

	MapInfo_ClearTemps();
	return sprintf("^7Maps in list: %s\n", maplist);
}

const int LSMAPS_MAX = 250;
string getlsmaps()
{
	string lsmaps = "", col;
	bool newmaps = false;
	int added = 0;

	for (int i = 0; i < MapInfo_count; ++i)
	{
		if ((MapInfo_Get_ByID(i)) && !(MapInfo_Map_flags & MapInfo_ForbiddenFlags()))
		{
			++added;

			if(added > LSMAPS_MAX)
				continue; // we still get the added count, but skip the actual processing

			// todo: Check by play count of maps for other game types?
			if (
			    (g_race && !stof(db_get(ServerProgsDB, strcat(MapInfo_Map_bspname, RACE_RECORD, "time"))))
			    ||
			    (g_cts && !stof(db_get(ServerProgsDB, strcat(MapInfo_Map_bspname, CTS_RECORD, "time"))))
			   )
			{
				newmaps = true;
				if (i % 2) col = "^4*"; else col = "^5*";
			}
			else
			{
				if (i % 2) col = "^2"; else col = "^3";
			}

			lsmaps = sprintf("%s%s%s ", lsmaps, col, MapInfo_Map_bspname);
		}
	}

	if(added > LSMAPS_MAX)
		lsmaps = sprintf("%s^7(%d not listed)", lsmaps, added - LSMAPS_MAX);

	MapInfo_ClearTemps();
	return sprintf("^7Maps available (%d)%s: %s\n", added, (newmaps ? " (New maps have asterisks marked in blue)" : ""), lsmaps);
}

string getmonsterlist()
{
	string monsterlist = "";

	FOREACH(Monsters, it != MON_Null && !(it.spawnflags & MON_FLAG_HIDDEN),
	{
		string col = ((i % 2) ? "^2" : "^3");
		monsterlist = sprintf("%s%s%s ", monsterlist, col, it.netname);
	});

	return sprintf("^7Monsters available: %s\n", monsterlist);
}
