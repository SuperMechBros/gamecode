#include "common.qh"

#include <common/t_items.qh>
#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/deathtypes/all.qh>
#include <common/notifications/all.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/items/_mod.qh>

void W_GiveWeapon(entity e, int wep)
{
	if (!wep) return;

	e.weapons |= WepSet_FromWeapon(Weapons_from(wep));

	if (IS_PLAYER(e)) {
	    Send_Notification(NOTIF_ONE, e, MSG_MULTI, ITEM_WEAPON_GOT, wep);
    }
}

void W_PlayStrengthSound(entity player) // void W_PlayStrengthSound
{
	if((player.items & ITEM_Strength.m_itemid)
		&& ((time > player.prevstrengthsound + autocvar_sv_strengthsound_antispam_time) // prevent insane sound spam
		|| (time > player.prevstrengthsoundattempt + autocvar_sv_strengthsound_antispam_refire_threshold)))
		{
			sound(player, CH_TRIGGER, SND_STRENGTH_FIRE, VOL_BASE, ATTEN_NORM);
			player.prevstrengthsound = time;
		}
		player.prevstrengthsoundattempt = time;
}

float W_CheckProjectileDamage(entity inflictor, entity projowner, int deathtype, float exception)
{
	float is_from_contents = (deathtype == DEATH_SLIME.m_id || deathtype == DEATH_LAVA.m_id);
	float is_from_owner = (inflictor == projowner);
	float is_from_exception = (exception != -1);

	//dprint(strcat("W_CheckProjectileDamage: from_contents ", ftos(is_from_contents), " : from_owner ", ftos(is_from_owner), " : exception ", strcat(ftos(is_from_exception), " (", ftos(exception), "). \n")));

	if(autocvar_g_projectiles_damage <= -2)
	{
		return false; // no damage to projectiles at all, not even with the exceptions
	}
	else if(autocvar_g_projectiles_damage == -1)
	{
		if(is_from_exception)
			return (exception); // if exception is detected, allow it to override
		else
			return false; // otherwise, no other damage is allowed
	}
	else if(autocvar_g_projectiles_damage == 0)
	{
		if(is_from_exception)
			return (exception); // if exception is detected, allow it to override
		else if(!is_from_contents)
			return false; // otherwise, only allow damage from contents
	}
	else if(autocvar_g_projectiles_damage == 1)
	{
		if(is_from_exception)
			return (exception); // if exception is detected, allow it to override
		else if(!(is_from_contents || is_from_owner))
			return false; // otherwise, only allow self damage and damage from contents
	}
	else if(autocvar_g_projectiles_damage == 2) // allow any damage, but override for exceptions
	{
		if(is_from_exception)
			return (exception); // if exception is detected, allow it to override
	}

	return true; // if none of these return, then allow damage anyway.
}

void W_PrepareExplosionByDamage(entity this, entity attacker, void(entity this) explode)
{
	this.takedamage = DAMAGE_NO;
	this.event_damage = func_null;

	if(IS_CLIENT(attacker) && !autocvar_g_projectiles_keep_owner)
	{
		this.owner = attacker;
		this.realowner = attacker;
	}

	MUTATOR_CALLHOOK(PrepareExplosionByDamage, this, attacker);

	// do not explode NOW but in the NEXT FRAME!
	// because recursive calls to RadiusDamage are not allowed
	this.nextthink = time;
	setthink(this, explode);
}
