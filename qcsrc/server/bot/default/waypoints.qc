#include "waypoints.qh"

#include "cvars.qh"

#include "bot.qh"
#include "navigation.qh"

#include <common/state.qh>

#include "../../antilag.qh"

#include <common/constants.qh>
#include <common/net_linked.qh>

#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>

void waypoint_setupmodel(entity wp)
{
	if (autocvar_g_waypointeditor)
	{
		// TODO: add some sort of visible box in edit mode for box waypoints
		vector m1 = wp.mins;
		vector m2 = wp.maxs;
		setmodel(wp, MDL_WAYPOINT);
		setsize(wp, m1, m2);
		wp.effects = EF_LOWPRECISION;
		if (wp.wpflags & WAYPOINTFLAG_ITEM)
			wp.colormod = '1 0 0';
		else if (wp.wpflags & WAYPOINTFLAG_GENERATED)
			wp.colormod = '1 1 0';
		else
			wp.colormod = '1 1 1';
	}
	else
		wp.model = "";
}

// create a new spawnfunc_waypoint and automatically link it to other waypoints, and link
// them back to it as well
// (suitable for spawnfunc_waypoint editor)
entity waypoint_spawn(vector m1, vector m2, float f)
{
	if(!(f & WAYPOINTFLAG_PERSONAL))
	{
		IL_EACH(g_waypoints, boxesoverlap(m1, m2, it.absmin, it.absmax),
		{
			return it;
		});
	}

	entity w = new(waypoint);
	IL_PUSH(g_waypoints, w);
	w.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	w.wpflags = f;
	w.solid = SOLID_TRIGGER;
	setorigin(w, (m1 + m2) * 0.5);
	setsize(w, m1 - w.origin, m2 - w.origin);
	if (w.size)
		w.wpisbox = true;

	if(!w.wpisbox)
	{
		setsize(w, PL_MIN_CONST - '1 1 0', PL_MAX_CONST + '1 1 0');
		if(!move_out_of_solid(w))
		{
			if(!(f & WAYPOINTFLAG_GENERATED))
			{
				LOG_TRACE("Killed a waypoint that was stuck in solid at ", vtos(w.origin));
				delete(w);
				return NULL;
			}
			else
			{
				if(autocvar_developer)
				{
					LOG_INFO("A generated waypoint is stuck in solid at ", vtos(w.origin), "\n");
					backtrace("Waypoint stuck");
				}
			}
		}
		setsize(w, '0 0 0', '0 0 0');
	}

	waypoint_clearlinks(w);
	//waypoint_schedulerelink(w);

	waypoint_setupmodel(w);

	return w;
}

bool waypoint_islinked(entity from, entity to)
{
	if (from.wp00 == to) return true;if (from.wp01 == to) return true;if (from.wp02 == to) return true;if (from.wp03 == to) return true;
	if (from.wp04 == to) return true;if (from.wp05 == to) return true;if (from.wp06 == to) return true;if (from.wp07 == to) return true;
	if (from.wp08 == to) return true;if (from.wp09 == to) return true;if (from.wp10 == to) return true;if (from.wp11 == to) return true;
	if (from.wp12 == to) return true;if (from.wp13 == to) return true;if (from.wp14 == to) return true;if (from.wp15 == to) return true;
	if (from.wp16 == to) return true;if (from.wp17 == to) return true;if (from.wp18 == to) return true;if (from.wp19 == to) return true;
	if (from.wp20 == to) return true;if (from.wp21 == to) return true;if (from.wp22 == to) return true;if (from.wp23 == to) return true;
	if (from.wp24 == to) return true;if (from.wp25 == to) return true;if (from.wp26 == to) return true;if (from.wp27 == to) return true;
	if (from.wp28 == to) return true;if (from.wp29 == to) return true;if (from.wp30 == to) return true;if (from.wp31 == to) return true;
	return false;
}

