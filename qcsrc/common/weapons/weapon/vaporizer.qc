#include "vaporizer.qh"
#ifndef IMPLEMENTATION
CLASS(Vaporizer, Weapon)
/* ammotype  */ ATTRIB(Vaporizer, ammo_field, .int, ammo_cells);
/* impulse   */ ATTRIB(Vaporizer, impulse, int, 7);
/* flags     */ ATTRIB(Vaporizer, spawnflags, int, WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_FLAG_SUPERWEAPON | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(Vaporizer, bot_pickupbasevalue, float, 10000);
/* color     */ ATTRIB(Vaporizer, wpcolor, vector, '0.5 1 1');
/* modelname */ ATTRIB(Vaporizer, mdl, string, "minstanex");
#ifdef GAMEQC
/* model     */ ATTRIB(Vaporizer, m_model, Model, MDL_VAPORIZER_ITEM);
#endif
/* crosshair */ ATTRIB(Vaporizer, w_crosshair, string, "gfx/crosshairminstanex");
/* crosshair */ ATTRIB(Vaporizer, w_crosshair_size, float, 0.6);
/* reticle   */ ATTRIB(Vaporizer, w_reticle, string, "gfx/reticle_nex");
/* wepimg    */ ATTRIB(Vaporizer, model2, string, "weaponminstanex");
/* refname   */ ATTRIB(Vaporizer, netname, string, "vaporizer");
/* wepname   */ ATTRIB(Vaporizer, m_name, string, _("Vaporizer"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, PRI) \
    	P(class, prefix, animtime, float, PRI) \
    	P(class, prefix, damage, float, PRI) \
    	P(class, prefix, refire, float, PRI) \
    	P(class, prefix, ammo, float, SEC) \
    	P(class, prefix, animtime, float, SEC) \
    	P(class, prefix, damage, float, SEC) \
    	P(class, prefix, delay, float, SEC) \
    	P(class, prefix, edgedamage, float, SEC) \
    	P(class, prefix, force, float, SEC) \
    	P(class, prefix, lifetime, float, SEC) \
    	P(class, prefix, radius, float, SEC) \
    	P(class, prefix, refire, float, SEC) \
    	P(class, prefix, shotangle, float, SEC) \
    	P(class, prefix, speed, float, SEC) \
    	P(class, prefix, spread, float, SEC) \
    	P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, weaponreplace, string, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Vaporizer, vaporizer)
#undef X

ENDCLASS(Vaporizer)
REGISTER_WEAPON(VAPORIZER, vaporizer, NEW(Vaporizer));


#ifdef SVQC
.float vaporizer_lasthit;
.float jump_interval;
.float jump_interval2;
.bool held_down;
.float rm_force;
.float rm_damage;
.float rm_edmg;
#endif
#endif
#ifdef IMPLEMENTATION

REGISTER_NET_TEMP(TE_CSQC_VAPORBEAMPARTICLE)

#if defined(SVQC)
void SendCSQCVaporizerBeamParticle(entity player, int hit) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteHeader(MSG_BROADCAST, TE_CSQC_VAPORBEAMPARTICLE);
	WriteCoord(MSG_BROADCAST, w_shotorg.x);
	WriteCoord(MSG_BROADCAST, w_shotorg.y);
	WriteCoord(MSG_BROADCAST, w_shotorg.z);
	WriteCoord(MSG_BROADCAST, v.x);
	WriteCoord(MSG_BROADCAST, v.y);
	WriteCoord(MSG_BROADCAST, v.z);
	WriteByte(MSG_BROADCAST, hit);
	WriteByte(MSG_BROADCAST, etof(player));
	WriteByte(MSG_BROADCAST, player.team);
}
#elif defined(CSQC)
bool autocvar_cl_vaporizerbeam_particle = false;
float autocvar_cl_vaporizerbeam_lifetime = 0.8;
float autocvar_cl_vaporizerbeam_colorboost = 0.7;

string Draw_VaporizerBeam_trace_callback_tex;
float Draw_VaporizerBeam_trace_callback_rnd;
vector Draw_VaporizerBeam_trace_callback_rgb;
float Draw_VaporizerBeam_trace_callback_a;
void Draw_VaporizerBeam_trace_callback(vector start, vector hit, vector end)
{
	float i;
	vector vorg;
	vorg = WarpZone_TransformOrigin(WarpZone_trace_transform, view_origin);
	for(i = 0; i < Draw_VaporizerBeam_trace_callback_a; ++i)
		Draw_CylindricLine(hit, start, 8, Draw_VaporizerBeam_trace_callback_tex, 0.25, Draw_VaporizerBeam_trace_callback_rnd, Draw_VaporizerBeam_trace_callback_rgb, min(1, Draw_VaporizerBeam_trace_callback_a - i), DRAWFLAG_NORMAL, vorg);
	Draw_VaporizerBeam_trace_callback_rnd += 0.25 * vlen(hit - start) / 8;
}

