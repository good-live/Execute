#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <execute>
#include <cstrike>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Execute - Editor",
	author = PLUGIN_AUTHOR,
	description = "Allows to edit the Execute Scenarios.",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

bool g_bConnected;
bool g_bLateConnect;

int g_iListen[MAXPLAYERS + 1];
int g_iIndex[MAXPLAYERS + 1];

Database g_hDatabase;

ArrayList g_aScenarios;
ArrayList g_aScenarioId;

StringMap g_smScenario[MAXPLAYERS + 1];
StringMap g_smSpawn[MAXPLAYERS + 1];

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
	{"random_rifle", "Random Rifle"},
	{"pref_rifle", "Prefered Rifle"}
};

char g_sShotguns[][][] = {
	{"weapon_xm1014","xm1014"},
	{"weapon_sawedoff","SawedOff"},
	{"weapon_nova","Nova"},
	{"weapon_mag7","MAG7"},
	{"random_shotgun", "Random Shotgun"},
	{"pref_shotgun", "Prefered Shotgun"}
};

char g_sMPs[][][] = {
	{"weapon_mp7","MP7"},
	{"weapon_mp9","MP9"},
	{"weapon_bizon","Bizon"},
	{"weapon_ump45","UMP"},
	{"weapon_p90","P90"},
	{"weapon_mac10","MAC-10"},
	{"random_mp", "Random MP"},
	{"pref_mp", "Prefered MP"}
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateConnect = late;
}

