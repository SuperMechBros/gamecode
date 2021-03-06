#include "breakable.qh"
#ifdef SVQC

#include <server/g_subs.qh>
#include <server/g_damage.qh>
#include <server/bot/api.qh>
#include <common/csqcmodel_settings.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <server/weapons/common.qh>

.entity sprite;

.float dmg;
.float dmg_edge;
.float dmg_radius;
.float dmg_force;
.float debrismovetype;
.float debrissolid;
.vector debrisvelocity;
.vector debrisvelocityjitter;
.vector debrisavelocityjitter;
.float debristime;
.float debristimejitter;
.float debrisfadetime;
.float debrisdamageforcescale;
.float debrisskin;

.string mdl_dead; // or "" to hide when broken
.string debris; // space separated list of debris models
// other fields:
//   mdl = particle effect name
//   count = particle effect multiplier
//   targetname = target to trigger to unbreak the model
//   target = targets to trigger when broken
//   health = amount of damage it can take
//   spawnflags:
//     1 = start disabled (needs to be triggered to activate)
//     2 = indicate damage
//     4 = don't take direct damage (needs to be triggered to 'explode', then triggered again to restore)
// notes:
//   for mdl_dead to work, origin must be set (using a common/origin brush).
//   Otherwise mdl_dead will be displayed at the map origin, and nobody would
//   want that!

void func_breakable_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force);

//
// func_breakable
// - basically func_assault_destructible for general gameplay use
//
void LaunchDebris (entity this, string debrisname, vector force)
{
	entity dbr = spawn();
	vector org = this.absmin
	           + '1 0 0' * random() * (this.absmax.x - this.absmin.x)
	           + '0 1 0' * random() * (this.absmax.y - this.absmin.y)
	           + '0 0 1' * random() * (this.absmax.z - this.absmin.z);
	setorigin(dbr, org);
	_setmodel (dbr, debrisname );
	dbr.skin = this.debrisskin;
	dbr.colormap = this.colormap; // inherit team colors
	dbr.owner = this; // do not be affected by our own explosion
	set_movetype(dbr, this.debrismovetype);
	dbr.solid = this.debrissolid;
	if(dbr.solid != SOLID_BSP) // SOLID_BSP has exact collision, MAYBE this works? TODO check this out
		setsize(dbr, '0 0 0', '0 0 0'); // needed for performance, until engine can deal better with it
	dbr.velocity_x = this.debrisvelocity.x + this.debrisvelocityjitter.x * crandom();
	dbr.velocity_y = this.debrisvelocity.y + this.debrisvelocityjitter.y * crandom();
	dbr.velocity_z = this.debrisvelocity.z + this.debrisvelocityjitter.z * crandom();
	this.velocity = this.velocity + force * this.debrisdamageforcescale;
	dbr.avelocity_x = random()*this.debrisavelocityjitter.x;
	dbr.avelocity_y = random()*this.debrisavelocityjitter.y;
	dbr.avelocity_z = random()*this.debrisavelocityjitter.z;
	dbr.damageforcescale = this.debrisdamageforcescale;
	if(dbr.damageforcescale)
		dbr.takedamage = DAMAGE_YES;
	SUB_SetFade(dbr, time + this.debristime + crandom() * this.debristimejitter, this.debrisfadetime);
}

void func_breakable_colormod(entity this)
{
	float h;
	if (!(this.spawnflags & 2))
		return;
	h = this.health / this.max_health;
	if(h < 0.25)
		this.colormod = '1 0 0';
	else if(h <= 0.75)
		this.colormod = '1 0 0' + '0 1 0' * (2 * h - 0.5);
	else
		this.colormod = '1 1 1';
}