.vector vorg1, vorg2;
.float spawn_time;
void VaporizerBeam_Draw(entity this)
{
	//draw either the old v2.3 beam or the new beam
	particles_alphamin = particles_alphamax = particles_fade = 1;

	string tex = "particles/lgbeam";
	if(this.cnt)
		tex = "particles/gauntletbeam";
	vector rgb;
	//entity e = CSQCModel_server2csqc(this.sv_entnum - 1);
	//if (e == NULL)
	//{
		rgb = colormapPaletteColor(entcs_GetClientColors(this.sv_entnum - 1) & 0x0F, true);
		//rgb = '1 1 1';
	//}
	//else
	//	rgb = e.glowmod;
	rgb *= (1 + autocvar_cl_vaporizerbeam_colorboost);

	float fail = (this.nextthink - time);

	Draw_VaporizerBeam_trace_callback_tex = tex;
	Draw_VaporizerBeam_trace_callback_rnd = 0;
	Draw_VaporizerBeam_trace_callback_rgb = rgb;
	Draw_VaporizerBeam_trace_callback_a = bound(0, fail, 1);
	WarpZone_TraceBox_ThroughZone(this.vorg1, '0 0 0', '0 0 0', this.vorg2, MOVE_NOTHING, NULL, NULL, Draw_VaporizerBeam_trace_callback);
	Draw_VaporizerBeam_trace_callback_tex = string_null;

	/*if(!MUTATOR_CALLHOOK(Particles_VaporizerBeam, this.vorg1, this.vorg2))
	if(autocvar_cl_particles_oldvortexbeam && (STAT(ALLOW_OLDVORTEXBEAM) || isdemo()))
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM_OLD), this.vorg1, this.vorg2, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM), this.vorg1, this.vorg2, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);*/
}

NET_HANDLE(TE_CSQC_VAPORBEAMPARTICLE, bool isNew)
{
	Net_Accept(vortex_beam);
	setthink(this, SUB_Remove);
	this.nextthink = time + bound(0, autocvar_cl_vaporizerbeam_lifetime, 10);
	this.draw = VaporizerBeam_Draw;
	if (isNew) IL_PUSH(g_drawables, this);
	this.drawmask = MASK_NORMAL;

	this.vorg1_x = ReadCoord(); this.vorg1_y = ReadCoord(); this.vorg1_z = ReadCoord();
	this.vorg2_x = ReadCoord(); this.vorg2_y = ReadCoord(); this.vorg2_z = ReadCoord();
	this.cnt = ReadByte();
	int myowner = ReadByte();
	this.owner = playerslots[myowner - 1];
	this.sv_entnum = myowner;
	this.team = ReadByte() - 1;

	pointparticles(EFFECT_VORTEX_MUZZLEFLASH, this.vorg1, normalize(this.vorg2 - this.vorg1) * 1000, 1);

	if(autocvar_cl_vaporizerbeam_particle)
	{
		WarpZone_TrailParticles(NULL, particleeffectnum(((this.cnt) ? EFFECT_VAPORIZER_HIT(this.team) : EFFECT_VAPORIZER(this.team))), this.vorg1, this.vorg2);
		this.draw = func_null;
		this.drawmask = MASK_NORMAL;
		delete(this);
	}

	return true;
}
#endif

#ifdef SVQC
spawnfunc(weapon_vaporizer) { weapon_defaultspawnfunc(this, WEP_VAPORIZER); }
spawnfunc(weapon_minstanex) { spawnfunc_weapon_vaporizer(this); }

void W_Vaporizer_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	bool flying = IsFlying(actor); // do this BEFORE to make the trace values from FireRailgunBullet last
	float vaporizer_damage = ((WEP_CVAR_PRI(vaporizer, damage) > 0) ? WEP_CVAR_PRI(vaporizer, damage) : 10000);

	W_SetupShot(actor, weaponentity, true, 0, SND_Null, CH_WEAPON_A, vaporizer_damage);
	// handle sound separately so we can change the volume
	// added bonus: no longer plays the strength sound (strength gives no bonus to instakill anyway)
	sound (actor, CH_WEAPON_A, SND_MINSTANEXFIRE, VOL_BASE * 0.8, ATTEN_NORM);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet(actor, weaponentity, w_shotorg, w_shotorg + w_shotdir * max_shot_distance, vaporizer_damage, 800, 0, 0, 0, 0, WEP_VAPORIZER.m_id);

	// do this now, as goodhits is disabled below
	SendCSQCVaporizerBeamParticle(actor, damage_goodhits);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(damage_goodhits && actor.vaporizer_lasthit)
	{
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		damage_goodhits = 0; // only every second time
	}

	actor.vaporizer_lasthit = damage_goodhits;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(vaporizer, ammo), weaponentity);
}

