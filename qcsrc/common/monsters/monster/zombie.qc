#include "zombie.qh"

#ifdef SVQC
float autocvar_g_monster_zombie_health;
float autocvar_g_monster_zombie_damageforcescale = 0.55;
float autocvar_g_monster_zombie_attack_melee_damage;
float autocvar_g_monster_zombie_attack_melee_delay;
float autocvar_g_monster_zombie_attack_leap_damage;
float autocvar_g_monster_zombie_attack_leap_force;
float autocvar_g_monster_zombie_attack_leap_speed;
float autocvar_g_monster_zombie_attack_leap_delay;
float autocvar_g_monster_zombie_speed_stop;
float autocvar_g_monster_zombie_speed_run;
float autocvar_g_monster_zombie_speed_walk;

/*
const float zombie_anim_attackleap			= 0;
const float zombie_anim_attackrun1			= 1;
const float zombie_anim_attackrun2			= 2;
const float zombie_anim_attackrun3			= 3;
const float zombie_anim_attackstanding1		= 4;
const float zombie_anim_attackstanding2		= 5;
const float zombie_anim_attackstanding3		= 6;
const float zombie_anim_blockend			= 7;
const float zombie_anim_blockstart			= 8;
const float zombie_anim_deathback1			= 9;
const float zombie_anim_deathback2			= 10;
const float zombie_anim_deathback3			= 11;
const float zombie_anim_deathfront1			= 12;
const float zombie_anim_deathfront2			= 13;
const float zombie_anim_deathfront3			= 14;
const float zombie_anim_deathleft1			= 15;
const float zombie_anim_deathleft2			= 16;
const float zombie_anim_deathright1			= 17;
const float zombie_anim_deathright2			= 18;
const float zombie_anim_idle				= 19;
const float zombie_anim_painback1			= 20;
const float zombie_anim_painback2			= 21;
const float zombie_anim_painfront1			= 22;
const float zombie_anim_painfront2			= 23;
const float zombie_anim_runbackwards		= 24;
const float zombie_anim_runbackwardsleft	= 25;
const float zombie_anim_runbackwardsright	= 26;
const float zombie_anim_runforward			= 27;
const float zombie_anim_runforwardleft		= 28;
const float zombie_anim_runforwardright		= 29;
const float zombie_anim_spawn				= 30;
*/

.vector moveto;

void M_Zombie_Attack_Leap_Touch(entity this, entity toucher)
{
	if (this.health <= 0)
		return;

	vector angles_face;

	if(toucher.takedamage)
	{
		angles_face = vectoangles(this.moveto - this.origin);
		angles_face = normalize(angles_face) * (autocvar_g_monster_zombie_attack_leap_force);
		Damage(toucher, this, this, (autocvar_g_monster_zombie_attack_leap_damage) * MONSTER_SKILLMOD(this), DEATH_MONSTER_ZOMBIE_JUMP.m_id, toucher.origin, angles_face);
		settouch(this, Monster_Touch); // instantly turn it off to stop damage spam
		this.state = 0;
	}

	if (trace_dphitcontents)
	{
		this.state = 0;
		settouch(this, Monster_Touch);
	}
}

void M_Zombie_Defend_Block_End(entity this)
{
	if(this.health <= 0)
		return;

	setanim(this, this.anim_blockend, false, true, true);
	this.armorvalue = autocvar_g_monsters_armor_blockpercent;
}

bool M_Zombie_Defend_Block(entity this)
{
	this.armorvalue = 0.9;
	this.state = MONSTER_ATTACK_MELEE; // freeze monster
	this.attack_finished_single[0] = time + 2.1;
	this.anim_finished = this.attack_finished_single[0];
	setanim(this, this.anim_blockstart, false, true, true);

	Monster_Delay(this, 1, 2, M_Zombie_Defend_Block_End);

	return true;
}

