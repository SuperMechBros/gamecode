#include "rifle.qh"
#ifndef IMPLEMENTATION
CLASS(Rifle, Weapon)
/* ammotype  */ ATTRIB(Rifle, ammo_field, .int, ammo_nails);
/* impulse   */ ATTRIB(Rifle, impulse, int, 7);
/* flags     */ ATTRIB(Rifle, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(Rifle, bot_pickupbasevalue, float, 7000);
/* color     */ ATTRIB(Rifle, wpcolor, vector, '0.5 1 0');
/* modelname */ ATTRIB(Rifle, mdl, string, "campingrifle");
#ifdef GAMEQC
/* model     */ ATTRIB(Rifle, m_model, Model, MDL_RIFLE_ITEM);
#endif
/* crosshair */ ATTRIB(Rifle, w_crosshair, string, "gfx/crosshairrifle");
/* crosshair */ ATTRIB(Rifle, w_crosshair_size, float, 0.6);
/* reticle   */ ATTRIB(Rifle, w_reticle, string, "gfx/reticle_nex");
/* wepimg    */ ATTRIB(Rifle, model2, string, "weaponrifle");
/* refname   */ ATTRIB(Rifle, netname, string, "rifle");
/* wepname   */ ATTRIB(Rifle, m_name, string, _("Rifle"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, BOTH) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, bullethail, float, BOTH) \
		P(class, prefix, burstcost, float, BOTH) \
		P(class, prefix, bursttime, float, NONE) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, force, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, reload, float, SEC) \
		P(class, prefix, reload_ammo, float, NONE) \
    	P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, shots, float, BOTH) \
		P(class, prefix, solidpenetration, float, BOTH) \
		P(class, prefix, spread, float, BOTH) \
    	P(class, prefix, switchdelay_drop, float, NONE) \
    	P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, tracer, float, BOTH) \
    	P(class, prefix, weaponreplace, string, NONE) \
    	P(class, prefix, weaponstartoverride, float, NONE) \
    	P(class, prefix, weaponstart, float, NONE) \
    	P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Rifle, rifle)
#undef X
ENDCLASS(Rifle)
REGISTER_WEAPON(RIFLE, rifle, NEW(Rifle));


#ifdef SVQC
.float rifle_accumulator;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_rifle) { weapon_defaultspawnfunc(this, WEP_RIFLE); }
spawnfunc(weapon_campingrifle) { spawnfunc_weapon_rifle(this); }
spawnfunc(weapon_sniperrifle) { spawnfunc_weapon_rifle(this); }

void W_Rifle_FireBullet(Weapon thiswep, .entity weaponentity, float pSpread, float pDamage, float pForce, float pSolidPenetration, float pAmmo, int deathtype, float pTracer, float pShots, Sound pSound, entity actor)
{
	float i;

	W_DecreaseAmmo(thiswep, actor, pAmmo, weaponentity);

	W_SetupShot(actor, weaponentity, true, 2, pSound, CH_WEAPON_A, pDamage * pShots);

	Send_Effect(EFFECT_RIFLE_MUZZLEFLASH, w_shotorg, w_shotdir * 2000, 1);

	if(PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = actor.origin + actor.view_ofs + ((w_shotorg - actor.origin - actor.view_ofs) * v_forward) * v_forward;
	}

	for(i = 0; i < pShots; ++i)
		fireBullet(actor, weaponentity, w_shotorg, w_shotdir, pSpread, pSolidPenetration, pDamage, pForce, deathtype, (pTracer ? EF_RED : EF_BLUE));

	if(autocvar_g_casings >= 2)
    {
        makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
    }
}

void W_Rifle_Attack(entity actor, .entity weaponentity)
{
	W_Rifle_FireBullet(WEP_RIFLE, weaponentity, WEP_CVAR_PRI(rifle, spread), WEP_CVAR_PRI(rifle, damage), WEP_CVAR_PRI(rifle, force), WEP_CVAR_PRI(rifle, solidpenetration), WEP_CVAR_PRI(rifle, ammo), WEP_RIFLE.m_id, WEP_CVAR_PRI(rifle, tracer), WEP_CVAR_PRI(rifle, shots), SND_CAMPINGRIFLE_FIRE, actor);
}