// add a new link to the spawnfunc_waypoint, replacing the furthest link it already has
void waypoint_addlink(entity from, entity to)
{
	float c;

	if (from == to)
		return;
	if (from.wpflags & WAYPOINTFLAG_NORELINK)
		return;

	if (waypoint_islinked(from, to))
		return;

	if (to.wpisbox || from.wpisbox)
	{
		// if either is a box we have to find the nearest points on them to
		// calculate the distance properly
		vector v1, v2, m1, m2;
		v1 = from.origin;
		m1 = to.absmin;
		m2 = to.absmax;
		v1_x = bound(m1_x, v1_x, m2_x);
		v1_y = bound(m1_y, v1_y, m2_y);
		v1_z = bound(m1_z, v1_z, m2_z);
		v2 = to.origin;
		m1 = from.absmin;
		m2 = from.absmax;
		v2_x = bound(m1_x, v2_x, m2_x);
		v2_y = bound(m1_y, v2_y, m2_y);
		v2_z = bound(m1_z, v2_z, m2_z);
		v2 = to.origin;
		c = vlen(v2 - v1);
	}
	else
		c = vlen(to.origin - from.origin);

	if (from.wp31mincost < c) return;
	if (from.wp30mincost < c) {from.wp31 = to;from.wp31mincost = c;return;} from.wp31 = from.wp30;from.wp31mincost = from.wp30mincost;
	if (from.wp29mincost < c) {from.wp30 = to;from.wp30mincost = c;return;} from.wp30 = from.wp29;from.wp30mincost = from.wp29mincost;
	if (from.wp28mincost < c) {from.wp29 = to;from.wp29mincost = c;return;} from.wp29 = from.wp28;from.wp29mincost = from.wp28mincost;
	if (from.wp27mincost < c) {from.wp28 = to;from.wp28mincost = c;return;} from.wp28 = from.wp27;from.wp28mincost = from.wp27mincost;
	if (from.wp26mincost < c) {from.wp27 = to;from.wp27mincost = c;return;} from.wp27 = from.wp26;from.wp27mincost = from.wp26mincost;
	if (from.wp25mincost < c) {from.wp26 = to;from.wp26mincost = c;return;} from.wp26 = from.wp25;from.wp26mincost = from.wp25mincost;
	if (from.wp24mincost < c) {from.wp25 = to;from.wp25mincost = c;return;} from.wp25 = from.wp24;from.wp25mincost = from.wp24mincost;
	if (from.wp23mincost < c) {from.wp24 = to;from.wp24mincost = c;return;} from.wp24 = from.wp23;from.wp24mincost = from.wp23mincost;
	if (from.wp22mincost < c) {from.wp23 = to;from.wp23mincost = c;return;} from.wp23 = from.wp22;from.wp23mincost = from.wp22mincost;
	if (from.wp21mincost < c) {from.wp22 = to;from.wp22mincost = c;return;} from.wp22 = from.wp21;from.wp22mincost = from.wp21mincost;
	if (from.wp20mincost < c) {from.wp21 = to;from.wp21mincost = c;return;} from.wp21 = from.wp20;from.wp21mincost = from.wp20mincost;
	if (from.wp19mincost < c) {from.wp20 = to;from.wp20mincost = c;return;} from.wp20 = from.wp19;from.wp20mincost = from.wp19mincost;
	if (from.wp18mincost < c) {from.wp19 = to;from.wp19mincost = c;return;} from.wp19 = from.wp18;from.wp19mincost = from.wp18mincost;
	if (from.wp17mincost < c) {from.wp18 = to;from.wp18mincost = c;return;} from.wp18 = from.wp17;from.wp18mincost = from.wp17mincost;
	if (from.wp16mincost < c) {from.wp17 = to;from.wp17mincost = c;return;} from.wp17 = from.wp16;from.wp17mincost = from.wp16mincost;
	if (from.wp15mincost < c) {from.wp16 = to;from.wp16mincost = c;return;} from.wp16 = from.wp15;from.wp16mincost = from.wp15mincost;
	if (from.wp14mincost < c) {from.wp15 = to;from.wp15mincost = c;return;} from.wp15 = from.wp14;from.wp15mincost = from.wp14mincost;
	if (from.wp13mincost < c) {from.wp14 = to;from.wp14mincost = c;return;} from.wp14 = from.wp13;from.wp14mincost = from.wp13mincost;
	if (from.wp12mincost < c) {from.wp13 = to;from.wp13mincost = c;return;} from.wp13 = from.wp12;from.wp13mincost = from.wp12mincost;
	if (from.wp11mincost < c) {from.wp12 = to;from.wp12mincost = c;return;} from.wp12 = from.wp11;from.wp12mincost = from.wp11mincost;
	if (from.wp10mincost < c) {from.wp11 = to;from.wp11mincost = c;return;} from.wp11 = from.wp10;from.wp11mincost = from.wp10mincost;
	if (from.wp09mincost < c) {from.wp10 = to;from.wp10mincost = c;return;} from.wp10 = from.wp09;from.wp10mincost = from.wp09mincost;
	if (from.wp08mincost < c) {from.wp09 = to;from.wp09mincost = c;return;} from.wp09 = from.wp08;from.wp09mincost = from.wp08mincost;
	if (from.wp07mincost < c) {from.wp08 = to;from.wp08mincost = c;return;} from.wp08 = from.wp07;from.wp08mincost = from.wp07mincost;
	if (from.wp06mincost < c) {from.wp07 = to;from.wp07mincost = c;return;} from.wp07 = from.wp06;from.wp07mincost = from.wp06mincost;
	if (from.wp05mincost < c) {from.wp06 = to;from.wp06mincost = c;return;} from.wp06 = from.wp05;from.wp06mincost = from.wp05mincost;
	if (from.wp04mincost < c) {from.wp05 = to;from.wp05mincost = c;return;} from.wp05 = from.wp04;from.wp05mincost = from.wp04mincost;
	if (from.wp03mincost < c) {from.wp04 = to;from.wp04mincost = c;return;} from.wp04 = from.wp03;from.wp04mincost = from.wp03mincost;
	if (from.wp02mincost < c) {from.wp03 = to;from.wp03mincost = c;return;} from.wp03 = from.wp02;from.wp03mincost = from.wp02mincost;
	if (from.wp01mincost < c) {from.wp02 = to;from.wp02mincost = c;return;} from.wp02 = from.wp01;from.wp02mincost = from.wp01mincost;
	if (from.wp00mincost < c) {from.wp01 = to;from.wp01mincost = c;return;} from.wp01 = from.wp00;from.wp01mincost = from.wp00mincost;
	from.wp00 = to;from.wp00mincost = c;return;
}

