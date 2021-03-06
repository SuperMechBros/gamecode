#include "dialog_settings_video.qh"

#include "commandbutton.qh"
#include "textlabel.qh"
#include "textslider.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "slider_resolution.qh"
#include "radiobutton.qh"

entity makeXonoticVideoSettingsTab()
{
	entity me;
	me = NEW(XonoticVideoSettingsTab);
	me.configureDialog(me);
	return me;
}
void XonoticVideoSettingsTab_fill(entity me)
{
	entity e;
	entity videoApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"vid_width $_menu_vid_width;"
		"vid_height $_menu_vid_height;"
		"vid_pixelheight $_menu_vid_pixelheight;"
		"vid_desktopfullscreen $_menu_vid_desktopfullscreen;"
		"menu_cmd update_conwidths_before_vid_restart;"
		"vid_restart;"
		"menu_cmd sync;"
		, COMMANDBUTTON_APPLY);
	videoApplyButton.disableOnClick = true;

	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Resolution:")));
		me.TD(me, 1, 2, e = makeXonoticResolutionSlider());
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Font/UI size:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("menu_vid_scale"));
			e.addValue(e, ZCTX(_("SZ^Unreadable")), "-1");
			e.addValue(e, ZCTX(_("SZ^Tiny")), "-0.75");
			e.addValue(e, ZCTX(_("SZ^Little")), "-0.5");
			e.addValue(e, ZCTX(_("SZ^Small")), "-0.25");
			e.addValue(e, ZCTX(_("SZ^Medium")), "0");
			e.addValue(e, ZCTX(_("SZ^Large")), "0.25");
			e.addValue(e, ZCTX(_("SZ^Huge")), "0.5");
			e.addValue(e, ZCTX(_("SZ^Gigantic")), "0.75");
			e.addValue(e, ZCTX(_("SZ^Colossal")), "1");
			e.configureXonoticTextSliderValues(e);
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Color depth:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("vid_bitsperpixel",
			_("How many bits per pixel (BPP) to render at, 32 is recommended")));
			e.addValue(e, _("16bit"), "16");
			e.addValue(e, _("32bit"), "32");
			e.configureXonoticTextSliderValues(e);
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "vid_fullscreen", _("Full screen")));
			e.applyButton = videoApplyButton;
		me.TD(me, 1, 2, e = makeXonoticCheckBox_T(0, "vid_vsync", _("Vertical Synchronization"),
			_("Enable vertical synchronization to prevent tearing, will cap your fps to the screen refresh rate (default: disabled)")));

	me.TR(me);
		if(cvar("developer"))
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "v_flipped", _("Flip view horizontally"),
				_("Poor man's left handed mode (default: off)")));
		}
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Anisotropy:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("gl_texture_anisotropy",
			_("Anisotropic filtering quality (default: 1x)")));
			e.addValue(e, ZCTX(_("ANISO^Disabled")), "1");
			e.addValue(e, _("2x"), "2");
			e.addValue(e, _("4x"), "4");
			e.addValue(e, _("8x"), "8");
			e.addValue(e, _("16x"), "16");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Antialiasing:")));
			setDependent(e, "r_viewfbo", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("vid_samples",
			_("Enable antialiasing, which smooths the edges of 3D geometry. Note that it might decrease performance by quite a lot (default: disabled)")));
			e.addValue(e, ZCTX(_("AA^Disabled")), "1");
			e.addValue(e, _("2x"), "2");
			e.addValue(e, _("4x"), "4");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "r_viewfbo", 0, 0);
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 0, "r_viewfbo", _("High-quality frame buffer")));
			setDependent(e, "vid_samples", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Depth first:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("r_depthfirst",
			_("Eliminate overdraw by rendering a depth-only version of the scene before the normal rendering starts (default: disabled)")));
			e.addValue(e, ZCTX(_("DF^Disabled")), "0");
			e.addValue(e, ZCTX(_("DF^World")), "1");
			e.addValue(e, ZCTX(_("DF^All")), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Vertex Buffer Objects (VBOs)")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(1, "gl_vbo", "0", ZCTX(_("VBO^Off"))));
		me.TD(me, 1, 1.9, e = makeXonoticRadioButton_T(1, "gl_vbo", "3", _("Vertices, some Tris (compatible)"),
			_("Make use of Vertex Buffer Objects to store static geometry in video memory for faster rendering (default: Vertex and Triangles)")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton_T(1, "gl_vbo", "2", _("Vertices"),
			_("Make use of Vertex Buffer Objects to store static geometry in video memory for faster rendering (default: Vertex and Triangles)")));
		me.TD(me, 1, 1.9, e = makeXonoticRadioButton_T(1, "gl_vbo", "1", _("Vertices and Triangles"),
			_("Make use of Vertex Buffer Objects to store static geometry in video memory for faster rendering (default: Vertex and Triangles)")));

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Brightness:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.0, 0.5, 0.02, "v_brightness",
			_("Brightness of black (default: 0)")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Contrast:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1.0, 3.0, 0.05, "v_contrast",
			_("Brightness of white (default: 1)")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gamma:")));
			setDependentAND(e, "vid_gl20", 1, 1, "v_glslgamma", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "v_gamma",
			_("Inverse gamma correction value, a brightness effect that does not affect white or black (default: 1.125)")));
			setDependentAND(e, "vid_gl20", 1, 1, "v_glslgamma", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Contrast boost:")));
			setDependentAND(e, "vid_gl20", 1, 1, "v_glslgamma", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1.0, 5.0, 0.1, "v_contrastboost",
			_("By how much to multiply the contrast in dark areas (default: 1)")));
			setDependentAND(e, "vid_gl20", 1, 1, "v_glslgamma", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Saturation:")));
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "r_glsl_saturation",
			_("Saturation adjustment (0 = grayscale, 1 = normal, 2 = oversaturated), requires GLSL color control (default: 1)")));
			setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("LIT^Ambient:"))));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 20.0, 0.25, "r_ambient",
			_("Ambient lighting, if set too high it tends to make light on maps look dull and flat (default: 4)")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Intensity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "r_hdr_scenebrightness",
			_("Global rendering brightness (default: 1)")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "gl_finish", _("Wait for GPU to finish each frame"),
			_("Make the CPU wait for the GPU to finish each frame, can help with some strange input or video lag on some machines (default: disabled)")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "vid_gl20", _("Use OpenGL 2.0 shaders (GLSL)")));
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "v_glslgamma", _("Use GLSL to handle color control"),
			_("Enable use of GLSL to apply gamma correction, note that it might decrease performance by a lot (default: disabled)")));
			setDependent(e, "vid_gl20", 1, 1);
	if(cvar("developer"))
	{
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "v_psycho", _("Psycho coloring (easter egg)")));
				setDependent(e, "vid_gl20", 1, 1);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "r_trippy", _("Trippy vertices (easter egg)")));
				setDependent(e, "vid_gl20", 1, 1);
	}

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, videoApplyButton);
}