public void OnPluginStart()
{
	if(!g_bConnected)
		DB_Connect();
		
	g_aScenarios = new ArrayList(1);
	g_aScenarioId = new ArrayList(1);

	RegAdminCmd("sm_edit", Command_Edit, ADMFLAG_ROOT);
	RegAdminCmd("sm_abort", Command_Abort, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	if(g_bConnected)
	{
		LoadScenarios();
	}else{
		g_bLateConnect = true;
	}
}

/***********DATABASE*************/

void DB_Connect()
{
	if(!SQL_CheckConfig("execute"))
		SetFailState("Could not find a database entry 'execute'");
		
	Database.Connect(DB_Connect_Callback, "execute");
}

public void DB_Connect_Callback(Database db, const char[] error, any data)
{
	if(db == INVALID_HANDLE || strlen(error) > 0)
		SetFailState("Error during Database connect: %s", error);
	
	g_hDatabase = db;
	g_bConnected = true;
	
	if(g_bLateConnect)
	{
		g_bLateConnect = false;
		LoadScenarios();
	}
}

void LoadScenarios()
{
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	char sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT `scenarios`.`scenario_id`,`scenarios`.`name`,`scenarios`.`description`,`scenarios`.`amount`,`spawns`.`team`,`spawns`.`pos_x`,`spawns`.`pos_y`,`spawns`.`pos_z`,`spawns`.`primary`, `spawns`.`spawn_id` FROM scenarios JOIN `spawns` ON `scenarios`.`scenario_id`=`spawns`.`scenario_id` WHERE `scenarios`.`map`='%s'", sMap);
	g_hDatabase.Query(DB_LoadScenarios_Callback, sQuery);
}

public void DB_DeleteScenario_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if(db == INVALID_HANDLE || strlen(error) > 0 || results == INVALID_HANDLE)
	{
		LogError("Error during deleting scenario: %s", error);
		if(IsClientConnected(client))
		{
			CPrintToChat(client, "There has been an error during saving your scenario. Check your console.");
			PrintToConsole(client, "%s", error);
		}
		return;
	}
	
	CPrintToChat(client, "Your Scenario has been sucesfully been saved");
	CloseHandles(g_smScenario[client]);
	g_smScenario[client] = view_as<StringMap>(INVALID_HANDLE);
	g_iIndex[client] = -1;
	
}
public void DB_UpdateScenario_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if(db == INVALID_HANDLE || strlen(error) > 0 || results == INVALID_HANDLE)
	{
		LogError("Error during saving scenarios: %s", error);
		if(IsClientConnected(client))
		{
			CPrintToChat(client, "There has been an error during saving your scenario. Check your console.");
			PrintToConsole(client, "%s", error);
		}
		return;
	}
	
	char sQuery[512];
	ArrayList spawns;
	StringMap spawn;
	int iSpawnID;
	int iTeam;
	float fPos[3];
	char sPrimary[32];
	if(g_smScenario[client].GetValue("spawnst", spawns) && spawns != INVALID_HANDLE)
	{
		iTeam = CS_TEAM_T;
		for (int i = 0; i < spawns.Length; i++)
		{
			spawn = spawns.Get(i);
			if(spawn != INVALID_HANDLE)
			{	
				if(!spawn.GetValue("ID", iSpawnID))
				{
					CPrintToChat(client, "Couldn't update a spawn, because there was no spawnid saved");
					continue;
				}
				
				if(!spawn.GetArray("pos", fPos, 3))
				{
					CPrintToChat(client, "Couldn't update a spawn, because there was no position saved");
					continue;
				}
				
				if(!spawn.GetString("primary", sPrimary, sizeof(sPrimary)))
				{
					Format(sPrimary, sizeof(sPrimary), "NULL");
				}
				Format(sQuery, sizeof(sQuery), "UPDATE `execute`.`spawns` SET `team` = '%i', `pos_x` = '%f', `pos_y` = '%f', `pos_z` = '%f', `primary` = '%s' WHERE `spawns`.`spawn_id` = %i", iTeam, fPos[0], fPos[1], fPos[2], sPrimary, iSpawnID);
				g_hDatabase.Query(DB_NewSpawnSaved_Callback, sQuery, data);
			}
		}
	}
	if(g_smScenario[client].GetValue("spawnsct", spawns) && spawns != INVALID_HANDLE)
	{
		iTeam = CS_TEAM_CT;
		for (int i = 0; i < spawns.Length; i++)
		{
			spawn = spawns.Get(i);
			if(spawn != INVALID_HANDLE)
			{
				if(!spawn.GetValue("ID", iSpawnID))
				{
					CPrintToChat(client, "Couldn't update a spawn, because there was no spawnid saved");
					continue;
				}
				
				if(!spawn.GetArray("pos", fPos, 3))
				{
					CPrintToChat(client, "Couldn't update a spawn, because there was no position saved");
					continue;
				}
				
				if(!spawn.GetString("primary", sPrimary, sizeof(sPrimary)))
				{
					Format(sPrimary, sizeof(sPrimary), "NULL");
				}
				Format(sQuery, sizeof(sQuery), "UPDATE `execute`.`spawns` SET `team` = '%i', `pos_x` = '%f', `pos_y` = '%f', `pos_z` = '%f', `primary` = '%s' WHERE `spawns`.`spawn_id` = %i", iTeam, fPos[0], fPos[1], fPos[2], sPrimary, iSpawnID);
				g_hDatabase.Query(DB_NewSpawnSaved_Callback, sQuery, data);
			}
		}
	}
	CPrintToChat(client, "Your Scenario has been sucesfully been saved");
	g_smSpawn[client] = view_as<StringMap>(INVALID_HANDLE);
	g_smScenario[client] = view_as<StringMap>(INVALID_HANDLE);
	g_iIndex[client] = -1;
	
}
public void DB_SaveNewScenario_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if(db == INVALID_HANDLE || strlen(error) > 0 || results == INVALID_HANDLE)
	{
		LogError("Error during saving scenarios: %s", error);
		if(IsClientConnected(client))
		{
			CPrintToChat(client, "There has been an error during saving your scenario. Check your console.");
			PrintToConsole(client, "%s", error);
		}
		return;
	}
	char sQuery[512];
	ArrayList spawns;
	StringMap spawn;
	int iScenarioID = results.InsertId;
	int iTeam;
	float fPos[3];
	char sPrimary[32];
	if(g_smScenario[client].GetValue("spawnst", spawns) && spawns != INVALID_HANDLE)
	{
		iTeam = CS_TEAM_T;
		for (int i = 0; i < spawns.Length; i++)
		{
			spawn = spawns.Get(i);
			if(spawn != INVALID_HANDLE)
			{	
				if(!spawn.GetArray("pos", fPos, 3))
				{
					CPrintToChat(client, "Couldn't save a spawn, because there was no position saved");
					continue;
				}
				
				if(!spawn.GetString("primary", sPrimary, sizeof(sPrimary)))
				{
					Format(sPrimary, sizeof(sPrimary), "NULL");
				}
				Format(sQuery, sizeof(sQuery), "INSERT INTO `execute`.`spawns` (`spawn_id`, `scenario_id`, `team`, `pos_x`, `pos_y`, `pos_z`, `primary`) VALUES (NULL, '%i', '%i', '%f', '%f', '%f', '%s')", iScenarioID, iTeam, fPos[0], fPos[1], fPos[2], sPrimary);
				g_hDatabase.Query(DB_NewSpawnSaved_Callback, sQuery, data);
			}
		}
	}
	if(g_smScenario[client].GetValue("spawnsct", spawns) && spawns != INVALID_HANDLE)
	{
		iTeam = CS_TEAM_CT;
		for (int i = 0; i < spawns.Length; i++)
		{
			spawn = spawns.Get(i);
			if(spawn != INVALID_HANDLE)
			{
				if(!spawn.GetArray("pos", fPos, 3))
				{
					CPrintToChat(client, "Couldn't save a spawn, because there was no position saved");
					continue;
				}
				
				if(!spawn.GetString("primary", sPrimary, sizeof(sPrimary)))
				{
					Format(sPrimary, sizeof(sPrimary), "NULL");
				}
				Format(sQuery, sizeof(sQuery), "INSERT INTO `execute`.`spawns` (`spawn_id`, `scenario_id`, `team`, `pos_x`, `pos_y`, `pos_z`, `primary`) VALUES (NULL, '%i', '%i', '%f', '%f', '%f', '%s')", iScenarioID, iTeam, fPos[0], fPos[1], fPos[2], sPrimary);
				g_hDatabase.Query(DB_NewSpawnSaved_Callback, sQuery, data);
			}
		}
	}
	CPrintToChat(client, "Your Scenario has been sucesfully been saved");
	g_smSpawn[client] = view_as<StringMap>(INVALID_HANDLE);
	g_aScenarios.Push(g_smScenario[client]);
	g_aScenarioId.Push(iScenarioID);
	g_smScenario[client] = view_as<StringMap>(INVALID_HANDLE);
	g_iIndex[client] = -1;
}