METHOD(Vaporizer, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(actor.(thiswep.ammo_field) > 0)
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 1, false);
    else
        PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR_SEC(vaporizer, speed), 0, WEP_CVAR_SEC(vaporizer, lifetime), false); // WEAPONTODO: replace with proper vaporizer cvars
}
METHOD(Vaporizer, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    float vaporizer_ammo = WEP_CVAR_PRI(vaporizer, ammo);
    // if the laser uses load, we also consider its ammo for reloading
    if(WEP_CVAR(vaporizer, reload_ammo) && WEP_CVAR_SEC(vaporizer, ammo) && actor.(weaponentity).clip_load < min(vaporizer_ammo, WEP_CVAR_SEC(vaporizer, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else if(WEP_CVAR(vaporizer, reload_ammo) && actor.(weaponentity).clip_load < vaporizer_ammo) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    }
    if((fire & 1) && !forbidWeaponUse(actor))
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(vaporizer, refire)))
        {
            W_Vaporizer_Attack(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(vaporizer, animtime), w_ready);
        }
    }
    if(fire & 2)
    {
        if (actor.(weaponentity).jump_interval <= time)
        {
            // handle refire manually, so that primary and secondary can be fired without conflictions (important for instagib)
            actor.(weaponentity).jump_interval = time + WEP_CVAR_SEC(vaporizer, refire) * W_WeaponRateFactor(actor);

            // decrease ammo for the laser?
            if(WEP_CVAR_SEC(vaporizer, ammo))
                W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(vaporizer, ammo), weaponentity);

            // ugly instagib hack to reuse the fire mode of the laser
            makevectors(actor.v_angle);
            Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
            actor.(weaponentity).m_weapon = WEP_BLASTER;
            W_Blaster_Attack(
                actor,
                weaponentity,
                WEP_BLASTER.m_id | HITTYPE_SECONDARY,
                WEP_CVAR_SEC(vaporizer, shotangle),
                WEP_CVAR_SEC(vaporizer, damage),
                WEP_CVAR_SEC(vaporizer, edgedamage),
                WEP_CVAR_SEC(vaporizer, radius),
                WEP_CVAR_SEC(vaporizer, force),
                WEP_CVAR_SEC(vaporizer, speed),
                WEP_CVAR_SEC(vaporizer, spread),
                WEP_CVAR_SEC(vaporizer, delay),
                WEP_CVAR_SEC(vaporizer, lifetime)
            );
            actor.(weaponentity).m_weapon = oldwep;

            // now do normal refire
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(vaporizer, animtime), w_ready);
        }
    }
    else
        actor.(weaponentity).held_down = false;
}
METHOD(Vaporizer, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
    actor.vaporizer_lasthit = 0;
}
METHOD(Vaporizer, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float vaporizer_ammo = WEP_CVAR_PRI(vaporizer, ammo);
    float ammo_amount = actor.(thiswep.ammo_field) >= vaporizer_ammo;
    ammo_amount += actor.(weaponentity).(weapon_load[WEP_VAPORIZER.m_id]) >= vaporizer_ammo;
    return ammo_amount;
}
METHOD(Vaporizer, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    if(!WEP_CVAR_SEC(vaporizer, ammo))
        return true;
    float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_SEC(vaporizer, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[WEP_VAPORIZER.m_id]) >= WEP_CVAR_SEC(vaporizer, ammo);
    return ammo_amount;
}
METHOD(Vaporizer, wr_resetplayer, void(entity thiswep, entity actor))
{
    actor.vaporizer_lasthit = 0;
}
METHOD(Vaporizer, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    float vaporizer_ammo = WEP_CVAR_PRI(vaporizer, ammo);
    float used_ammo;
    if(WEP_CVAR_SEC(vaporizer, ammo))
        used_ammo = min(vaporizer_ammo, WEP_CVAR_SEC(vaporizer, ammo));
    else
        used_ammo = vaporizer_ammo;

    W_Reload(actor, weaponentity, used_ammo, SND_RELOAD);
}
METHOD(Vaporizer, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Vaporizer, wr_killmessage, Notification(entity thiswep))
{
    return WEAPON_VAPORIZER_MURDER;
}

#endif
#ifdef CSQC

METHOD(Vaporizer, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2 = w_org + w_backoff * 6;
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        pointparticles(EFFECT_BLASTER_IMPACT, org2, w_backoff * 1000, 1);
        if(!w_issilent) { sound(actor, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM); }
    }
    else
    {
        pointparticles(EFFECT_VORTEX_IMPACT, org2, '0 0 0', 1);
        if(!w_issilent) { sound(actor, CH_SHOTS, SND_NEXIMPACT, VOL_BASE, ATTN_NORM); }
    }
}
METHOD(Vaporizer, wr_init, void(entity thiswep))
{
    if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
    {
        precache_pic("gfx/reticle_nex");
    }
}
METHOD(Vaporizer, wr_zoom, bool(entity thiswep, entity actor))
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