void W_Rifle_Attack2(entity actor, .entity weaponentity)
{
	W_Rifle_FireBullet(WEP_RIFLE, weaponentity, WEP_CVAR_SEC(rifle, spread), WEP_CVAR_SEC(rifle, damage), WEP_CVAR_SEC(rifle, force), WEP_CVAR_SEC(rifle, solidpenetration), WEP_CVAR_SEC(rifle, ammo), WEP_RIFLE.m_id | HITTYPE_SECONDARY, WEP_CVAR_SEC(rifle, tracer), WEP_CVAR_SEC(rifle, shots), SND_CAMPINGRIFLE_FIRE2, actor);
}

.void(entity actor, .entity weaponentity) rifle_bullethail_attackfunc;
.WFRAME rifle_bullethail_frame;
.float rifle_bullethail_animtime;
.float rifle_bullethail_refire;
void W_Rifle_BulletHail_Continue(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	float r, af;

	Weapon sw = actor.(weaponentity).m_switchweapon; // make it not detect weapon changes as reason to abort firing
	int slot = weaponslot(weaponentity);
	af = ATTACK_FINISHED(actor, slot);
	actor.(weaponentity).m_switchweapon = actor.(weaponentity).m_weapon;
	ATTACK_FINISHED(actor, slot) = time;
	r = weapon_prepareattack(thiswep, actor, weaponentity, actor.rifle_bullethail_frame == WFRAME_FIRE2, actor.rifle_bullethail_refire);
	if(actor.(weaponentity).m_switchweapon == actor.(weaponentity).m_weapon)
		actor.(weaponentity).m_switchweapon = sw;
	if(r)
	{
		actor.rifle_bullethail_attackfunc(actor, weaponentity);
		weapon_thinkf(actor, weaponentity, actor.rifle_bullethail_frame, actor.rifle_bullethail_animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		ATTACK_FINISHED(actor, slot) = af; // reset attack_finished if we didn't fire, so the last shot enforces the refire time
	}
}

void W_Rifle_BulletHail(entity actor, .entity weaponentity, float mode, void(entity actor, .entity weaponentity) AttackFunc, WFRAME fr, float animtime, float refire)
{
	// if we get here, we have at least one bullet to fire
	AttackFunc(actor, weaponentity);
	if(mode)
	{
		// continue hail
		actor.rifle_bullethail_attackfunc = AttackFunc;
		actor.rifle_bullethail_frame = fr;
		actor.rifle_bullethail_animtime = animtime;
		actor.rifle_bullethail_refire = refire;
		weapon_thinkf(actor, weaponentity, fr, animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		// just one shot
		weapon_thinkf(actor, weaponentity, fr, animtime, w_ready);
	}
}

.float bot_secondary_riflemooth;

METHOD(Rifle, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    PHYS_INPUT_BUTTON_ATCK(actor) = false;
    PHYS_INPUT_BUTTON_ATCK2(actor) = false;
    if(vdist(actor.origin - actor.enemy.origin, >, 1000))
        actor.bot_secondary_riflemooth = 0;
    if(actor.bot_secondary_riflemooth == 0)
    {
        if(bot_aim(actor, weaponentity, 1000000, 0, 0.001, false))
        {
            PHYS_INPUT_BUTTON_ATCK(actor) = true;
            if(random() < 0.01) actor.bot_secondary_riflemooth = 1;
        }
    }
    else
    {
        if(bot_aim(actor, weaponentity, 1000000, 0, 0.001, false))
        {
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
            if(random() < 0.03) actor.bot_secondary_riflemooth = 0;
        }
    }
}
METHOD(Rifle, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(autocvar_g_balance_rifle_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(rifle, ammo), WEP_CVAR_SEC(rifle, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else
    {
        actor.rifle_accumulator = bound(time - WEP_CVAR(rifle, bursttime), actor.rifle_accumulator, time);
        if(fire & 1)
        if(weapon_prepareattack_check(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(rifle, refire)))
        if(time >= actor.rifle_accumulator + WEP_CVAR_PRI(rifle, burstcost))
        {
            weapon_prepareattack_do(actor, weaponentity, false, WEP_CVAR_PRI(rifle, refire));
            W_Rifle_BulletHail(actor, weaponentity, WEP_CVAR_PRI(rifle, bullethail), W_Rifle_Attack, WFRAME_FIRE1, WEP_CVAR_PRI(rifle, animtime), WEP_CVAR_PRI(rifle, refire));
            actor.rifle_accumulator += WEP_CVAR_PRI(rifle, burstcost);
        }
        if(fire & 2)
        {
            if(WEP_CVAR(rifle, secondary))
            {
                if(WEP_CVAR_SEC(rifle, reload)) {
                    thiswep.wr_reload(thiswep, actor, weaponentity);
                } else
                {
                    if(weapon_prepareattack_check(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(rifle, refire)))
                    if(time >= actor.rifle_accumulator + WEP_CVAR_SEC(rifle, burstcost))
                    {
                        weapon_prepareattack_do(actor, weaponentity, true, WEP_CVAR_SEC(rifle, refire));
                        W_Rifle_BulletHail(actor, weaponentity, WEP_CVAR_SEC(rifle, bullethail), W_Rifle_Attack2, WFRAME_FIRE2, WEP_CVAR_SEC(rifle, animtime), WEP_CVAR_PRI(rifle, refire));
                        actor.rifle_accumulator += WEP_CVAR_SEC(rifle, burstcost);
                    }
                }
            }
        }
    }
}
METHOD(Rifle, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_PRI(rifle, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[WEP_RIFLE.m_id]) >= WEP_CVAR_PRI(rifle, ammo);
    return ammo_amount;
}
METHOD(Rifle, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_SEC(rifle, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[WEP_RIFLE.m_id]) >= WEP_CVAR_SEC(rifle, ammo);
    return ammo_amount;
}
METHOD(Rifle, wr_resetplayer, void(entity thiswep, entity actor))
{
    actor.rifle_accumulator = time - WEP_CVAR(rifle, bursttime);
}
METHOD(Rifle, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(rifle, ammo), WEP_CVAR_SEC(rifle, ammo)), SND_RELOAD);
}
METHOD(Rifle, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Rifle, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        if(w_deathtype & HITTYPE_BOUNCE)
            return WEAPON_RIFLE_MURDER_HAIL_PIERCING;
        else
            return WEAPON_RIFLE_MURDER_HAIL;
    }
    else
    {
        if(w_deathtype & HITTYPE_BOUNCE)
            return WEAPON_RIFLE_MURDER_PIERCING;
        else
            return WEAPON_RIFLE_MURDER;
    }
}
METHOD(Rifle, wr_zoom, bool(entity thiswep, entity actor))
{
    return PHYS_INPUT_BUTTON_ATCK2(actor) && WEP_CVAR(rifle, secondary) == 0;
}

#endif
#ifdef CSQC

METHOD(Rifle, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 2;
    pointparticles(EFFECT_RIFLE_IMPACT, org2, w_backoff * 1000, 1);
    if(!w_issilent)
    {
        sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
    }
}
METHOD(Rifle, wr_init, void(entity thiswep))
{
    if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
    {
        precache_pic("gfx/reticle_nex");
    }
}
METHOD(Rifle, wr_zoom, bool(entity thiswep, entity actor))
{
    if(button_zoom || zoomscript_caught)
    {
        return true;
    }
    else
    {
        // no weapon specific image for this weapon
        return false;
    }
}

#endif
#endif