public void DB_NewSpawnSaved_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if(db == INVALID_HANDLE || strlen(error) > 0 || results == INVALID_HANDLE)
	{
		LogError("Error during saving a spawn: %s", error);
		if(IsClientConnected(client))
		{
			CPrintToChat(client, "There has been an error during saving a spawn. Check your console.");
			PrintToConsole(client, "%s", error);
		}
		return;
	}
}
public void DB_LoadScenarios_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == INVALID_HANDLE || strlen(error) > 0 || results == INVALID_HANDLE)
		SetFailState("Error during loading scenarios: %s", error);
	
	ArrayList aScenarios = new ArrayList(1);
	ArrayList aScenarioId = new ArrayList(1);
	
	int iID;
	int iIndex = -1;
	char sName[32];
	char sDesc[64];
	int iTeam;
	float fPos[3];
	char sPrimary[32];
	
	while(results.FetchRow())
	{
		iID = results.FetchInt(0);
		iIndex = aScenarioId.FindValue(iID);
		if(iIndex == -1)
		{
			StringMap smScenario = new StringMap();
			results.FetchString(1, sName, sizeof(sName));
			results.FetchString(2, sDesc, sizeof(sDesc));
			smScenario.SetString("name", sName, false);
			smScenario.SetString("desc", sDesc, false);
			smScenario.SetValue("amount", results.FetchInt(3), false);
			iIndex = aScenarios.Push(smScenario);
			aScenarioId.Push(iID);
		}
		
		StringMap smScenario = view_as<StringMap>(aScenarios.Get(iIndex));
		StringMap smSpawn = new StringMap();
		ArrayList aSpawns;
		iTeam = results.FetchInt(4);
		if(iTeam == CS_TEAM_CT)
		{
			if(!smScenario.GetValue("spawnsct", aSpawns))
			{
				aSpawns = new ArrayList(1);
			}
		}else{
			if(!smScenario.GetValue("spawnst", aSpawns))
			{
				aSpawns = new ArrayList(1);
			}
		}
		
		
		results.FetchString(8, sPrimary, sizeof(sPrimary));
		smSpawn.SetString("primary", sPrimary, false);
		fPos[0] = results.FetchFloat(5);
		fPos[1] = results.FetchFloat(6);
		fPos[2] = results.FetchFloat(7);
		smSpawn.SetArray("pos", fPos, 3, false);
		smSpawn.SetValue("ID", results.FetchInt(9), false);
		aSpawns.Push(smSpawn);
		
		if(iTeam == CS_TEAM_CT)
			smScenario.SetValue("spawnsct", aSpawns, true);
		else
			smScenario.SetValue("spawnst", aSpawns, true);
	}
	
	g_aScenarioId = aScenarioId;
	g_aScenarios = aScenarios;
}

