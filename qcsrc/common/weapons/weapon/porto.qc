#include "porto.qh"
#ifndef IMPLEMENTATION
CLASS(PortoLaunch, Weapon)
/* ammotype  */ ATTRIB(PortoLaunch, ammo_field, .int, ammo_none);
/* impulse   */ ATTRIB(PortoLaunch, impulse, int, 0);
/* flags     */ ATTRIB(PortoLaunch, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_SUPERWEAPON);
/* rating    */ ATTRIB(PortoLaunch, bot_pickupbasevalue, float, 0);
/* color     */ ATTRIB(PortoLaunch, wpcolor, vector, '0.5 0.5 0.5');
/* modelname */ ATTRIB(PortoLaunch, mdl, string, "porto");
#ifdef GAMEQC
/* model     */ ATTRIB(PortoLaunch, m_model, Model, MDL_PORTO_ITEM);
#endif
/* crosshair */ ATTRIB(PortoLaunch, w_crosshair, string, "gfx/crosshairporto");
/* crosshair */ ATTRIB(PortoLaunch, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(PortoLaunch, model2, string, "weaponporto");
/* refname   */ ATTRIB(PortoLaunch, netname, string, "porto");
/* wepname   */ ATTRIB(PortoLaunch, m_name, string, _("Port-O-Launch"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, speed, float, BOTH) \
        P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string,NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, PortoLaunch, porto)
#undef X
ENDCLASS(PortoLaunch)
REGISTER_WEAPON(PORTO, porto, NEW(PortoLaunch));

#ifdef SVQC
.entity porto_current;
.vector porto_v_angle; // holds "held" view angles
.float porto_v_angle_held;
.vector right_vector;
.float porto_forbidden;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
#include <common/triggers/trigger/jumppads.qh>

spawnfunc(weapon_porto) { weapon_defaultspawnfunc(this, WEP_PORTO); }

REGISTER_MUTATOR(porto_ticker, true);
MUTATOR_HOOKFUNCTION(porto_ticker, SV_StartFrame) {
	FOREACH_CLIENT(IS_PLAYER(it), it.porto_forbidden = max(0, it.porto_forbidden - 1));
}

void W_Porto_Success(entity this)
{
	if(this.realowner == NULL)
	{
		objerror(this, "Cannot succeed successfully: no owner\n");
		return;
	}

	this.realowner.porto_current = NULL;
	delete(this);
}

string W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo, .entity weaponentity);
void W_Porto_Fail(entity this, float failhard)
{
	if(this.realowner == NULL)
	{
		objerror(this, "Cannot fail successfully: no owner\n");
		return;
	}

	// no portals here!
	if(this.cnt < 0)
	{
		Portal_ClearWithID(this.realowner, this.portal_id);
	}

	this.realowner.porto_current = NULL;

	if(this.cnt < 0 && !failhard && this.realowner.playerid == this.playerid && !IS_DEAD(this.realowner) && !(this.realowner.weapons & WEPSET(PORTO)))
	{
		setsize(this, '-16 -16 0', '16 16 32');
		setorigin(this, this.origin + trace_plane_normal);
		if(move_out_of_solid(this))
		{
			this.flags = FL_ITEM;
			IL_PUSH(g_items, this);
			this.velocity = trigger_push_calculatevelocity(this.origin, this.realowner, 128);
			tracetoss(this, this);
			if(vdist(trace_endpos - this.realowner.origin, <, 128))
			{
				.entity weaponentity = this.weaponentity_fld;
				W_ThrowNewWeapon(this.realowner, WEP_PORTO.m_id, 0, this.origin, this.velocity, weaponentity);
				Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_FAILED);
			}
		}
	}
	delete(this);
}

void W_Porto_Remove(entity p)
{
	if(p.porto_current.realowner == p && p.porto_current.classname == "porto")
	{
		W_Porto_Fail(p.porto_current, 1);
	}
}

void W_Porto_Think(entity this)
{
	trace_plane_normal = '0 0 0';
	if(this.realowner.playerid != this.playerid)
		delete(this);
	else
		W_Porto_Fail(this, 0);
}

void W_Porto_Touch(entity this, entity toucher)
{
	vector norm;

	// do not use PROJECTILE_TOUCH here
	// FIXME but DO handle warpzones!

	if(toucher.classname == "portal")
		return; // handled by the portal

	norm = trace_plane_normal;
	if(trace_ent.iscreature)
	{
		// TODO: why not use entity size?
		traceline(trace_ent.origin, trace_ent.origin + '0 0 2' * PL_MIN_CONST.z, MOVE_WORLDONLY, this);
		if(trace_fraction >= 1)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;
	}

	if(this.realowner.playerid != this.playerid)
	{
		sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
		delete(this);
	}
	else if((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) || (trace_dphitcontents & DPCONTENTS_PLAYERCLIP))
	{
		spamsound(this, CH_SHOTS, SND(PORTO_BOUNCE), VOL_BASE, ATTEN_NORM);
		// just reflect
		this.right_vector = this.right_vector - 2 * trace_plane_normal * (this.right_vector * trace_plane_normal);
		this.angles = vectoangles(this.velocity - 2 * trace_plane_normal * (this.velocity * trace_plane_normal));
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
		W_Porto_Fail(this, 0);
		if(this.cnt < 0)
			Portal_ClearAll_PortalsOnly(this.realowner);
	}
	else if(this.cnt == 0)
	{
		// in-portal only
		if(Portal_SpawnInPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
		{
			sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_IN);
			W_Porto_Success(this);
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(this, 0);
		}
	}
	else if(this.cnt == 1)
	{
		// out-portal only
		if(Portal_SpawnOutPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
		{
			sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_OUT);
			W_Porto_Success(this);
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(this, 0);
		}
	}
	else if(this.effects & EF_RED)
	{
		this.effects += EF_BLUE - EF_RED;
		if(Portal_SpawnInPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
		{
			sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_IN);
			this.right_vector = this.right_vector - 2 * trace_plane_normal * (this.right_vector * norm);
			this.angles = vectoangles(this.velocity - 2 * trace_plane_normal * (this.velocity * norm));
			CSQCProjectile(this, true, PROJECTILE_PORTO_BLUE, true); // change type
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Portal_ClearAll_PortalsOnly(this.realowner);
			W_Porto_Fail(this, 0);
		}
	}
	else
	{
		if(this.realowner.portal_in.portal_id == this.portal_id)
		{
			if(Portal_SpawnOutPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
			{
				sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
				trace_plane_normal = norm;
				Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_OUT);
				W_Porto_Success(this);
			}
			else
			{
				sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
				Portal_ClearAll_PortalsOnly(this.realowner);
				W_Porto_Fail(this, 0);
			}
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			Portal_ClearAll_PortalsOnly(this.realowner);
			W_Porto_Fail(this, 0);
		}
	}
}