// relink this spawnfunc_waypoint
// (precompile a list of all reachable waypoints from this spawnfunc_waypoint)
// (SLOW!)
void waypoint_think(entity this)
{
	vector sv, sm1, sm2, ev, em1, em2, dv;

	bot_calculate_stepheightvec();

	bot_navigation_movemode = ((autocvar_bot_navigation_ignoreplayers) ? MOVE_NOMONSTERS : MOVE_NORMAL);

	//dprint("waypoint_think wpisbox = ", ftos(this.wpisbox), "\n");
	sm1 = this.origin + this.mins;
	sm2 = this.origin + this.maxs;
	IL_EACH(g_waypoints, true,
	{
		if (boxesoverlap(this.absmin, this.absmax, it.absmin, it.absmax))
		{
			waypoint_addlink(this, it);
			waypoint_addlink(it, this);
		}
		else
		{
			++relink_total;
			if(!checkpvs(this.origin, it))
			{
				++relink_pvsculled;
				continue;
			}
			sv = it.origin;
			sv.x = bound(sm1_x, sv.x, sm2_x);
			sv.y = bound(sm1_y, sv.y, sm2_y);
			sv.z = bound(sm1_z, sv.z, sm2_z);
			ev = this.origin;
			em1 = it.origin + it.mins;
			em2 = it.origin + it.maxs;
			ev.x = bound(em1_x, ev.x, em2_x);
			ev.y = bound(em1_y, ev.y, em2_y);
			ev.z = bound(em1_z, ev.z, em2_z);
			dv = ev - sv;
			dv.z = 0;
			if(vdist(dv, >=, 1050)) // max search distance in XY
			{
				++relink_lengthculled;
				continue;
			}
			navigation_testtracewalk = 0;
			if (!this.wpisbox)
			{
				tracebox(sv - PL_MIN_CONST.z * '0 0 1', PL_MIN_CONST, PL_MAX_CONST, sv, false, this);
				if (!trace_startsolid)
				{
					//dprint("sv deviation", vtos(trace_endpos - sv), "\n");
					sv = trace_endpos + '0 0 1';
				}
			}
			if (!it.wpisbox)
			{
				tracebox(ev - PL_MIN_CONST.z * '0 0 1', PL_MIN_CONST, PL_MAX_CONST, ev, false, it);
				if (!trace_startsolid)
				{
					//dprint("ev deviation", vtos(trace_endpos - ev), "\n");
					ev = trace_endpos + '0 0 1';
				}
			}
			//traceline(this.origin, it.origin, false, NULL);
			//if (trace_fraction == 1)
			if (!this.wpisbox && tracewalk(this, sv, PL_MIN_CONST, PL_MAX_CONST, ev, MOVE_NOMONSTERS))
				waypoint_addlink(this, it);
			else
				relink_walkculled += 0.5;
			if (!it.wpisbox && tracewalk(it, ev, PL_MIN_CONST, PL_MAX_CONST, sv, MOVE_NOMONSTERS))
				waypoint_addlink(it, this);
			else
				relink_walkculled += 0.5;
		}
	});
	navigation_testtracewalk = 0;
	this.wplinked = true;
}

void waypoint_clearlinks(entity wp)
{
	// clear links to other waypoints
	float f = 10000000;
	wp.wp00 = wp.wp01 = wp.wp02 = wp.wp03 = wp.wp04 = wp.wp05 = wp.wp06 = wp.wp07 = NULL;
	wp.wp08 = wp.wp09 = wp.wp10 = wp.wp11 = wp.wp12 = wp.wp13 = wp.wp14 = wp.wp15 = NULL;
	wp.wp16 = wp.wp17 = wp.wp18 = wp.wp19 = wp.wp20 = wp.wp21 = wp.wp22 = wp.wp23 = NULL;
	wp.wp24 = wp.wp25 = wp.wp26 = wp.wp27 = wp.wp28 = wp.wp29 = wp.wp30 = wp.wp31 = NULL;

	wp.wp00mincost = wp.wp01mincost = wp.wp02mincost = wp.wp03mincost = wp.wp04mincost = wp.wp05mincost = wp.wp06mincost = wp.wp07mincost = f;
	wp.wp08mincost = wp.wp09mincost = wp.wp10mincost = wp.wp11mincost = wp.wp12mincost = wp.wp13mincost = wp.wp14mincost = wp.wp15mincost = f;
	wp.wp16mincost = wp.wp17mincost = wp.wp18mincost = wp.wp19mincost = wp.wp20mincost = wp.wp21mincost = wp.wp22mincost = wp.wp23mincost = f;
	wp.wp24mincost = wp.wp25mincost = wp.wp26mincost = wp.wp27mincost = wp.wp28mincost = wp.wp29mincost = wp.wp30mincost = wp.wp31mincost = f;

	wp.wplinked = false;
}