void func_breakable_look_destroyed(entity this)
{
	float floorZ;

	if(this.solid == SOLID_BSP) // in case a misc_follow moved me, save the current origin first
		this.dropped_origin = this.origin;

	if(this.mdl_dead == "")
		this.effects |= EF_NODRAW;
	else {
		if (this.origin == '0 0 0')	{	// probably no origin brush, so don't spawn in the middle of the map..
			floorZ = this.absmin.z;
			setorigin(this, ((this.absmax + this.absmin) * 0.5));
			this.origin_z = floorZ;
		}
		_setmodel(this, this.mdl_dead);
		ApplyMinMaxScaleAngles(this);
		this.effects &= ~EF_NODRAW;
	}

	this.solid = SOLID_NOT;
}

void func_breakable_look_restore(entity this)
{
	_setmodel(this, this.mdl);
	ApplyMinMaxScaleAngles(this);
	this.effects &= ~EF_NODRAW;

	if(this.mdl_dead != "") // only do this if we use mdl_dead, to behave better with misc_follow
		setorigin(this, this.dropped_origin);

	this.solid = SOLID_BSP;
}

void func_breakable_behave_destroyed(entity this)
{
	this.health = this.max_health;
	this.takedamage = DAMAGE_NO;
	if(this.bot_attack)
		IL_REMOVE(g_bot_targets, this);
	this.bot_attack = false;
	this.event_damage = func_null;
	this.state = 1;
	if(this.spawnflags & 4)
		this.use = func_null;
	func_breakable_colormod(this);
	if (this.noise1)
		stopsound (this, CH_TRIGGER_SINGLE);
}

void func_breakable_think(entity this)
{
	this.nextthink = time;
	CSQCMODEL_AUTOUPDATE(this);
}

void func_breakable_destroy(entity this, entity actor, entity trigger);
void func_breakable_behave_restore(entity this)
{
	this.health = this.max_health;
	if(this.sprite)
	{
		WaypointSprite_UpdateMaxHealth(this.sprite, this.max_health);
		WaypointSprite_UpdateHealth(this.sprite, this.health);
	}
	if(!(this.spawnflags & 4))
	{
		this.takedamage = DAMAGE_AIM;
		if(!this.bot_attack)
			IL_PUSH(g_bot_targets, this);
		this.bot_attack = true;
		this.event_damage = func_breakable_damage;
	}
	if(this.spawnflags & 4)
		this.use = func_breakable_destroy; // don't need to set it usually, as .use isn't reset
	this.state = 0;
	//this.nextthink = 0; // cancel auto respawn
	setthink(this, func_breakable_think);
	this.nextthink = time + 0.1;
	func_breakable_colormod(this);
	if (this.noise1)
		_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
}

