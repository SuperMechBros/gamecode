#include "minelayer.qh"
#ifndef IMPLEMENTATION
CLASS(MineLayer, Weapon)
/* ammotype  */ ATTRIB(MineLayer, ammo_field, .int, ammo_rockets);
/* impulse   */ ATTRIB(MineLayer, impulse, int, 4);
/* flags     */ ATTRIB(MineLayer, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(MineLayer, bot_pickupbasevalue, float, 7000);
/* color     */ ATTRIB(MineLayer, wpcolor, vector, '0.75 1 0');
/* modelname */ ATTRIB(MineLayer, mdl, string, "minelayer");
#ifdef GAMEQC
/* model     */ ATTRIB(MineLayer, m_model, Model, MDL_MINELAYER_ITEM);
#endif
/* crosshair */ ATTRIB(MineLayer, w_crosshair, string, "gfx/crosshairminelayer");
/* crosshair */ ATTRIB(MineLayer, w_crosshair_size, float, 0.9);
/* wepimg    */ ATTRIB(MineLayer, model2, string, "weaponminelayer");
/* refname   */ ATTRIB(MineLayer, netname, string, "minelayer");
/* wepname   */ ATTRIB(MineLayer, m_name, string, _("Mine Layer"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, NONE) \
		P(class, prefix, animtime, float, NONE) \
		P(class, prefix, damageforcescale, float, NONE) \
		P(class, prefix, damage, float, NONE) \
		P(class, prefix, detonatedelay, float, NONE) \
		P(class, prefix, edgedamage, float, NONE) \
		P(class, prefix, force, float, NONE) \
		P(class, prefix, health, float, NONE) \
		P(class, prefix, lifetime, float, NONE) \
		P(class, prefix, lifetime_countdown, float, NONE) \
		P(class, prefix, limit, float, NONE) \
		P(class, prefix, protection, float, NONE) \
		P(class, prefix, proximityradius, float, NONE) \
		P(class, prefix, radius, float, NONE) \
		P(class, prefix, refire, float, NONE) \
		P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, remote_damage, float, NONE) \
		P(class, prefix, remote_edgedamage, float, NONE) \
		P(class, prefix, remote_force, float, NONE) \
		P(class, prefix, remote_radius, float, NONE) \
		P(class, prefix, speed, float, NONE) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, time, float, NONE) \
        P(class, prefix, weaponreplace, string, NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, MineLayer, minelayer)
#undef X
ENDCLASS(MineLayer)
REGISTER_WEAPON(MINE_LAYER, minelayer, NEW(MineLayer));

#ifdef SVQC
void W_MineLayer_Think(entity this);
.float minelayer_detonate, mine_explodeanyway;
.float mine_time;
.vector mine_orientation;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_minelayer) { weapon_defaultspawnfunc(this, WEP_MINE_LAYER); }

void W_MineLayer_Stick(entity this, entity to)
{
	spamsound(this, CH_SHOTS, SND(MINE_STICK), VOL_BASE, ATTN_NORM);

	// in order for mines to face properly when sticking to the ground, they must be a server side entity rather than a csqc projectile

	entity newmine = spawn();
	IL_PUSH(g_mines, newmine);
	newmine.weaponentity_fld = this.weaponentity_fld;
	newmine.classname = this.classname;

	newmine.bot_dodge = this.bot_dodge;
	newmine.bot_dodgerating = this.bot_dodgerating;

	newmine.owner = this.owner;
	newmine.realowner = this.realowner;
	setsize(newmine, '-4 -4 -4', '4 4 4');
	setorigin(newmine, this.origin);
	setmodel(newmine, MDL_MINELAYER_MINE);
	newmine.angles = vectoangles(-trace_plane_normal); // face against the surface

	newmine.mine_orientation = -trace_plane_normal;

	newmine.takedamage = this.takedamage;
	newmine.damageforcescale = this.damageforcescale;
	newmine.health = this.health;
	newmine.event_damage = this.event_damage;
	newmine.spawnshieldtime = this.spawnshieldtime;
	newmine.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, newmine);

	set_movetype(newmine, MOVETYPE_NONE); // lock the mine in place
	newmine.projectiledeathtype = this.projectiledeathtype;

	newmine.mine_time = this.mine_time;

	settouch(newmine, func_null);
	setthink(newmine, W_MineLayer_Think);
	newmine.nextthink = time;
	newmine.cnt = this.cnt;
	newmine.flags = this.flags;
	IL_PUSH(g_projectiles, newmine);
	IL_PUSH(g_bot_dodge, newmine);

	delete(this);

	if(to)
		SetMovetypeFollow(newmine, to);
}

