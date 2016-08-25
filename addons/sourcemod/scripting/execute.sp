#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>
#include <clientprefs>

#include "execute/execute_queue.sp"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Execute",
	author = PLUGIN_AUTHOR,
	description = "Play a randomized competetive Scenario.",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

ArrayList g_aScenarios;
ArrayList g_aPossibleScenarios;

bool g_bUseM4[MAXPLAYERS + 1];
bool g_bIsActive;

Handle g_hM4Cookie;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Ex_RegisterScenario", Native_RegisterScenario);
	//TODO Chane Cokkie Access when everything is working fine. This is just for debug reasons readable.
	g_hM4Cookie = RegClientCookie("M4A1S", "Whether you wanna use the M4A1S or just the M4", CookieAccess_Protected); 
}

public void OnPluginStart()
{
	LoadTranslations("execute.phrases");
	
	g_aScenarios = new ArrayList(1);
	g_aPossibleScenarios = new ArrayList(1);
	
	//Cookie LateLoading
	for (int i = 1; i <= MaxClients; i++)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        OnClientCookiesCached(i);
    }
	
	Queue_OnPluginStart();
	
	HookEvent("round_start", OnRoundStart);
	AddCommandListener(OnJoinTeam, "jointeam");
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CalculatePlayers();
}

public void OnClientCookiesCached(int client)
{
    char sValue[8];
    GetClientCookie(client, g_hM4Cookie, sValue, sizeof(sValue));
    
    g_bUseM4[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public Action OnJoinTeam(int client, const char[] szCommand, int iArgCount)
{
	if(iArgCount < 1)
		return Plugin_Continue;

	char szData[2];
	GetCmdArg(1, szData, sizeof(szData));
	int iTeam = StringToInt(szData);
	
	if(iTeam !=  CS_TEAM_SPECTATOR && !IsClientActive(client))
	{
		if(g_bIsActive)
		{
			AddClientToQueue(client);
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			return Plugin_Stop;
		}else{
			AddClientToGame(client);
			CreateTimer(0.1, Timer_CalculatePlayers);
		}
	}
	if(iTeam ==  CS_TEAM_SPECTATOR)
	{
		RemoveClientFromGame(client);
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	RemoveClientFromQueue(client);
	RemoveClientFromGame(client);
}

public void OnMapEnd()
{
	for (int i = 0; i < g_aScenarios.Length; i++)
	{
		StringMap smTemp = g_aScenarios.Get(i);
		if(smTemp != INVALID_HANDLE)
		{
			CloseHandle(smTemp);
		}
	}
	
	g_aScenarios.Clear();
	g_aActive.Clear();
	g_bIsActive = false;
	g_aQueue.Clear();
}

public Action Timer_CalculatePlayers(Handle timer)
{
	CalculatePlayers();
	return;
}

void CalculatePlayers()
{
	g_bIsActive = true;
	int iActivePlayers = GetActivePlayers();
	for (int i = g_aQueue.Length; i >= 0; i--)
	{
		if(GetScenarioAmount(iActivePlayers + i) > 0)
		{
			LoadPossibleScenarios(iActivePlayers + i);
			InitiateRandomScenario(i);
			return;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientConnected(i))
			CPrintToChat(i, "%t%t", "TAG", "Not enough players");
	
	CPrintToChatAll("Setting Game to inactive!");
	g_bIsActive = false;
}

int GetScenarioAmount(int iClientAmount)
{
	int iAmount = 0;
	StringMap smBuffer;
	int iTemp;
	for (int i = 0; i < g_aScenarios.Length; i++)
	{
		smBuffer = view_as<StringMap>(g_aScenarios.Get(i));
		if(smBuffer.GetValue("amount", iTemp))
			if(iTemp == iClientAmount)
				iAmount++;
	}
	return iAmount;
}

void LoadPossibleScenarios(int iClientAmount)
{
	g_aPossibleScenarios.Clear();
	StringMap smBuffer;
	int iTemp;
	for (int i = 0; i < g_aScenarios.Length; i++)
	{
		smBuffer = view_as<StringMap>(g_aScenarios.Get(i));
		if(smBuffer.GetValue("amount", iTemp))
			if(iTemp == iClientAmount)
				g_aPossibleScenarios.Push(smBuffer);
	}
}

void InitiateRandomScenario(int iAmountQueue)
{
	int iIndex;
	
	SetRandomSeed(GetTime());
	
	iIndex = GetRandomInt(0, g_aPossibleScenarios.Length - 1);
	
	StringMap smActiveScenario = view_as<StringMap>(g_aPossibleScenarios.Get(iIndex));
	
	char sName[64];
	smActiveScenario.GetString("name", sName, sizeof(sName));
	
	CPrintToChatAll("The Scenario %s has started. %i player/s from the Queue get added to the game.", sName, iAmountQueue);
	
	AddClientsToGame(iAmountQueue);
	
	SpawnClients(smActiveScenario);
}

void SpawnClients(StringMap smActiveScenario)
{
	int iAmount = 0;
	char sSpawn[16];
	StringMap smSpawn;
	int iTeam;
	float fPos[3];
	for (int i = 0; i < g_aActive.Length; i++)
	{
		int client = GetClientOfUserId(g_aActive.Get(i));
		if(!IsClientValid(client))
		{
			LogError("A invalid client has been in the active clients List.");
			g_aActive.Erase(i);
			CalculatePlayers();
			return;
		}
		
		Format(sSpawn, sizeof(sSpawn), "spawn_%i", i + 1);
		
		if(!smActiveScenario.GetValue(sSpawn, smSpawn))
		{
			int iAmounts;
			smActiveScenario.GetValue("amount", iAmounts);
			
			if(iAmount >= i+1)
				SetFailState("There is no Spawn number %i defined for a Scenario. Needed Spawns: %i", i + 1, iAmounts);
			
			LogError("There are too much clients for the current Scenario. Failed to calculate scenario correctly. Calculating again ...");
			CalculatePlayers();
			return;
		}
		
		if(smSpawn == INVALID_HANDLE)
		{
			LogError("The spawn %i is invalid.", i+1);
			CalculatePlayers();
			return;
		}
		
		if(smSpawn.GetValue("team", iTeam))
		{
			if(GetClientTeam(client) != iTeam)
				CS_SwitchTeam(client, iTeam);
		}
		
		if(!smSpawn.GetArray("pos", fPos, sizeof(fPos)))
		{
			LogError("There is no spawning Position for spawn %i.", i+1);
		}
		
		if(!IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		
		TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
		CPrintToChatAll("[Execute] Client %N has been spawned at Positon: %f %f %f", client, fPos[0], fPos[1], fPos[2]);
		
		AssignWeapons(client, smSpawn);
	}
}

void AssignWeapons(int client, StringMap smActiveScenario)
{
	StripWeapons(client);
	
	char sPrimary[32];
	if(smActiveScenario.GetString("primary", sPrimary, sizeof(sPrimary)))
	{
		if(StrEqual(sPrimary, "weapon_m4a1", false) || StrEqual(sPrimary, "weapon_m4a1_silencer", false))
		{
			if(g_bUseM4[client])
				GivePlayerItem(client, "weapon_m4a1");
			else
				GivePlayerItem(client, "weapon_m4a1_silencer");
		}else{
			GivePlayerItem(client, sPrimary);
		}
	}
}

void StripWeapons(int client) 
{  
	for(int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
	{
		int iCurrent = GetPlayerWeaponSlot(client, i);
		if(iCurrent != INVALID_ENT_REFERENCE && IsValidEdict(iCurrent))
		{
			RemovePlayerItem(client, iCurrent);
			RemoveEdict(iCurrent);
		}
	}
	
	int entity = GivePlayerItem(client, "weapon_knife");
	if(entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity))
		return;
}

int IsClientValid(int client)
{
	if(0 < client <= MaxClients && IsClientConnected(client))
		return true;
	
	return false;
}

public int Native_RegisterScenario(Handle plugin, int numParams)
{
	StringMap smScenario = GetNativeCell(1);
	int iAmount;
	smScenario.GetValue("amount", iAmount);
	CPrintToChatAll("Adding a new scenario for %i players", iAmount );
	if(smScenario == INVALID_HANDLE)
		return 0;
		
	g_aScenarios.Push(smScenario);
	return 0;
}
