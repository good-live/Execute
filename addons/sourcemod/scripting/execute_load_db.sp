#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <execute>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Execute - Load DB",
	author = PLUGIN_AUTHOR,
	description = "Loads the Scenarios from the Database",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

bool g_bConnected;
bool g_bLateConnect;

Database g_hDatabase;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateConnect = late;
}

public void OnPluginStart()
{
	if(!g_bConnected)
		DB_Connect();
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
	Format(sQuery, sizeof(sQuery), "SELECT scenario_id, name, description, amount, team, primary, pos_x, pos_y, pos_z FROM scenarios JOIN spawns ON scenarios.scenario_id=spawns.scenario_id WHERE map=%s", sMap);
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
		if(!smScenario.GetValue("spawns", aSpawns))
		{
			aSpawns = new ArrayList(1);
		}
		
		iTeam = results.FetchInt(4);
		smSpawn.SetValue("team", iTeam, false);
		results.FetchString(5, sPrimary, sizeof(sPrimary));
		smSpawn.SetString("primary", sPrimary, false);
		fPos[0] = results.FetchFloat(6);
		fPos[1] = results.FetchFloat(7);
		fPos[2] = results.FetchFloat(8);
		smSpawn.SetArray("pos", fPos, 3, false);
		aSpawns.Push(smSpawn);
		smScenario.SetValue("spawns", aSpawns, true);
	}
	
	for (int i = 0; i < aScenarios.Length; i++)
	{
		Ex_RegisterScenario(aScenarios.Get(i));
	}
}