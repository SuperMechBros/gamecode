#include "healtharmor.qh"

#include <common/deathtypes/all.qh>

// Health/armor (#3)

void HUD_HealthArmor()
{
	int armor, health, fuel;
	if(!autocvar__hud_configure)
	{
		if((!autocvar_hud_panel_healtharmor) || (spectatee_status == -1))
			return;
		if(hud != HUD_NORMAL) return;

		health = STAT(HEALTH);
		if(health <= 0)
		{
			health = 0;
			prev_health = -1;
			if(autocvar_hud_panel_healtharmor_hide_ondeath)
				return;
		}
		armor = STAT(ARMOR);

		// code to check for spectatee_status changes is in ENT_CLIENT_CLIENTDATA
		// prev_p_health and prev_health can be set to -1 there

		if (prev_p_health == -1)
		{
			// no effect
			health_beforedamage = 0;
			armor_beforedamage = 0;
			health_damagetime = 0;
			armor_damagetime = 0;
			prev_health = health;
			prev_armor = armor;
			old_p_health = health;
			old_p_armor = armor;
			prev_p_health = health;
			prev_p_armor = armor;
		}
		else if (prev_health == -1)
		{
			//start the load effect
			health_damagetime = 0;
			armor_damagetime = 0;
			prev_health = 0;
			prev_armor = 0;
		}
		fuel = STAT(FUEL);
	}
	else
	{
		health = 150;
		armor = 75;
		fuel = 20;
	}

	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_healtharmor_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	int baralign = autocvar_hud_panel_healtharmor_baralign;
	int iconalign = autocvar_hud_panel_healtharmor_iconalign;

    int maxhealth = autocvar_hud_panel_healtharmor_maxhealth;
    int maxarmor = autocvar_hud_panel_healtharmor_maxarmor;
	if(autocvar_hud_panel_healtharmor_combined) // combined health and armor display
	{
		vector v;
		v = healtharmor_maxdamage(health, armor, armorblockpercent, DEATH_WEAPON.m_id);

		float hp = floor(v.x + 1);

        float maxtotal = maxhealth + maxarmor;
		string biggercount;
		if(v.z) // NOT fully armored
		{
			biggercount = "health";
			if(autocvar_hud_panel_healtharmor_progressbar)
				HUD_Panel_DrawProgressBar(pos, mySize, autocvar_hud_panel_healtharmor_progressbar_health, hp/maxtotal, 0, (baralign == 1 || baralign == 2), autocvar_hud_progressbar_health_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			if(armor)
            if(autocvar_hud_panel_healtharmor_text)
				drawpic_aspect_skin(pos + eX * mySize.x - eX * 0.5 * mySize.y, "armor", '0.5 0.5 0' * mySize.y, '1 1 1', panel_fg_alpha * armor / health, DRAWFLAG_NORMAL);
		}
		else
		{
			biggercount = "armor";
			if(autocvar_hud_panel_healtharmor_progressbar)
				HUD_Panel_DrawProgressBar(pos, mySize, autocvar_hud_panel_healtharmor_progressbar_armor, hp/maxtotal, 0, (baralign == 1 || baralign == 2), autocvar_hud_progressbar_armor_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			if(health)
            if(autocvar_hud_panel_healtharmor_text)
				drawpic_aspect_skin(pos + eX * mySize.x - eX * 0.5 * mySize.y, "health", '0.5 0.5 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
        if(autocvar_hud_panel_healtharmor_text)
			DrawNumIcon(pos, mySize, hp, biggercount, 0, iconalign, HUD_Get_Num_Color(hp, maxtotal), 1);

		if(fuel)
			HUD_Panel_DrawProgressBar(pos, eX * mySize.x + eY * 0.2 * mySize.y, "progressbar", fuel/100, 0, (baralign == 1 || baralign == 3), autocvar_hud_progressbar_fuel_color, panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
	}
	else
	{
		float panel_ar = mySize.x/mySize.y;
		bool is_vertical = (panel_ar < 1);
		vector health_offset = '0 0 0', armor_offset = '0 0 0';
		if (panel_ar >= 4 || (panel_ar >= 1/4 && panel_ar < 1))
		{
			mySize.x *= 0.5;
			if (autocvar_hud_panel_healtharmor_flip)
				health_offset.x = mySize.x;
			else
				armor_offset.x = mySize.x;
		}
		else
		{
			mySize.y *= 0.5;
			if (autocvar_hud_panel_healtharmor_flip)
				health_offset.y = mySize.y;
			else
				armor_offset.y = mySize.y;
		}

		bool health_baralign, armor_baralign, fuel_baralign;
		bool health_iconalign, armor_iconalign;
		if (autocvar_hud_panel_healtharmor_flip)
		{
			armor_baralign = (autocvar_hud_panel_healtharmor_baralign == 2 || autocvar_hud_panel_healtharmor_baralign == 1);
			health_baralign = (autocvar_hud_panel_healtharmor_baralign == 3 || autocvar_hud_panel_healtharmor_baralign == 1);
			fuel_baralign = health_baralign;
			armor_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 2 || autocvar_hud_panel_healtharmor_iconalign == 1);
			health_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 3 || autocvar_hud_panel_healtharmor_iconalign == 1);
		}
		else
		{
			health_baralign = (autocvar_hud_panel_healtharmor_baralign == 2 || autocvar_hud_panel_healtharmor_baralign == 1);
			armor_baralign = (autocvar_hud_panel_healtharmor_baralign == 3 || autocvar_hud_panel_healtharmor_baralign == 1);
			fuel_baralign = armor_baralign;
			health_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 2 || autocvar_hud_panel_healtharmor_iconalign == 1);
			armor_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 3 || autocvar_hud_panel_healtharmor_iconalign == 1);
		}

		//if(health)
		{
			if(autocvar_hud_panel_healtharmor_progressbar)
			{
				float p_health, pain_health_alpha;
				p_health = health;
				pain_health_alpha = 1;
				if (autocvar_hud_panel_healtharmor_progressbar_gfx)
				{
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_smooth > 0)
					{
						if (fabs(prev_health - health) >= autocvar_hud_panel_healtharmor_progressbar_gfx_smooth)
						{
							if (time - old_p_healthtime < 1)
								old_p_health = prev_p_health;
							else
								old_p_health = prev_health;
							old_p_healthtime = time;
						}
						if (time - old_p_healthtime < 1)
						{
							p_health += (old_p_health - health) * (1 - (time - old_p_healthtime));
							prev_p_health = p_health;
						}
					}
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_damage > 0)
					{
						if (prev_health - health >= autocvar_hud_panel_healtharmor_progressbar_gfx_damage)
						{
							if (time - health_damagetime >= 1)
								health_beforedamage = prev_health;
							health_damagetime = time;
						}
						if (time - health_damagetime < 1)
						{
							float health_damagealpha = 1 - (time - health_damagetime)*(time - health_damagetime);
							HUD_Panel_DrawProgressBar(pos + health_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_health, health_beforedamage/maxhealth, is_vertical, health_baralign, autocvar_hud_progressbar_health_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * health_damagealpha, DRAWFLAG_NORMAL);
						}
					}
					prev_health = health;

					if (health <= autocvar_hud_panel_healtharmor_progressbar_gfx_lowhealth)
					{
						float BLINK_FACTOR = 0.15;
						float BLINK_BASE = 0.85;
						float BLINK_FREQ = 9;
						pain_health_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ);
					}
				}
				HUD_Panel_DrawProgressBar(pos + health_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_health, p_health/maxhealth, is_vertical, health_baralign, autocvar_hud_progressbar_health_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * pain_health_alpha, DRAWFLAG_NORMAL);
			}
			if(autocvar_hud_panel_healtharmor_text)
				DrawNumIcon(pos + health_offset, mySize, health, "health", is_vertical, health_iconalign, HUD_Get_Num_Color(health, maxhealth), 1);
		}

		//if(armor)
		{
			float p_armor = armor;
			if(autocvar_hud_panel_healtharmor_progressbar)
			{
				if (autocvar_hud_panel_healtharmor_progressbar_gfx)
				{
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_smooth > 0)
					{
						if (fabs(prev_armor - armor) >= autocvar_hud_panel_healtharmor_progressbar_gfx_smooth)
						{
							if (time - old_p_armortime < 1)
								old_p_armor = prev_p_armor;
							else
								old_p_armor = prev_armor;
							old_p_armortime = time;
						}
						if (time - old_p_armortime < 1)
						{
							p_armor += (old_p_armor - armor) * (1 - (time - old_p_armortime));
							prev_p_armor = p_armor;
						}
					}
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_damage > 0)
					{
						if (prev_armor - armor >= autocvar_hud_panel_healtharmor_progressbar_gfx_damage)
						{
							if (time - armor_damagetime >= 1)
								armor_beforedamage = prev_armor;
							armor_damagetime = time;
						}
						if (time - armor_damagetime < 1)
						{
							float armor_damagealpha = 1 - (time - armor_damagetime)*(time - armor_damagetime);
							HUD_Panel_DrawProgressBar(pos + armor_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_armor, armor_beforedamage/maxarmor, is_vertical, armor_baralign, autocvar_hud_progressbar_armor_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * armor_damagealpha, DRAWFLAG_NORMAL);
						}
					}
					prev_armor = armor;
				}
				if(p_armor)
					HUD_Panel_DrawProgressBar(pos + armor_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_armor, p_armor/maxarmor, is_vertical, armor_baralign, autocvar_hud_progressbar_armor_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			if(!autocvar_hud_panel_healtharmor_progressbar || p_armor)
			if(autocvar_hud_panel_healtharmor_text)
				DrawNumIcon(pos + armor_offset, mySize, armor, "armor", is_vertical, armor_iconalign, HUD_Get_Num_Color(armor, maxarmor), 1);
		}

		if(fuel)
		{
			if (is_vertical)
				mySize.x *= 0.2 / 2; //if vertical always halve x to not cover too much numbers with 3 digits
			else
				mySize.y *= 0.2;
			if (panel_ar >= 4)
				mySize.x *= 2; //restore full panel size
			else if (panel_ar < 1/4)
				mySize.y *= 2; //restore full panel size
			HUD_Panel_DrawProgressBar(pos, mySize, "progressbar", fuel/100, is_vertical, fuel_baralign, autocvar_hud_progressbar_fuel_color, panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
		}
	}

	draw_endBoldFont();
}
