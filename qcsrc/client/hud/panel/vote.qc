#include "vote.qh"

#include <common/mapinfo.qh>

// Vote (#9)

void HUD_Vote()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_vote) return;
		/*
		if(cvar("hud_panel_vote_test")) {
			if(vote_called_vote) strunzone(vote_called_vote); vote_called_vote = strzone("^1test the vote panel");
			vote_active = true; vote_yescount = 3; vote_nocount = 2; vote_needed = 4;
		} else vote_active = false;
		*/
	}
	else
	{
		vote_yescount = 3;
		vote_nocount = 2;
		vote_needed = 4;
	}

	string s;
	float a;
	if(vote_active != vote_prev) {
		vote_change = time;
		vote_prev = vote_active;
	}

	if(vote_active || autocvar__hud_configure)
		vote_alpha = bound(0, (time - vote_change) * 2, 1);
	else
		vote_alpha = bound(0, 1 - (time - vote_change) * 2, 1);

	a = vote_alpha * (vote_highlighted ? autocvar_hud_panel_vote_alreadyvoted_alpha : 1);
	if(a <= 0)
		return;
	//panel_fade_alpha *= a;
	// nothing can hide this panel, not even the menu
	float hud_fade_alpha_save = hud_fade_alpha;
	hud_fade_alpha = a;
	HUD_Panel_LoadCvars();
	hud_fade_alpha = hud_fade_alpha_save;

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_vote_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 3:1 aspect
	vector newSize = '0 0 0';
	if(mySize.x/mySize.y > 3)
	{
		newSize.x = 3 * mySize.y;
		newSize.y = mySize.y;

		pos.x = pos.x + (mySize.x - newSize.x) / 2;
	}
	else
	{
		newSize.y = 1/3 * mySize.x;
		newSize.x = mySize.x;

		pos.y = pos.y + (mySize.y - newSize.y) / 2;
	}
	mySize = newSize;

	s = _("A vote has been called for:");
	drawstring_aspect(pos, s, eX * mySize.x + eY * (2/8) * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	s = textShortenToWidth(ColorTranslateRGB(vote_called_vote), mySize.x, '1 1 0' * mySize.y * (1/8), stringwidth_colors);
	if(autocvar__hud_configure)
		s = _("^1Configure the HUD");
	drawcolorcodedstring_aspect(pos + eY * (2/8) * mySize.y, s, eX * mySize.x + eY * (1.75/8) * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);

	// print the yes/no counts
	s = sprintf("^2%s ^7(%d)", getcommandkey_forcename(_("Yes"), "vyes"), vote_yescount);
	drawcolorcodedstring_aspect(pos + eY * (4/8) * mySize.y, s, eX * 0.5 * mySize.x + eY * (1.5/8) * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);
	s = sprintf("^1%s ^7(%d)", getcommandkey_forcename(_("No"), "vno"), vote_nocount);
	drawcolorcodedstring_aspect(pos + eX * 0.5 * mySize.x + eY * (4/8) * mySize.y, s, eX * 0.5 * mySize.x + eY * (1.5/8) * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);

	pos.y += (5/8) * mySize.y;
	vector tmp_size = eX * mySize.x + eY * (3/8) * mySize.y;
	// draw the progress bar backgrounds
	drawpic_skin(pos, "voteprogress_back", tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

	// draw the highlights
	if(vote_highlighted == 1) {
		drawsetcliparea(pos.x, pos.y, mySize.x * 0.5, mySize.y);
		drawpic_skin(pos, "voteprogress_voted", tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else if(vote_highlighted == -1) {
		drawsetcliparea(pos.x + 0.5 * mySize.x, pos.y, mySize.x * 0.5, mySize.y);
		drawpic_skin(pos, "voteprogress_voted", tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	// draw the progress bars
	if(vote_yescount && vote_needed)
	{
		drawsetcliparea(pos.x, pos.y, mySize.x * 0.5 * (vote_yescount/vote_needed), mySize.y);
		drawpic_skin(pos, "voteprogress_prog", tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if(vote_nocount && vote_needed)
	{
		drawsetcliparea(pos.x + mySize.x - mySize.x * 0.5 * (vote_nocount/vote_needed), pos.y, mySize.x * 0.5, mySize.y);
		drawpic_skin(pos, "voteprogress_prog", tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	drawresetcliparea();
}
