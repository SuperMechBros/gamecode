#include "radiobutton.qh"

entity makeXonoticRadioButton_T(float theGroup, string theCvar, string theValue, string theText, string theTooltip)
{
	entity me;
	me = NEW(XonoticRadioButton);
	me.configureXonoticRadioButton(me, theGroup, theCvar, theValue, theText, theTooltip);
	return me;
}
entity makeXonoticRadioButton(float theGroup, string theCvar, string theValue, string theText)
{
	return makeXonoticRadioButton_T(theGroup, theCvar, theValue, theText, string_null);
}
void XonoticRadioButton_configureXonoticRadioButton(entity me, float theGroup, string theCvar, string theValue, string theText, string theTooltip)
{
	me.cvarName = (theCvar) ? theCvar : string_null;
	me.cvarValue = theValue;
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
	me.configureRadioButton(me, theText, me.fontSize, me.image, theGroup, 0);
}
void XonoticRadioButton_setChecked(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void XonoticRadioButton_loadCvars(entity me)
{
	if(me.cvarValue)
	{
		if(me.cvarName)
		{
			if(me.cvarValueIsAnotherCvar)
				me.checked = (cvar_string(me.cvarName) == cvar_string(me.cvarValue));
			else
				me.checked = (cvar_string(me.cvarName) == me.cvarValue);
		}
	}
	else
	{
		if(me.cvarName)
		{
			me.checked = boolean(cvar(me.cvarName));
		}
		else
		{
			// this is difficult
			// this is the "generic" selection... but at this time, not
			// everything is constructed yet.
			// we need to set this later in draw()
			me.checked = 0;
		}
	}
}
void XonoticRadioButton_draw(entity me)
{
	if (!me.cvarValue)
		if (!me.cvarName)
		{
			// this is the "other" option
			// always select this if none other is
			entity e;
			float found;
			found = 0;
			for(e = me.parent.firstChild; e; e = e.nextSibling)
				if(e.group == me.group)
					if(e.checked)
						found = 1;
			if(!found)
				me.setChecked(me, 1);
		}
	SUPER(XonoticRadioButton).draw(me);
}
void XonoticRadioButton_saveCvars(entity me)
{
	if(me.cvarValue)
	{
		if(me.cvarName)
		{
			if(me.checked)
			{
				if(me.cvarValueIsAnotherCvar)
					cvar_set(me.cvarName, cvar_string(me.cvarValue));
				else
					cvar_set(me.cvarName, me.cvarValue);
			}
			else if(me.cvarOffValue)
				cvar_set(me.cvarName, me.cvarOffValue);
		}
	}
	else
	{
		if(me.cvarName)
		{
			cvar_set(me.cvarName, ftos(me.checked));
		}
	}
}
