#include "dialog_singleplayer.qh"
#include "dialog_multiplayer_profile.qh"

#include <common/mapinfo.qh>
#include "bigbutton.qh"
#include "radiobutton.qh"
#include "textlabel.qh"
#include "campaign.qh"

void XonoticSingleplayerDialog_fill(entity me)
{
	entity e, btnPrev, btnNext, lblTitle;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, btnPrev = makeXonoticButton("<<", '0 0 0'));
		me.TD(me, 1, me.columns - 2, lblTitle = makeXonoticTextLabel(0.5, _("???")));
		me.TD(me, 1, 1, btnNext = makeXonoticButton(">>", '0 0 0'));
	me.TR(me);
		me.TD(me, me.rows - 6, me.columns, me.campaignBox = makeXonoticCampaignList());
			btnPrev.onClick = MultiCampaign_Prev;
			btnPrev.onClickEntity = me.campaignBox;
			btnNext.onClick = MultiCampaign_Next;
			btnNext.onClickEntity = me.campaignBox;
			me.campaignBox.buttonNext = btnNext;
			me.campaignBox.buttonPrev = btnPrev;
			me.campaignBox.labelTitle = lblTitle;

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Difficulty:")));
		me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "g_campaign_skill", "-2", ZCTX(_("CSKL^Easy"))));
		me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "g_campaign_skill", "-1", ZCTX(_("CSKL^Medium"))));
		me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "g_campaign_skill", "0", ZCTX(_("CSKL^Hard"))));
		me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Start Singleplayer!"), '0 0 0'));
			e.onClick = CampaignList_LoadMap;
			e.onClickEntity = me.campaignBox;
}
