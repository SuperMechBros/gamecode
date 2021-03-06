#include "tracing.qh"

#include "accuracy.qh"
#include "common.qh"
#include "hitplot.qh"
#include "weaponsystem.qh"

#include "../g_damage.qh"
#include "../g_subs.qh"
#include "../antilag.qh"

#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/util.qh>

#include <common/weapons/_all.qh>
#include <common/state.qh>

#include <lib/warpzone/common.qh>

// this function calculates w_shotorg and w_shotdir based on the weapon model
// offset, trueaim and antilag, and won't put w_shotorg inside a wall.
// make sure you call makevectors first (FIXME?)
void W_SetupShot_Dir_ProjectileSize_Range(entity ent, .entity weaponentity, vector s_forward, vector mi, vector ma, float antilag, float recoil, Sound snd, float chan, float maxdamage, float range)
{
	TC(Sound, snd);
	float nudge = 1; // added to traceline target and subtracted from result  TOOD(divVerent): do we still need this? Doesn't the engine do this now for us?
	float oldsolid;
	vector vecs, dv;
	oldsolid = ent.dphitcontentsmask;
	if (IS_PLAYER(ent) && ent.(weaponentity).m_weapon == WEP_RIFLE)
		ent.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	else
		ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	if(antilag)
		WarpZone_traceline_antilag(NULL, ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
		// passing NULL, because we do NOT want it to touch dphitcontentsmask
	else
		WarpZone_TraceLine(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NOMONSTERS, ent);
	ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	w_shotend = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos); // warpzone support
	v_forward = vf;
	v_right = vr;
	v_up = vu;

	// un-adjust trueaim if shotend is too close
	if(vdist(w_shotend - (ent.origin + ent.view_ofs), <, autocvar_g_trueaim_minrange))
		w_shotend = ent.origin + ent.view_ofs + s_forward * autocvar_g_trueaim_minrange;

	// track max damage
	if (IS_PLAYER(ent) && accuracy_canbegooddamage(ent))
		accuracy_add(ent, ent.(weaponentity).m_weapon.m_id, maxdamage, 0);

	if(IS_PLAYER(ent))
		W_HitPlotAnalysis(ent, weaponentity, v_forward, v_right, v_up);

	vector md = ent.(weaponentity).movedir;
	if(md.x > 0)
		vecs = md;
	else
		vecs = '0 0 0';

	dv = v_right * -vecs.y + v_up * vecs.z;
	w_shotorg = ent.origin + ent.view_ofs + dv;

	// now move the shotorg forward as much as requested if possible
	if(antilag)
	{
		if(CS(ent).antilag_debug)
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + v_forward * (vecs.x + nudge), MOVE_NORMAL, ent, CS(ent).antilag_debug);
		else
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + v_forward * (vecs.x + nudge), MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
	}
	else
		tracebox(w_shotorg, mi, ma, w_shotorg + v_forward * (vecs.x + nudge), MOVE_NORMAL, ent);
	w_shotorg = trace_endpos - v_forward * nudge;
	// calculate the shotdir from the chosen shotorg
	w_shotdir = normalize(w_shotend - w_shotorg);

	//vector prevdir = w_shotdir;
	//vector prevorg = w_shotorg;
	//vector prevend = w_shotend;

	if (antilag)
	if (!ent.cvar_cl_noantilag)
	{
		if (autocvar_g_antilag == 1) // switch to "ghost" if not hitting original
		{
			traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
			if (!trace_ent.takedamage)
			{
				traceline_antilag_force (ent, w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
				if (trace_ent.takedamage && IS_PLAYER(trace_ent))
				{
					entity e;
					e = trace_ent;
					traceline(w_shotorg, e.origin, MOVE_NORMAL, ent);
					if(trace_ent == e)
						w_shotdir = normalize(trace_ent.origin - w_shotorg);
				}
			}
		}
		else if(autocvar_g_antilag == 3) // client side hitscan
		{
			// this part MUST use prydon cursor
			if (ent.cursor_trace_ent)                 // client was aiming at someone
			if (ent.cursor_trace_ent != ent)         // just to make sure
			if (ent.cursor_trace_ent.takedamage)      // and that person is killable
			if (IS_PLAYER(ent.cursor_trace_ent)) // and actually a player
			{
				// verify that the shot would miss without antilag
				// (avoids an issue where guns would always shoot at their origin)
				traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
				if (!trace_ent.takedamage)
				{
					// verify that the shot would hit if altered
					traceline(w_shotorg, ent.cursor_trace_ent.origin, MOVE_NORMAL, ent);
					if (trace_ent == ent.cursor_trace_ent)
						w_shotdir = normalize(ent.cursor_trace_ent.origin - w_shotorg);
					else
						LOG_INFO("antilag fail\n");
				}
			}
		}
	}

	ent.dphitcontentsmask = oldsolid; // restore solid type (generally SOLID_SLIDEBOX)

	if (!autocvar_g_norecoil)
		ent.punchangle_x = recoil * -1;

	if (snd != SND_Null) {
		sound (ent, chan, snd, VOL_BASE, ATTN_NORM);
		W_PlayStrengthSound(ent);
	}

	// nudge w_shotend so a trace to w_shotend hits
	w_shotend = w_shotend + normalize(w_shotend - w_shotorg) * nudge;
	//if(w_shotend != prevend) { printf("SERVER: shotEND differs: %s - %s\n", vtos(w_shotend), vtos(prevend)); }
	//if(w_shotorg != prevorg) { printf("SERVER: shotORG differs: %s - %s\n", vtos(w_shotorg), vtos(prevorg)); }
	//if(w_shotdir != prevdir) { printf("SERVER: shotDIR differs: %s - %s\n", vtos(w_shotdir), vtos(prevdir)); }
}