// tell a spawnfunc_waypoint to relink
void waypoint_schedulerelink(entity wp)
{
	if (wp == NULL)
		return;

	waypoint_setupmodel(wp);
	wp.wpisbox = vdist(wp.size, >, 0);
	wp.enemy = NULL;
	if (!(wp.wpflags & WAYPOINTFLAG_PERSONAL))
		wp.owner = NULL;
	if (!(wp.wpflags & WAYPOINTFLAG_NORELINK))
		waypoint_clearlinks(wp);
	// schedule an actual relink on next frame
	setthink(wp, waypoint_think);
	wp.nextthink = time;
	wp.effects = EF_LOWPRECISION;
}

// spawnfunc_waypoint map entity
spawnfunc(waypoint)
{
	IL_PUSH(g_waypoints, this);

	setorigin(this, this.origin);
	// schedule a relink after other waypoints have had a chance to spawn
	waypoint_clearlinks(this);
	//waypoint_schedulerelink(this);
}

void waypoint_remove(entity wp)
{
	// tell all waypoints linked to wp that they need to relink
	IL_EACH(g_waypoints, it != wp,
	{
		if (waypoint_islinked(it, wp))
			waypoint_schedulerelink(it);
	});
	delete(wp);
}

void waypoint_removeall()
{
	IL_EACH(g_waypoints, true,
	{
		delete(it);
	});
}

// tell all waypoints to relink
// actually this is useful only to update relink_* stats
void waypoint_schedulerelinkall()
{
	relink_total = relink_walkculled = relink_pvsculled = relink_lengthculled = 0;
	IL_EACH(g_waypoints, true,
	{
		waypoint_schedulerelink(it);
	});
	waypoint_load_links_hardwired();
}

// Load waypoint links from file
float waypoint_load_links()
{
	string filename, s;
	float file, tokens, c = 0, found;
	entity wp_from = NULL, wp_to;
	vector wp_to_pos, wp_from_pos;
	filename = strcat("maps/", mapname);
	filename = strcat(filename, ".waypoints.cache");
	file = fopen(filename, FILE_READ);

	if (file < 0)
	{
		LOG_TRACE("waypoint links load from ");
		LOG_TRACE(filename);
		LOG_TRACE(" failed");
		return false;
	}

	while ((s = fgets(file)))
	{
		tokens = tokenizebyseparator(s, "*");

		if (tokens!=2)
		{
			// bad file format
			fclose(file);
			return false;
		}

		wp_from_pos	= stov(argv(0));
		wp_to_pos	= stov(argv(1));

		// Search "from" waypoint
		if(!wp_from || wp_from.origin!=wp_from_pos)
		{
			wp_from = findradius(wp_from_pos, 1);
			found = false;
			while(wp_from)
			{
				if(vdist(wp_from.origin - wp_from_pos, <, 1))
				if(wp_from.classname == "waypoint")
				{
					found = true;
					break;
				}
				wp_from = wp_from.chain;
			}

			if(!found)
			{
				LOG_TRACE("waypoint_load_links: couldn't find 'from' waypoint at ", vtos(wp_from.origin));
				continue;
			}

		}

		// Search "to" waypoint
		wp_to = findradius(wp_to_pos, 1);
		found = false;
		while(wp_to)
		{
			if(vdist(wp_to.origin - wp_to_pos, <, 1))
			if(wp_to.classname == "waypoint")
			{
				found = true;
				break;
			}
			wp_to = wp_to.chain;
		}

		if(!found)
		{
			LOG_TRACE("waypoint_load_links: couldn't find 'to' waypoint at ", vtos(wp_to.origin));
			continue;
		}

		++c;
		waypoint_addlink(wp_from, wp_to);
	}

	fclose(file);

	LOG_TRACE("loaded ", ftos(c), " waypoint links from maps/", mapname, ".waypoints.cache");

	botframe_cachedwaypointlinks = true;
	return true;
}

