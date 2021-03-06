#include "accuracy.qh"

#include "../mutators/_mod.qh"
#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>

int accuracy_byte(float n, float d)
{
	if (n <= 0) return 0;
	if (n > d) return 255;
	return 1 + rint(n * 100.0 / d);
}

bool accuracy_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_ACCURACY);

	entity a = this.owner;
	if (IS_SPEC(a)) a = a.enemy;
	a = a.accuracy;

	if (to != a.owner)
		if (!autocvar_sv_accuracy_data_share && !a.owner.cvar_cl_accuracy_data_share)
			sf = 0;
	// note: zero sendflags can never be sent... so we can use that to say that we send no accuracy!
	WriteInt24_t(MSG_ENTITY, sf);
	if (sf == 0) return true;
	// note: we know that client and server agree about SendFlags...
	int f = 1;
	for (int w = 0; w <= WEP_LAST - WEP_FIRST; ++w) {
		if (sf & f) WriteByte(MSG_ENTITY, accuracy_byte(a.accuracy_hit[w], a.accuracy_fired[w]));
		f = (f == 0x800000) ? 1 : f * 2;
	}
	return true;
}

// init/free
void accuracy_init(entity e)
{
	entity a = e.accuracy = new_pure(accuracy);
	a.owner = e;
	a.drawonlytoclient = e;
	Net_LinkEntity(a, false, 0, accuracy_send);
}

void accuracy_free(entity e)
{
	delete(e.accuracy);
}

// force a resend of a player's accuracy stats
void accuracy_resend(entity e)
{
	e.accuracy.SendFlags = 0xFFFFFF;
}

// update accuracy stats
//.float hit_time;
.float fired_time;

void accuracy_add(entity this, int w, int fired, int hit)
{
	if (IS_INDEPENDENT_PLAYER(this)) return;
	entity a = this.accuracy;
	if (!a) return;
	if (!hit && !fired) return;
	w -= WEP_FIRST;
	int b = accuracy_byte(a.accuracy_hit[w], a.accuracy_fired[w]);
	if (hit)    a.accuracy_hit  [w] += hit;
	if (fired)  a.accuracy_fired[w] += fired;

    if (hit && a.hit_time != time) { // only run this once per frame
        a.accuracy_cnt_hit[w] += 1;
        a.hit_time = time;
    }

    if (fired && a.fired_time != time) { // only run this once per frame
        a.accuracy_cnt_fired[w] += 1;
        a.fired_time = time;
    }

	if (b == accuracy_byte(a.accuracy_hit[w], a.accuracy_fired[w])) return; // no change
	int sf = 1 << (w % 24);
	a.SendFlags |= sf;
	FOREACH_CLIENT(IS_SPEC(it) && it.enemy == this, LAMBDA(it.accuracy.SendFlags |= sf));
}

bool accuracy_isgooddamage(entity attacker, entity targ)
{
	int mutator_check = MUTATOR_CALLHOOK(AccuracyTargetValid, attacker, targ);

	if (warmup_stage) return false;
	if (IS_DEAD(targ)) return false;
	if (SAME_TEAM(attacker, targ)) return false;

	if (mutator_check == MUT_ACCADD_INVALID) return true;

	if (mutator_check != MUT_ACCADD_VALID) return false;
	if (!IS_CLIENT(targ)) return false;

	return true;
}

bool accuracy_canbegooddamage(entity attacker)
{
	return !warmup_stage;
}