void func_breakable_init_for_player(entity this, entity player)
{
	if (this.noise1 && this.state == 0 && clienttype(player) == CLIENTTYPE_REAL)
	{
		msg_entity = player;
		soundto (MSG_ONE, this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	}
}

void func_breakable_destroyed(entity this)
{
	func_breakable_look_destroyed(this);
	func_breakable_behave_destroyed(this);
}

void func_breakable_restore(entity this, entity actor, entity trigger)
{
	func_breakable_look_restore(this);
	func_breakable_behave_restore(this);
}

void func_breakable_restore_self(entity this)
{
	func_breakable_restore(this, NULL, NULL);
}

vector debrisforce; // global, set before calling this
void func_breakable_destroy(entity this, entity actor, entity trigger)
{
	float n, i;
	string oldmsg;

	entity act = this.owner;
	this.owner = NULL; // set by W_PrepareExplosionByDamage

	// now throw around the debris
	n = tokenize_console(this.debris);
	for(i = 0; i < n; ++i)
		LaunchDebris(this, argv(i), debrisforce);

	func_breakable_destroyed(this);

	if(this.noise)
		_sound (this, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);

	if(this.dmg)
		RadiusDamage(this, act, this.dmg, this.dmg_edge, this.dmg_radius, this, NULL, this.dmg_force, DEATH_HURTTRIGGER.m_id, NULL);

	if(this.cnt) // TODO
		__pointparticles(this.cnt, this.absmin * 0.5 + this.absmax * 0.5, '0 0 0', this.count);

	if(this.respawntime)
	{
		CSQCMODEL_AUTOUPDATE(this);
		setthink(this, func_breakable_restore_self);
		this.nextthink = time + this.respawntime + crandom() * this.respawntimejitter;
	}

	oldmsg = this.message;
	this.message = "";
	SUB_UseTargets(this, act, trigger);
	this.message = oldmsg;
}

void func_breakable_destroy_self(entity this)
{
	func_breakable_destroy(this, NULL, NULL);
}

void func_breakable_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(this.state == 1)
		return;
	if(this.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	if(this.team)
		if(attacker.team == this.team)
			return;
	this.pain_finished = time;
	this.health = this.health - damage;
	if(this.sprite)
	{
		WaypointSprite_Ping(this.sprite);
		WaypointSprite_UpdateHealth(this.sprite, this.health);
	}
	func_breakable_colormod(this);

	if(this.health <= 0)
	{
		debrisforce = force;

		this.takedamage = DAMAGE_NO;
		this.event_damage = func_null;

		if(IS_CLIENT(attacker) && this.classname == "func_assault_destructible")
		{
			this.owner = attacker;
			this.realowner = attacker;
		}

		// do not explode NOW but in the NEXT FRAME!
		// because recursive calls to RadiusDamage are not allowed
		this.nextthink = time;
		CSQCMODEL_AUTOUPDATE(this);
		setthink(this, func_breakable_destroy_self);
	}
}

void func_breakable_reset(entity this)
{
	this.team = this.team_saved;
	func_breakable_look_restore(this);
	if(this.spawnflags & 1)
		func_breakable_behave_destroyed(this);
	else
		func_breakable_behave_restore(this);
}

// destructible walls that can be used to trigger target_objective_decrease
spawnfunc(func_breakable)
{
	float n, i;
	if(!this.health)
		this.health = 100;
	this.max_health = this.health;

	// yes, I know, MOVETYPE_NONE is not available here, not that one would want it here anyway
	if(!this.debrismovetype) this.debrismovetype = MOVETYPE_BOUNCE;
	if(!this.debrissolid) this.debrissolid = SOLID_NOT;
	if(this.debrisvelocity == '0 0 0') this.debrisvelocity = '0 0 140';
	if(this.debrisvelocityjitter == '0 0 0') this.debrisvelocityjitter = '70 70 70';
	if(this.debrisavelocityjitter == '0 0 0') this.debrisavelocityjitter = '600 600 600';
	if(!this.debristime) this.debristime = 3.5;
	if(!this.debristimejitter) this.debristime = 2.5;

	if(this.mdl != "")
		this.cnt = _particleeffectnum(this.mdl);
	if(this.count == 0)
		this.count = 1;

	if(this.message == "")
		this.message = "got too close to an explosion";
	if(this.message2 == "")
		this.message2 = "was pushed into an explosion by";
	if(!this.dmg_radius)
		this.dmg_radius = 150;
	if(!this.dmg_force)
		this.dmg_force = 200;

	this.mdl = this.model;
	SetBrushEntityModel(this);

	if(this.spawnflags & 4)
		this.use = func_breakable_destroy;
	else
		this.use = func_breakable_restore;

	if(this.spawnflags & 4)
	{
		this.takedamage = DAMAGE_NO;
		this.event_damage = func_null;
		this.bot_attack = false;
	}

	// precache all the models
	if (this.mdl_dead)
		precache_model(this.mdl_dead);
	n = tokenize_console(this.debris);
	for(i = 0; i < n; ++i)
		precache_model(argv(i));
	if(this.noise)
		precache_sound(this.noise);
	if(this.noise1)
		precache_sound(this.noise1);

	this.team_saved = this.team;
	this.dropped_origin = this.origin;

	this.reset = func_breakable_reset;
	this.reset(this);

	IL_PUSH(g_initforplayer, this);
	this.init_for_player = func_breakable_init_for_player;

	CSQCMODEL_AUTOINIT(this);
}

// for use in maps with a "model" key set
spawnfunc(misc_breakablemodel) {
	spawnfunc_func_breakable(this);
}
#endif
