#include "mainwindow.qh"

#include "../mutators/events.qh"

#include "nexposee.qh"
#include "inputbox.qh"
#include "dialog_firstrun.qh"
#include "dialog_hudsetup_exit.qh"
#include "dialog_hudpanel_notification.qh"
#include "dialog_hudpanel_ammo.qh"
#include "dialog_hudpanel_healtharmor.qh"
#include "dialog_hudpanel_chat.qh"
#include "dialog_hudpanel_modicons.qh"
#include "dialog_hudpanel_powerups.qh"
#include "dialog_hudpanel_pressedkeys.qh"
#include "dialog_hudpanel_racetimer.qh"
#include "dialog_hudpanel_radar.qh"
#include "dialog_hudpanel_score.qh"
#include "dialog_hudpanel_timer.qh"
#include "dialog_hudpanel_vote.qh"
#include "dialog_hudpanel_weapons.qh"
#include "dialog_hudpanel_engineinfo.qh"
#include "dialog_hudpanel_infomessages.qh"
#include "dialog_hudpanel_physics.qh"
#include "dialog_hudpanel_centerprint.qh"
#include "dialog_hudpanel_quickmenu.qh"

#include "dialog_settings_input_userbind.qh"
#include "dialog_settings_misc_cvars.qh"
#include "dialog_settings_misc_reset.qh"
#include "dialog_settings_user_languagewarning.qh"
#include "dialog_settings_game_hudconfirm.qh"
#include "dialog_singleplayer_winner.qh"
#include "dialog_monstertools.qh"
#include "dialog_teamselect.qh"
#include "dialog_singleplayer.qh"
#include "dialog_settings.qh"
#include "dialog_credits.qh"
#include "dialog_quit.qh"

void MainWindow_draw(entity me)
{
	SUPER(MainWindow).draw(me);

	if(me.dialogToShow)
	{
		DialogOpenButton_Click_withCoords(NULL, me.dialogToShow, '0 0 0', eX * conwidth + eY * conheight);
		me.dialogToShow = NULL;
	}
}

void DemoButton_Click(entity me, entity other)
{
	if(me.text == _("Do not press this button again!"))
		DialogOpenButton_Click(me, other);
	else
		me.setText(me, _("Do not press this button again!"));
}

void MainWindow_configureMainWindow(entity me)
{
	entity n, i;

	// dialog run upon startup
	me.firstRunDialog = i = NEW(XonoticFirstRunDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// hud_configure dialogs
	i = NEW(XonoticHUDExitDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDNotificationDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDAmmoDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDHealthArmorDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDChatDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDModIconsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDPowerupsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDPressedKeysDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDRaceTimerDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDRadarDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDScoreDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDTimerDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDVoteDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDWeaponsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDEngineInfoDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDInfoMessagesDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDPhysicsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDCenterprintDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDQuickMenuDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	// dialogs used by settings
	me.userbindEditDialog = i = NEW(XonoticUserbindEditDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.cvarsDialog = i = NEW(XonoticCvarsDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.resetDialog = i = NEW(XonoticResetDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.languageWarningDialog = i = NEW(XonoticLanguageWarningDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.hudconfirmDialog = i = NEW(XonoticHUDConfirmDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialog used by singleplayer
	me.winnerDialog = i = NEW(XonoticWinnerDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticProfileTab);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// mutator dialogs


	// miscellaneous dialogs
	i = NEW(XonoticTeamSelectDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticMonsterToolsDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z * SKINALPHA_DIALOG_SANDBOXTOOLS);

	MUTATOR_CALLHOOK(ConfigureDialogs, me);


	// main dialogs/windows
	me.mainNexposee = n = NEW(XonoticNexposee);
	/*
		if(checkextension("DP_GECKO_SUPPORT"))
		{
			i = spawnXonoticNewsDialog();
			i.configureDialog(i);
			n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
			n.setNexposee(n, i, '0.1 0.1 0', SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		}
	*/
		i = NEW(XonoticSingleplayerDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, '0.5 0.6 0', SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = NEW(XonoticSettingsDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_CREDITS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / conheight));

		i = NEW(XonoticQuitDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_QUIT, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / conheight));

	me.addItem(me, n, '0 0 0', '1 1 0', SKINALPHAS_MAINMENU_z);
	me.moveItemAfter(me, n, NULL);

	me.initializeDialog(me, n);

	if(cvar_string("_cl_name") == cvar_defstring("_cl_name"))
		me.dialogToShow = me.firstRunDialog;
}