bool M_Zombie_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(random() < 0.3 && actor.health < 75 && actor.enemy.health > 10)
				return M_Zombie_Defend_Block(actor);

			float anim_chance = random();
			vector chosen_anim;

			if(anim_chance < 0.33)
				chosen_anim = actor.anim_melee1;
			else if(anim_chance < 0.66)
				chosen_anim = actor.anim_melee2;
			else
				chosen_anim = actor.anim_melee3;

			return Monster_Attack_Melee(actor, actor.enemy, (autocvar_g_monster_zombie_attack_melee_damage), chosen_anim, actor.attack_range, (autocvar_g_monster_zombie_attack_melee_delay), DEATH_MONSTER_ZOMBIE_MELEE.m_id, true);
		}
		case MONSTER_ATTACK_RANGED:
		{
			makevectors(actor.angles);
			return Monster_Attack_Leap(actor, actor.anim_shoot, M_Zombie_Attack_Leap_Touch, v_forward * (autocvar_g_monster_zombie_attack_leap_speed) + '0 0 200', (autocvar_g_monster_zombie_attack_leap_delay));
		}
	}

	return false;
}

spawnfunc(monster_zombie) { Monster_Spawn(this, true, MON_ZOMBIE.monsterid); }
#endif // SVQC

#ifdef SVQC
METHOD(Zombie, mr_think, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    if(time >= actor.spawn_time)
        actor.damageforcescale = autocvar_g_monster_zombie_damageforcescale;
    return true;
}

METHOD(Zombie, mr_pain, float(Zombie this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(Zombie, this);
    actor.pain_finished = time + 0.34;
    setanim(actor, ((random() > 0.5) ? actor.anim_pain1 : actor.anim_pain2), true, true, false);
    return damage_take;
}

METHOD(Zombie, mr_death, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    actor.armorvalue = autocvar_g_monsters_armor_blockpercent;

    setanim(actor, ((random() > 0.5) ? actor.anim_die1 : actor.anim_die2), false, true, true);
    return true;
}
#endif
#ifdef GAMEQC
METHOD(Zombie, mr_anim, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    vector none = '0 0 0';
    actor.anim_die1 = animfixfps(actor, '9 1 0.5', none); // 2 seconds
    actor.anim_die2 = animfixfps(actor, '12 1 0.5', none); // 2 seconds
    actor.anim_spawn = animfixfps(actor, '30 1 3', none);
    actor.anim_walk = animfixfps(actor, '27 1 1', none);
    actor.anim_idle = animfixfps(actor, '19 1 1', none);
    actor.anim_pain1 = animfixfps(actor, '20 1 2', none); // 0.5 seconds
    actor.anim_pain2 = animfixfps(actor, '22 1 2', none); // 0.5 seconds
    actor.anim_melee1 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_melee2 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_melee3 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_shoot = animfixfps(actor, '0 1 5', none); // analyze models and set framerate
    actor.anim_run = animfixfps(actor, '27 1 1', none);
    actor.anim_blockstart = animfixfps(actor, '8 1 1', none);
    actor.anim_blockend = animfixfps(actor, '7 1 1', none);
    return true;
}
#endif
#ifdef SVQC
METHOD(Zombie, mr_setup, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    if(!actor.health) actor.health = (autocvar_g_monster_zombie_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_zombie_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_zombie_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_zombie_speed_stop); }

    if(actor.spawnflags & MONSTERFLAG_NORESPAWN)
        actor.spawnflags &= ~MONSTERFLAG_NORESPAWN; // zombies always respawn

    actor.spawnflags &= ~MONSTERFLAG_APPEAR; // once it's appeared, it will respawn quickly, we don't want it to appear

    actor.spawnflags |= MONSTER_RESPAWN_DEATHPOINT;

    actor.monster_loot = ITEM_HealthMedium;
    actor.monster_attackfunc = M_Zombie_Attack;
    actor.spawnshieldtime = actor.spawn_time;
    actor.respawntime = 0.2;
    actor.damageforcescale = 0.0001; // no push while spawning

    setanim(actor, actor.anim_spawn, false, true, true);
    actor.spawn_time = actor.animstate_endtime;

    return true;
}

METHOD(Zombie, mr_precache, bool(Zombie this))
{
    TC(Zombie, this);
    return true;
}
#endif
