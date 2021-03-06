#include "campaign.qh"

#include <common/campaign_common.qh>
#include "inputbox.qh"

string campaign_longdesc_wrapped[CAMPAIGN_MAX_ENTRIES];

void rewrapCampaign(float w, float l0, float emptyheight, vector theFontSize)
{
	int i, j;
	int n;
	float l;
	string r, s;
	for(i = 0; i < campaign_entries; ++i)
	{
		l = l0;
		if(campaign_longdesc_wrapped[i])
			strunzone(campaign_longdesc_wrapped[i]);
		n = tokenizebyseparator(campaign_longdesc[i], "\n");
		r = "";
		for(j = 0; j < n; ++j)
		{
			s = argv(j);
			if(s == "")
			{
				l -= emptyheight;
				r = strcat(r, "\n");
				continue;
			}

			getWrappedLine_remaining = s;
			while(getWrappedLine_remaining)
			{
				s = getWrappedLine(w, theFontSize, draw_TextWidth_WithoutColors);
				if(--l < 0) goto toolong;
				r = strcat(r, s, "\n");
			}
		}
		goto nottoolong;
LABEL(toolong)
		while(substring(r, strlen(r) - 1, 1) == "\n")
			r = substring(r, 0, strlen(r) - 1);
		r = strcat(r, "...\n");
LABEL(nottoolong)
		campaign_longdesc_wrapped[i] = strzone(substring(r, 0, strlen(r) - 1));
	}
}

entity makeXonoticCampaignList()
{
	entity me;
	me = NEW(XonoticCampaignList);
	me.configureXonoticCampaignList(me);
	return me;
}
void XonoticCampaignList_configureXonoticCampaignList(entity me)
{
	me.configureXonoticListBox(me);
	me.campaignGlob = search_begin("maps/campaign*.txt", true, true);
	me.loadCvars(me);
	me.campaignGo(me, 0); // takes care of enabling/disabling buttons too
}

void XonoticCampaignList_destroy(entity me)
{
	if(me.campaignGlob >= 0)
		search_end(me.campaignGlob);
}

void XonoticCampaignList_loadCvars(entity me)
{
	// read campaign cvars
	if(campaign_name)
		strunzone(campaign_name);
	if(me.cvarName)
		strunzone(me.cvarName);
	campaign_name = strzone(cvar_string("g_campaign_name"));
	me.cvarName = strzone(strcat("g_campaign", campaign_name, "_index"));
	registercvar(me.cvarName, "", 0); // saved by server QC anyway
	CampaignFile_Unload();
	CampaignFile_Load(0, CAMPAIGN_MAX_ENTRIES);
	me.campaignIndex = bound(0, cvar(me.cvarName), campaign_entries);
	cvar_set(me.cvarName, ftos(me.campaignIndex));
	if(me.columnNameSize)
		rewrapCampaign(me.columnNameSize, me.rowsPerItem - 3, me.emptyLineHeight, me.realFontSize);
	me.nItems = min(me.campaignIndex + 2, campaign_entries);
	me.setSelected(me, min(me.campaignIndex, me.nItems - 1));
	if(me.nItems - 1 > me.campaignIndex)
		me.scrollToItem(me, me.nItems - 1);
	if(me.labelTitle)
		me.labelTitle.setText(me.labelTitle, campaign_title);
}

void XonoticCampaignList_saveCvars(entity me)
{
	// write campaign cvars
	// no reason to do this!
	// cvar_set("g_campaign_name", campaign_name);
	// cvar_set(me.cvarName, ftos(me.campaignIndex)); // NOTE: only server QC does that!
}

void XonoticCampaignList_campaignGo(entity me, float step)
{
	float canNext, canPrev;
	string s;
	float i, j, n;

	canNext = canPrev = 0;

	if(me.campaignGlob >= 0)
	{
		n = search_getsize(me.campaignGlob);
		if(n > 0)
		{
			j = -1;
			s = strcat("maps/campaign", campaign_name, ".txt");
			for(i = 0; i < n; ++i)
			{
				if(search_getfilename(me.campaignGlob, i) == s)
					j = i;
			}
			if(j < 0)
			{
				s = strcat("maps/campaign", cvar_defstring("g_campaign_name"), ".txt");
				for(i = 0; i < n; ++i)
				{
					if(search_getfilename(me.campaignGlob, i) == s)
						j = i;
				}
			}
			if(j < 0)
			{
				if(step >= 0)
					j = 0;
				else
					j = n - 1;
			}
			else
				j = mod(j + step, n);
			s = search_getfilename(me.campaignGlob, j);
			s = substring(s, 13, strlen(s) - 17);
			cvar_set("g_campaign_name", s);
			me.loadCvars(me);
			canNext = (j != n - 1);
			canPrev = (j != 0);
		}
	}

	if(me.buttonNext)
		me.buttonNext.disabled = !canNext;
	if(me.buttonPrev)
		me.buttonPrev.disabled = !canPrev;
}