vector W_CalculateProjectileVelocity(entity actor, vector pvelocity, vector mvelocity, float forceAbsolute)
{
	vector mdirection;
	float mspeed;
	vector outvelocity;

	mvelocity = mvelocity * W_WeaponSpeedFactor(actor);

	mdirection = normalize(mvelocity);
	mspeed = vlen(mvelocity);

	outvelocity = get_shotvelocity(pvelocity, mdirection, mspeed, (forceAbsolute ? 0 : autocvar_g_projectiles_newton_style), autocvar_g_projectiles_newton_style_2_minfactor, autocvar_g_projectiles_newton_style_2_maxfactor);

	return outvelocity;
}

void W_SetupProjVelocity_Explicit(entity proj, vector dir, vector upDir, float pSpeed, float pUpSpeed, float pZSpeed, float spread, float forceAbsolute)
{
	if(proj.owner == NULL)
		error("Unowned missile");

	dir = dir + upDir * (pUpSpeed / pSpeed);
	dir.z += pZSpeed / pSpeed;
	pSpeed *= vlen(dir);
	dir = normalize(dir);

	#if 0
	if(autocvar_g_projectiles_spread_style != mspercallsstyle)
	{
		mspercallsum = mspercallcount = 0;
		mspercallsstyle = autocvar_g_projectiles_spread_style;
	}
	mspercallsum -= gettime(GETTIME_HIRES);
	#endif

	dir = W_CalculateSpread(dir, spread, g_weaponspreadfactor, autocvar_g_projectiles_spread_style);

	#if 0
	mspercallsum += gettime(GETTIME_HIRES);
	mspercallcount += 1;
	LOG_INFO("avg: ", ftos(mspercallcount / mspercallsum), " per sec\n");
	#endif

	proj.velocity = W_CalculateProjectileVelocity(proj.owner, proj.owner.velocity, pSpeed * dir, forceAbsolute);
}


// ====================
//  Ballistics Tracing
// ====================