void W_MineLayer_Explode(entity this, entity directhitentity)
{
	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	RadiusDamage(this, this.realowner, WEP_CVAR(minelayer, damage), WEP_CVAR(minelayer, edgedamage), WEP_CVAR(minelayer, radius), NULL, NULL, WEP_CVAR(minelayer, force), this.projectiledeathtype, directhitentity);

	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == WEP_MINE_LAYER)
	{
		entity own = this.realowner;
		Weapon w = WEP_MINE_LAYER;
		if(!w.wr_checkammo1(w, own, weaponentity))
		{
			own.cnt = WEP_MINE_LAYER.m_id;
			int slot = weaponslot(weaponentity);
			ATTACK_FINISHED(own, slot) = time;
			own.(weaponentity).m_switchweapon = w_getbestweapon(own, weaponentity);
		}
	}
	this.realowner.(weaponentity).minelayer_mines -= 1;
	delete(this);
}

void W_MineLayer_Explode_think(entity this)
{
	W_MineLayer_Explode(this, NULL);
}

void W_MineLayer_DoRemoteExplode(entity this)
{
	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	if(this.move_movetype == MOVETYPE_NONE || this.move_movetype == MOVETYPE_FOLLOW)
		this.velocity = this.mine_orientation; // particle fx and decals need .velocity

	RadiusDamage(this, this.realowner, WEP_CVAR(minelayer, remote_damage), WEP_CVAR(minelayer, remote_edgedamage), WEP_CVAR(minelayer, remote_radius), NULL, NULL, WEP_CVAR(minelayer, remote_force), this.projectiledeathtype | HITTYPE_BOUNCE, NULL);

	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == WEP_MINE_LAYER)
	{
		entity own = this.realowner;
		Weapon w = WEP_MINE_LAYER;
		if(!w.wr_checkammo1(w, own, weaponentity))
		{
			own.cnt = WEP_MINE_LAYER.m_id;
			int slot = weaponslot(weaponentity);
			ATTACK_FINISHED(own, slot) = time;
			own.(weaponentity).m_switchweapon = w_getbestweapon(own, weaponentity);
		}
	}
	this.realowner.(weaponentity).minelayer_mines -= 1;
	delete(this);
}

void W_MineLayer_RemoteExplode(entity this)
{
	if(!IS_DEAD(this.realowner))
		if((this.spawnshieldtime >= 0)
			? (time >= this.spawnshieldtime) // timer
			: (vdist(NearestPointOnBox(this.realowner, this.origin) - this.origin, >, WEP_CVAR(minelayer, remote_radius))) // safety device
		)
		{
			W_MineLayer_DoRemoteExplode(this);
		}
}

void W_MineLayer_ProximityExplode(entity this)
{
	// make sure no friend is in the mine's radius. If there is any, explosion is delayed until he's at a safe distance
	if(WEP_CVAR(minelayer, protection) && this.mine_explodeanyway == 0)
	{
		entity head;
		head = findradius(this.origin, WEP_CVAR(minelayer, radius));
		while(head)
		{
			if(head == this.realowner || SAME_TEAM(head, this.realowner))
				return;
			head = head.chain;
		}
	}

	this.mine_time = 0;
	W_MineLayer_Explode(this, NULL);
}

int W_MineLayer_Count(entity e, .entity weaponentity)
{
	int minecount = 0;
	IL_EACH(g_mines, it.realowner == e && it.weaponentity_fld == weaponentity,
	{
		minecount += 1;
	});

	return minecount;
}

