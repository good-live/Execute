#if defined _executes_included_
  #endinput
#endif
#define _executes_included_

char g_sRifles[][][] = {
	{"weapon_ak47","AK-47"},
	{"weapon_aug","AUG"},
	{"weapon_famas","FAMAS"},
	{"weapon_g3sg1","G3SG1"},
	{"weapon_galilar","Galil"},
	{"weapon_m249","M249"},
	{"weapon_m4a1","M4A1"},
	{"weapon_negev","Negev"},
	{"weapon_scar20","Scar 20"},
	{"weapon_sg556","sg556"},
	{"weapon_ssg08","Scout"},
};

char g_sShotguns[][][] = {
	{"weapon_xm1014","xm1014"},
	{"weapon_sawedoff","SawedOff"},
	{"weapon_nova","Nova"},
	{"weapon_mag7","MAG7"},
};

char g_sMPs[][][] = {
	{"weapon_mp7","MP7"},
	{"weapon_mp9","MP9"},
	{"weapon_bizon","Bizon"},
	{"weapon_ump45","UMP"},
	{"weapon_p90","P90"},
	{"weapon_mac10","MAC-10"},
};

/**
 * Registers a new Scenario.
 *
 * @note    	  	There is no prevention of double registration.
 * @param Scenario	The scenario that should get registered.
 */
native void Ex_RegisterScenario(StringMap Scenario);