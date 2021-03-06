#include "spawning.qh"

#include "weaponsystem.qh"
#include "../mutators/_mod.qh"
#include <common/t_items.qh>
#include <common/weapons/_all.qh>

string W_Apply_Weaponreplace(string in)
{
	string out = "";
	FOREACH_WORD(in, true, {
		string replacement = "";
		Weapon w = Weapons_fromstr(it);
		if (w)
		{
            replacement = w.weaponreplace;
            if (replacement == "") replacement = it;
		}
		if (replacement == "0") continue;
		out = cons(out, replacement);
	});
	return out;
}

void weapon_defaultspawnfunc(entity this, Weapon e)
{
	Weapon wpn = e;
	if (this.classname != "droppedweapon" && this.classname != "replacedweapon")
	{
		if (e.spawnflags & WEP_FLAG_MUTATORBLOCKED)
		{
			LOG_WARNF("Attempted to spawn a mutator-blocked weapon rejected: prvm_edict server %i", this);
			startitem_failed = true;
			return;
		}

		string s = W_Apply_Weaponreplace(e.netname);
		MUTATOR_CALLHOOK(SetWeaponreplace, this, e, s);
		s = M_ARGV(2, string);
		if (s == "")
		{
			delete(this);
			startitem_failed = true;
			return;
		}
		int t = tokenize_console(s);
		if (t >= 2)
		{
			this.team = --internalteam;
			for (int i = 1; i < t; ++i)
			{
				s = argv(i);
				FOREACH(Weapons, it != WEP_Null, LAMBDA(
					if(it.netname == s)
					{
						entity replacement = spawn();
						copyentity(this, replacement);
						replacement.classname = "replacedweapon";
						weapon_defaultspawnfunc(replacement, it);
						break;
					}
				));
			}
		}
		if (t >= 1) // always the case!
		{
			s = argv(0);
			wpn = WEP_Null;
			FOREACH(Weapons, it != WEP_Null, LAMBDA(
				if(it.netname == s)
				{
					wpn = it;
					break;
				}
			));
		}
		if (wpn == WEP_Null)
		{
			delete(this);
			startitem_failed = true;
			return;
		}
	}

	if (!this.respawntime)
	{
		if (wpn.spawnflags & WEP_FLAG_SUPERWEAPON)
		{
			this.respawntime = g_pickup_respawntime_superweapon;
			this.respawntimejitter = g_pickup_respawntimejitter_superweapon;
		}
		else
		{
			this.respawntime = g_pickup_respawntime_weapon;
			this.respawntimejitter = g_pickup_respawntimejitter_weapon;
		}
	}

	if (wpn.spawnflags & WEP_FLAG_SUPERWEAPON)
		if (!this.superweapons_finished)
			this.superweapons_finished = autocvar_g_balance_superweapons_time;

	// if we don't already have ammo, give us some ammo
	if (!this.(wpn.ammo_field))
	{
		switch (wpn.ammo_field)
		{
			case ammo_shells:  this.ammo_shells  = cvar("g_pickup_shells_weapon");  break;
			case ammo_nails:   this.ammo_nails   = cvar("g_pickup_nails_weapon");   break;
			case ammo_rockets: this.ammo_rockets = cvar("g_pickup_rockets_weapon"); break;
			case ammo_cells:   this.ammo_cells   = cvar("g_pickup_cells_weapon");   break;
			case ammo_plasma:  this.ammo_plasma  = cvar("g_pickup_plasma_weapon");  break;
			case ammo_fuel:    this.ammo_fuel    = cvar("g_pickup_fuel_weapon");    break;
		}
	}

	#if 0 // WEAPONTODO
	if (wpn.items)
	{
		for (int i = 0, j = 1; i < 24; ++i, j <<= 1)
		{
			if (wpn.items & j)
			{
				ammotype = Item_CounterField(j);
				if (!this.ammotype)
					this.ammotype = cvar(strcat("g_pickup_", Item_CounterFieldName(j), "_weapon"));
			}
		}
	}
	#endif

	// pickup anyway
	if (g_pickup_weapons_anyway)
		this.pickup_anyway = true;

	GameItem def = wpn.m_pickup;
	_StartItem(
		this,
		this.itemdef = def,
		this.respawntime, // defaultrespawntime
		this.respawntimejitter // defaultrespawntimejitter
	);
	#if 0 // WEAPONTODO
	if (this.modelindex) { // don't precache if this was removed
		wpn.wr_init(wpn);
	}
	#endif
}