void FireRailgunBullet (entity this, .entity weaponentity, vector start, vector end, float bdamage, float bforce, float mindist, float maxdist, float halflifedist, float forcehalflifedist, int deathtype)
{
	vector hitloc, force, endpoint, dir;
	entity ent, endent;
	float endq3surfaceflags;
	float totaldmg;
	entity o;

	float length;
	vector beampos;
	string snd;
	entity pseudoprojectile;
	float f, ffs;

	pseudoprojectile = NULL;

	dir = normalize(end - start);
	length = vlen(end - start);
	force = dir * bforce;

	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;

	totaldmg = 0;

	// trace multiple times until we hit a wall, each obstacle will be made
	// non-solid so we can hit the next, while doing this we spawn effects and
	// note down which entities were hit so we can damage them later
	o = this;
	while (1)
	{
		if(CS(this).antilag_debug)
			WarpZone_traceline_antilag (this, start, end, false, o, CS(this).antilag_debug);
		else
			WarpZone_traceline_antilag (this, start, end, false, o, ANTILAG_LATENCY(this));
		if(o && WarpZone_trace_firstzone)
		{
			o = NULL;
			continue;
		}

		if(trace_ent.solid == SOLID_BSP || trace_ent.solid == SOLID_SLIDEBOX)
			Damage_DamageInfo(trace_endpos, bdamage, 0, 0, force, deathtype, trace_ent.species, this);

		// if it is NULL we can't hurt it so stop now
		if (trace_ent == NULL || trace_fraction == 1)
			break;

		// make the entity non-solid so we can hit the next one
		trace_ent.railgunhit = true;
		trace_ent.railgunhitloc = end;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;
		trace_ent.railgundistance = vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos) - start);
		trace_ent.railgunforce = WarpZone_TransformVelocity(WarpZone_trace_transform, force);

		// stop if this is a wall
		if (trace_ent.solid == SOLID_BSP)
			break;

		// make the entity non-solid
		trace_ent.solid = SOLID_NOT;
	}

	endpoint = trace_endpos;
	endent = trace_ent;
	endq3surfaceflags = trace_dphitq3surfaceflags;

	// find all the entities the railgun hit and restore their solid state
	ent = findfloat(NULL, railgunhit, true);
	while (ent)
	{
		// restore their solid type
		ent.solid = ent.railgunhitsolidbackup;
		ent = findfloat(ent, railgunhit, true);
	}

	// spawn a temporary explosion entity for RadiusDamage calls
	//explosion = spawn();

	// Find all non-hit players the beam passed close by
	if(deathtype == WEP_VAPORIZER.m_id || deathtype == WEP_VORTEX.m_id)
	{
		FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != this, LAMBDA(
			if(!it.railgunhit)
			if(!(IS_SPEC(it) && it.enemy == this))
			{
				msg_entity = it;
				// nearest point on the beam
				beampos = start + dir * bound(0, (msg_entity.origin - start) * dir, length);

				f = bound(0, 1 - vlen(beampos - msg_entity.origin) / 512, 1);
				if(f <= 0)
					continue;

				snd = SND(NEXWHOOSH_RANDOM());

				if(!pseudoprojectile)
					pseudoprojectile = spawn(); // we need this so the sound uses the "entchannel4" volume
				soundtoat(MSG_ONE, pseudoprojectile, beampos, CH_SHOTS, snd, VOL_BASE * f, ATTEN_NONE);
			}
		));

		if(pseudoprojectile)
			delete(pseudoprojectile);
	}

	// find all the entities the railgun hit and hurt them
	ent = findfloat(NULL, railgunhit, true);
	while (ent)
	{
		// get the details we need to call the damage function
		hitloc = ent.railgunhitloc;

		f = ExponentialFalloff(mindist, maxdist, halflifedist, ent.railgundistance);
		ffs = ExponentialFalloff(mindist, maxdist, forcehalflifedist, ent.railgundistance);

		if(accuracy_isgooddamage(this, ent))
			totaldmg += bdamage * f;

		// apply the damage
		if (ent.takedamage)
			Damage (ent, this, this, bdamage * f, deathtype, hitloc, ent.railgunforce * ffs);

		// create a small explosion to throw gibs around (if applicable)
		//setorigin(explosion, hitloc);
		//RadiusDamage (explosion, this, 10, 0, 50, NULL, NULL, 300, deathtype);

		ent.railgunhitloc = '0 0 0';
		ent.railgunhitsolidbackup = SOLID_NOT;
		ent.railgunhit = false;
		ent.railgundistance = 0;

		// advance to the next entity
		ent = findfloat(ent, railgunhit, true);
	}

	// calculate hits and fired shots for hitscan
	accuracy_add(this, this.(weaponentity).m_weapon.m_id, 0, min(bdamage, totaldmg));

	trace_endpos = endpoint;
	trace_ent = endent;
	trace_dphitq3surfaceflags = endq3surfaceflags;
}

void fireBullet_trace_callback(vector start, vector hit, vector end)
{
	if(vdist(hit - start, >, 16))
		trailparticles(NULL, fireBullet_trace_callback_eff, start, hit);
	WarpZone_trace_forent = NULL;
	fireBullet_last_hit = NULL;
}

