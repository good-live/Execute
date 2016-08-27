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

Database g_hDatabase;

ArrayList g_aScenarios;

StringMap g_smScenario[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateConnect = late;
}

public void OnPluginStart()
{
	if(!g_bConnected)
		DB_Connect();
		
	g_aScenarios = new ArrayList(1);

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
	Format(sQuery, sizeof(sQuery), "SELECT `scenarios`.`scenario_id`,`scenarios`.`name`,`scenarios`.`description`,`scenarios`.`amount`,`spawns`.`team`,`spawns`.`pos_x`,`spawns`.`pos_y`,`spawns`.`pos_z`,`spawns`.`primary` FROM scenarios JOIN `spawns` ON `scenarios`.`scenario_id`=`spawns`.`scenario_id` WHERE `scenarios`.`map`='%s'", sMap);
	g_hDatabase.Query(DB_LoadScenarios_Callback, sQuery);
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
		aSpawns.Push(smSpawn);
		
		if(iTeam == CS_TEAM_CT)
			smScenario.SetValue("spawnsct", aSpawns, true);
		else
			smScenario.SetValue("spawnst", aSpawns, true);
	}
	
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
		}else{
			g_smScenario[client] = g_aScenarios.Get(StringToInt(info));
		}
		
		ShowEditMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
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
	
	if(!g_smScenario[client].GetValue("amount", iAmount))
	{
		menu.AddItem("amount", "Player Amount: UNDEFINED");
	}else{
		Format(sItem, sizeof(sItem), "Player Amount: %i", iAmount);
		menu.AddItem("amount", sItem);
	}
	
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
		else if (StrEqual(info, "amount", false))
			g_iListen[client] = 2;
		else if (StrEqual(info, "save", false))
			SaveCurrentScenario(client);
		else if (StrEqual(info, "delete", false))
			DeleteCurrentScenario(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void SaveCurrentScenario(int client)
{
	//Code to save the scenario
}

void DeleteCurrentScenario(int client)
{
	//Code to delete the scenario
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(g_iListen[client])
	{
		if(g_smScenario[client] == INVALID_HANDLE)
			return Plugin_Continue;
		switch (g_iListen[client])
		{
			case 1:
			{
				g_smScenario[client].SetString("name", sArgs, true);
				CPrintToChat(client, "Saved the name locally");
				ShowEditMenu(client);
				g_iListen[client] = 0;
				return Plugin_Handled;
			}
			case 2:
			{
				g_smScenario[client].SetValue("amount", StringToInt(sArgs), true);
				CPrintToChat(client, "Saved the amount locally");
				ShowEditMenu(client);
				g_iListen[client] = 0;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action Command_Abort(int client, int args)
{
	g_iListen[client] = 0;
	ShowEditMenu(client);
}