public Action Command_Edit(int client, int args)
{
	if(g_smScenario[client] == INVALID_HANDLE)
	{
		ShowSelectMenu(client);
	}else{
		ShowEditMenu(client);
	}
	
	return Plugin_Handled;
}

void ShowSelectMenu(int client)
{
	Menu menu = new Menu(SelectMenu);
	menu.SetTitle("Choose the scenario that you want to edit:");
	menu.AddItem("new", "Create a new one");
	char sName[32];
	char sInfo[5];
	for (int i = 0; i < g_aScenarios.Length; i++)
	{
		StringMap smTemp = g_aScenarios.Get(i);
		if(smTemp.GetString("name", sName, sizeof(sName)))
		{
			IntToString(i, sInfo, sizeof(sInfo));
			menu.AddItem(sInfo, sName);
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "new", false))
		{
			StringMap smScenario = new StringMap();
			g_smScenario[client] = smScenario;
			g_iIndex[client] = -1;
		}else{
			g_smScenario[client] = g_aScenarios.Get(StringToInt(info));
			g_iIndex[client] = StringToInt(info);
		}
		
		ShowEditMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowEditMenu(int client)
{
	if(g_smScenario[client] == INVALID_HANDLE)
	{
		CPrintToChat(client, "Something went wrong. Try it again");
		return;
	}
	
	Menu menu = new Menu(EditMenu);
	menu.SetTitle("Edit Menu:");
	
	char sName[32];
	char sItem[64];
	int iAmount;
	if(!g_smScenario[client].GetString("name", sName, sizeof(sName)))
	{
		menu.AddItem("name", "Name: UNDEFINED");
	}else{
		Format(sItem, sizeof(sItem), "Name: %s", sName);
		menu.AddItem("name", sItem);
	}
	
	if(!g_smScenario[client].GetString("desc", sName, sizeof(sName)))
	{
		menu.AddItem("desc", "Description: UNDEFINED");
	}else{
		Format(sItem, sizeof(sItem), "Description: %s", sName);
		menu.AddItem("desc", sItem);
	}
	
	if(!g_smScenario[client].GetValue("amount", iAmount))
	{
		menu.AddItem("amount", "Player Amount: UNDEFINED");
	}else{
		Format(sItem, sizeof(sItem), "Player Amount: %i", iAmount);
		menu.AddItem("amount", sItem);
	}
	
	menu.AddItem("spawn", "Edit spawns");
	menu.AddItem("save", "Save this scenario");
	menu.AddItem("delete", "Delete this scenario");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int EditMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "name", false))
			g_iListen[client] = 1;
		else if (StrEqual(info, "desc", false))
			g_iListen[client] = 2;
		else if (StrEqual(info, "amount", false))
			g_iListen[client] = 3;
		else if (StrEqual(info, "save", false))
			SaveCurrentScenario(client);
		else if (StrEqual(info, "delete", false))
			DeleteCurrentScenario(client);
		else if (StrEqual(info, "spawn"))
			ShowSpawnMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int SpawnEditMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "pos", false))
		{
			float fPos[3];
			GetClientAbsOrigin(client, fPos);
			g_smSpawn[client].SetArray("pos", fPos, 3, true);
			CPrintToChat(client, "Saved the spawn position locally");
		}
		else if (StrEqual(info, "primary", false))
			ShowPrimaryMenu(client);
		else if (StrEqual(info, "delete", false))
			return; //TODO
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void ShowPrimaryMenu(int client)
{
	Menu menu = new Menu(PrimaryMenu);
	menu.SetTitle("Choose a class");
	menu.AddItem("rifle", "Rifle");
	menu.AddItem("shotgun", "Shotgun");
	menu.AddItem("mp", "MP");
	menu.AddItem("random", "Random");
	menu.AddItem("pref", "Prefered Primary");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PrimaryMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "rifle", false))
		{
			ShowRifleMenu(client);
		}else if (StrEqual(info, "shotgun", false)){
			ShowShotgunMenu(client);
		}else if (StrEqual(info, "mp", false)){
			ShowMPMenu(client);
		}else{
			g_smSpawn[client].SetString("primary", info, true);
		}
	}else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void ShowRifleMenu(int client)
{
	Menu menu = new Menu(RifleMenu);
	menu.SetTitle("Choose a rifle");
	char sInfo[16];
	for (int i = 0; i < sizeof(g_sRifles); i++)
	{
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, g_sRifles[i][1]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RifleMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		int iIndex = StringToInt(info);
		g_smSpawn[client].SetString("primary", g_sRifles[iIndex][0], true);
	}else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void ShowShotgunMenu(int client)
{
	Menu menu = new Menu(ShotgunMenu);
	menu.SetTitle("Choose a rifle");
	char sInfo[16];
	for (int i = 0; i < sizeof(g_sShotguns); i++)
	{
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, g_sShotguns[i][1]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ShotgunMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		int iIndex = StringToInt(info);
		g_smSpawn[client].SetString("primary", g_sShotguns[iIndex][0], true);
	}else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void ShowMPMenu(int client)
{
	Menu menu = new Menu(MPMenu);
	menu.SetTitle("Choose a rifle");
	char sInfo[16];
	for (int i = 0; i < sizeof(g_sMPs); i++)
	{
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, g_sMPs[i][1]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MPMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		int iIndex = StringToInt(info);
		g_smSpawn[client].SetString("primary", g_sMPs[iIndex][0], true);
	}else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void ShowSpawnMenu(int client)
{
	if(g_smScenario[client] == INVALID_HANDLE)
	{	
		CPrintToChat(client, "Couldn't allocate your current scenario. Please use !edit");
		return;
	}
	Menu menu = new Menu(SpawnMenu);
	menu.SetTitle("Select a spawn");
	menu.AddItem("new", "Create a new spawn");
	ArrayList spawns;
	StringMap spawn;
	int iID;
	char sInfo[16];
	char sItem[32];
	if(g_smScenario[client].GetValue("spawnst", spawns))
	{
		for (int i = 0; i <= spawns.Length; i++)
		{
			spawn = spawns.Get(i);
			if(spawn != INVALID_HANDLE && spawn.GetValue("ID", iID))
			{
				IntToString(iID, sInfo, sizeof(sInfo));
				Format(sItem, sizeof(sItem), "ID: %i", iID);
			}
		}
	}
	if(g_smScenario[client].GetValue("spawnsct", spawns))
	{
		for (int i = 0; i <= spawns.Length; i++)
		{
			spawn = spawns.Get(i);
			if(spawn != INVALID_HANDLE && spawn.GetValue("ID", iID))
			{
				IntToString(iID, sInfo, sizeof(sInfo));
				Format(sItem, sizeof(sItem), "ID: %i", iID);
			}
		}
	}
	menu.AddItem("back", "Go back");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SpawnMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "new", false))
		{
			StringMap smSpawn = new StringMap();
			g_smSpawn[client] = smSpawn;
			ShowSpawnEditMenu(client);
		}else if (StrEqual(info, "back", false)){
			ShowEditMenu(client);
		}else{
			ArrayList spawns;
			StringMap spawn;
			int iID = StringToInt(info);
			int iTemp;
			if(g_smScenario[client].GetValue("spawnst", spawns) && spawns != INVALID_HANDLE)
			{
				for (int i = 0; i < spawns.Length; i++)
				{
					spawn = spawns.Get(i);
					if(spawn != INVALID_HANDLE)
					{
						if(spawn.GetValue("ID", iTemp))
						{
							if(iID == iTemp)
							{
								g_smSpawn[client] = spawn;
								ShowSpawnEditMenu(client);
								return 0;
							}
						}
					}
				}
			}
			if(g_smScenario[client].GetValue("spawnsct", spawns) && spawns != INVALID_HANDLE)
			{
				for (int i = 0; i < spawns.Length; i++)
				{
					spawn = spawns.Get(i);
					if(spawn != INVALID_HANDLE)
					{
						if(spawn.GetValue("ID", iTemp))
						{
							if(iID == iTemp)
							{
								g_smSpawn[client] = spawn;
								ShowSpawnEditMenu(client);
								return 0;
							}
						}
					}
				}
			}
			CPrintToChat(client, "We couldn't find this spawn. Maybe it got deleted?");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowSpawnEditMenu(int client)
{
	if(g_smSpawn[client] == INVALID_HANDLE)
	{
		CPrintToChat(client, "Something went wrong. Please try again");
	}
	
	Menu menu = new Menu(SpawnEditMenu);
	
	menu.SetTitle("Spawn propertys");
	
	float fPos[3];
	char sItem[32];
	if(g_smSpawn[client].GetArray("pos", fPos, 3))
	{
		Format(sItem, sizeof(sItem), "Position: %f, %f, %f", fPos[0], fPos[1], fPos[2]);
		menu.AddItem("pos", sItem);
	}else{
		menu.AddItem("pos", "Position: UNDEFINED");
	}
	
	char sPrimary[16];
	if(g_smSpawn[client].GetString("primary", sPrimary, sizeof(sPrimary)))
	{
		Format(sItem, sizeof(sItem), "Primary Weapon: %s", sPrimary);
		menu.AddItem("primary", sItem);
	}else{
		menu.AddItem("primary", "Primary Weapon: UNDEFINED");
	}
	
	menu.AddItem("save", "Save this spawn");
}

void SaveCurrentScenario(int client)
{
	char sName[32];
	char sDesc[64];
	char sMap[32];
	
	GetCurrentMap(sMap, sizeof(sMap));
	
	int iAmount;
	
	if(!g_smScenario[client].GetString("name", sName, sizeof(sName)))
	{
		CPrintToChat(client, "You need to enter a name");
		ShowEditMenu(client);
		return;
	}
	if(!g_smScenario[client].GetString("desc", sDesc, sizeof(sDesc)))
	{
		CPrintToChat(client, "You need to enter a description");
		ShowEditMenu(client);
		return;
	}
	if(!g_smScenario[client].GetValue("amount", iAmount))
	{
		CPrintToChat(client, "You need to enter a player amount");
		ShowEditMenu(client);
		return;
	}
	
	char sQuery[512];
	if(g_iIndex[client] == -1)
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO `execute`.`scenarios` (`scenario_id`, `name`, `description`, `amount`, `map`) VALUES (NULL, '%s', '%s', '%i', '%s')", sName, sDesc, iAmount, sMap);
		g_hDatabase.Query(DB_SaveNewScenario_Callback, sQuery, GetClientUserId(client));
	}else{
		int iId = g_aScenarioId.Get(g_iIndex[client]);
		Format(sQuery, sizeof(sQuery), "UPDATE `execute`.`scenarios` SET `name` = '%s', `description` = '%s', `amount` = '%i' WHERE `scenarios`.`scenario_id` = %i", sName, sDesc, iAmount, iId);
		g_hDatabase.Query(DB_UpdateScenario_Callback, sQuery, GetClientUserId(client));
	}
}

void DeleteCurrentScenario(int client)
{
	if(g_iIndex[client] != -1)
	{
		char sQuery[512];
		Format(sQuery, sizeof(sQuery), "DELETE FROM `execute`.`scenarios` WHERE `scenarios`.`scenario_id` = %i", g_aScenarioId.Get(g_iIndex[client]));
		g_hDatabase.Query(DB_DeleteScenario_Callback, sQuery, GetClientUserId(client));
		g_aScenarioId.Erase(g_iIndex[client]);
		g_aScenarios.Erase(g_iIndex[client]);
	}
}

void CloseHandles(StringMap scenario)
{
	//Close all these handles. We dont want to leak the memory >:D.
	if(scenario != INVALID_HANDLE)
	{
		ArrayList spawntemp;
		StringMap spawn;
		if(scenario.GetValue("spawnst", spawntemp))
		{
			if(spawntemp != INVALID_HANDLE)
			{
				for (int i = 0; i < spawntemp.Length; i++)
				{
					spawn = spawntemp.Get(i);
					if(spawn != INVALID_HANDLE)
					{
						CloseHandle(spawn);
					}
				}
				CloseHandle(spawntemp);
			}
		}
		if(scenario.GetValue("spawnsct", spawntemp))
		{
			if(spawntemp != INVALID_HANDLE)
			{
				for (int i = 0; i < spawntemp.Length; i++)
				{
					spawn = spawntemp.Get(i);
					if(spawn != INVALID_HANDLE)
					{
						CloseHandle(spawn);
					}
				}
				CloseHandle(spawntemp);
			}
		}
		CloseHandle(scenario);
	}
}
public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!g_iListen[client])
	{
		if(g_smScenario[client] == INVALID_HANDLE)
			return;
		switch (g_iListen[client])
		{
			case 1:
			{
				g_smScenario[client].SetString("name", sArgs, true);
				CPrintToChat(client, "Saved the name locally");
				ShowEditMenu(client);
				g_iListen[client] = 0;
				return;
			}
			case 2:
			{
				g_smScenario[client].SetString("desc", sArgs, true);
				CPrintToChat(client, "Saved the description locally");
				ShowEditMenu(client);
				g_iListen[client] = 0;
				return;
			}
			case 3:
			{
				g_smScenario[client].SetValue("amount", StringToInt(sArgs), true);
				CPrintToChat(client, "Saved the amount locally");
				ShowEditMenu(client);
				g_iListen[client] = 0;
				return;
			}
		}
	}
	return;
}

public Action Command_Abort(int client, int args)
{
	g_iListen[client] = 0;
	ShowEditMenu(client);
}