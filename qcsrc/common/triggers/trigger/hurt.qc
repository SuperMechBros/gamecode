#include "hurt.qh"
#ifdef SVQC
void trigger_hurt_use(entity this, entity actor, entity trigger)
{
	if(IS_PLAYER(actor))
		this.enemy = actor;
	else
		this.enemy = NULL; // let's just destroy it, if taking over is too much work
}

.float triggerhurttime;
void trigger_hurt_touch(entity this, entity toucher)
{
	if (this.active != ACTIVE_ACTIVE)
		return;

	if(this.team)
		if(((this.spawnflags & 4) == 0) == (this.team != toucher.team))
			return;

	// only do the EXACTTRIGGER_TOUCH checks when really needed (saves some cpu)
	if (toucher.iscreature)
	{
		if (toucher.takedamage)
		if (toucher.triggerhurttime < time)
		{
			EXACTTRIGGER_TOUCH(this, toucher);
			toucher.triggerhurttime = time + 1;

			entity own;
			own = this.enemy;
			if (!IS_PLAYER(own))
			{
				own = this;
				this.enemy = NULL; // I still hate you all
			}

			Damage (toucher, this, own, this.dmg, DEATH_HURTTRIGGER.m_id, toucher.origin, '0 0 0');
		}
	}
	else if(toucher.damagedbytriggers)
	{
		if(toucher.takedamage)
		{
			EXACTTRIGGER_TOUCH(this, toucher);
			Damage(toucher, this, this, this.dmg, DEATH_HURTTRIGGER.m_id, toucher.origin, '0 0 0');
		}
	}

	return;
}

/*QUAKED spawnfunc_trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
defalt dmg = 5
*/
.entity trigger_hurt_next;
entity trigger_hurt_last;
entity trigger_hurt_first;
spawnfunc(trigger_hurt)
{
	EXACTTRIGGER_INIT;
	this.active = ACTIVE_ACTIVE;
	settouch(this, trigger_hurt_touch);
	this.use = trigger_hurt_use;
	this.enemy = world; // I hate you all
	if (!this.dmg)
		this.dmg = 1000;
	if (this.message == "")
		this.message = "was in the wrong place";
	if (this.message2 == "")
		this.message2 = "was thrown into a world of hurt by";
	// this.message = "someone like %s always gets wrongplaced";

	if(!trigger_hurt_first)
		trigger_hurt_first = this;
	if(trigger_hurt_last)
		trigger_hurt_last.trigger_hurt_next = this;
	trigger_hurt_last = this;
}

float tracebox_hits_trigger_hurt(vector start, vector mi, vector ma, vector end)
{
	entity th;

	for(th = trigger_hurt_first; th; th = th.trigger_hurt_next)
		if(tracebox_hits_box(start, mi, ma, end, th.absmin, th.absmax))
			return true;

	return false;
}
#endif