void W_MineLayer_Think(entity this)
{
	entity head;

	this.nextthink = time;

	if(this.move_movetype == MOVETYPE_FOLLOW)
	{
		if(LostMovetypeFollow(this))
		{
			UnsetMovetypeFollow(this);
			set_movetype(this, MOVETYPE_NONE);
		}
	}

	// our lifetime has expired, it's time to die - mine_time just allows us to play a sound for this
	// TODO: replace this mine_trigger.wav sound with a real countdown
	if((time > this.cnt) && (!this.mine_time) && (this.cnt > 0))
	{
		if(WEP_CVAR(minelayer, lifetime_countdown) > 0)
			spamsound(this, CH_SHOTS, SND(MINE_TRIGGER), VOL_BASE, ATTN_NORM);
		this.mine_time = time + WEP_CVAR(minelayer, lifetime_countdown);
		this.mine_explodeanyway = 1; // make the mine super aggressive -- Samual: Rather, make it not care if a team mate is near.
	}

	// a player's mines shall explode if he disconnects or dies
	// TODO: Do this on team change too -- Samual: But isn't a player killed when they switch teams?
	if(!IS_PLAYER(this.realowner) || IS_DEAD(this.realowner))
	{
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		W_MineLayer_Explode(this, NULL);
		return;
	}

	// set the mine for detonation when a foe gets close enough
	head = findradius(this.origin, WEP_CVAR(minelayer, proximityradius));
	while(head)
	{
		if(IS_PLAYER(head) && !IS_DEAD(head))
		if(head != this.realowner && DIFF_TEAM(head, this.realowner)) // don't trigger for team mates
		if(!this.mine_time)
		{
			spamsound(this, CH_SHOTS, SND(MINE_TRIGGER), VOL_BASE, ATTN_NORM);
			this.mine_time = time + WEP_CVAR(minelayer, time);
		}
		head = head.chain;
	}

	// explode if it's time to
	if(this.mine_time && time >= this.mine_time)
	{
		W_MineLayer_ProximityExplode(this);
		return;
	}

	// remote detonation
	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == WEP_MINE_LAYER)
	if(!IS_DEAD(this.realowner))
	if(this.minelayer_detonate)
		W_MineLayer_RemoteExplode(this);
}

void W_MineLayer_Touch(entity this, entity toucher)
{
	if(this.move_movetype == MOVETYPE_NONE || this.move_movetype == MOVETYPE_FOLLOW)
		return; // we're already a stuck mine, why do we get called? TODO does this even happen?

	if(WarpZone_Projectile_Touch(this, toucher))
	{
		if(wasfreed(this))
		{
			.entity weaponentity = this.weaponentity_fld;
			this.realowner.(weaponentity).minelayer_mines -= 1;
		}
		return;
	}

	if((toucher && IS_PLAYER(toucher) && !IS_DEAD(toucher)) || toucher.owner == this.owner)
	{
		// hit a player or other mine
		// don't stick
	}
	else
	{
		W_MineLayer_Stick(this, toucher);
	}
}

void W_MineLayer_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(this.health <= 0)
		return;

	float is_from_enemy = (inflictor.realowner != this.realowner);

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, (is_from_enemy ? 1 : -1)))
		return; // g_projectiles_damage says to halt

	this.health = this.health - damage;
	this.angles = vectoangles(this.velocity);

	if(this.health <= 0)
		W_PrepareExplosionByDamage(this, attacker, W_MineLayer_Explode_think);
}