void waypoint_load_links_hardwired()
{
	string filename, s;
	float file, tokens, c = 0, found;
	entity wp_from = NULL, wp_to;
	vector wp_to_pos, wp_from_pos;
	filename = strcat("maps/", mapname);
	filename = strcat(filename, ".waypoints.hardwired");
	file = fopen(filename, FILE_READ);

	botframe_loadedforcedlinks = true;

	if (file < 0)
	{
		LOG_TRACE("waypoint links load from ", filename, " failed");
		return;
	}

	while ((s = fgets(file)))
	{
		if(substring(s, 0, 2)=="//")
			continue;

		if(substring(s, 0, 1)=="#")
			continue;

		tokens = tokenizebyseparator(s, "*");

		if (tokens!=2)
			continue;

		wp_from_pos	= stov(argv(0));
		wp_to_pos	= stov(argv(1));

		// Search "from" waypoint
		if(!wp_from || wp_from.origin!=wp_from_pos)
		{
			wp_from = findradius(wp_from_pos, 5);
			found = false;
			while(wp_from)
			{
				if(vdist(wp_from.origin - wp_from_pos, <, 5))
				if(wp_from.classname == "waypoint")
				{
					found = true;
					break;
				}
				wp_from = wp_from.chain;
			}

			if(!found)
			{
				LOG_INFO(strcat("NOTICE: Can not find waypoint at ", vtos(wp_from_pos), ". Path skipped\n"));
				continue;
			}
		}

		// Search "to" waypoint
		wp_to = findradius(wp_to_pos, 5);
		found = false;
		while(wp_to)
		{
			if(vdist(wp_to.origin - wp_to_pos, <, 5))
			if(wp_to.classname == "waypoint")
			{
				found = true;
				break;
			}
			wp_to = wp_to.chain;
		}

		if(!found)
		{
			LOG_INFO(strcat("NOTICE: Can not find waypoint at ", vtos(wp_to_pos), ". Path skipped\n"));
			continue;
		}

		++c;
		waypoint_addlink(wp_from, wp_to);
		wp_from.wphardwired = true;
		wp_to.wphardwired = true;
	}

	fclose(file);

	LOG_TRACE("loaded ", ftos(c), " waypoint links from maps/", mapname, ".waypoints.hardwired");
}

entity waypoint_get_link(entity w, float i)
{
	switch(i)
	{
		case  0:return w.wp00;
		case  1:return w.wp01;
		case  2:return w.wp02;
		case  3:return w.wp03;
		case  4:return w.wp04;
		case  5:return w.wp05;
		case  6:return w.wp06;
		case  7:return w.wp07;
		case  8:return w.wp08;
		case  9:return w.wp09;
		case 10:return w.wp10;
		case 11:return w.wp11;
		case 12:return w.wp12;
		case 13:return w.wp13;
		case 14:return w.wp14;
		case 15:return w.wp15;
		case 16:return w.wp16;
		case 17:return w.wp17;
		case 18:return w.wp18;
		case 19:return w.wp19;
		case 20:return w.wp20;
		case 21:return w.wp21;
		case 22:return w.wp22;
		case 23:return w.wp23;
		case 24:return w.wp24;
		case 25:return w.wp25;
		case 26:return w.wp26;
		case 27:return w.wp27;
		case 28:return w.wp28;
		case 29:return w.wp29;
		case 30:return w.wp30;
		case 31:return w.wp31;
		default:return NULL;
	}
}

// Save all waypoint links to a file
void waypoint_save_links()
{
	string filename = sprintf("maps/%s.waypoints.cache", mapname);
	int file = fopen(filename, FILE_WRITE);
	if (file < 0)
	{
		LOG_INFOF("waypoint link save to %s failed\n", filename);
		return;
	}

	int c = 0;
	IL_EACH(g_waypoints, true,
	{
		for(int j = 0; j < 32; ++j)
		{
			entity link = waypoint_get_link(it, j);
			if(link)
			{
				string s = strcat(vtos(it.origin), "*", vtos(link.origin), "\n");
				fputs(file, s);
				++c;
			}
		}
	});
	fclose(file);
	botframe_cachedwaypointlinks = true;

	LOG_INFOF("saved %d waypoint links to maps/%s.waypoints.cache\n", c, mapname);
}

// save waypoints to gamedir/data/maps/mapname.waypoints
void waypoint_saveall()
{
	string filename = sprintf("maps/%s.waypoints", mapname);
	int file = fopen(filename, FILE_WRITE);
	if (file < 0)
	{
		waypoint_save_links(); // save anyway?
		botframe_loadedforcedlinks = false;

		LOG_INFOF("waypoint links: save to %s failed\n", filename);
		return;
	}

	int c = 0;
	IL_EACH(g_waypoints, true,
	{
		if(it.wpflags & WAYPOINTFLAG_GENERATED)
			continue;

		string s;
		s = strcat(vtos(it.origin + it.mins), "\n");
		s = strcat(s, vtos(it.origin + it.maxs));
		s = strcat(s, "\n");
		s = strcat(s, ftos(it.wpflags));
		s = strcat(s, "\n");
		fputs(file, s);
		c++;
	});
	fclose(file);
	waypoint_save_links();
	botframe_loadedforcedlinks = false;

	LOG_INFOF("saved %d waypoints to maps/%s.waypoints\n", c, mapname);
}

// load waypoints from file
float waypoint_loadall()
{
	string filename, s;
	float file, cwp, cwb, fl;
	vector m1, m2;
	cwp = 0;
	cwb = 0;
	filename = strcat("maps/", mapname);
	filename = strcat(filename, ".waypoints");
	file = fopen(filename, FILE_READ);
	if (file >= 0)
	{
		while ((s = fgets(file)))
		{
			m1 = stov(s);
			s = fgets(file);
			if (!s)
				break;
			m2 = stov(s);
			s = fgets(file);
			if (!s)
				break;
			fl = stof(s);
			waypoint_spawn(m1, m2, fl);
			if (m1 == m2)
				cwp = cwp + 1;
			else
				cwb = cwb + 1;
		}
		fclose(file);
		LOG_TRACE("loaded ", ftos(cwp), " waypoints and ", ftos(cwb), " wayboxes from maps/", mapname, ".waypoints");
	}
	else
	{
		LOG_TRACE("waypoint load from ", filename, " failed");
	}
	return cwp + cwb;
}