void MultiCampaign_Next(entity btn, entity me)
{
	me.campaignGo(me, +1);
}
void MultiCampaign_Prev(entity btn, entity me)
{
	me.campaignGo(me, -1);
}

void XonoticCampaignList_draw(entity me)
{
	if(cvar(me.cvarName) != me.campaignIndex || cvar_string("g_campaign_name") != campaign_name)
		me.loadCvars(me);
	SUPER(XonoticCampaignList).draw(me);
}

void XonoticCampaignList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticCampaignList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize.y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize.x * (1 - me.controlWidth)));
	me.realUpperMargin1 = 0.5 * me.realFontSize.y;
	me.realUpperMargin2 = me.realUpperMargin1 + 2 * me.realFontSize.y;

	me.checkMarkSize = (eX * (me.itemAbsSize.y / me.itemAbsSize.x) + eY) * 0.5;

	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize.y / me.itemAbsSize.x * 4 / 3;
	me.columnCheckMarkSize = me.checkMarkSize.x;
	me.columnNameSize = 1 - me.columnPreviewSize - me.columnCheckMarkSize - 4 * me.realFontSize.x;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize.x;
	me.columnCheckMarkOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize.x * 2;

	me.checkMarkOrigin = eY + eX * (me.columnCheckMarkOrigin + me.columnCheckMarkSize) - me.checkMarkSize;

	rewrapCampaign(me.columnNameSize, me.rowsPerItem - 3, me.emptyLineHeight, me.realFontSize);
}
void XonoticCampaignList_doubleClickListBoxItem(entity me, float i, vector where)
{
	CampaignList_LoadMap(me, me);
}
void XonoticCampaignList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	vector theColor;
	float theAlpha;
	float j, n;
	vector o;

	if(i < me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_SELECTABLE;
		theColor = SKINCOLOR_CAMPAIGN_SELECTABLE;
	}
	else if(i == me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_CURRENT;
		theColor = SKINCOLOR_CAMPAIGN_CURRENT;
	}
	else
	{
		theAlpha = SKINALPHA_CAMPAIGN_FUTURE;
		theColor = SKINCOLOR_CAMPAIGN_FUTURE;
	}

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	if(draw_PictureSize(strcat("/maps/", campaign_mapname[i])) == '0 0 0')
		draw_Picture(me.columnPreviewOrigin * eX, "nopreview_map", me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	else
		draw_Picture(me.columnPreviewOrigin * eX, strcat("/maps/", campaign_mapname[i]), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);

	if(i < me.campaignIndex)
		draw_Picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);
	if(i <= me.campaignIndex)
		s = campaign_shortdesc[i]; // fteqcc sucks
	else
		s = "???";
	if(strstrofs(s, "Level", 0) >= 0) // it already has a level name/number, just who title
		s = draw_TextShortenToWidth(sprintf("%s", s), me.columnNameSize, 0, me.realFontSize);
	else
		s = draw_TextShortenToWidth(sprintf(_("Level %d: %s"), i+1, s), me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, theColor, theAlpha, 0);

	if(i <= me.campaignIndex)
	{
		s = campaign_longdesc_wrapped[i];
		n = tokenizebyseparator(s, "\n");
		o = me.realUpperMargin2 * eY + me.columnNameOrigin * eX;
		for(j = 0; j < n; ++j)
			if(argv(j) != "")
			{
				draw_Text(o, argv(j), me.realFontSize, theColor, theAlpha * SKINALPHA_CAMPAIGN_DESCRIPTION, 0);
				o.y += me.realFontSize.y;
			}
			else
				o.y += me.realFontSize.y * me.emptyLineHeight;
	}
}
void CampaignList_LoadMap(entity btn, entity me)
{
	if(me.selectedItem >= me.nItems || me.selectedItem < 0)
		return;
	CampaignSetup(me.selectedItem);
}

void XonoticCampaignList_setSelected(entity me, float i)
{
	// prevent too late items from being played
	SUPER(XonoticCampaignList).setSelected(me, min(i, me.campaignIndex));
}

float XonoticCampaignList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_SPACE || scan == K_KP_ENTER)
		CampaignList_LoadMap(me, me);
	else
		return SUPER(XonoticCampaignList).keyDown(me, scan, ascii, shift);
	return 1;
}
