#include "colorpicker_string.qh"

.bool disabled;

entity makeXonoticColorpickerString(string theCvar, string theDefaultCvar)
{
	entity me;
	me = NEW(XonoticColorpickerString);
	me.configureXonoticColorpickerString(me, theCvar, theDefaultCvar);
	return me;
}

void XonoticColorpickerString_configureXonoticColorpickerString(entity me, string theCvar, string theDefaultCvar)
{
	me.configureImage(me, me.image);
	me.cvarName = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
}

void XonoticColorpickerString_loadCvars(entity me)
{
	if (!me.cvarName)
		return;

	if(substring(me.cvarName, -1, 1) == "_")
	{
		me.prevcoords = color_hslimage(
			eX * cvar(strcat(me.cvarName, "red")) +
			eY * cvar(strcat(me.cvarName, "green")) +
			eZ * cvar(strcat(me.cvarName, "blue")),
			me.imagemargin);
	}
	else
		me.prevcoords = color_hslimage(stov(cvar_string(me.cvarName)), me.imagemargin);
}

void XonoticColorpickerString_saveCvars(entity me)
{
	if (!me.cvarName)
		return;

	if(substring(me.cvarName, -1, 1) == "_")
	{
		vector v = hslimage_color(me.prevcoords, me.imagemargin);
		cvar_set(strcat(me.cvarName, "red"), ftos(v.x));
		cvar_set(strcat(me.cvarName, "green"), ftos(v.y));
		cvar_set(strcat(me.cvarName, "blue"), ftos(v.z));
	}
	else
		cvar_set(me.cvarName, sprintf("%v", hslimage_color(me.prevcoords, me.imagemargin)));
}

float XonoticColorpickerString_mousePress(entity me, vector coords)
{
	me.mouseDrag(me, coords);
	return 1;
}

float XonoticColorpickerString_mouseDrag(entity me, vector coords)
{
	if(me.disabled)
		return 0;
	vector margin;
	margin = me.imagemargin;
	if(coords.x >= margin.x)
	if(coords.y >= margin.y)
	if(coords.x <= 1 - margin.x)
	if(coords.y <= 1 - margin.y)
	{
		me.prevcoords = coords;
		me.saveCvars(me);
	}

	return 1;
}

float XonoticColorpickerString_mouseRelease(entity me, vector coords)
{
	m_play_click_sound(MENU_SOUND_SLIDE);
	me.mouseDrag(me, coords);
	return 1;
}

void XonoticColorpickerString_draw(entity me)
{
	float save;
	save = draw_alpha;
	if(me.disabled)
		draw_alpha *= me.disabledAlpha;

	SUPER(XonoticColorpickerString).draw(me);

	vector sz;
	sz = draw_PictureSize(strcat(me.src, "_selected"));
	sz = globalToBoxSize(sz, draw_scale);

	if(!me.disabled)
		draw_Picture(me.imgOrigin + me.prevcoords - 0.5 * sz, strcat(me.src, "_selected"), sz, '1 1 1', 1);

	draw_alpha = save;
}
