#include "dialog_quit.qh"

#include "textlabel.qh"
#include "commandbutton.qh"
#include "button.qh"

void XonoticQuitDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to quit?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton_T(_("Yes"), '1 0 0', "echo ]quit\nquit", 0,
			_("Until next time, everybody...")));
		me.TD(me, 1, 1, e = makeXonoticButton_T(_("No"), '0 1 0',
			_("Do the Mechanico!")));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