void W_MineLayer_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity mine;
	entity flash;

	// scan how many mines we placed, and return if we reached our limit
	if(WEP_CVAR(minelayer, limit))
	{
		if(actor.(weaponentity).minelayer_mines >= WEP_CVAR(minelayer, limit))
		{
			// the refire delay keeps this message from being spammed
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, WEAPON_MINELAYER_LIMIT, WEP_CVAR(minelayer, limit));
			play2(actor, SND(UNAVAILABLE));
			return;
		}
	}

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(minelayer, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-4 -4 -4', '4 4 4', false, 5, SND_MINE_FIRE, CH_WEAPON_A, WEP_CVAR(minelayer, damage));
	Send_Effect(EFFECT_ROCKET_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	mine = WarpZone_RefSys_SpawnSameRefSys(actor);
	mine.weaponentity_fld = weaponentity;
	IL_PUSH(g_mines, mine);
	mine.owner = mine.realowner = actor;
	if(WEP_CVAR(minelayer, detonatedelay) >= 0)
		mine.spawnshieldtime = time + WEP_CVAR(minelayer, detonatedelay);
	else
		mine.spawnshieldtime = -1;
	mine.classname = "mine";
	mine.bot_dodge = true;
	mine.bot_dodgerating = WEP_CVAR(minelayer, damage) * 2; // * 2 because it can detonate inflight which makes it even more dangerous

	mine.takedamage = DAMAGE_YES;
	mine.damageforcescale = WEP_CVAR(minelayer, damageforcescale);
	mine.health = WEP_CVAR(minelayer, health);
	mine.event_damage = W_MineLayer_Damage;
	mine.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, mine);

	set_movetype(mine, MOVETYPE_TOSS);
	PROJECTILE_MAKETRIGGER(mine);
	mine.projectiledeathtype = WEP_MINE_LAYER.m_id;
	setsize(mine, '-4 -4 -4', '4 4 4'); // give it some size so it can be shot

	setorigin(mine, w_shotorg - v_forward * 4); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(mine, WEP_CVAR(minelayer, speed), 0);
	mine.angles = vectoangles(mine.velocity);

	settouch(mine, W_MineLayer_Touch);
	setthink(mine, W_MineLayer_Think);
	mine.nextthink = time;
	mine.cnt = (WEP_CVAR(minelayer, lifetime) - WEP_CVAR(minelayer, lifetime_countdown));
	mine.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, mine);
	IL_PUSH(g_bot_dodge, mine);
	mine.missile_flags = MIF_SPLASH | MIF_ARC | MIF_PROXY;

	if(mine.cnt > 0) { mine.cnt += time; }

	CSQCProjectile(mine, true, PROJECTILE_MINE, true);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, MDL_MINELAYER_MUZZLEFLASH); // precision set below
	SUB_SetFade(flash, time, 0.1);
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(actor, weaponentity, flash, '5 0 0');

	// common properties

	MUTATOR_CALLHOOK(EditProjectile, actor, mine);

	actor.(weaponentity).minelayer_mines = W_MineLayer_Count(actor, weaponentity);
}

bool W_MineLayer_PlacedMines(entity this, .entity weaponentity, bool detonate)
{
	bool minfound = false;

	IL_EACH(g_mines, it.realowner == this && it.weaponentity_fld == weaponentity,
	{
		if(detonate)
		{
			if(!it.minelayer_detonate)
			{
				it.minelayer_detonate = true;
				minfound = true;
			}
		}
		else
			minfound = true;
	});
	return minfound;
}