void W_Porto_Attack(entity actor, .entity weaponentity, float type)
{
	entity gren;

	W_SetupShot(actor, weaponentity, false, 4, SND_PORTO_FIRE, CH_WEAPON_A, 0);
	// always shoot from the eye
	w_shotdir = v_forward;
	w_shotorg = actor.origin + actor.view_ofs + ((w_shotorg - actor.origin - actor.view_ofs) * v_forward) * v_forward;

	//Send_Effect(EFFECT_GRENADE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	gren = new(porto);
	gren.weaponentity_fld = weaponentity;
	gren.cnt = type;
	gren.owner = gren.realowner = actor;
	gren.playerid = actor.playerid;
	gren.bot_dodge = true;
	gren.bot_dodgerating = 200;
	set_movetype(gren, MOVETYPE_BOUNCEMISSILE);
	PROJECTILE_MAKETRIGGER(gren);
	gren.effects = EF_RED;
	gren.scale = 4;
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 0', '0 0 0');

	gren.nextthink = time + WEP_CVAR_BOTH(porto, (type <= 0), lifetime);
	setthink(gren, W_Porto_Think);
	settouch(gren, W_Porto_Touch);

	if(actor.items & ITEM_Strength.m_itemid)
		W_SetupProjVelocity_Basic(gren, WEP_CVAR_BOTH(porto, (type <= 0), speed) * autocvar_g_balance_powerup_strength_force, 0);
	else
		W_SetupProjVelocity_Basic(gren, WEP_CVAR_BOTH(porto, (type <= 0), speed), 0);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	gren.portal_id = time;
	actor.porto_current = gren;
	gren.playerid = actor.playerid;
	fixedmakevectors(fixedvectoangles(gren.velocity));
	gren.right_vector = v_right;

	gren.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;

	if(type > 0)
		CSQCProjectile(gren, true, PROJECTILE_PORTO_BLUE, true);
	else
		CSQCProjectile(gren, true, PROJECTILE_PORTO_RED, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

METHOD(PortoLaunch, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    PHYS_INPUT_BUTTON_ATCK(actor) = false;
    PHYS_INPUT_BUTTON_ATCK2(actor) = false;
    if(!WEP_CVAR(porto, secondary))
        if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(porto, speed), 0, WEP_CVAR_PRI(porto, lifetime), false))
            PHYS_INPUT_BUTTON_ATCK(actor) = true;
}
METHOD(PortoLaunch, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(WEP_CVAR(porto, secondary))
    {
        if(fire & 1)
        if(!actor.porto_current)
        if(!actor.porto_forbidden)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(porto, refire)))
        {
            W_Porto_Attack(actor, weaponentity, 0);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(porto, animtime), w_ready);
        }

        if(fire & 2)
        if(!actor.porto_current)
        if(!actor.porto_forbidden)
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(porto, refire)))
        {
            W_Porto_Attack(actor, weaponentity, 1);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(porto, animtime), w_ready);
        }
    }
    else
    {
        if(actor.(weaponentity).porto_v_angle_held)
        {
            if(!(fire & 2))
                actor.(weaponentity).porto_v_angle_held = 0;
        }
        else
        {
            if(fire & 2)
            {
                actor.(weaponentity).porto_v_angle = actor.v_angle;
                actor.(weaponentity).porto_v_angle_held = 1;
            }
        }
        if(actor.(weaponentity).porto_v_angle_held)
            makevectors(actor.(weaponentity).porto_v_angle); // override the previously set angles

        if(fire & 1)
        if(!actor.porto_current)
        if(!actor.porto_forbidden)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(porto, refire)))
        {
            W_Porto_Attack(actor, weaponentity, -1);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(porto, animtime), w_ready);
        }
    }
}
METHOD(PortoLaunch, wr_checkammo1, bool(entity thiswep, entity this, .entity weaponentity))
{
    // always allow infinite ammo
    return true;
}
METHOD(PortoLaunch, wr_checkammo2, bool(entity thiswep, entity this, .entity weaponentity))
{
    // always allow infinite ammo
    return true;
}
METHOD(PortoLaunch, wr_resetplayer, void(entity thiswep, entity actor))
{
    actor.porto_current = NULL;
}
#endif
#ifdef CSQC
METHOD(PortoLaunch, wr_impacteffect, void(entity this, entity actor)) {
    LOG_WARN("Since when does Porto send DamageInfo?");
}
#endif
#endif