void fireBullet(entity this, .entity weaponentity, vector start, vector dir, float spread, float max_solid_penetration, float damage, float force, float dtype, int tracereffects)
{
	vector  end;

	dir = normalize(dir + randomvec() * spread);
	end = start + dir * max_shot_distance;

	fireBullet_last_hit = NULL;
	float solid_penetration_left = 1;
	float total_damage = 0;

	if(tracereffects & EF_RED)
		fireBullet_trace_callback_eff = EFFECT_RIFLE;
	else if(tracereffects & EF_BLUE)
		fireBullet_trace_callback_eff = EFFECT_RIFLE_WEAK;
	else
		fireBullet_trace_callback_eff = EFFECT_BULLET;

	float lag = ANTILAG_LATENCY(this);
	if(lag < 0.001)
		lag = 0;
	if (!IS_REAL_CLIENT(this))
		lag = 0;
	if(autocvar_g_antilag == 0 || this.cvar_cl_noantilag)
		lag = 0; // only do hitscan, but no antilag
	if(lag)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != this, antilag_takeback(it, CS(it), time - lag));
		IL_EACH(g_monsters, it != this,
		{
			antilag_takeback(it, it, time - lag);
		});
	}

	// change shooter to SOLID_BBOX so the shot can hit corpses
	int oldsolid = this.dphitcontentsmask;
	if(this)
		this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	WarpZone_trace_forent = this;

	for (;;)
	{
		// TODO also show effect while tracing
		WarpZone_TraceBox_ThroughZone(start, '0 0 0', '0 0 0', end, false, WarpZone_trace_forent, NULL, fireBullet_trace_callback);
		dir = WarpZone_TransformVelocity(WarpZone_trace_transform, dir);
		end = WarpZone_TransformOrigin(WarpZone_trace_transform, end);
		start = trace_endpos;
		entity hit = trace_ent;

		// traced up to max_shot_distance and didn't hit anything at all
		if (trace_fraction == 1.0)
			break;

		// When hitting sky, stop.
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
			break;

		// can't use noimpact, as we need to pass through walls
		//if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			//break;

		// if we hit "weapclip", bail out
		//
		// rationale of this check:
		//
		// any shader that is solid, nodraw AND trans is meant to clip weapon
		// shots and players, but has no other effect!
		//
		// if it is not trans, it is caulk and should not have this side effect
		//
		// matching shaders:
		//   common/weapclip (intended)
		//   common/noimpact (is supposed to eat projectiles, but is erased anyway)
		bool is_weapclip = false;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODRAW)
		if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID))
		if (!(trace_dphitcontents & DPCONTENTS_OPAQUE))
			is_weapclip = true;

		if(!hit || hit.solid == SOLID_BSP || hit.solid == SOLID_SLIDEBOX)
			Damage_DamageInfo(start, damage * solid_penetration_left, 0, 0, max(1, force) * dir * solid_penetration_left, dtype, hit.species, this);

		if (hit && hit != WarpZone_trace_forent && hit != fireBullet_last_hit)  // Avoid self-damage (except after going through a warp); avoid hitting the same entity twice (engine bug).
		{
			fireBullet_last_hit = hit;
			yoda = 0;
			MUTATOR_CALLHOOK(FireBullet_Hit, this, hit, start, end, damage, this.(weaponentity));
			damage = M_ARGV(4, float);
			float g = accuracy_isgooddamage(this, hit);
			Damage(hit, this, this, damage * solid_penetration_left, dtype, start, force * dir * solid_penetration_left);
			// calculate hits for ballistic weapons
			if(g)
			{
				// do not exceed 100%
				float added_damage = min(damage - total_damage, damage * solid_penetration_left);
				total_damage += damage * solid_penetration_left;
				accuracy_add(this, this.(weaponentity).m_weapon.m_id, 0, added_damage);
			}
		}

		if (is_weapclip && !autocvar_g_ballistics_penetrate_clips)
			break;

		// go through solid!
		// outside the world? forget it
		if(start.x > world.maxs.x || start.y > world.maxs.y || start.z > world.maxs.z || start.x < world.mins.x || start.y < world.mins.y || start.z < world.mins.z)
			break;

		float maxdist;
		if(max_solid_penetration < 0)
			break;
		else if(hit.ballistics_density < -1)
			break; // -2: no solid penetration, ever
		else if(hit.ballistics_density < 0)
			maxdist = vlen(hit.maxs - hit.mins) + 1; // -1: infinite travel distance
		else if(hit.ballistics_density == 0)
			maxdist = max_solid_penetration * solid_penetration_left;
		else
			maxdist = max_solid_penetration * solid_penetration_left * hit.ballistics_density;

		if(maxdist <= autocvar_g_ballistics_mindistance)
			break;

		// move the entity along its velocity until it's out of solid, then let it resume
		// The previously hit entity is ignored here!
		traceline_inverted (start, start + dir * maxdist, MOVE_NORMAL, WarpZone_trace_forent, true, hit);
		if(trace_fraction == 1) // 1: we never got out of solid
			break;

		float dist_taken = max(autocvar_g_ballistics_mindistance, vlen(trace_endpos - start));
		// fraction_used_of_what_is_left = dist_taken / maxdist
		// solid_penetration_left = solid_penetration_left - solid_penetration_left * fraction_used_of_what_is_left
		solid_penetration_left *= 1 - dist_taken / maxdist;
		solid_penetration_left = max(solid_penetration_left, 0);

		// Only show effect when going through a player (invisible otherwise)
		if (hit && (hit.solid != SOLID_BSP))
			if(vdist(trace_endpos - start, >, 4))
				trailparticles(this, fireBullet_trace_callback_eff, start, trace_endpos);

		start = trace_endpos;

		if(hit.solid == SOLID_BSP)
			Damage_DamageInfo(start, 0, 0, 0, max(1, force) * normalize(dir) * -solid_penetration_left, dtype, 0, this);
	}

	if(lag)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != this, antilag_restore(it, CS(it)));
		IL_EACH(g_monsters, it != this,
		{
			antilag_restore(it, it);
		});
	}

	// restore shooter solid type
	if(this)
		this.dphitcontentsmask = oldsolid;
}