METHOD(MineLayer, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    // aim and decide to fire if appropriate
    if(actor.(weaponentity).minelayer_mines >= WEP_CVAR(minelayer, limit))
        PHYS_INPUT_BUTTON_ATCK(actor) = false;
    else
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR(minelayer, speed), 0, WEP_CVAR(minelayer, lifetime), false);
    if(skill >= 2) // skill 0 and 1 bots won't detonate mines!
    {
        // decide whether to detonate mines
        float edgedamage, coredamage, edgeradius, recipricoledgeradius;
        float selfdamage, teamdamage, enemydamage;
        edgedamage = WEP_CVAR(minelayer, edgedamage);
        coredamage = WEP_CVAR(minelayer, damage);
        edgeradius = WEP_CVAR(minelayer, radius);
        recipricoledgeradius = 1 / edgeradius;
        selfdamage = 0;
        teamdamage = 0;
        enemydamage = 0;

        IL_EACH(g_mines, it.realowner == actor,
        {
        	entity mine = it;
        	IL_EACH(g_bot_targets, it.bot_attack,
        	{
        		float d = vlen(it.origin + (it.mins + it.maxs) * 0.5 - mine.origin);
        		d = bound(0, edgedamage + (coredamage - edgedamage) * sqrt(1 - d * recipricoledgeradius), 10000);
                // count potential damage according to type of target
                if(it == actor)
                    selfdamage = selfdamage + d;
                else if(SAME_TEAM(it, actor))
                    teamdamage = teamdamage + d;
                else if(bot_shouldattack(actor, it))
                    enemydamage = enemydamage + d;
        	});
        });

        float desirabledamage;
        desirabledamage = enemydamage;
        if(time > actor.invincible_finished && time > actor.spawnshieldtime)
            desirabledamage = desirabledamage - selfdamage * autocvar_g_balance_selfdamagepercent;
        if(teamplay && actor.team)
            desirabledamage = desirabledamage - teamdamage;

        makevectors(actor.v_angle);
        IL_EACH(g_mines, it.realowner == actor,
        {
            if(skill > 9) // normal players only do this for the target they are tracking
            {
	            entity mine = it;
	            IL_EACH(g_bot_targets, it.bot_attack,
	            {
	            	if((v_forward * normalize(mine.origin - it.origin) < 0.1)
	                    && desirabledamage > 0.1 * coredamage
	                    ) PHYS_INPUT_BUTTON_ATCK2(actor) = true;
	            });
	        }
	        else
	        {
                //As the distance gets larger, a correct detonation gets near imposible
                //Bots are assumed to use the mine spawnfunc_light to see if the mine gets near a player
                if((v_forward * normalize(it.origin - actor.enemy.origin) < 0.1)
                	&& IS_PLAYER(actor.enemy)
                	&& (desirabledamage >= 0.1 * coredamage)
                	)
                {
                	float distance = bound(300, vlen(actor.origin - actor.enemy.origin), 30000);
                	if(random() / distance * 300 > frametime * bound(0, (10 - skill) * 0.2, 1))
                		PHYS_INPUT_BUTTON_ATCK2(actor) = true;
                }
	        }
        });

        // if we would be doing at X percent of the core damage, detonate it
        // but don't fire a new shot at the same time!
        if(desirabledamage >= 0.75 * coredamage) //this should do group damage in rare fortunate events
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
        if((skill > 6.5) && (selfdamage > actor.health))
            PHYS_INPUT_BUTTON_ATCK2(actor) = false;
        //if(PHYS_INPUT_BUTTON_ATCK2(actor) == true)
        //	dprint(ftos(desirabledamage),"\n");
        if(PHYS_INPUT_BUTTON_ATCK2(actor)) PHYS_INPUT_BUTTON_ATCK(actor) = false;
    }
}
METHOD(MineLayer, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(weaponslot(weaponentity) == 0)
		actor.minelayer_mines = actor.(weaponentity).minelayer_mines;

    if(autocvar_g_balance_minelayer_reload_ammo && actor.(weaponentity).clip_load < WEP_CVAR(minelayer, ammo)) // forced reload
    {
        // not if we're holding the minelayer without enough ammo, but can detonate existing mines
        if(!(W_MineLayer_PlacedMines(actor, weaponentity, false) && actor.(thiswep.ammo_field) < WEP_CVAR(minelayer, ammo))) {
            thiswep.wr_reload(thiswep, actor, weaponentity);
        }
    }
    else if(fire & 1)
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(minelayer, refire)))
        {
            W_MineLayer_Attack(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(minelayer, animtime), w_ready);
        }
    }

    if(fire & 2)
    {
        if(W_MineLayer_PlacedMines(actor, weaponentity, true))
            sound(actor, CH_WEAPON_B, SND_MINE_DET, VOL_BASE, ATTN_NORM);
    }
}
METHOD(MineLayer, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    //int slot = 0; // TODO: unhardcode
    // actually do // don't switch while placing a mine
    //if(ATTACK_FINISHED(actor, slot) <= time || PS(actor).m_weapon != WEP_MINE_LAYER)
    //{
        float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR(minelayer, ammo);
        ammo_amount += actor.(weaponentity).(weapon_load[WEP_MINE_LAYER.m_id]) >= WEP_CVAR(minelayer, ammo);
        return ammo_amount;
    //}
    //return true;
}
METHOD(MineLayer, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    if(W_MineLayer_PlacedMines(actor, weaponentity, false))
        return true;
    else
        return false;
}
METHOD(MineLayer, wr_resetplayer, void(entity thiswep, entity actor))
{
    actor.minelayer_mines = 0;
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
    	.entity weaponentity = weaponentities[slot];
    	actor.(weaponentity).minelayer_mines = 0;
    }
}
METHOD(MineLayer, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, WEP_CVAR(minelayer, ammo), SND_RELOAD);
}
METHOD(MineLayer, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_MINELAYER_SUICIDE;
}
METHOD(MineLayer, wr_killmessage, Notification(entity thiswep))
{
    return WEAPON_MINELAYER_MURDER;
}

#endif
#ifdef CSQC

METHOD(MineLayer, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 12;
    pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_MINE_EXP, VOL_BASE, ATTN_NORM);
}

#endif
#endif