vector waypoint_fixorigin(vector position)
{
	tracebox(position + '0 0 1' * (1 - PL_MIN_CONST.z), PL_MIN_CONST, PL_MAX_CONST, position + '0 0 -512', MOVE_NOMONSTERS, NULL);
	if(trace_fraction < 1)
		position = trace_endpos;
	//traceline(position, position + '0 0 -512', MOVE_NOMONSTERS, NULL);
	//print("position is ", ftos(trace_endpos_z - position_z), " above solid\n");
	return position;
}

void waypoint_spawnforitem_force(entity e, vector org)
{
	// Fix the waypoint altitude if necessary
	org = waypoint_fixorigin(org);

	// don't spawn an item spawnfunc_waypoint if it already exists
	IL_EACH(g_waypoints, true,
	{
		if(it.wpisbox)
		{
			if(boxesoverlap(org, org, it.absmin, it.absmax))
			{
				e.nearestwaypoint = it;
				return;
			}
		}
		else
		{
			if(vdist(it.origin - org, <, 16))
			{
				e.nearestwaypoint = it;
				return;
			}
		}
	});

	e.nearestwaypoint = waypoint_spawn(org, org, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_ITEM);
}

void waypoint_spawnforitem(entity e)
{
	if(!bot_waypoints_for_items)
		return;

	waypoint_spawnforitem_force(e, e.origin);
}

void waypoint_spawnforteleporter_boxes(entity e, vector org1, vector org2, vector destination1, vector destination2, float timetaken)
{
	entity w;
	entity dw;
	w = waypoint_spawn(org1, org2, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_NORELINK);
	dw = waypoint_spawn(destination1, destination2, WAYPOINTFLAG_GENERATED);
	// one way link to the destination
	w.wp00 = dw;
	w.wp00mincost = timetaken; // this is just for jump pads
	// the teleporter's nearest spawnfunc_waypoint is this one
	// (teleporters are not goals, so this is probably useless)
	e.nearestwaypoint = w;
	e.nearestwaypointtimeout = -1;
}

void waypoint_spawnforteleporter_v(entity e, vector org, vector destination, float timetaken)
{
	org = waypoint_fixorigin(org);
	destination = waypoint_fixorigin(destination);
	waypoint_spawnforteleporter_boxes(e, org, org, destination, destination, timetaken);
}

void waypoint_spawnforteleporter(entity e, vector destination, float timetaken)
{
	destination = waypoint_fixorigin(destination);
	waypoint_spawnforteleporter_boxes(e, e.absmin, e.absmax, destination, destination, timetaken);
}

entity waypoint_spawnpersonal(entity this, vector position)
{
	entity w;

	// drop the waypoint to a proper location:
	//   first move it up by a player height
	//   then move it down to hit the floor with player bbox size
	position = waypoint_fixorigin(position);

	w = waypoint_spawn(position, position, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_PERSONAL);
	w.nearestwaypoint = NULL;
	w.nearestwaypointtimeout = 0;
	w.owner = this;

	waypoint_schedulerelink(w);

	return w;
}

void waypoint_showlink(entity wp1, entity wp2, int display_type)
{
	if (!(wp1 && wp2))
		return;

	if (wp1.wphardwired && wp2.wphardwired)
		te_beam(NULL, wp1.origin, wp2.origin);
	else if (display_type == 1)
		te_lightning2(NULL, wp1.origin, wp2.origin);
}

