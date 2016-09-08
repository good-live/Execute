#include <clientprefs>

bool g_bUseM4[MAXPLAYERS + 1];
char g_sPrimaryPref[MAXPLAYERS + 1] [32];
char g_sRiflePref[MAXPLAYERS + 1] [32];
char g_sShotgunPref[MAXPLAYERS + 1] [32];
char g_sMPPref[MAXPLAYERS + 1] [32];

Handle g_hPrimaryCookie;
Handle g_hRifleCookie;
Handle g_hShotgunCookie;
Handle g_hMPCookie;
Handle g_hM4Cookie;

public void Guns_OnPluginStart()
{
	//TODO Change Cokkie Access when everything is working fine. This is just for debug reasons readable.
	g_hM4Cookie = RegClientCookie("execute_m4a1", "Whether you wanna use the M4A1S or just the M4", CookieAccess_Protected);
	g_hPrimaryCookie = RegClientCookie("execute_primary", "The prefered primary weapon", CookieAccess_Protected);
	g_hRifleCookie = RegClientCookie("execute_rifle", "The prefered primary weapon", CookieAccess_Protected);
	g_hShotgunCookie = RegClientCookie("execute_shotgun", "The prefered primary weapon", CookieAccess_Protected);
	g_hMPCookie = RegClientCookie("execute_mp", "The prefered primary weapon", CookieAccess_Protected);	
	//Cookie LateLoading
	for (int i = 1; i <= MaxClients; i++)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        OnClientCookiesCached(i);
    }
	RegConsoleCmd("sm_guns", Command_Guns, "Choose your favorite gun.");
	
	LoadTranslations("execute_guns.phrases");
}

public Action Command_Guns(int client, int args)
{
	ShowGunMenuToClient(client);
	return Plugin_Handled;
}

void ShowGunMenuToClient(int client)
{
	char sTitle[16];
	Format(sTitle, sizeof(sTitle), "%t", "Gun_Menu_Title");
	Menu menu = new Menu(GunMenu_Callback);
	menu.SetTitle(sTitle);
	char sItem[32];
	if(g_bUseM4[client])
	{
		Format(sItem, sizeof(sItem), "%t", "Gun_Menu_M4_No");
		menu.AddItem("m4_n", sItem);
	}else{
		Format(sItem, sizeof(sItem), "%t", "Gun_Menu_M4_Yes");
		menu.AddItem("m4_y", sItem);
	}
	menu.AddItem("primary", "Primary");
	menu.AddItem("rifle", "Rifle");
	menu.AddItem("shotgun", "Shotgun");
	menu.AddItem("mp", "MP");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int GunMenu_Callback(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual("m4_n", info, false))
			{
				g_bUseM4[client] = false;
				SetClientCookie(client, g_hM4Cookie, "0");
				CPrintToChat(client, "%t%t", "TAG", "You stopped using M4A1");
			}else if(StrEqual("m4_y", info, false)){
				g_bUseM4[client] = true;
				SetClientCookie(client, g_hM4Cookie, "1");
				CPrintToChat(client, "%t%t", "TAG", "You started using M4A1");
			}else if(StrEqual("primary", info, false)){
				ShowPrimarySelection(client);
			}else if(StrEqual("rifle", info, false)){
				ShowRifleSelection(client);
			}else if(StrEqual("shotgun", info, false)){
				ShowShotgunSelection(client);
			}else if(StrEqual("mp", info, false)){
				ShowMPSelection(client);
			}
		}
		case MenuAction_Cancel:
		{
			delete menu;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void ShowRifleSelection(int client)
{
	Menu menu = new Menu(RifleSelection);
	char sTitle[16];
	Format(sTitle, sizeof(sTitle), "%t", "Rifle Selection - Title");
	menu.SetTitle(sTitle);
	char sInfo[32];
	for (int i = 0; i < sizeof(g_sRifles); i++)
	{
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, g_sRifles[i][1]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RifleSelection(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			SetClientCookie(client, g_hRifleCookie, info);
			Format(g_sRiflePref[client], 32, "%s", info);
		}
		case MenuAction_Cancel:
		{
			delete menu;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void ShowMPSelection(int client)
{
	Menu menu = new Menu(MPSelection);
	char sTitle[16];
	Format(sTitle, sizeof(sTitle), "%t", "Shotgun Selection - Title");
	menu.SetTitle(sTitle);
	char sInfo[32];
	for (int i = 0; i < sizeof(g_sMPs); i++)
	{
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, g_sMPs[i][1]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MPSelection(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			SetClientCookie(client, g_hMPCookie, info);
			Format(g_sMPPref[client], 32, "%s", info);
		}
		case MenuAction_Cancel:
		{
			delete menu;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void ShowShotgunSelection(int client)
{
	Menu menu = new Menu(ShotgunSelection);
	char sTitle[16];
	Format(sTitle, sizeof(sTitle), "%t", "Shotgun Selection - Title");
	menu.SetTitle(sTitle);
	char sInfo[32];
	for (int i = 0; i < sizeof(g_sRifles); i++)
	{
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, g_sShotguns[i][1]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ShotgunSelection(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			SetClientCookie(client, g_hShotgunCookie, info);
			Format(g_sShotgunPref[client], 32, "%s", info);
		}
		case MenuAction_Cancel:
		{
			delete menu;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void ShowPrimarySelection(int client)
{
	Menu menu = new Menu(PrimarySelection);
	char sTitle[16];
	Format(sTitle, sizeof(sTitle), "%t", "Primary Selection - Title");
	menu.SetTitle(sTitle);
	menu.AddItem("rifle", "Rifle");
	menu.AddItem("mp", "MP");
	menu.AddItem("shot", "Shotgun");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PrimarySelection(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			SetClientCookie(client, g_hPrimaryCookie, info);
			Format(g_sPrimaryPref[client], 32, "%s", info);
		}
		case MenuAction_Cancel:
		{
			delete menu;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public void OnClientCookiesCached(int client)
{
    char sValue[8];
    GetClientCookie(client, g_hM4Cookie, sValue, sizeof(sValue));
    g_bUseM4[client] = (sValue[0] != '\0' && StringToInt(sValue));
    GetClientCookie(client, g_hPrimaryCookie, g_sPrimaryPref[client], 32);
    GetClientCookie(client, g_hRifleCookie, g_sRiflePref[client], 32);
    GetClientCookie(client, g_hShotgunCookie, g_sShotgunPref[client], 32);
    GetClientCookie(client, g_hMPCookie, g_sMPPref[client], 32);
}