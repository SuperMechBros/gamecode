#include "dialog_settings_misc.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "textslider.qh"
#include "slider.qh"
#include "checkbox.qh"
#include "button.qh"
#include "mainwindow.qh"

#define ADDVALUE_FPS(i) e.addValue(e, strzone(sprintf(_("%d fps"), i)), #i)
#define ADDVALUE_SPEED_KB(i) e.addValue(e, strzone(sprintf(_("%d KB/s"), i)), #i)
#define ADDVALUE_SPEED_MB(i, j) e.addValue(e, strzone(sprintf(_("%d MB/s"), i)), #j)
entity makeXonoticMiscSettingsTab()
{
	entity me;
	me = NEW(XonoticMiscSettingsTab);
	me.configureDialog(me);
	return me;
}
void XonoticMiscSettingsTab_fill(entity me)
{
	entity e;
	//entity sk;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Network")));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Client UDP port:")));
		me.TD(me, 1, 1.5, e = makeXonoticInputBox_T(0, "cl_port",
			_("Force client to use chosen port unless it is set to 0")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bandwidth:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("_cl_rate",
			_("Specify your network speed")));
			e.addValue(e, _("56k"), "4000");
			e.addValue(e, _("ISDN"), "7000");
			e.addValue(e, _("Slow ADSL"), "15000");
			e.addValue(e, _("Fast ADSL"), "20000");
			e.addValue(e, _("Broadband"), "66666");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Input packets/s:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(20, 100, 5, "cl_netfps",
			_("How many input packets to send to the server each second")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Server queries/s:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(20, 100, 10, "net_slist_queriespersecond"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Downloads:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 5, 1, "cl_curl_maxdownloads",
			_("Maximum number of concurrent HTTP/FTP downloads")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Download speed:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_curl_maxspeed"));
		ADDVALUE_SPEED_KB(50);
		ADDVALUE_SPEED_KB(100);
		ADDVALUE_SPEED_KB(300);
		ADDVALUE_SPEED_KB(500);
		ADDVALUE_SPEED_MB(1, 1000);
		ADDVALUE_SPEED_MB(2, 2000);
		e.addValue(e, strzone(_("Unlimited")), "0");
		e.configureXonoticTextSliderValues(e);
	me.TR(me);
		if(cvar("developer"))
		{
			me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Local latency:")));
			me.TD(me, 1, 2, e = makeXonoticSlider(0, 1000, 25, "cl_netlocalping"));
		}
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "shownetgraph", _("Show netgraph"),
			_("Show a graph of packet sizes and other information")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_movement", _("Client-side movement prediction")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_movement_errorcompensation", _("Movement error compensation")));
		setDependent(e, "cl_movement", 1, 1);
	me.TR(me);
		if(cvar_type("crypto_aeslevel") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "crypto_aeslevel", _("Use encryption (AES) when available"))); // TODO: move up

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Framerate")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Maximum:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_maxfps"));
			ADDVALUE_FPS(30);
			ADDVALUE_FPS(40);
			ADDVALUE_FPS(50);
			ADDVALUE_FPS(60);
			ADDVALUE_FPS(70);
			ADDVALUE_FPS(80);
			ADDVALUE_FPS(100);
			ADDVALUE_FPS(125);
			ADDVALUE_FPS(150);
			ADDVALUE_FPS(200);
			e.addValue(e, ZCTX(_("MAXFPS^Unlimited")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Target:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_minfps"));
			e.addValue(e, ZCTX(_("TRGT^Disabled")), "0");
			ADDVALUE_FPS(30);
			ADDVALUE_FPS(40);
			ADDVALUE_FPS(50);
			ADDVALUE_FPS(60);
			ADDVALUE_FPS(80);
			ADDVALUE_FPS(100);
			ADDVALUE_FPS(125);
			ADDVALUE_FPS(150);
			ADDVALUE_FPS(200);
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Idle limit:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_maxidlefps"));
			ADDVALUE_FPS(10);
			ADDVALUE_FPS(20);
			ADDVALUE_FPS(30);
			ADDVALUE_FPS(60);
			e.addValue(e, ZCTX(_("IDLFPS^Unlimited")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_maxfps_alwayssleep", _("Save processing time for other apps")));
		setDependent(e, "cl_maxfps", 1, 1000);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "showfps", _("Show frames per second"),
			_("Show your rendered frames per second")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Menu tooltips:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("menu_tooltips",
			_("Menu tooltips: disabled, standard or advanced (also shows cvar or console command bound to the menu item)")));
			e.addValue(e, ZCTX(_("TLTIP^Disabled")), "0");
			e.addValue(e, ZCTX(_("TLTIP^Standard")), "1");
			e.addValue(e, ZCTX(_("TLTIP^Advanced")), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "showtime", _("Show current date and time"),
			_("Show current date and time of day, useful on screenshots")));
			makeMulti(e, "showdate");
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "developer", _("Enable developer mode")));

	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Advanced settings..."), '0 0 0',
			_("Advanced settings where you can tweak every single variable of the game")));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Factory reset"), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.resetDialog;
}
#undef ADDVALUE_FPS
