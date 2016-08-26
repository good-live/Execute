bool g_bUseM4[MAXPLAYERS + 1];
Handle g_hM4Cookie;

public void Guns_OnPluginStart()
{
	//TODO Chane Cokkie Access when everything is working fine. This is just for debug reasons readable.
	g_hM4Cookie = RegClientCookie("M4A1S", "Whether you wanna use the M4A1S or just the M4", CookieAccess_Protected);
	
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
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int GunMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual("m4_n", info, false))
			{
				g_bUseM4[param1] = false;
				SetClientCookie(param1, g_hM4Cookie, "0");
				CPrintToChat(param1, "%t%t", "TAG", "You stopped using M4A1");
			}else if(StrEqual("m4_y", info, false)){
				g_bUseM4[param1] = true;
				SetClientCookie(param1, g_hM4Cookie, "1");
				CPrintToChat(param1, "%t%t", "TAG", "You started using M4A1");
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

public void OnClientCookiesCached(int client)
{
    char sValue[8];
    GetClientCookie(client, g_hM4Cookie, sValue, sizeof(sValue));
    
    g_bUseM4[client] = (sValue[0] != '\0' && StringToInt(sValue));
}