void botframe_showwaypointlinks()
{
	if (time < botframe_waypointeditorlightningtime)
		return;
	botframe_waypointeditorlightningtime = time + 0.5;
	FOREACH_CLIENT(IS_PLAYER(it) && !it.isbot,
	{
		int display_type = 0;
		entity head = navigation_findnearestwaypoint(it, false);
		if (IS_ONGROUND(it) || it.waterlevel > WATERLEVEL_NONE)
			display_type = 1; // default
		else if(head && (head.wphardwired))
			display_type = 2; // only hardwired

		if (display_type)
		{
			//navigation_testtracewalk = true;
			//print("currently selected WP is ", etos(head), "\n");
			//navigation_testtracewalk = false;
			if (head)
			{
				te_lightning2(NULL, head.origin, it.origin);
				waypoint_showlink(head.wp00, head, display_type);
				waypoint_showlink(head.wp01, head, display_type);
				waypoint_showlink(head.wp02, head, display_type);
				waypoint_showlink(head.wp03, head, display_type);
				waypoint_showlink(head.wp04, head, display_type);
				waypoint_showlink(head.wp05, head, display_type);
				waypoint_showlink(head.wp06, head, display_type);
				waypoint_showlink(head.wp07, head, display_type);
				waypoint_showlink(head.wp08, head, display_type);
				waypoint_showlink(head.wp09, head, display_type);
				waypoint_showlink(head.wp10, head, display_type);
				waypoint_showlink(head.wp11, head, display_type);
				waypoint_showlink(head.wp12, head, display_type);
				waypoint_showlink(head.wp13, head, display_type);
				waypoint_showlink(head.wp14, head, display_type);
				waypoint_showlink(head.wp15, head, display_type);
				waypoint_showlink(head.wp16, head, display_type);
				waypoint_showlink(head.wp17, head, display_type);
				waypoint_showlink(head.wp18, head, display_type);
				waypoint_showlink(head.wp19, head, display_type);
				waypoint_showlink(head.wp20, head, display_type);
				waypoint_showlink(head.wp21, head, display_type);
				waypoint_showlink(head.wp22, head, display_type);
				waypoint_showlink(head.wp23, head, display_type);
				waypoint_showlink(head.wp24, head, display_type);
				waypoint_showlink(head.wp25, head, display_type);
				waypoint_showlink(head.wp26, head, display_type);
				waypoint_showlink(head.wp27, head, display_type);
				waypoint_showlink(head.wp28, head, display_type);
				waypoint_showlink(head.wp29, head, display_type);
				waypoint_showlink(head.wp30, head, display_type);
				waypoint_showlink(head.wp31, head, display_type);
			}
		}
	});
}

float botframe_autowaypoints_fixdown(vector v)
{
	tracebox(v, PL_MIN_CONST, PL_MAX_CONST, v + '0 0 -64', MOVE_NOMONSTERS, NULL);
	if(trace_fraction >= 1)
		return 0;
	return 1;
}

float botframe_autowaypoints_createwp(vector v, entity p, .entity fld, float f)
{
	IL_EACH(g_waypoints, boxesoverlap(v - '32 32 32', v + '32 32 32', it.absmin, it.absmax),
	{
		// if a matching spawnfunc_waypoint already exists, don't add a duplicate
		return 0;
	});

	waypoint_schedulerelink(p.(fld) = waypoint_spawn(v, v, f));
	return 1;
}

// return value:
//    1 = WP created
//    0 = no action needed
//   -1 = temp fail, try from world too
//   -2 = permanent fail, do not retry
float botframe_autowaypoints_fix_from(entity p, float walkfromwp, entity wp, .entity fld)
{
	// make it possible to go from p to wp, if we can
	// if wp is NULL, nearest is chosen

	entity w;
	vector porg;
	float t, tmin, tmax;
	vector o;
	vector save;

	if(!botframe_autowaypoints_fixdown(p.origin))
		return -2;
	porg = trace_endpos;

	if(wp)
	{
		// if any WP w fulfills wp -> w -> porg and w is closer than wp, then switch from wp to w

		// if wp -> porg, then OK
		float maxdist;
		if(navigation_waypoint_will_link(wp.origin, porg, p, walkfromwp, 1050))
		{
			// we may find a better one
			maxdist = vlen(wp.origin - porg);
		}
		else
		{
			// accept any "good"
			maxdist = 2100;
		}

		float bestdist = maxdist;
		IL_EACH(g_waypoints, it != wp && !(it.wpflags & WAYPOINTFLAG_NORELINK),
		{
			float d = vlen(wp.origin - it.origin) + vlen(it.origin - porg);
			if(d < bestdist)
			if(navigation_waypoint_will_link(wp.origin, it.origin, p, walkfromwp, 1050))
			if(navigation_waypoint_will_link(it.origin, porg, p, walkfromwp, 1050))
			{
				bestdist = d;
				p.(fld) = it;
			}
		});
		if(bestdist < maxdist)
		{
			LOG_INFO("update chain to new nearest WP ", etos(p.(fld)), "\n");
			return 0;
		}

		if(bestdist < 2100)
		{
			// we know maxdist < 2100
			// so wp -> porg is still valid
			// all is good
			p.(fld) = wp;
			return 0;
		}

		// otherwise, no existing WP can fix our issues
	}
	else
	{
		save = p.origin;
		setorigin(p, porg);
		w = navigation_findnearestwaypoint(p, walkfromwp);
		setorigin(p, save);
		if(w)
		{
			p.(fld) = w;
			return 0;
		}
	}

	tmin = 0;
	tmax = 1;
	for (;;)
	{
		if(tmax - tmin < 0.001)
		{
			// did not get a good candidate
			return -1;
		}

		t = (tmin + tmax) * 0.5;
		o = antilag_takebackorigin(p, CS(p), time - t);
		if(!botframe_autowaypoints_fixdown(o))
			return -2;
		o = trace_endpos;

		if(wp)
		{
			if(!navigation_waypoint_will_link(wp.origin, o, p, walkfromwp, 1050))
			{
				// we cannot walk from wp.origin to o
				// get closer to tmax
				tmin = t;
				continue;
			}
		}
		else
		{
			save = p.origin;
			setorigin(p, o);
			w = navigation_findnearestwaypoint(p, walkfromwp);
			setorigin(p, save);
			if(!w)
			{
				// we cannot walk from any WP to o
				// get closer to tmax
				tmin = t;
				continue;
			}
		}

		// if we get here, o is valid regarding waypoints
		// check if o is connected right to the player
		// we break if it succeeds, as that means o is a good waypoint location
		if(navigation_waypoint_will_link(o, porg, p, walkfromwp, 1050))
			break;

		// o is no good, we need to get closer to the player
		tmax = t;
	}

	LOG_INFO("spawning a waypoint for connecting to ", etos(wp), "\n");
	botframe_autowaypoints_createwp(o, p, fld, 0);
	return 1;
}

