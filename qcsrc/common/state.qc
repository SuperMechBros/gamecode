#include "state.qh"

void Inventory_new(entity this);
void Inventory_delete(entity this);

void PlayerState_attach(entity this)
{
	this._ps = NEW(PlayerState, this);

	Inventory_new(this);
}

void PlayerState_detach(entity this)
{
    PlayerState ps = PS(this);
	if (!ps) return;  // initial connect
	PS(this) = NULL;

	if (ps.m_client != this) return;  // don't own state, spectator
	ps.ps_push(ps, this);

	FOREACH_CLIENT(PS(it) == ps, { PS(it) = NULL; });
	delete(ps);

    Inventory_delete(this);
}

void GetCvars(entity this, int);
void DecodeLevelParms(entity this);
void PlayerScore_Attach(entity this);
void ClientData_Attach(entity this);
void accuracy_init(entity this);
void entcs_attach(entity this);
void playerdemo_init(entity this);
void anticheat_init(entity this);
void W_HitPlotOpen(entity this);
void bot_clientconnect(entity this);

void ClientState_attach(entity this)
{
	this._cs = NEW(ClientState, this);

    GetCvars(this, 0);  // get other cvars from player

	// TODO: fold all of these into ClientState

	DecodeLevelParms(this);

	PlayerScore_Attach(this);
	ClientData_Attach(this);
	accuracy_init(this);
	entcs_attach(this);
	playerdemo_init(this);
	anticheat_init(this);
	W_HitPlotOpen(this);

	bot_clientconnect(this);
}

void bot_clientdisconnect(entity this);
void W_HitPlotClose(entity this);
void anticheat_report_to_eventlog(entity this);
void playerdemo_shutdown(entity this);
void entcs_detach(entity this);
void accuracy_free(entity this);
void ClientData_Detach(entity this);
void PlayerScore_Detach(entity this);

void ClientState_detach(entity this)
{
	delete(CS(this));
	this._cs = NULL;

    GetCvars(this, -1);  // free cvars

    bot_clientdisconnect(this);

    W_HitPlotClose(this);
    anticheat_report_to_eventlog(this);
    playerdemo_shutdown(this);
    entcs_detach(this);
    accuracy_free(this);
    ClientData_Detach(this);
    PlayerScore_Detach(this);
}