// automatically create missing waypoints
.entity botframe_autowaypoints_lastwp0, botframe_autowaypoints_lastwp1;
void botframe_autowaypoints_fix(entity p, float walkfromwp, .entity fld)
{
	float r = botframe_autowaypoints_fix_from(p, walkfromwp, p.(fld), fld);
	if(r != -1)
		return;
	r = botframe_autowaypoints_fix_from(p, walkfromwp, NULL, fld);
	if(r != -1)
		return;

	LOG_INFO("emergency: got no good nearby WP to build a link from, starting a new chain\n");
	if(!botframe_autowaypoints_fixdown(p.origin))
		return; // shouldn't happen, caught above
	botframe_autowaypoints_createwp(trace_endpos, p, fld, WAYPOINTFLAG_PROTECTED);
}

void botframe_deleteuselesswaypoints()
{
	IL_EACH(g_items, it.bot_pickup,
	{
		// NOTE: this protects waypoints if they're the ONLY nearest
		// waypoint. That's the intention.
		navigation_findnearestwaypoint(it, false);  // Walk TO item.
		navigation_findnearestwaypoint(it, true);  // Walk FROM item.
	});
	IL_EACH(g_waypoints, true,
	{
		it.wpflags |= WAYPOINTFLAG_DEAD_END;
		it.wpflags &= ~WAYPOINTFLAG_USEFUL;
		// WP is useful if:
		if (it.wpflags & WAYPOINTFLAG_ITEM)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		if (it.wpflags & WAYPOINTFLAG_TELEPORT)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		if (it.wpflags & WAYPOINTFLAG_PROTECTED)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		// b) WP is closest WP for an item/spawnpoint/other entity
		//    This has been done above by protecting these WPs.
	});
	// c) There are w1, w, w2 so that w1 -> w, w -> w2 and not w1 -> w2.
	IL_EACH(g_waypoints, !(it.wpflags & WAYPOINTFLAG_PERSONAL),
	{
		for (int m = 0; m < 32; ++m)
		{
			entity w = waypoint_get_link(it, m);
			if (!w)
				break;
			if (w.wpflags & WAYPOINTFLAG_PERSONAL)
				continue;
			if (w.wpflags & WAYPOINTFLAG_USEFUL)
				continue;
			for (int j = 0; j < 32; ++j)
			{
				entity w2 = waypoint_get_link(w, j);
				if (!w2)
					break;
				if (it == w2)
					continue;
				if (w2.wpflags & WAYPOINTFLAG_PERSONAL)
					continue;
				// If we got here, it != w2 exist with it -> w
				// and w -> w2. That means the waypoint is not
				// a dead end.
				w.wpflags &= ~WAYPOINTFLAG_DEAD_END;
				for (int k = 0; k < 32; ++k)
				{
					if (waypoint_get_link(it, k) == w2)
						continue;
					// IF WE GET HERE, w is proven useful
					// to get from it to w2!
					w.wpflags |= WAYPOINTFLAG_USEFUL;
					goto next;
				}
			}
LABEL(next)
		}
	});
	// d) The waypoint is a dead end. Dead end waypoints must be kept as
	//     they are needed to complete routes while autowaypointing.

	IL_EACH(g_waypoints, !(it.wpflags & (WAYPOINTFLAG_USEFUL | WAYPOINTFLAG_DEAD_END)),
	{
		LOG_INFOF("Removed a waypoint at %v. Try again for more!\n", it.origin);
		te_explosion(it.origin);
		waypoint_remove(it);
		break;
	});

	IL_EACH(g_waypoints, true,
	{
		it.wpflags &= ~(WAYPOINTFLAG_USEFUL | WAYPOINTFLAG_DEAD_END); // temp flag
	});
}

void botframe_autowaypoints()
{
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && !IS_DEAD(it), LAMBDA(
		// going back is broken, so only fix waypoints to walk TO the player
		//botframe_autowaypoints_fix(p, false, botframe_autowaypoints_lastwp0);
		botframe_autowaypoints_fix(it, true, botframe_autowaypoints_lastwp1);
		//te_explosion(p.botframe_autowaypoints_lastwp0.origin);
	));

	if (autocvar_g_waypointeditor_auto >= 2) {
		botframe_deleteuselesswaypoints();
	}
}

